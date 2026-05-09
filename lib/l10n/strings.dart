import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

class S {
  S._();

  static Map<String, dynamic> _m = {};

  static Future<void> load() async {
    final raw = await rootBundle.loadString('assets/l10n/uk.yaml');
    _m = Map<String, dynamic>.from(loadYaml(raw) as Map);
  }

  static String _s(String key) => _m[key] as String? ?? key;

  // ── App ─────────────────────────────────────────────────────────────────
  static String get appTitle => _s('app_title');
  static String get appTagline => _s('app_tagline');

  // ── Navigation ──────────────────────────────────────────────────────────
  static String get tabCalendar => _s('tab_calendar');
  static String get tabToday => _s('tab_today');
  static String get tabReport => _s('tab_report');
  static String get tabRecipes => _s('tab_recipes');
  static String get tabSettings => _s('tab_settings');

  // ── Onboarding ──────────────────────────────────────────────────────────
  static String get onboardingNameTitle => _s('onboarding_name_title');
  static String get onboardingNameHint => _s('onboarding_name_hint');
  static String get onboardingNameBtn => _s('onboarding_name_btn');
  static String welcomeTitle(String name) =>
      _s('onboarding_welcome_title').replaceFirst('{name}', name);
  static String get welcomeTitleDefault => _s('onboarding_welcome_title_default');
  static String get welcomeBody => _s('onboarding_welcome_body');
  static String get welcomeBtn => _s('onboarding_welcome_btn');
  static String get onboardingGuideTitle => _s('onboarding_guide_title');
  static String get onboardingGuideText => _s('onboarding_guide_text');
  static String get onboardingGuideBtn => _s('onboarding_guide_btn');

  // ── Today ────────────────────────────────────────────────────────────────
  static String greetingNamed(String name) =>
      _s('today_greeting_named').replaceFirst('{name}', name);
  static String get greetingDefault => _s('today_greeting_default');
  static String get todayDatePrefix => _s('today_date_prefix');
  static String get todaySectionMeals => _s('today_section_meals');
  static String get todaySectionNote => _s('today_section_note');
  static String get todayNoteHint => _s('today_note_hint');
  static String get todayNoItems => _s('today_no_items');
  static String get todayBtnAddPrefix => _s('today_btn_add_prefix');

  // ── Calendar ─────────────────────────────────────────────────────────────
  static String get calendarFutureDay => _s('calendar_future_day');
  static String get calendarNoData => _s('calendar_no_data');
  static String get calendarBtnAdd => _s('calendar_btn_add');
  static String get calendarBtnEdit => _s('calendar_btn_edit');

  // ── Edit day ─────────────────────────────────────────────────────────────
  static String get editBtnSave => _s('edit_btn_save');

  // ── Recipe picker ────────────────────────────────────────────────────────
  static String get pickerTitlePrefix => _s('picker_title_prefix');
  static String get pickerEmpty => _s('picker_empty');
  static String get pickerGoRecipes => _s('picker_go_recipes');
  static String get pickerFilterAll => _s('picker_filter_all');

  // ── Recipes ───────────────────────────────────────────────────────────────
  static String get recipesTitle => _s('recipes_title');
  static String get recipesFilterAll => _s('recipes_filter_all');
  static String get recipesEmptyTitle => _s('recipes_empty_title');
  static String get recipesEmptySubtitle => _s('recipes_empty_subtitle');
  static String get recipesEmptyBtn => _s('recipes_empty_btn');
  static String recipesCount(int n) {
    if (n == 1) return '$n ${_s('recipes_count_suffix_1')}';
    if (n >= 2 && n <= 4) return '$n ${_s('recipes_count_suffix_few')}';
    return '$n ${_s('recipes_count_suffix_many')}';
  }

  // ── Recipe detail ─────────────────────────────────────────────────────────
  static String get recipeDetailDeleteBtn => _s('recipe_detail_delete_btn');
  static String get recipeDeleteTitle => _s('recipe_delete_title');
  static String get recipeDeleteBody => _s('recipe_delete_body');
  static String get recipeDeleteConfirm => _s('recipe_delete_confirm');
  static String get recipeDeleteCancel => _s('recipe_delete_cancel');

