import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../providers/app_provider.dart';
import '../widgets/ingredient_picker_sheet.dart';

const _nativePickerChannel = MethodChannel('com.texapp.smakolist/image_picker');

class _IngredientEntry {
  RecipeIngredient ingredient;
  final TextEditingController quantityController;

  _IngredientEntry({required this.ingredient})
      : quantityController = TextEditingController(
          text: ingredient.quantity != null
              ? (ingredient.quantity! % 1 == 0
                  ? ingredient.quantity!.toInt().toString()
                  : ingredient.quantity!.toString())
              : '',
        );

  void dispose() => quantityController.dispose();
}

class AddEditRecipeScreen extends StatefulWidget {
  final Recipe? recipe;

  const AddEditRecipeScreen({super.key, this.recipe});

  @override
  State<AddEditRecipeScreen> createState() => _AddEditRecipeScreenState();
}

class _AddEditRecipeScreenState extends State<AddEditRecipeScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late Set<MealType> _tags;
  String? _category;
  late List<_IngredientEntry> _entries;
  late List<TextEditingController> _stepControllers;
  late TextEditingController _cookTimeController;
  String? _photoPath;     // relative: 'recipe_photos/file.jpg' (stored in Recipe)
  String? _photoAbsPath;  // absolute: resolved at runtime for Image.file
  String? _nameError;

  bool get _isEdit => widget.recipe != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.recipe?.name ?? '');
    _descController =
        TextEditingController(text: widget.recipe?.description ?? '');
    _tags = Set<MealType>.from(widget.recipe?.tags ?? []);
    _category = widget.recipe?.category;
    _photoPath = widget.recipe?.photoPath;
    if (_photoPath != null) _resolvePhotoPath(_photoPath!);
    _entries = (widget.recipe?.ingredients ?? [])
        .map((i) => _IngredientEntry(ingredient: i))
        .toList();
    _stepControllers = (widget.recipe?.steps ?? [])
        .map((s) => TextEditingController(text: s))
        .toList();
    _cookTimeController = TextEditingController(
      text: widget.recipe?.cookTimeMinutes?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    for (final e in _entries) {
      e.dispose();
    }
    for (final c in _stepControllers) {
      c.dispose();
    }
    _cookTimeController.dispose();
    super.dispose();
  }

  Future<void> _resolvePhotoPath(String relative) async {
    final String abs;
    if (relative.startsWith('/')) {
      abs = relative;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      abs = p.join(dir.path, relative);
    }
    if (mounted) setState(() => _photoAbsPath = abs);
  }

  Future<XFile?> _pickFromSource(ImageSource source) async {
    if (Platform.isIOS) {
      final sourceArg = source == ImageSource.camera ? 'camera' : 'gallery';
      final path = await _nativePickerChannel.invokeMethod<String>('pickImage', sourceArg);
      return path != null ? XFile(path) : null;
    }
    return ImagePicker().pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 1920,
      maxHeight: 1920,
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await _pickFromSource(source);
    if (picked == null) return;
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: S.recipeCropPhoto,
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: true,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: S.recipeCropPhoto,
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          rotateButtonsHidden: true,
          rotateClockwiseButtonHidden: true,
          aspectRatioPickerButtonHidden: true,
        ),
      ],
    );
    if (cropped == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(dir.path, 'recipe_photos'));
    if (!photosDir.existsSync()) photosDir.createSync(recursive: true);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final dest = p.join(photosDir.path, fileName);
    await File(cropped.path).copy(dest);

    if (mounted) {
      setState(() {
        _photoPath = p.join('recipe_photos', fileName);
        _photoAbsPath = dest;
      });
    }
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(S.recipePhotoGallery, style: const TextStyle(fontFamily: 'FixelText', fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(S.recipePhotoCamera, style: const TextStyle(fontFamily: 'FixelText', fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _toggleTag(MealType tag) {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_tags.contains(tag)) {
        _tags.remove(tag);
      } else {
        _tags.add(tag);
      }
    });
  }

  void _addIngredient(String name) {
    setState(() {
      _entries.add(_IngredientEntry(
        ingredient: RecipeIngredient(name: name, unit: kDefaultUnits.first),
      ));
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _entries[index].dispose();
      _entries.removeAt(index);
    });
  }

  void _updateUnit(int index, String unit) {
    setState(() {
      _entries[index].ingredient =
          _entries[index].ingredient.copyWith(unit: unit);
    });
  }

  void _addStep() {
    setState(() {
      _stepControllers.add(TextEditingController());
    });
  }

  void _removeStep(int index) {
    setState(() {
      _stepControllers[index].dispose();
      _stepControllers.removeAt(index);
    });
  }

  void _showIngredientPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => IngredientPickerSheet(onSelected: _addIngredient),
    );
  }

  void _showAddCategoryDialog() {
    final provider = context.read<AppProvider>();
    final controller = TextEditingController();

    void submit(String value) {
      final v = value.trim().toLowerCase();
      if (v.isEmpty) return;
      provider.addCustomCategory(v);
      if (mounted) setState(() => _category = v);
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          S.recipeNewCategory,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          decoration: InputDecoration(
            hintText: S.recipeCategoryNameHint,
            hintStyle: const TextStyle(color: Colors.black38),
            counterStyle: const TextStyle(
              fontFamily: 'FixelText',
              fontSize: 11,
              color: Colors.black38,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onSubmitted: (v) {
            submit(v);
            Navigator.of(ctx).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              S.commonCancel,
              style: TextStyle(color: Colors.black54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              submit(controller.text);
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(S.commonAdd),
          ),
        ],
      ),
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final provider = context.read<AppProvider>();
    if (provider.isNameTaken(name, excludeId: widget.recipe?.id)) {
      setState(() => _nameError = S.recipeNameErrorDuplicate);
      return;
    }

    HapticFeedback.mediumImpact();

    final desc = _descController.text.trim();
    final ingredients = _entries.map((e) {
      final qty = double.tryParse(e.quantityController.text.trim());
      return e.ingredient.copyWith(quantity: qty, clearQuantity: qty == null);
    }).toList();
    final steps = _stepControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final cookRaw = int.tryParse(_cookTimeController.text.trim());
    final cookTimeMinutes = (cookRaw != null && cookRaw > 0) ? cookRaw : null;

    if (_isEdit) {
      final updated = widget.recipe!.copyWith(
        name: name,
        descriptionOrNull: desc.isEmpty ? null : desc,
        tags: _tags.toList(),
        categoryOrNull: _category,
        ingredients: ingredients,
        photoPathOrNull: _photoPath,
        stepsOrNull: steps.isEmpty ? null : steps,
        cookTimeMinutesOrNull: cookTimeMinutes,
      );
      provider.saveRecipe(updated);
    } else {
      final recipe = Recipe.create(
        name: name,
        description: desc.isEmpty ? null : desc,
        tags: _tags.toList(),
        category: _category,
        ingredients: ingredients,
        photoPath: _photoPath,
        steps: steps.isEmpty ? null : steps,
        cookTimeMinutes: cookTimeMinutes,
      );
      provider.saveRecipe(recipe);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _nameController.text.trim().isNotEmpty;
    final categories = context.watch<AppProvider>().allCategories;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Text(
                  _isEdit ? S.recipeEditTitle : S.recipeAddTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
            const Divider(height: 1, thickness: 1, color: Colors.black12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // Photo picker
                    GestureDetector(
                      onTap: _showPhotoSourceSheet,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _photoPath != null
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    if (_photoAbsPath != null)
                                      Image.file(
                                        File(_photoAbsPath!),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.black.withValues(alpha: 0.04),
                                        ),
                                      ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () => setState(() {
                                          _photoPath = null;
                                          _photoAbsPath = null;
                                        }),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.55),
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(6),
                                          child: const Icon(Icons.close, color: Colors.white, size: 18),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate_outlined, size: 36, color: Colors.black38),
                                      SizedBox(height: 8),
                                      Text(
                                        S.recipeAddPhoto,
                                        style: TextStyle(
                                          fontFamily: 'FixelText',
                                          fontSize: 14,
                                          color: Colors.black38,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Name field
                    _SectionLabel(S.recipeSectionName),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      maxLength: 60,
                      decoration: InputDecoration(
                        hintText: S.recipeNameHint,
                        hintStyle: const TextStyle(color: Colors.black38),
                        errorText: _nameError,
                        errorStyle: const TextStyle(
                          fontFamily: 'FixelText',
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: Colors.black54, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: Colors.black54, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        counterStyle: const TextStyle(
                          fontFamily: 'FixelText',
                          fontSize: 11,
                          color: Colors.black38,
                        ),
                      ),
                      onChanged: (_) {
                        if (_nameError != null) {
                          setState(() => _nameError = null);
                        } else {
                          setState(() {});
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    // Description
                    _SectionLabel(S.recipeSectionDesc),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descController,
                      maxLines: null,
                      maxLength: 140,
                      decoration: InputDecoration(
                        hintText: S.recipeDescHint,
                        hintStyle: const TextStyle(color: Colors.black38),
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.04),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        counterStyle: const TextStyle(
                          fontFamily: 'FixelText',
                          fontSize: 11,
                          color: Colors.black38,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Cook time
                    _SectionLabel(S.recipeSectionCookTime),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: _cookTimeController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              hintText: S.recipeCookTimeHint,
                              hintStyle: const TextStyle(color: Colors.black38),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Colors.black, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Colors.black, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          S.recipeCookTimeMinutes,
                          style: const TextStyle(
                            fontFamily: 'FixelText',
                            fontSize: 15,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Category
                    _SectionLabel(S.recipeSectionCategory),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ...categories.map((cat) {
                            final selected = _category == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _category = selected ? null : cat;
                                }),
                                child: _PillChip(
                                  label: cat,
                                  selected: selected,
                                ),
                              ),
                            );
                          }),
                          GestureDetector(
                            onTap: _showAddCategoryDialog,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.black26, width: 1.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add,
                                      size: 16, color: Colors.black38),
                                  SizedBox(width: 4),
                                  Text(
                                    S.recipeCategoryNewTag,
                                    style: TextStyle(
                                      fontFamily: 'FixelText',
                                      fontSize: 14,
                                      color: Colors.black38,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Meal type tags (optional)
                    _SectionLabel(S.recipeSectionTags),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: MealType.values.map((t) {
                          final isActive = _tags.contains(t);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => _toggleTag(t),
                              child: _PillChip(
                                label: t.label,
                                selected: isActive,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Ingredients
                    _SectionLabel(S.recipeSectionIngredients),
                    const SizedBox(height: 8),
                    ..._entries.asMap().entries.map((entry) {
                      final i = entry.key;
                      final e = entry.value;
                      return _IngredientRow(
                        entry: e,
                        onRemove: () => _removeIngredient(i),
                        onUnitChanged: (unit) => _updateUnit(i, unit),
                      );
                    }),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: _showIngredientPicker,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: Colors.black26, width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, size: 18, color: Colors.black45),
                            SizedBox(width: 8),
                            Text(
                              S.recipeAddIngredient,
                              style: TextStyle(
                                fontFamily: 'FixelText',
                                fontSize: 15,
                                color: Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Steps
                    _SectionLabel(S.recipeSectionSteps),
                    const SizedBox(height: 8),
                    ..._stepControllers.asMap().entries.map((entry) {
                      final i = entry.key;
                      final controller = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              margin: const EdgeInsets.only(top: 10, right: 10),
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  fontFamily: 'FixelText',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: controller,
                                maxLines: null,
                                decoration: InputDecoration(
                                  hintText: S.recipeStepHint(i + 1),
                                  hintStyle: const TextStyle(color: Colors.black38),
                                  filled: true,
                                  fillColor: Colors.black.withValues(alpha: 0.04),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18, color: Colors.black38),
                              onPressed: () => _removeStep(i),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                          ],
                        ),
                      );
                    }),
                    GestureDetector(
                      onTap: _addStep,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black26, width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, size: 18, color: Colors.black45),
                            SizedBox(width: 8),
                            Text(
                              S.recipeAddStep,
                              style: TextStyle(
                                fontFamily: 'FixelText',
                                fontSize: 15,
                                color: Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            // Save button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Opacity(
                opacity: canSave ? 1.0 : 0.4,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: canSave ? _save : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.black,
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      S.recipeBtnSave,
                      style: const TextStyle(
                        fontFamily: 'FixelText',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  final _IngredientEntry entry;
  final VoidCallback onRemove;
  final void Function(String) onUnitChanged;

  const _IngredientRow({
    required this.entry,
    required this.onRemove,
    required this.onUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                entry.ingredient.name,
                style: const TextStyle(
                  fontFamily: 'FixelText',
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 64,
              child: TextField(
                controller: entry.quantityController,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'FixelText', fontSize: 14),
                decoration: InputDecoration(
                  hintText: '–',
                  hintStyle: const TextStyle(color: Colors.black38),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 6),
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: Colors.black26, width: 1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: Colors.black, width: 1.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            DropdownButton<String>(
              value: kDefaultUnits.contains(entry.ingredient.unit)
                  ? entry.ingredient.unit
                  : kDefaultUnits.first,
              underline: const SizedBox(),
              isDense: true,
              style: const TextStyle(
                fontFamily: 'FixelText',
                fontSize: 14,
                color: Colors.black,
              ),
              items: kDefaultUnits
                  .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                  .toList(),
              onChanged: (u) {
                if (u != null) onUnitChanged(u);
              },
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: Colors.black38),
              onPressed: onRemove,
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillChip extends StatelessWidget {
  final String label;
  final bool selected;

  const _PillChip({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? Colors.black : Colors.white,
        border: Border.all(
          color: selected ? Colors.black : Colors.black38,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'FixelText',
          fontSize: 14,
          color: selected ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'FixelText',
        fontWeight: FontWeight.w700,
        fontSize: 10,
        letterSpacing: 1.2,
        color: Colors.black54,
      ),
    );
  }
}
