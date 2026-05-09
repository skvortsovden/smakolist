# Смаколист — Requirements

**Version:** 1.0.0  
**Platform:** iOS & Android (Flutter)  
**Language:** Ukrainian only (`uk_UA`)

---

## 1. Overview

Смаколист is a personal meal-tracking app. Users build a collection of their own recipes, then log daily meals by picking from that collection. The app tracks eating history across a calendar, surfaces simple stats in a report, and sends meal-time reminders.

**Name meaning:** Смак (taste/flavour) + список (list) = "flavour list" or "tasty list".

---

## 2. Screens

The app has five permanent tabs in a bottom navigation bar:

| # | Tab | Ukrainian |
|---|---|---|
| 0 | Calendar | Календар |
| 1 | Today | Сьогодні |
| 2 | Report | Звіт |
| 3 | Recipes | Рецепти |
| 4 | Settings | Налаштування |

---

## 3. Feature Requirements

### 3.1 Calendar (Календар)

**FR-CAL-1** The calendar displays the current month by default with navigation to previous months.  
**FR-CAL-2** Each day cell shows a visual marker if any meal was logged on that day.  
**FR-CAL-3** Tapping a day reveals a detail panel below the calendar listing every meal logged on that day, grouped by slot (Сніданок / Обід / Вечеря / Перекус).  
**FR-CAL-4** The detail panel has an **Додати** (no data) or **Змінити** (has data) action that opens the **Edit Day** screen.  
**FR-CAL-5** Future days are non-interactive (no tap action, no edit button).  
**FR-CAL-6** The calendar cannot navigate beyond the current month into the future.

---

### 3.2 Today (Сьогодні)

**FR-TOD-1** The screen shows today's date and a personalised greeting using the saved username.  
**FR-TOD-2** Four meal slots are displayed vertically: Сніданок, Обід, Вечеря, Перекус.  
**FR-TOD-3** Each slot lists the recipes already logged in it and shows an **"+ Додати"** button.  
**FR-TOD-4** Tapping **"+ Додати"** opens a bottom-sheet picker showing the user's recipe list, filterable by meal-type tag.  
**FR-TOD-5** A recipe can appear in multiple slots on the same day.  
**FR-TOD-6** Tapping a logged recipe on a slot reveals a remove option (swipe or long-press).  
**FR-TOD-7** A short optional note (max 140 chars) can be added for the day.  
**FR-TOD-8** All changes on Today are persisted immediately (no explicit save button).

---

### 3.3 Report (Звіт)

> The exact content of this screen is to be finalised with the user. The following is a proposed default set.

**FR-REP-1** Period selector: Тиждень / Місяць / Рік with back/forward navigator.  
**FR-REP-2** **Logging streak card** — current consecutive days with ≥ 1 meal logged; longest streak in period.  
**FR-REP-3** **Fill rate card** — percentage of days in the period with ≥ 1 meal logged, shown as a number, percentage, and bar.  
**FR-REP-4** **Top recipes card** — up to 5 most-logged recipes in the period with a frequency bar.  
**FR-REP-5** **Meal slot distribution card** — count of each slot type logged (Сніданок / Обід / Вечеря / Перекус) shown as bars.  
**FR-REP-6** Empty state shown when there are no logs in the selected period.

---

### 3.4 Recipes (Рецепти)

**FR-REC-1** Displays a flat list of all user-created recipes.  
**FR-REC-2** List can be filtered by meal-type tag (Сніданок / Обід / Вечеря / Перекус / all).  
**FR-REC-3** A **"+ Новий рецепт"** button opens the **Add Recipe** screen.  
**FR-REC-4** Tapping a recipe in the list opens the **Recipe Detail** screen.  
**FR-REC-5** A recipe can be deleted from the detail screen with a confirmation dialog.  
**FR-REC-6** Deleting a recipe does not remove historical meal log entries (the name is stored as a snapshot).  
**FR-REC-7** Empty state shown when the recipe list is empty.

#### Add / Edit Recipe screen

**FR-REC-8** Fields: Name (required, max 60 chars), Description (optional, max 300 chars), Meal type tags (multi-select: Сніданок, Обід, Вечеря, Перекус).  
**FR-REC-9** Save is only enabled when the name is non-empty.  
**FR-REC-10** Name must be unique (case-insensitive); duplicate names show an inline error.

---

### 3.5 Settings (Налаштування)

**FR-SET-1** Username field (max 30 chars); shown in greetings on Today.  
**FR-SET-2** Three independent meal reminders — Сніданок, Обід, Вечеря — each with:  
  - An enabled/disabled toggle  
  - A time picker (24-hour format)  
**FR-SET-3** Enabling any reminder for the first time requests OS notification permission; if denied, the toggle snaps back.  
**FR-SET-4** Export data action — exports all recipes and meal logs as a JSON file via the system share sheet.  
**FR-SET-5** Import data action — imports from a JSON file; merges with existing data (recipes: upsert by name; logs: upsert by date).  
**FR-SET-6** Delete all data action with a two-step confirmation dialog.  
**FR-SET-7** App version, copyright, and a short tagline displayed at the bottom of the screen.

---

## 4. Data Model

### Recipe

| Field | Type | Constraints |
|---|---|---|
| `id` | `String` (UUID v4) | unique, immutable |
| `name` | `String` | required, max 60, unique |
| `description` | `String?` | max 300 |
| `tags` | `List<MealType>` | 0–4 items |
| `createdAt` | `DateTime` | set on creation |

### MealLog (one document per calendar date)

| Field | Type | Constraints |
|---|---|---|
| `date` | `String` (YYYY-MM-DD) | primary key |
| `slots` | `Map<MealType, List<MealEntry>>` | |
| `note` | `String?` | max 140 |

### MealEntry

| Field | Type | Notes |
|---|---|---|
| `recipeId` | `String` | FK to Recipe.id |
| `recipeName` | `String` | snapshot at log time |
| `loggedAt` | `DateTime` | for ordering |

### MealType enum

`breakfast` · `lunch` · `dinner` · `snack`  
Ukrainian labels: Сніданок · Обід · Вечеря · Перекус

---

## 5. Non-Functional Requirements

| Concern | Requirement |
|---|---|
| Language | Ukrainian only; all strings in `uk_UA` ARB/intl files |
| Storage | Local-only; Hive or Isar (same pattern as Atensia's SharedPreferences usage) |
| Offline | No network required |
| Orientation | Portrait only |
| Touch targets | Minimum 44 dp |
| Notifications | `flutter_local_notifications` |
| Accessibility | Sufficient contrast (monochrome palette already ensures this) |

---

## 6. Out of Scope for v1

- Cloud sync or multi-device support  
- Recipe photos  
- Nutritional / calorie tracking  
- Social sharing  
- Multi-user / family mode  
- Barcode scanning  
- AI recipe suggestions