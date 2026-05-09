import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ingredient.dart';
import '../models/meal_log.dart';
import '../models/recipe.dart';
import '../services/notification_service.dart';

class ReminderConfig {
  final bool enabled;
  final TimeOfDay time;

  const ReminderConfig({required this.enabled, required this.time});

  ReminderConfig copyWith({bool? enabled, TimeOfDay? time}) =>
      ReminderConfig(enabled: enabled ?? this.enabled, time: time ?? this.time);
}

class AppProvider extends ChangeNotifier {
  List<Recipe> _recipes = [];
  Map<String, MealLog> _logs = {}; // keyed by YYYY-MM-DD
  String _username = '';
  List<String> _customIngredients = [];
  List<String> _customCategories = [];

  ReminderConfig _breakfastReminder =
      const ReminderConfig(enabled: false, time: TimeOfDay(hour: 8, minute: 0));
  ReminderConfig _lunchReminder =
      const ReminderConfig(enabled: false, time: TimeOfDay(hour: 13, minute: 0));
  ReminderConfig _dinnerReminder =
      const ReminderConfig(enabled: false, time: TimeOfDay(hour: 19, minute: 0));

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  static const _recipesKey = 'smakolist_recipes';
  static const _logsKey = 'smakolist_logs';
  static const _usernameKey = 'smakolist_username';
  static const _launchedKey = 'smakolist_launched';
  static const _breakfastReminderKey = 'smakolist_reminder_breakfast';
  static const _lunchReminderKey = 'smakolist_reminder_lunch';
  static const _dinnerReminderKey = 'smakolist_reminder_dinner';
  static const _customIngredientsKey = 'smakolist_custom_ingredients';
  static const _customCategoriesKey = 'smakolist_custom_categories';

  // ── Getters ──────────────────────────────────────────────────────────────

  List<Recipe> get recipes => List.unmodifiable(_recipes);
  Map<String, MealLog> get logs => Map.unmodifiable(_logs);
  String get username => _username;
  bool get isInitialized => _isInitialized;
  bool get isFirstLaunch =>
      _prefs != null && !(_prefs!.getBool(_launchedKey) ?? false);

  ReminderConfig get breakfastReminder => _breakfastReminder;
  ReminderConfig get lunchReminder => _lunchReminder;
  ReminderConfig get dinnerReminder => _dinnerReminder;

  List<String> get customIngredients => List.unmodifiable(_customIngredients);
  List<String> get customCategories => List.unmodifiable(_customCategories);

  List<String> get allIngredients => [
        ...kDefaultIngredients,
        ..._customIngredients.where((c) => !kDefaultIngredients.contains(c)),
      ];

  List<String> get allCategories => [
        ...kDefaultCategories,
        ..._customCategories.where((c) => !kDefaultCategories.contains(c)),
      ];

  // ── Init ─────────────────────────────────────────────────────────────────

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _username = _prefs!.getString(_usernameKey) ?? '';

      final rawRecipes = _prefs!.getString(_recipesKey);
      if (rawRecipes != null) {
        try {
          final list = jsonDecode(rawRecipes) as List<dynamic>;
          _recipes = list
              .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
              .toList();
        } catch (_) {
          _recipes = [];
        }
      }

      final rawLogs = _prefs!.getString(_logsKey);
      if (rawLogs != null) {
        try {
          final map = jsonDecode(rawLogs) as Map<String, dynamic>;
          _logs = map.map(
            (k, v) => MapEntry(k, MealLog.fromJson(v as Map<String, dynamic>)),
          );
        } catch (_) {
          _logs = {};
        }
      }

      _breakfastReminder = _loadReminder(_breakfastReminderKey,
          const ReminderConfig(enabled: false, time: TimeOfDay(hour: 8, minute: 0)));
      _lunchReminder = _loadReminder(_lunchReminderKey,
          const ReminderConfig(enabled: false, time: TimeOfDay(hour: 13, minute: 0)));
      _dinnerReminder = _loadReminder(_dinnerReminderKey,
          const ReminderConfig(enabled: false, time: TimeOfDay(hour: 19, minute: 0)));

      final rawIngredients = _prefs!.getString(_customIngredientsKey);
      if (rawIngredients != null) {
        try {
          _customIngredients = List<String>.from(jsonDecode(rawIngredients) as List);
        } catch (_) {}
      }

