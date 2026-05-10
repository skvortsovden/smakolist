import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/recipe.dart';
import '../providers/app_provider.dart';
import 'add_edit_recipe_screen.dart';
import 'recipe_detail_screen.dart';

class RecipesView extends StatefulWidget {
  const RecipesView({super.key});

  @override
  State<RecipesView> createState() => _RecipesViewState();
}

class _RecipesViewState extends State<RecipesView> {
  MealType? _filter; // null = all

  @override
  Widget build(BuildContext context) {
    final recipes = context.watch<AppProvider>().recipes;
    final filtered = _filter == null
        ? recipes
        : recipes.where((r) => r.tags.contains(_filter)).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // Header
              Text(S.recipesTitle,
                  style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 4),
              Text(
                S.recipesCount(recipes.length),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: S.recipesFilterAll,
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
              const SizedBox(height: 16),
              // List or empty state
              Expanded(
                child: recipes.isEmpty
                    ? _EmptyState(
                        onAdd: () => _openAdd(context),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Text(
                              S.recipesEmptyTitle,
                              style: const TextStyle(
                                fontFamily: 'FixelText',
                                fontSize: 16,
                                color: Colors.black38,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (ctx, i) {
                              final recipe = filtered[i];
                              return _RecipeCard(
                                recipe: recipe,
                                onTap: () => _openDetail(context, recipe),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: recipes.isEmpty
          ? null
          : _BlackFab(onTap: () => _openAdd(context)),
    );
  }

  void _openAdd(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddEditRecipeScreen(),
      ),
    );
  }

  void _openDetail(BuildContext context, Recipe recipe) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(recipe: recipe),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
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
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;

  const _RecipeCard({required this.recipe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
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
                  if (recipe.description != null &&
                      recipe.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      recipe.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'FixelText',
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
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
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.menu_book_outlined, size: 64, color: Colors.black26),
          const SizedBox(height: 16),
          Text(
            S.recipesEmptyTitle,
            style: const TextStyle(
              fontFamily: 'FixelText',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.black38,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            S.recipesEmptySubtitle,
            style: const TextStyle(
              fontFamily: 'FixelText',
              fontSize: 14,
              color: Colors.black26,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: onAdd,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: const BorderSide(color: Colors.black, width: 2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              S.recipesEmptyBtn,
              style: const TextStyle(
                fontFamily: 'FixelText',
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlackFab extends StatelessWidget {
  final VoidCallback onTap;

  const _BlackFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 24),
      ),
    );
  }
}
