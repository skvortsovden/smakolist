import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/meal_log.dart';
import '../models/recipe.dart';
import '../providers/app_provider.dart';
import '../widgets/meal_slot_card.dart';
import '../widgets/recipe_picker_sheet.dart';

class EditDayScreen extends StatefulWidget {
  final DateTime date;

  const EditDayScreen({super.key, required this.date});

  @override
  State<EditDayScreen> createState() => _EditDayScreenState();
}

class _EditDayScreenState extends State<EditDayScreen> {
  late MealLog _log;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    _log = provider.getOrCreateLog(widget.date);
    _noteController = TextEditingController(text: _log.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _openPicker(MealType slot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<AppProvider>(),
        child: RecipePickerSheet(
          slot: slot,
          onSelected: (recipe) => _addEntry(recipe, slot),
        ),
      ),
    );
  }

  void _addEntry(Recipe recipe, MealType slot) {
    setState(() {
      final slots = Map<MealType, List<MealEntry>>.from(
          _log.slots.map((k, v) => MapEntry(k, List<MealEntry>.from(v))));
      slots[slot] = [
        ...(slots[slot] ?? []),
        MealEntry(
          recipeId: recipe.id,
          recipeName: recipe.name,
          loggedAt: DateTime.now(),
        ),
      ];
      _log = _log.copyWith(slots: slots);
    });
  }

  void _removeEntry(MealType slot, int index) {
    setState(() {
      final slots = Map<MealType, List<MealEntry>>.from(
          _log.slots.map((k, v) => MapEntry(k, List<MealEntry>.from(v))));
      final list = List<MealEntry>.from(slots[slot] ?? []);
      list.removeAt(index);
      slots[slot] = list;
      _log = _log.copyWith(slots: slots);
    });
  }

  void _save() {
    HapticFeedback.mediumImpact();
    final note = _noteController.text.trim();
    final updated = _log.copyWith(
      noteOrNull: note.isEmpty ? null : note,
    );
    context.read<AppProvider>().saveLog(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMMM yyyy', S.locale).format(widget.date);

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
                Text(
                  dateStr,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
            const Divider(height: 1, thickness: 1, color: Colors.black12),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _SectionLabel(S.todaySectionMeals),
                    const SizedBox(height: 12),
                    ...MealType.values.map((slot) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: MealSlotCard(
                            slot: slot,
                            entries: _log.slots[slot] ?? [],
                            onAdd: () => _openPicker(slot),
                            onRemove: (i) => _removeEntry(slot, i),
                          ),
                        )),
                    const SizedBox(height: 12),
                    _SectionLabel(S.todaySectionNote),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _noteController,
                      maxLines: null,
                      maxLength: 140,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: S.todayNoteHint,
                        hintStyle: const TextStyle(color: Colors.black38),
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.04),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        counterStyle: const TextStyle(
                          fontFamily: 'FixelText',
                          fontSize: 11,
                          color: Colors.black38,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            // Save button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    S.editBtnSave,
                    style: const TextStyle(
                      fontFamily: 'FixelText',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
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
