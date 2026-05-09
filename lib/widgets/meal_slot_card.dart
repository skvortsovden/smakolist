import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/strings.dart';
import '../models/meal_log.dart';
import '../models/recipe.dart';

class MealSlotCard extends StatelessWidget {
  final MealType slot;
  final List<MealEntry> entries;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  const MealSlotCard({
    super.key,
    required this.slot,
    required this.entries,
    required this.onAdd,
    required this.onRemove,
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
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Text(
              slot.label,
              style: const TextStyle(
                fontFamily: 'FixelText',
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          // Logged recipes or placeholder
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              child: Text(
                S.todayNoItems,
                style: const TextStyle(
                  fontFamily: 'FixelText',
                  fontSize: 14,
                  color: Colors.black38,
                ),
              ),
            ),
          ...entries.asMap().entries.map((e) {
            final index = e.key;
            final entry = e.value;
            return Dismissible(
              key: Key('${slot.key}-$index-${entry.loggedAt.millisecondsSinceEpoch}'),
              direction: DismissDirection.endToStart,
              onDismissed: (_) {
                HapticFeedback.mediumImpact();
                onRemove(index);
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                color: Colors.black12,
                child: const Icon(Icons.delete_outline, color: Colors.black54),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 2, 4, 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.recipeName,
                        style: const TextStyle(
                          fontFamily: 'FixelText',
                          fontSize: 15,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16, color: Colors.black38),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        onRemove(index);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 24,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          // Add button
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                onAdd();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black26, width: 1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Додати',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'FixelText',
                    fontSize: 13,
                    color: Colors.black38,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
