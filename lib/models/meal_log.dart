import 'recipe.dart';

class MealEntry {
  final String recipeId;
  final String recipeName;
  final DateTime loggedAt;

  const MealEntry({
    required this.recipeId,
    required this.recipeName,
    required this.loggedAt,
  });

  Map<String, dynamic> toJson() => {
        'recipeId': recipeId,
        'recipeName': recipeName,
        'loggedAt': loggedAt.toIso8601String(),
      };

  factory MealEntry.fromJson(Map<String, dynamic> json) => MealEntry(
        recipeId: json['recipeId'] as String,
        recipeName: json['recipeName'] as String,
        loggedAt: DateTime.parse(json['loggedAt'] as String),
      );
}

class MealLog {
  final String date; // YYYY-MM-DD
  final Map<MealType, List<MealEntry>> slots;
  final String? note;

  const MealLog({
    required this.date,
    required this.slots,
    this.note,
  });

  factory MealLog.empty(String date) => MealLog(
        date: date,
        slots: {
          MealType.breakfast: [],
          MealType.lunch: [],
          MealType.dinner: [],
          MealType.snack: [],
        },
      );

  bool get isEmpty =>
      slots.values.every((list) => list.isEmpty) &&
      (note == null || note!.isEmpty);

  MealLog copyWith({
    Map<MealType, List<MealEntry>>? slots,
    Object? noteOrNull = _sentinel,
  }) {
    return MealLog(
      date: date,
      slots: slots ?? Map.from(this.slots),
      note: noteOrNull == _sentinel ? note : noteOrNull as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'slots': slots.map(
          (type, entries) => MapEntry(
            type.key,
            entries.map((e) => e.toJson()).toList(),
          ),
        ),
        'note': note,
      };

  factory MealLog.fromJson(Map<String, dynamic> json) {
    final rawSlots = json['slots'] as Map<String, dynamic>? ?? {};
    final slots = <MealType, List<MealEntry>>{};
    for (final t in MealType.values) {
      final raw = rawSlots[t.key] as List<dynamic>? ?? [];
      slots[t] = raw
          .map((e) => MealEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return MealLog(
      date: json['date'] as String,
      slots: slots,
      note: json['note'] as String?,
    );
  }
}

const _sentinel = Object();
