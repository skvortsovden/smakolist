import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/strings.dart';
import '../models/meal_log.dart';
import '../models/recipe.dart';

class MealSlotCard extends StatelessWidget {
  final MealType slot;
  final List<MealEntry> entries;
  final VoidCallback? onAdd;
  final void Function(int index)? onRemove;

  const MealSlotCard({
    super.key,
    required this.slot,
    required this.entries,
    this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row — "не додано" inline on the right when empty
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Text(
                  S.mealLabel(slot),
                  style: const TextStyle(
                    fontFamily: 'FixelText',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                if (entries.isEmpty) ...[
                  const Spacer(),
                  Text(
                    S.todayNoItems,
                    style: const TextStyle(
                      fontFamily: 'FixelText',
                      fontSize: 13,
                      color: Colors.black38,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ...entries.asMap().entries.map((e) {
            final index = e.key;
            final entry = e.value;
            final row = Padding(
              padding: EdgeInsets.fromLTRB(12, 3, onRemove != null ? 8 : 12, 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.recipeName,
                      style: const TextStyle(
                        fontFamily: 'FixelText',
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  if (onRemove != null)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        onRemove!(index);
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close, size: 14, color: Colors.black38),
                      ),
                    ),
                ],
              ),
            );
            if (onRemove == null) return row;
            return Dismissible(
              key: Key('${slot.key}-$index-${entry.loggedAt.millisecondsSinceEpoch}'),
              direction: DismissDirection.endToStart,
              onDismissed: (_) {
                HapticFeedback.mediumImpact();
                onRemove!(index);
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                color: Colors.black12,
                child: const Icon(Icons.delete_outline, color: Colors.black54),
              ),
              child: row,
            );
          }),
          if (onAdd != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onAdd!();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black26, width: 1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    S.calendarBtnAdd,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'FixelText',
                      fontSize: 13,
                      color: Colors.black38,
                    ),
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 10),
        ],
      ),
    );
  }
}