      final rawCategories = _prefs!.getString(_customCategoriesKey);
      if (rawCategories != null) {
        try {
          _customCategories = List<String>.from(jsonDecode(rawCategories) as List);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('AppProvider: init failed ($e). Using empty in-memory state.');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  ReminderConfig _loadReminder(String key, ReminderConfig defaultValue) {
    final raw = _prefs?.getString(key);
    if (raw == null) return defaultValue;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final timeParts = (map['time'] as String).split(':');
      return ReminderConfig(
        enabled: map['enabled'] as bool? ?? false,
        time: TimeOfDay(
          hour: int.tryParse(timeParts[0]) ?? defaultValue.time.hour,
          minute: int.tryParse(timeParts[1]) ?? defaultValue.time.minute,
        ),
      );
    } catch (_) {
      return defaultValue;
    }
  }

  void _saveReminder(String key, ReminderConfig config) {
    _prefs?.setString(
      key,
      jsonEncode({
        'enabled': config.enabled,
        'time':
            '${config.time.hour.toString().padLeft(2, '0')}:${config.time.minute.toString().padLeft(2, '0')}',
      }),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static String dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  MealLog getOrCreateLog(DateTime date) {
    final key = dateKey(date);
    return _logs[key] ?? MealLog.empty(key);
  }

  // ── Recipes ───────────────────────────────────────────────────────────────

  bool isNameTaken(String name, {String? excludeId}) {
    final lower = name.trim().toLowerCase();
    return _recipes.any((r) =>
        r.name.toLowerCase() == lower && (excludeId == null || r.id != excludeId));
  }

  void saveRecipe(Recipe recipe) {
    final idx = _recipes.indexWhere((r) => r.id == recipe.id);
    if (idx >= 0) {
      _recipes[idx] = recipe;
    } else {
      _recipes.add(recipe);
    }
    _persistRecipes();
    notifyListeners();
  }

  void deleteRecipe(String id) {
    _recipes.removeWhere((r) => r.id == id);
    _persistRecipes();
    notifyListeners();
  }

  Recipe? findRecipe(String id) {
    try {
      return _recipes.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Meal logs ─────────────────────────────────────────────────────────────

  void addMealEntry(DateTime date, MealType slot, MealEntry entry) {
    final key = dateKey(date);
    final log = getOrCreateLog(date);
    final slots = Map<MealType, List<MealEntry>>.from(
        log.slots.map((k, v) => MapEntry(k, List<MealEntry>.from(v))));
    slots[slot] = [...(slots[slot] ?? []), entry];
    _logs[key] = log.copyWith(slots: slots);
    _persistLogs();
    notifyListeners();
  }

  void removeMealEntry(DateTime date, MealType slot, int index) {
    final key = dateKey(date);
    final log = _logs[key];
    if (log == null) return;
    final slots = Map<MealType, List<MealEntry>>.from(
        log.slots.map((k, v) => MapEntry(k, List<MealEntry>.from(v))));
    final list = slots[slot];
    if (list == null || index >= list.length) return;
    list.removeAt(index);
    slots[slot] = list;
    final updated = log.copyWith(slots: slots);
    if (updated.isEmpty) {
      _logs.remove(key);
    } else {
      _logs[key] = updated;
    }
    _persistLogs();
    notifyListeners();
  }

  void setNote(DateTime date, String? note) {
    final key = dateKey(date);
    final log = getOrCreateLog(date);
    final trimmed = note?.trim().isEmpty == true ? null : note?.trim();
    final updated = log.copyWith(noteOrNull: trimmed);
    if (updated.isEmpty) {
      _logs.remove(key);
    } else {
      _logs[key] = updated;
    }
    _persistLogs();
    notifyListeners();
  }

  void saveLog(MealLog log) {
    if (log.isEmpty) {
      _logs.remove(log.date);
    } else {
      _logs[log.date] = log;
    }
    _persistLogs();
    notifyListeners();
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  void setUsername(String name) {
    _username = name;
    _prefs?.setString(_usernameKey, name);
    notifyListeners();
  }

  void markLaunched() {
    _prefs?.setBool(_launchedKey, true);
  }

  Future<void> setBreakfastReminder(ReminderConfig config) async {
    if (config.enabled && !_breakfastReminder.enabled) {
      final granted = await NotificationService.instance.requestPermission();
      final ok = granted ||
          await NotificationService.instance.isPermissionGranted();
      if (!ok) {
        notifyListeners();
        return;
      }
    }
    _breakfastReminder = config;
    _saveReminder(_breakfastReminderKey, config);
    try {
      await NotificationService.instance
          .scheduleBreakfast(config.time, enabled: config.enabled);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setLunchReminder(ReminderConfig config) async {
    if (config.enabled && !_lunchReminder.enabled) {
      final granted = await NotificationService.instance.requestPermission();
      final ok = granted ||
          await NotificationService.instance.isPermissionGranted();
      if (!ok) {
        notifyListeners();
        return;
      }
    }
    _lunchReminder = config;
    _saveReminder(_lunchReminderKey, config);
    try {
      await NotificationService.instance
          .scheduleLunch(config.time, enabled: config.enabled);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setDinnerReminder(ReminderConfig config) async {
    if (config.enabled && !_dinnerReminder.enabled) {
      final granted = await NotificationService.instance.requestPermission();
      final ok = granted ||
          await NotificationService.instance.isPermissionGranted();
      if (!ok) {
        notifyListeners();
        return;
      }
    }
    _dinnerReminder = config;
    _saveReminder(_dinnerReminderKey, config);
    try {
      await NotificationService.instance
          .scheduleDinner(config.time, enabled: config.enabled);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> clearAllData() async {
    _recipes = [];
    _logs = {};
    if (_prefs != null) {
      await _prefs!.remove(_recipesKey);
      await _prefs!.remove(_logsKey);
    }
    notifyListeners();
  }

  // ── Custom ingredients & categories ──────────────────────────────────────

  void addCustomIngredient(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (allIngredients.any((i) => i.toLowerCase() == trimmed.toLowerCase())) return;
    _customIngredients.add(trimmed);
    _prefs?.setString(_customIngredientsKey, jsonEncode(_customIngredients));
    notifyListeners();
  }

  void addCustomCategory(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (allCategories.any((c) => c.toLowerCase() == trimmed.toLowerCase())) return;
    _customCategories.add(trimmed);
    _prefs?.setString(_customCategoriesKey, jsonEncode(_customCategories));
    notifyListeners();
  }

  // ── Import / Export ───────────────────────────────────────────────────────

  String buildJson() {
    return jsonEncode({
      'recipes': _recipes.map((r) => r.toJson()).toList(),
      'logs': _logs.map((k, v) => MapEntry(k, v.toJson())),
    });
  }

  String buildCsv() {
    final buf = StringBuffer();
    buf.writeln(_csvRow(['назва', 'категорія', 'прийом їжі', 'інгредієнти', 'опис']));
    for (final r in _recipes) {
      final tags = r.tags.map((t) => t.label).join('; ');
      final ingredients = r.ingredients.map((i) {
        if (i.quantity != null) {
          final qty = i.quantity! % 1 == 0
              ? i.quantity!.toInt().toString()
              : i.quantity!.toString();
          return '${i.name} $qty ${i.unit}';
        }
        return i.name;
      }).join('; ');
      buf.writeln(_csvRow([
        r.name,
        r.category ?? '',
        tags,
        ingredients,
        r.description ?? '',
      ]));
    }
    return buf.toString();
  }

  static String _csvRow(List<String> fields) {
    return fields.map((f) {
      if (f.contains(',') || f.contains('"') || f.contains('\n') || f.contains('\r')) {
        return '"${f.replaceAll('"', '""')}"';
      }
      return f;
    }).join(',');
  }

  String? importCsv(String raw) {
    try {
      final rows = _parseCsvRows(raw);
      if (rows.length < 2) return null;

      for (final row in rows.skip(1)) {
        if (row.every((f) => f.isEmpty)) continue;
        final r = List<String>.from(row);
        while (r.length < 5) {
          r.add('');
        }

        final name = r[0].trim();
        if (name.isEmpty) continue;

        final category = r[1].trim().isEmpty ? null : r[1].trim().toLowerCase();

        final tags = r[2]
            .split(';')
            .map((s) => s.trim().toLowerCase())
            .where((s) => s.isNotEmpty)
            .map((s) {
              for (final t in MealType.values) {
                if (t.label == s) return t;
              }
              return null;
            })
            .whereType<MealType>()
            .toList();

        final ingredients = r[3]
            .split(';')
            .map((s) => s.trim().toLowerCase())
            .where((s) => s.isNotEmpty)
            .map(_parseIngredientStr)
            .toList();

        final description = r[4].trim().isEmpty ? null : r[4].trim().toLowerCase();

        final recipe = Recipe.create(
          name: name,
          description: description,
          tags: tags,
          category: category,
          ingredients: ingredients,
        );

        final idx = _recipes.indexWhere(
            (ex) => ex.name.toLowerCase() == name.toLowerCase());
        if (idx >= 0) {
          _recipes[idx] = _recipes[idx].copyWith(
            name: recipe.name,
            descriptionOrNull: description,
            tags: recipe.tags,
            categoryOrNull: category,
            ingredients: recipe.ingredients,
          );
        } else {
          _recipes.add(recipe);
        }
      }

      _persistRecipes();
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  static RecipeIngredient _parseIngredientStr(String s) {
    final parts = s.trim().split(RegExp(r'\s+'));
    if (parts.length >= 3) {
      final unit = parts.last;
      final qty = double.tryParse(parts[parts.length - 2]);
      if (qty != null && kDefaultUnits.contains(unit)) {
        return RecipeIngredient(
          name: parts.take(parts.length - 2).join(' '),
          quantity: qty,
          unit: unit,
        );
      }
    }
    if (parts.length >= 2) {
      final qty = double.tryParse(parts.last);
      if (qty != null) {
        return RecipeIngredient(
          name: parts.take(parts.length - 1).join(' '),
          quantity: qty,
          unit: kDefaultUnits.first,
        );
      }
    }
    return RecipeIngredient(name: s.trim(), unit: kDefaultUnits.first);
  }

  static List<List<String>> _parseCsvRows(String raw) {
    final rows = <List<String>>[];
    for (final line
        in raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n')) {
      if (line.trim().isEmpty) continue;
      rows.add(_parseCsvLine(line));
    }
    return rows;
  }

  static List<String> _parseCsvLine(String line) {
    final fields = <String>[];
    var i = 0;
    while (i < line.length) {
      if (line[i] == '"') {
        i++;
        final buf = StringBuffer();
        while (i < line.length) {
          if (line[i] == '"') {
            if (i + 1 < line.length && line[i + 1] == '"') {
              buf.write('"');
              i += 2;
            } else {
              i++;
              break;
            }
          } else {
            buf.write(line[i]);
            i++;
          }
        }
        fields.add(buf.toString());
        if (i < line.length && line[i] == ',') i++;
      } else {
        final start = i;
        while (i < line.length && line[i] != ',') {
          i++;
        }
        fields.add(line.substring(start, i));
        if (i < line.length) i++;
      }
    }
    return fields;
  }

  String? importJson(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;

      final rawRecipes = map['recipes'] as List<dynamic>? ?? [];
      final importedRecipes = rawRecipes
          .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
          .toList();

      final rawLogs = map['logs'] as Map<String, dynamic>? ?? {};
      final importedLogs = rawLogs.map(
        (k, v) => MapEntry(k, MealLog.fromJson(v as Map<String, dynamic>)),
      );

      // Upsert recipes by name (case-insensitive)
      for (final imported in importedRecipes) {
        final idx = _recipes.indexWhere(
            (r) => r.name.toLowerCase() == imported.name.toLowerCase());
        if (idx >= 0) {
          _recipes[idx] = imported;
        } else {
          _recipes.add(imported);
        }
      }

      // Upsert logs by date
      _logs = {..._logs, ...importedLogs};

      _persistRecipes();
      _persistLogs();
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  void _persistRecipes() {
    if (_prefs == null) return;
    _prefs!.setString(
      _recipesKey,
      jsonEncode(_recipes.map((r) => r.toJson()).toList()),
    );
  }

  void _persistLogs() {
    if (_prefs == null) return;
    _prefs!.setString(
      _logsKey,
      jsonEncode(_logs.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }

  // ── Stats helpers ─────────────────────────────────────────────────────────

  List<String> datesInRange(DateTime start, DateTime end) {
    final dates = <String>[];
    var d = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    while (!d.isAfter(last)) {
      dates.add(dateKey(d));
      d = d.add(const Duration(days: 1));
    }
    return dates;
  }

  int filledDays(List<String> dates) =>
      dates.where((d) => _logs.containsKey(d)).length;

  int currentStreak() {
    final today = DateTime.now();
    int streak = 0;
    for (int i = 0; i < 10000; i++) {
      final d = today.subtract(Duration(days: i));
      if (_logs.containsKey(dateKey(d))) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  int longestStreak(List<String> dates) {
    int best = 0;
    int current = 0;
    for (final d in dates) {
      if (_logs.containsKey(d)) {
        current++;
        if (current > best) best = current;
      } else {
        current = 0;
      }
    }
    return best;
  }

  Map<String, int> topRecipes(List<String> dates, {int limit = 5}) {
    final counts = <String, int>{};
    for (final d in dates) {
      final log = _logs[d];
      if (log == null) continue;
      for (final entries in log.slots.values) {
        for (final e in entries) {
          counts[e.recipeName] = (counts[e.recipeName] ?? 0) + 1;
        }
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(limit));
  }

  Map<MealType, int> slotDistribution(List<String> dates) {
    final counts = {for (final t in MealType.values) t: 0};
    for (final d in dates) {
      final log = _logs[d];
      if (log == null) continue;
      for (final t in MealType.values) {
        counts[t] = (counts[t] ?? 0) + (log.slots[t]?.length ?? 0);
      }
    }
    return counts;
  }
}
