import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/recipe.dart';
import '../providers/app_provider.dart';

class RecipePickerSheet extends StatefulWidget {
  final MealType slot;
  final void Function(Recipe) onSelected;
  final VoidCallback? onGoToRecipes;

  const RecipePickerSheet({
    super.key,
    required this.slot,
    required this.onSelected,
    this.onGoToRecipes,
  });

  @override
  State<RecipePickerSheet> createState() => _RecipePickerSheetState();
}

class _RecipePickerSheetState extends State<RecipePickerSheet> {
  MealType? _filter; // null = all

  @override
  void initState() {
    super.initState();
    _filter = widget.slot;
  }

  @override
  Widget build(BuildContext context) {
    final recipes = context.watch<AppProvider>().recipes;
    final filtered = _filter == null
        ? recipes
        : recipes
            .where((r) => r.tags.isEmpty || r.tags.contains(_filter))
            .toList();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${S.pickerTitlePrefix}${widget.slot.label}',
                    style: const TextStyle(
                      fontFamily: 'FixelText',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black,
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
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                _FilterChip(
                  label: S.pickerFilterAll,
                  active: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                const SizedBox(width: 8),
                ...MealType.values.map((t) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label: t.label,
                        active: _filter == t,
                        onTap: () => setState(() => _filter = t),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Recipe list
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: filtered.isEmpty
                ? _EmptyState(onGoToRecipes: widget.onGoToRecipes)
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final recipe = filtered[i];
                      return _RecipeRow(
                        recipe: recipe,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          widget.onSelected(recipe);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'FixelText',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: active ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

class _RecipeRow extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;

  const _RecipeRow({required this.recipe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
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
                  if (recipe.tags.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: recipe.tags
                          .map((t) => _SmallChip(label: t.label))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String label;

  const _SmallChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'FixelText',
          fontSize: 11,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback? onGoToRecipes;

  const _EmptyState({this.onGoToRecipes});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            S.pickerEmpty,
            style: const TextStyle(
              fontFamily: 'FixelText',
              fontSize: 16,
              color: Colors.black38,
            ),
          ),
          if (onGoToRecipes != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onGoToRecipes,
              child: Text(
                S.pickerGoRecipes,
                style: const TextStyle(
                  fontFamily: 'FixelText',
                  fontSize: 14,
                  color: Colors.black54,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
