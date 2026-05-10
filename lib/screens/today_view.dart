import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/meal_log.dart';
import '../models/recipe.dart';
import '../providers/app_provider.dart';
import '../widgets/meal_slot_card.dart';
import '../widgets/recipe_picker_sheet.dart';

class TodayView extends StatefulWidget {
  const TodayView({super.key});

  @override
  State<TodayView> createState() => _TodayViewState();
}

class _TodayViewState extends State<TodayView> {
  late TextEditingController _noteController;
  bool _noteInitialized = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _showGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.onboardingGuideTitle,
              style: const TextStyle(
                fontFamily: 'FixelDisplay',
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              S.onboardingGuideText,
              style: const TextStyle(
                fontFamily: 'FixelText',
                fontSize: 15,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  S.onboardingGuideBtn,
                  style: const TextStyle(
                    fontFamily: 'FixelText',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPicker(BuildContext context, MealType slot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => RecipePickerSheet(
        slot: slot,
        onSelected: (recipe) => _addEntry(recipe, slot),
      ),
    );
  }

  void _addEntry(Recipe recipe, MealType slot) {
    final provider = context.read<AppProvider>();
    final today = DateTime.now();
    provider.addMealEntry(
      today,
      slot,
      MealEntry(
        recipeId: recipe.id,
        recipeName: recipe.name,
        loggedAt: DateTime.now(),
      ),
    );
  }

  void _removeEntry(MealType slot, int index) {
    final provider = context.read<AppProvider>();
    provider.removeMealEntry(DateTime.now(), slot, index);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final today = DateTime.now();
    final log = provider.getOrCreateLog(today);

    // Sync note controller once
    if (!_noteInitialized) {
      _noteController.text = log.note ?? '';
      _noteInitialized = true;
    }

    final username = provider.username;
    final greeting =
        username.isEmpty ? S.greetingDefault : S.greetingNamed(username);
    final dateStr = DateFormat('EEEE, d MMMM', S.locale).format(today);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // Greeting row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${S.todayDatePrefix} $dateStr.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.black54,
                              ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showGuide(context),
                    child: Image.asset('assets/smakolist-logo.png', height: 32, fit: BoxFit.contain),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Main header
              Text(
                S.todayMealsTitle,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 20),
              // Four meal slots
              ...MealType.values.map((slot) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MealSlotCard(
                      slot: slot,
                      entries: log.slots[slot] ?? [],
                      onAdd: () => _openPicker(context, slot),
                      onRemove: (i) => _removeEntry(slot, i),
                    ),
                  )),
              const SizedBox(height: 12),
              // Note section
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
                onChanged: (v) {
                  context.read<AppProvider>().setNote(today, v);
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
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