  // ── Add / Edit recipe ─────────────────────────────────────────────────────
  static String get recipeAddTitle => _s('recipe_add_title');
  static String get recipeEditTitle => _s('recipe_edit_title');
  static String get recipeSectionName => _s('recipe_section_name');
  static String get recipeNameHint => _s('recipe_name_hint');
  static String get recipeNameErrorDuplicate => _s('recipe_name_error_duplicate');
  static String get recipeSectionDesc => _s('recipe_section_desc');
  static String get recipeDescHint => _s('recipe_desc_hint');
  static String get recipeSectionTags => _s('recipe_section_tags');
  static String get recipeBtnSave => _s('recipe_btn_save');

  // ── Report ────────────────────────────────────────────────────────────────
  static String get reportTitle => _s('report_title');
  static String get reportPeriodWeek => _s('report_period_week');
  static String get reportPeriodMonth => _s('report_period_month');
  static String get reportPeriodYear => _s('report_period_year');
  static String get reportNoData => _s('report_no_data');
  static String get reportSectionFill => _s('report_section_fill');
  static String reportFillDays(int n, int m) =>
      _s('report_fill_days').replaceFirst('{n}', '$n').replaceFirst('{m}', '$m');
  static String get reportSectionStreak => _s('report_section_streak');
  static String reportStreakCurrent(int n) =>
      _s('report_streak_current').replaceFirst('{n}', '$n');
  static String reportStreakLongest(int n) =>
      _s('report_streak_longest').replaceFirst('{n}', '$n');
  static String get reportSectionTop => _s('report_section_top');
  static String get reportTimesSuffix => _s('report_times_suffix');
  static String get reportSectionSlots => _s('report_section_slots');

  // ── Settings ──────────────────────────────────────────────────────────────
  static String get settingsTitle => _s('settings_title');
  static String get settingsNameLabel => _s('settings_name_label');
  static String get settingsNameHint => _s('settings_name_hint');
  static String get settingsSectionReminders => _s('settings_section_reminders');
  static String get settingsSectionData => _s('settings_section_data');
  static String get settingsExportBtn => _s('settings_export_btn');
  static String get settingsImportBtn => _s('settings_import_btn');
  static String get settingsClearBtn => _s('settings_clear_btn');
  static String get settingsExportTitle => _s('settings_export_title');
  static String get settingsExportMessage => _s('settings_export_message');
  static String get settingsExportSave => _s('settings_export_save');
  static String get settingsExportCancel => _s('settings_export_cancel');
  static String get settingsImportTitle => _s('settings_import_title');
  static String get settingsImportMessage => _s('settings_import_message');
  static String get settingsImportTemplateBtn => _s('settings_import_template_btn');
  static String get settingsImportChoose => _s('settings_import_choose');
  static String get settingsImportCancel => _s('settings_import_cancel');
  static String get settingsImportDoneTitle => _s('settings_import_done_title');
  static String get settingsImportDoneMessage => _s('settings_import_done_message');
  static String get settingsImportDoneBtn => _s('settings_import_done_btn');
  static String get settingsImportErrorTitle => _s('settings_import_error_title');
  static String get settingsImportErrorMessage => _s('settings_import_error_message');
  static String get settingsImportErrorBtn => _s('settings_import_error_btn');
  static String get settingsClearTitle => _s('settings_clear_title');
  static String get settingsClearMessage => _s('settings_clear_message');
  static String get settingsClearExport => _s('settings_clear_export');
  static String get settingsClearErase => _s('settings_clear_erase');
  static String get settingsClearCancel => _s('settings_clear_cancel');
  static String get settingsClearDoneTitle => _s('settings_clear_done_title');
  static String get settingsClearDoneMessage => _s('settings_clear_done_message');
  static String get settingsClearDoneBtn => _s('settings_clear_done_btn');
  static String get settingsPrivacy => _s('settings_privacy');
  static String get settingsReminderBreakfast => _s('settings_reminder_breakfast');
  static String get settingsReminderLunch => _s('settings_reminder_lunch');
  static String get settingsReminderDinner => _s('settings_reminder_dinner');
  static String get settingsReminderTimeLabel => _s('settings_reminder_time_label');

  // ── Slot time hints ───────────────────────────────────────────────────────
  static String get slotTimeBreakfast => _s('today_slot_time_breakfast');
  static String get slotTimeLunch => _s('today_slot_time_lunch');
  static String get slotTimeDinner => _s('today_slot_time_dinner');
  static String get slotTimeSnack => _s('today_slot_time_snack');
}
