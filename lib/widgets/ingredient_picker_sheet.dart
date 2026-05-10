import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../providers/app_provider.dart';

class IngredientPickerSheet extends StatefulWidget {
  final void Function(String name) onSelected;

  const IngredientPickerSheet({super.key, required this.onSelected});

  @override
  State<IngredientPickerSheet> createState() => _IngredientPickerSheetState();
}

class _IngredientPickerSheetState extends State<IngredientPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = context.watch<AppProvider>().allIngredients;
    final filtered = _query.isEmpty
        ? all
        : all
            .where((i) => i.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    final exactMatch = all.any((i) => i.toLowerCase() == _query.trim().toLowerCase());
    final showAdd = _query.trim().isNotEmpty && !exactMatch;

    final mq = MediaQuery.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: mq.size.height - mq.padding.top - 48,
      ),
      child: Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      S.ingredientPickerTitle,
                      style: TextStyle(
                        fontFamily: 'FixelText',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: S.ingredientSearchHint,
                  hintStyle: const TextStyle(color: Colors.black38),
                  prefixIcon: const Icon(Icons.search, color: Colors.black38),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.04),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            // List
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  if (showAdd)
                    _IngredientRow(
                      name: S.ingredientAddNew(_query.trim().toLowerCase()),
                      isAdd: true,
                      onTap: () {
                        final name = _query.trim().toLowerCase();
                        context.read<AppProvider>().addCustomIngredient(name);
                        widget.onSelected(name);
                        Navigator.of(context).pop();
                      },
                    ),
                  ...filtered.map((name) => _IngredientRow(
                        name: name,
                        onTap: () {
                          widget.onSelected(name);
                          Navigator.of(context).pop();
                        },
                      )),
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

class _IngredientRow extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  final bool isAdd;

  const _IngredientRow({
    required this.name,
    required this.onTap,
    this.isAdd = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            if (isAdd)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.add, size: 18, color: Colors.black54),
              ),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontFamily: 'FixelText',
                  fontSize: 16,
                  color: isAdd ? Colors.black54 : Colors.black,
                  fontStyle: isAdd ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
