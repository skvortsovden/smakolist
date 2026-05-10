import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../l10n/strings.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../models/shopping_list.dart';
import '../providers/app_provider.dart';
import '../widgets/ingredient_picker_sheet.dart';

// ── Draft model ───────────────────────────────────────────────────────────────

class _ItemDraft {
  final String id;
  final String name;
  String unit;
  bool checked;
  final TextEditingController qtyController;

  _ItemDraft.fromItem(ShoppingItem item)
      : id = item.id,
        name = item.name,
        unit = item.unit,
        checked = item.checked,
        qtyController = TextEditingController(
          text: item.quantity != null
              ? (item.quantity! % 1 == 0
                  ? item.quantity!.toInt().toString()
                  : item.quantity!.toString())
              : '',
        );

  _ItemDraft.newItem(String itemName)
      : id = const Uuid().v4(),
        name = itemName,
        unit = kDefaultUnits.first,
        checked = false,
        qtyController = TextEditingController();

  void dispose() => qtyController.dispose();

  ShoppingItem toItem() => ShoppingItem(
        id: id,
        name: name,
        quantity: double.tryParse(qtyController.text.trim()),
        unit: unit,
        checked: checked,
      );
}

// ── Screen ────────────────────────────────────────────────────────────────────

class AddEditShoppingListScreen extends StatefulWidget {
  final ShoppingList? list;
  final String? initialName;

  const AddEditShoppingListScreen({super.key, this.list, this.initialName});

  @override
  State<AddEditShoppingListScreen> createState() =>
      _AddEditShoppingListScreenState();
}

