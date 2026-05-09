import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../providers/app_provider.dart';
import '../widgets/ingredient_picker_sheet.dart';

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
  String? _category;
  late List<_IngredientEntry> _entries;
  String? _nameError;

  bool get _isEdit => widget.recipe != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.recipe?.name ?? '');
    _descController =
        TextEditingController(text: widget.recipe?.description ?? '');
    _category = widget.recipe?.category;
    _entries = (widget.recipe?.ingredients ?? [])
        .map((i) => _IngredientEntry(ingredient: i))
        .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    for (final e in _entries) {
      e.dispose();
    }
    super.dispose();
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
      final v = value.trim();
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
        title: const Text(
          'Нова категорія',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          decoration: InputDecoration(
            hintText: 'Назва категорії…',
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
            child: const Text(
              'Скасувати',
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
            child: const Text('Додати'),
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

    if (_isEdit) {
      final updated = widget.recipe!.copyWith(
        name: name,
        descriptionOrNull: desc.isEmpty ? null : desc,
        categoryOrNull: _category,
        ingredients: ingredients,
      );
      provider.saveRecipe(updated);
    } else {
      final recipe = Recipe.create(
        name: name,
        description: desc.isEmpty ? null : desc,
        category: _category,
        ingredients: ingredients,
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
                      maxLength: 300,
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
                    // Category
                    const _SectionLabel('КАТЕГОРІЯ'),
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
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 140),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? Colors.black
                                        : Colors.white,
                                    border: Border.all(
                                        color: selected
                                            ? Colors.black
                                            : Colors.black38,
                                        width: 1.5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    cat,
                                    style: TextStyle(
                                      fontFamily: 'FixelText',
                                      fontSize: 14,
                                      color: selected
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
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
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add,
                                      size: 16, color: Colors.black38),
                                  SizedBox(width: 4),
                                  Text(
                                    'Своя',
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
                    // Ingredients
                    const _SectionLabel('ІНГРЕДІЄНТИ'),
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
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, size: 18, color: Colors.black45),
                            SizedBox(width: 8),
                            Text(
                              'Додати інгредієнт',
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

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
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
