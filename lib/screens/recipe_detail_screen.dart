import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/recipe.dart';
import '../providers/app_provider.dart';
import 'add_edit_recipe_screen.dart';

class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    final current =
        context.watch<AppProvider>().findRecipe(recipe.id) ?? recipe;

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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    current.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _openEdit(context, current),
                  ),
                ),
              ],
            ),
            const Divider(height: 1, thickness: 1, color: Colors.black12),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo
                    if (current.photoPath != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: _PhotoImage(current.photoPath!),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Tags + category chips
                    if (current.tags.isNotEmpty || current.category != null) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (current.category != null)
                            _TagChip(
                                label: current.category!, filled: true),
                          ...current.tags
                              .map((t) => _TagChip(label: t.label)),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Description
                    if (current.description != null &&
                        current.description!.isNotEmpty) ...[
                      Text(
                        current.description!,
                        style: const TextStyle(
                          fontFamily: 'FixelText',
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    // Ingredients
                    if (current.ingredients.isNotEmpty) ...[
                      const _SectionLabel('ІНГРЕДІЄНТИ'),
                      const SizedBox(height: 10),
                      ...current.ingredients.map(
                        (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  i.name,
                                  style: const TextStyle(
                                    fontFamily: 'FixelText',
                                    fontSize: 15,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              if (i.quantity != null)
                                Text(
                                  '${_formatQty(i.quantity!)} ${i.unit}',
                                  style: const TextStyle(
                                    fontFamily: 'FixelText',
                                    fontSize: 15,
                                    color: Colors.black54,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const SizedBox(height: 8),
                    // Delete action
                    GestureDetector(
                      onTap: () => _confirmDelete(context, current),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline,
                                size: 20, color: Colors.black54),
                            const SizedBox(width: 12),
                            Text(
                              S.recipeDetailDeleteBtn,
                              style: const TextStyle(
                                fontFamily: 'FixelText',
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatQty(double qty) {
    if (qty % 1 == 0) return qty.toInt().toString();
    return qty.toString();
  }

  void _openEdit(BuildContext context, Recipe current) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditRecipeScreen(recipe: current),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Recipe current) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          S.recipeDeleteTitle,
          style: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Text(
          S.recipeDeleteBody,
          style: const TextStyle(
              fontSize: 14, height: 1.6, color: Colors.black87),
        ),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.read<AppProvider>().deleteRecipe(current.id);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(S.recipeDeleteConfirm),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  S.recipeDeleteCancel,
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhotoImage extends StatefulWidget {
  final String photoPath;

  const _PhotoImage(this.photoPath);

  @override
  State<_PhotoImage> createState() => _PhotoImageState();
}

class _PhotoImageState extends State<_PhotoImage> {
  String? _resolved;

  @override
  void initState() {
    super.initState();
    _resolve(widget.photoPath);
  }

  @override
  void didUpdateWidget(_PhotoImage old) {
    super.didUpdateWidget(old);
    if (old.photoPath != widget.photoPath) _resolve(widget.photoPath);
  }

  Future<void> _resolve(String path) async {
    final String abs;
    if (path.startsWith('/')) {
      abs = path;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      abs = p.join(dir.path, path);
    }
    if (mounted) setState(() => _resolved = abs);
  }

  @override
  Widget build(BuildContext context) {
    if (_resolved == null) return const SizedBox.expand();
    return Image.file(
      File(_resolved!),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.black.withValues(alpha: 0.04),
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined,
              color: Colors.black26, size: 40),
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

class _TagChip extends StatelessWidget {
  final String label;
  final bool filled;

  const _TagChip({required this.label, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? Colors.black : Colors.white,
        border: Border.all(
            color: filled ? Colors.black : Colors.black54, width: 1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'FixelText',
          fontSize: 12,
          color: filled ? Colors.white : Colors.black87,
          fontWeight: filled ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}
