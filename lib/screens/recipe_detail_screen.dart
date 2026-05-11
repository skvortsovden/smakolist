import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/strings.dart';
import '../models/recipe.dart';
import '../providers/app_provider.dart';
import 'add_edit_recipe_screen.dart';

String _fmtQty(double qty) =>
    qty % 1 == 0 ? qty.toInt().toString() : qty.toString();

String _fmtCookTime(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '$m ${S.recipeCookTimeMinutes}';
  if (m == 0) return '$h ${S.recipeCookTimeHours}';
  return '$h ${S.recipeCookTimeHours} $m ${S.recipeCookTimeMinutes}';
}

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
                            _TagChip(label: current.category!, filled: true),
                          ...current.tags.map((t) => _TagChip(label: t.label)),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Cook time
                    if (current.cookTimeMinutes != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.schedule_outlined, size: 16, color: Colors.black45),
                          const SizedBox(width: 6),
                          Text(
                            _fmtCookTime(current.cookTimeMinutes!),
                            style: const TextStyle(
                              fontFamily: 'FixelText',
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
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
                      _SectionLabel(S.recipeSectionIngredients),
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
                                  '${_fmtQty(i.quantity!)} ${i.unit}',
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
                    // Steps
                    if (current.steps != null && current.steps!.isNotEmpty) ...[
                      _SectionLabel(S.recipeSectionSteps),
                      const SizedBox(height: 10),
                      ...current.steps!.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                margin: const EdgeInsets.only(top: 1, right: 12),
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${entry.key + 1}',
                                  style: const TextStyle(
                                    fontFamily: 'FixelText',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: const TextStyle(
                                    fontFamily: 'FixelText',
                                    fontSize: 15,
                                    color: Colors.black87,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 8),
                    // Share recipe
                    GestureDetector(
                      onTap: () => _shareRecipe(context, current),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.share_outlined,
                                size: 20, color: Colors.black54),
                            SizedBox(width: 12),
                            Text(
                              S.recipeShareBtn,
                              style: TextStyle(
                                fontFamily: 'FixelText',
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Copy ingredients
                    if (current.ingredients.isNotEmpty) ...[
                      GestureDetector(
                        onTap: () => _copyIngredients(context, current),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.copy_outlined,
                                  size: 20, color: Colors.black54),
                              SizedBox(width: 12),
                              Text(
                                S.recipeCopyIngredientsBtn,
                                style: TextStyle(
                                  fontFamily: 'FixelText',
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    // Delete action
                    GestureDetector(
                      onTap: () => _confirmDelete(context, current),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 2),
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

  Future<void> _shareRecipe(BuildContext context, Recipe recipe) async {
    final box = context.findRenderObject() as RenderBox?;
    final shareOrigin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : const Rect.fromLTWH(0, 0, 1, 1);

    // Pre-load photo bytes so the share card renders synchronously in the sheet
    Uint8List? photoBytes;
    if (recipe.photoPath != null) {
      try {
        final String absPath;
        if (recipe.photoPath!.startsWith('/')) {
          absPath = recipe.photoPath!;
        } else {
          final dir = await getApplicationDocumentsDirectory();
          absPath = p.join(dir.path, recipe.photoPath!);
        }
        photoBytes = await File(absPath).readAsBytes();
      } catch (_) {}
    }

    if (!context.mounted) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RecipeShareSheet(
        recipe: recipe,
        photoBytes: photoBytes,
        shareOrigin: shareOrigin,
      ),
    );
  }

  void _copyIngredients(BuildContext context, Recipe current) {
    final lines = current.ingredients.map((i) {
      if (i.quantity != null) {
        return '${i.name} — ${_fmtQty(i.quantity!)} ${i.unit}';
      }
      return i.name;
    }).join('\n');
    Clipboard.setData(ClipboardData(text: lines));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          S.recipeIngredientsCopied,
          style: TextStyle(fontFamily: 'FixelText'),
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
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

// ── Share preview sheet ───────────────────────────────────────────────────────

class _RecipeShareSheet extends StatefulWidget {
  final Recipe recipe;
  final Uint8List? photoBytes;
  final Rect shareOrigin;

  const _RecipeShareSheet({
    required this.recipe,
    required this.photoBytes,
    required this.shareOrigin,
  });

  @override
  State<_RecipeShareSheet> createState() => _RecipeShareSheetState();
}

class _RecipeShareSheetState extends State<_RecipeShareSheet> {
  final _captureKey = GlobalKey();
  bool _sharing = false;

  Future<void> _capture() async {
    setState(() => _sharing = true);
    try {
      // Give Flutter one extra frame to ensure the card is fully painted
      await Future.delayed(const Duration(milliseconds: 80));

      final boundary = _captureKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = data!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File(p.join(
          dir.path,
          'smakolist_${DateTime.now().millisecondsSinceEpoch ~/ 1000}.png'));
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      Navigator.of(context).pop();

      await Share.shareXFiles([XFile(file.path, mimeType: 'image/png')],
          sharePositionOrigin: widget.shareOrigin);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    // Scale 360×640 card to fit within the bottom sheet preview area
    final previewMaxW = screenW - 40;
    final previewMaxH = screenH * 0.52;
    // Compute uniform scale that fits both dimensions
    final scale = (previewMaxW / _ShareCard.kW)
        .clamp(0.0, previewMaxH / _ShareCard.kH);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Preview card with shadow — fixed 9:16 aspect ratio
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: _ShareCard.kW * scale,
                    height: _ShareCard.kH * scale,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      alignment: Alignment.topCenter,
                      child: RepaintBoundary(
                        key: _captureKey,
                        child: _ShareCard(
                          recipe: widget.recipe,
                          photoBytes: widget.photoBytes,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Helper text
            Text(
              S.recipeShareImageHint,
              style: TextStyle(
                fontFamily: 'FixelText',
                fontSize: 13,
                color: Colors.black38,
              ),
            ),
            const SizedBox(height: 20),
            // Share button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _sharing ? null : _capture,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _sharing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        S.recipeShareBtn,
                        style: TextStyle(
                          fontFamily: 'FixelText',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Share card ────────────────────────────────────────────────────────────────
// Fixed 360×640 logical canvas → 1080×1920 px at pixelRatio 3.0 (story size)

class _ShareCard extends StatelessWidget {
  final Recipe recipe;
  final Uint8List? photoBytes;

  static const double kW = 360.0;
  static const double kH = 640.0;
  static const double _pad = 28.0;

  const _ShareCard({required this.recipe, this.photoBytes});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hasPhoto = photoBytes != null;
    final topPad = hasPhoto ? 20.0 : 40.0;

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: kW,
        height: kH,
        child: Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo — padded to match text margins, natural aspect ratio (no crop)
              if (hasPhoto)
                Padding(
                  padding: const EdgeInsets.fromLTRB(_pad, _pad, _pad, 0),
                  child: Image.memory(
                    photoBytes!,
                    width: kW - 2 * _pad,
                    fit: BoxFit.fitWidth,
                  ),
                ),

              // Header: name + logo
              Padding(
                padding: EdgeInsets.fromLTRB(_pad, topPad, _pad, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recipe.name,
                            style: const TextStyle(
                              fontFamily: 'FixelDisplay',
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              height: 1.2,
                            ),
                          ),
                          if (recipe.category != null ||
                              recipe.tags.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 5,
                              runSpacing: 5,
                              children: [
                                if (recipe.category != null)
                                  _ShareChip(recipe.category!, filled: true),
                                ...recipe.tags.map((t) => _ShareChip(t.label)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Image.asset('assets/smakolist-logo.png',
                        height: 26, fit: BoxFit.contain),
                  ],
                ),
              ),

              // 2px divider
              Padding(
                padding: const EdgeInsets.fromLTRB(_pad, 14, _pad, 0),
                child: Container(height: 2, color: Colors.black),
              ),

              // Middle section — single column, full width.
              // With photo: ingredients only. Without photo: description then ingredients.
              // OverflowBox removes height constraint; ClipRect clips the bottom.
              // CrossAxisAlignment.stretch on the Column forces ingredient Rows to the
              // full content width so quantities land at the card's right padding edge.
              Expanded(
                child: ClipRect(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(_pad, 14, _pad, 0),
                    child: LayoutBuilder(builder: (_, constraints) {
                      // Reserve height for description block when shown (no photo).
                      // label ≈ 9pt+8gap = 19px; each desc line ≈ 12pt*1.5 = 18px; gap = 14px.
                      double reservedForDesc = 0;
                      final hasDesc = !hasPhoto &&
                          recipe.description != null &&
                          recipe.description!.isNotEmpty;
                      if (hasDesc) {
                        final lines =
                            (recipe.description!.length / 35).ceil().clamp(1, 8);
                        reservedForDesc = 19 + lines * 18.0 + 14;
                      }

                      // How many ingredient rows fit in remaining height.
                      // label ≈ 19px; each row ≈ 12pt*1.4 + 5px spacing ≈ 22px.
                      const labelH = 19.0;
                      const rowH = 22.0;
                      final availForIngr =
                          constraints.maxHeight - reservedForDesc;
                      final maxItems =
                          ((availForIngr - labelH) / rowH).floor().clamp(
                                0,
                                recipe.ingredients.length,
                              );
                      final overflow = recipe.ingredients.length - maxItems;

                      return OverflowBox(
                        alignment: Alignment.topLeft,
                        maxHeight: double.infinity,
                        child: Column(
                          // stretch forces Row children to full content width
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Description (no photo only)
                            if (hasDesc) ...[
                              Text(
                                S.recipeSectionDescLabel,
                                style: TextStyle(
                                  fontFamily: 'FixelText',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9,
                                  letterSpacing: 1.2,
                                  color: Colors.black45,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                recipe.description!,
                                style: const TextStyle(
                                  fontFamily: 'FixelText',
                                  fontSize: 12,
                                  color: Colors.black87,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                            // Ingredients
                            if (recipe.ingredients.isNotEmpty) ...[
                              Text(
                                S.recipeSectionIngredients,
                                style: TextStyle(
                                  fontFamily: 'FixelText',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9,
                                  letterSpacing: 1.2,
                                  color: Colors.black45,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...recipe.ingredients.take(maxItems).map(
                                    (i) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 5),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              i.name,
                                              style: const TextStyle(
                                                fontFamily: 'FixelText',
                                                fontSize: 12,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                          if (i.quantity != null)
                                            Text(
                                              '${_fmtQty(i.quantity!)} ${i.unit}',
                                              style: const TextStyle(
                                                fontFamily: 'FixelText',
                                                fontSize: 12,
                                                color: Colors.black54,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                              if (overflow > 0)
                                Text(
                                  S.recipeMoreOverflow(overflow),
                                  style: const TextStyle(
                                    fontFamily: 'FixelText',
                                    fontSize: 11,
                                    color: Colors.black38,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),

              // Footer: 1px divider + branding + date
              Padding(
                padding: const EdgeInsets.fromLTRB(_pad, 0, _pad, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(height: 1, color: Colors.black12),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                S.appTitle,
                                style: TextStyle(
                                  fontFamily: 'FixelDisplay',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                S.appTagline,
                                style: TextStyle(
                                  fontFamily: 'FixelText',
                                  fontSize: 9,
                                  color: Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat('d MMMM', S.locale).format(now),
                              style: const TextStyle(
                                fontFamily: 'FixelText',
                                fontSize: 9,
                                color: Colors.black45,
                              ),
                            ),
                            Text(
                              DateFormat('yyyy', S.locale).format(now),
                              style: const TextStyle(
                                fontFamily: 'FixelText',
                                fontSize: 9,
                                color: Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ],
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

class _ShareChip extends StatelessWidget {
  final String label;
  final bool filled;

  const _ShareChip(this.label, {this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? Colors.black : Colors.white,
        border: Border.all(
            color: filled ? Colors.black : Colors.black38, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'FixelText',
          fontSize: 11,
          color: filled ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

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
      text.toUpperCase(),
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
        label.toLowerCase(),
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
