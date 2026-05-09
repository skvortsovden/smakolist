import 'package:uuid/uuid.dart';

import 'ingredient.dart';

enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;

  String get label {
    switch (this) {
      case MealType.breakfast:
        return 'Сніданок';
      case MealType.lunch:
        return 'Обід';
      case MealType.dinner:
        return 'Вечеря';
      case MealType.snack:
        return 'Перекус';
    }
  }

  String get key {
    switch (this) {
      case MealType.breakfast:
        return 'breakfast';
      case MealType.lunch:
        return 'lunch';
      case MealType.dinner:
        return 'dinner';
      case MealType.snack:
        return 'snack';
    }
  }

  static MealType? fromKey(String key) {
    for (final t in MealType.values) {
      if (t.key == key) return t;
    }
    return null;
  }
}

class Recipe {
  final String id;
  final String name;
  final String? description;
  final List<MealType> tags;
  final String? category;
  final List<RecipeIngredient> ingredients;
  final DateTime createdAt;

  Recipe({
    required this.id,
    required this.name,
    this.description,
    required this.tags,
    this.category,
    this.ingredients = const [],
    required this.createdAt,
  });

  factory Recipe.create({
    required String name,
    String? description,
    List<MealType> tags = const [],
    String? category,
    List<RecipeIngredient> ingredients = const [],
  }) {
    return Recipe(
      id: const Uuid().v4(),
      name: name,
      description: description,
      tags: tags,
      category: category,
      ingredients: ingredients,
      createdAt: DateTime.now(),
    );
  }

  Recipe copyWith({
    String? name,
    String? description,
    List<MealType>? tags,
    String? category,
    List<RecipeIngredient>? ingredients,
    Object? descriptionOrNull = _sentinel,
    Object? categoryOrNull = _sentinel,
  }) {
    return Recipe(
      id: id,
      name: name ?? this.name,
      description: descriptionOrNull == _sentinel
          ? description ?? this.description
          : descriptionOrNull as String?,
      tags: tags ?? this.tags,
      category: categoryOrNull == _sentinel
          ? category ?? this.category
          : categoryOrNull as String?,
      ingredients: ingredients ?? this.ingredients,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'tags': tags.map((t) => t.key).toList(),
        'category': category,
        'ingredients': ingredients.map((i) => i.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Recipe.fromJson(Map<String, dynamic> json) {
    final rawTags = (json['tags'] as List<dynamic>? ?? []);
    final tags = rawTags
        .map((k) => MealType.fromKey(k as String))
        .whereType<MealType>()
        .toList();
    final rawIngredients = json['ingredients'] as List<dynamic>? ?? [];
    final ingredients = rawIngredients
        .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
        .toList();
    return Recipe(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      tags: tags,
      category: json['category'] as String?,
      ingredients: ingredients,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

const _sentinel = Object();