class _AddEditShoppingListScreenState
    extends State<AddEditShoppingListScreen> {
  late TextEditingController _nameController;
  late List<_ItemDraft> _drafts;
  String? _clipboardText;

  bool get _isEdit => widget.list != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _nameController = TextEditingController(text: widget.list!.name);
      _drafts = widget.list!.items.map(_ItemDraft.fromItem).toList();
    } else {
      _nameController = TextEditingController(text: widget.initialName ?? '');
      _drafts = [];
      _loadClipboard();
    }
  }

  Future<void> _loadClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isNotEmpty && mounted) {
      setState(() => _clipboardText = text);
    }
  }

  void _pasteFromClipboard() {
    if (_clipboardText == null) return;
    final allLines = _clipboardText!.split('\n');
    final bulletRe = RegExp(r'^[•✓\-\*]');
    final qtyRe = RegExp(r'\s*[—–]\s*(\S+)(?:\s+(.+))?$');

    final hasBullets = allLines.any((l) => bulletRe.hasMatch(l.trim()));

    setState(() {
      for (final raw in allLines) {
        final line = raw.trim();
        if (hasBullets && !bulletRe.hasMatch(line)) continue;

        var text = line.replaceFirst(RegExp(r'^[•✓\-\*]\s*'), '');

        String? qtyStr;
        String? unitStr;
        final qtyMatch = qtyRe.firstMatch(text);
        if (qtyMatch != null) {
          qtyStr = qtyMatch.group(1);
          unitStr = qtyMatch.group(2)?.trim();
          text = text.substring(0, qtyMatch.start).trim();
        }

        if (text.isEmpty) continue;

        final draft = _ItemDraft.newItem(text);
        if (qtyStr != null) draft.qtyController.text = qtyStr;
        if (unitStr != null && unitStr.isNotEmpty) draft.unit = unitStr;
        _drafts.add(draft);
      }
      _clipboardText = null;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final d in _drafts) {
      d.dispose();
    }
    super.dispose();
  }

  void _addItem(String name) {
    setState(() => _drafts.add(_ItemDraft.newItem(name)));
  }

  void _removeItem(int index) {
    setState(() {
      _drafts[index].dispose();
      _drafts.removeAt(index);
    });
  }

  void _updateUnit(int index, String unit) {
    setState(() => _drafts[index].unit = unit);
  }

  void _showIngredientPicker() {
    final provider = context.read<AppProvider>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: IngredientPickerSheet(onSelected: _addItem),
      ),
    );
  }

  Future<void> _openRecipePicker() async {
    final provider = context.read<AppProvider>();
    final recipes = provider.recipes;
    if (recipes.isEmpty) return;

    final selected = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _RecipePickerSheet(recipes: recipes),
    );

    if (selected == null || selected.isEmpty) return;

    setState(() {
      for (final recipeId in selected) {
        final recipe = recipes.firstWhere((r) => r.id == recipeId);
        for (final ingredient in recipe.ingredients) {
          final draft = _ItemDraft.newItem(ingredient.name);
          draft.unit = ingredient.unit;
          if (ingredient.quantity != null) {
            draft.qtyController.text = ingredient.quantity! % 1 == 0
                ? ingredient.quantity!.toInt().toString()
                : ingredient.quantity!.toString();
          }
          _drafts.add(draft);
        }
      }
    });
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    HapticFeedback.mediumImpact();

    final provider = context.read<AppProvider>();
    final items = _drafts.map((d) => d.toItem()).toList();

    if (_isEdit) {
      widget.list!.name = name;
      widget.list!.items
        ..clear()
        ..addAll(items);
      provider.updateShoppingList(widget.list!);
    } else {
      final list = ShoppingList(
        id: const Uuid().v4(),
        name: name,
        createdAt: DateTime.now(),
        items: items,
      );
      provider.addShoppingList(list);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _nameController.text.trim().isNotEmpty;
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
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
                  _isEdit ? S.shoppingEditList : S.shoppingNewList,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
            const Divider(height: 1, thickness: 1, color: Colors.black12),
            // Name field (fixed)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(S.shoppingNameSection),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    maxLength: 60,
                    decoration: InputDecoration(
                      hintText: S.shoppingNameHint,
                      hintStyle: const TextStyle(color: Colors.black38),
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
                      counterStyle: const TextStyle(
                        fontFamily: 'FixelText',
                        fontSize: 11,
                        color: Colors.black38,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  _SectionLabel(S.shoppingItemsSection),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            // Items (scrollable)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                children: _drafts
                    .asMap()
                    .entries
                    .map((e) => _ItemRow(
                          draft: e.value,
                          onRemove: () => _removeItem(e.key),
                          onUnitChanged: (u) => _updateUnit(e.key, u),
                        ))
                    .toList(),
              ),
            ),
            // Add buttons + save (fixed, hidden when keyboard is open)
            if (!keyboardOpen) Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                children: [
                  if (_clipboardText != null) ...[
                    _AddButton(
                      icon: Icons.content_paste_outlined,
                      label: S.shoppingPasteBtn,
                      onTap: _pasteFromClipboard,
                    ),
                    const SizedBox(height: 8),
                  ],
                  _AddButton(
                    icon: Icons.add,
                    label: S.shoppingAddItemBtn,
                    onTap: _showIngredientPicker,
                  ),
                  const SizedBox(height: 8),
                  _AddButton(
                    icon: Icons.menu_book_outlined,
                    label: S.shoppingAddRecipeBtn,
                    onTap: _openRecipePicker,
                  ),
                  const SizedBox(height: 12),
                  Opacity(
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
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ── Item row ──────────────────────────────────────────────────────────────────

class _ItemRow extends StatelessWidget {
  final _ItemDraft draft;
  final VoidCallback onRemove;
  final void Function(String) onUnitChanged;

  const _ItemRow({
    required this.draft,
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
                draft.name,
                style: const TextStyle(fontFamily: 'FixelText', fontSize: 15),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 64,
              child: TextField(
                controller: draft.qtyController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontFamily: 'FixelText', fontSize: 14),
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
              value: kDefaultUnits.contains(draft.unit)
                  ? draft.unit
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
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add button row ────────────────────────────────────────────────────────────

class _AddButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AddButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black26, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.black45),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'FixelText',
                fontSize: 15,
                color: Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

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

// ── Recipe picker sheet ───────────────────────────────────────────────────────

class _RecipePickerSheet extends StatefulWidget {
  final List<Recipe> recipes;
  const _RecipePickerSheet({required this.recipes});

  @override
  State<_RecipePickerSheet> createState() => _RecipePickerSheetState();
}

class _RecipePickerSheetState extends State<_RecipePickerSheet> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              S.shoppingPickRecipesTitle,
              style: const TextStyle(
                fontFamily: 'FixelDisplay',
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Colors.black12),
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: widget.recipes.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 20, endIndent: 20),
              itemBuilder: (_, i) {
                final recipe = widget.recipes[i];
                final isSelected = _selected.contains(recipe.id);
                return InkWell(
                  onTap: () => setState(() {
                    if (isSelected) {
                      _selected.remove(recipe.id);
                    } else {
                      _selected.add(recipe.id);
                    }
                  }),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recipe.name,
                                style: const TextStyle(
                                  fontFamily: 'FixelText',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              if (recipe.ingredients.isNotEmpty)
                                Text(
                                  '${recipe.ingredients.length} інгр.',
                                  style: const TextStyle(
                                    fontFamily: 'FixelText',
                                    fontSize: 13,
                                    color: Colors.black38,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Icon(
                          isSelected
                              ? Icons.circle
                              : Icons.radio_button_unchecked,
                          size: 22,
                          color: isSelected ? Colors.black : Colors.black26,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                16 + MediaQuery.of(context).viewInsets.bottom),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selected.isEmpty
                    ? null
                    : () => Navigator.of(context).pop(_selected),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.black12,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontFamily: 'FixelText',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                child: Text(_selected.isEmpty
                    ? S.shoppingPickRecipesTitle
                    : S.shoppingPickRecipesBtn(_selected.length)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
