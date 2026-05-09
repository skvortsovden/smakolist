# Смаколист — UI/UX Design Document

**Version:** 1.0.0  
**Language:** Ukrainian only (`uk_UA`)  
**Orientation:** Portrait only

---

## 1. Design System

Смаколист inherits the full design system of Атенція. The palette, typography, spacing, border conventions, and interaction patterns are identical.

### Colour palette

| Role | Value |
|---|---|
| Background | `#FFFFFF` white |
| Primary text | `#000000` black |
| Secondary text | `Colors.black54` |
| Hint / placeholder | `Colors.black38` |
| Disabled / subdued | `Colors.black26`, `Colors.black12` |
| Active control fill | black |
| Active control label | white |
| Inactive control fill | white |
| Inactive control label | black |

No colour is used for meaning or decoration — the entire UI is monochrome.

### Typography (Fixel font family by MacPaw)

| Token | Font | Weight | Size | Usage |
|---|---|---|---|---|
| `headlineLarge` | Fixel Display | 700 | 24 sp | Screen titles, section headers |
| `headlineMedium` | Fixel Display | 600 | 20 sp | Sub-titles, modal titles |
| `titleMedium` | Fixel Text | 600 | 16 sp | Card headers, recipe names in list |
| `bodyLarge` | Fixel Text | 400 | 16 sp | Body copy, slot labels, list items |
| `bodyMedium` | Fixel Text | 400 | 14 sp | Secondary body, dates |
| Section labels | Fixel Text | 700 | 10–11 sp | ALL-CAPS, letter-spacing 1.2–1.4 |
| Micro / stat | Fixel Text | 400–700 | 9–13 sp | Counts, tags, version string |

### Spacing & shape

| Token | Value |
|---|---|
| Standard border | 2 px solid black |
| Corner radius (controls, cards, inputs) | 8 dp |
| Corner radius (primary buttons) | 12–14 dp |
| Card padding | 16 dp |
| Screen horizontal margin | 20 dp |
| No shadows | All depth is implied by 2 px borders |

### Interactive feedback

- **Haptic:** `HapticFeedback.mediumImpact()` on every toggle and primary action.
- **Toggle animation:** 140 ms `AnimatedContainer` for fill/colour transitions.
- **Page transitions:** default `MaterialPageRoute` slide for pushed screens.
- **Opacity fade:** 200 ms for label appearance / disappearance.

---

## 2. App Shell

### Bottom Navigation Bar

Persistent bar at the bottom of `MainScreen`, separated by a 2 px black top border (no shadow, no elevation).

| Index | Icon (inactive → active) | Label |
|---|---|---|
| 0 | `calendar_month_outlined` → `calendar_month` | Календар |
| 1 | `wb_sunny_outlined` → `wb_sunny` | Сьогодні |
| 2 | `bar_chart_outlined` → `bar_chart` | Звіт |
| 3 | `menu_book_outlined` → `menu_book` | Рецепти |
| 4 | `tune_outlined` → `tune` | Налаштування |

- **Default tab on launch:** Сьогодні (index 1).
- Selected icon and label: black. Unselected: `#999999`.
- Label font: Fixel Text, 11 sp, bold when selected.
- `IndexedStack` keeps all five screens alive; switching tabs does not rebuild them.

---

## 3. Onboarding (2 pages)

Shown only on first launch. Horizontal `PageView` with `NeverScrollableScrollPhysics`.

### Progress indicator
Two dots centred at the top. Active: 20×8 dp black pill (radius 4). Inactive: 8×8 dp grey pill. Animated 250 ms.

### Page 1 — Name

| Element | Detail |
|---|---|
| Title | "Як до тебе звертатись?" — 28 sp, bold |
| Text field | Underline style; hint "Введи своє ім'я…"; `textCapitalization.words`; max 30 chars; auto-focused |
| Primary button | "Далі" |

### Page 2 — Guide

| Element | Detail |
|---|---|
| Title | "Як користуватись?" — 24 sp, bold |
| Body | Short guide: create recipes → log meals today → browse history on calendar |
| Primary button | "Розпочати" — calls `markLaunched()` and pushes `MainScreen` |

### Primary Button
Full-width, 52 dp tall, radius 14, black fill, white label, no elevation.

---

## 4. Today View (Сьогодні)

Scrollable `SingleChildScrollView` with 20 dp horizontal padding.

### Header

| Element | Detail |
|---|---|
| Greeting | "Вітаю, {name}!" — headlineLarge |
| Date line | "Сьогодні {день тижня, d MMMM}" — bodyMedium, `Colors.black54` |

### Meal slots

Section label "ПРИЙОМИ ЇЖІ" (ALL-CAPS, 10 sp, 700, 1.2 letter-spacing, `Colors.black54`).

Four vertical slot cards, each in a 2 px bordered container (radius 8, padding 12–16):

**Slot header row:**
- Slot icon (outlined, 20 dp, left) + Slot name (titleMedium, 600) + time suggestion (bodyMedium, `Colors.black38`, right)

| Slot | Icon | Time hint |
|---|---|---|
| Сніданок | `free_breakfast_outlined` | 7:00–10:00 |
| Обід | `lunch_dining_outlined` | 12:00–14:00 |
| Вечеря | `dinner_dining_outlined` | 18:00–21:00 |
| Перекус | `local_cafe_outlined` | будь-коли |

**Logged recipes** (shown below header, one per row):
- Recipe name (bodyLarge) + `close` icon button (18 dp, `Colors.black38`) to remove
- Swipe-to-remove gesture also supported

**"+ Додати" row** (always last in the slot):
- Outlined text button, 2 px border, radius 8, label "+" + slot name

Tapping "+ Додати" opens the **Recipe Picker** bottom sheet (see §8).

Slots with no recipes show a placeholder text "не додано" (`Colors.black38`, 14 sp).

### Note field

Section label "НОТАТКА".

Multiline `TextField`:
- Filled style, fill colour `Colors.black` at 4% opacity
- No visible border, radius 10
- Hint: "Що за смаколики?"
- Max 140 chars; counter in 11 sp `Colors.black38`
- `textCapitalization.sentences`
- Changes persisted immediately (no save button)

---

## 5. Calendar View (Календар)

Two-part layout: calendar (fixed 345 dp) + detail panel (flexible). Same structure as Атенція.

### Calendar widget (`TableCalendar`)

| Setting | Value |
|---|---|
| Locale | `uk_UA` |
| First day of week | Monday |
| Row height | 44 dp |
| Days-of-week row height | 22 dp |
| Max selectable date | today |

**Header:** Month name centred, Fixel Text 600 15 sp. Chevron arrows 20 dp. Forward arrow disabled when already at current month.

**Day cells:**
- Default: black 16 sp text
- Weekend: `Colors.black54`
- Outside month: `Colors.black26`
- Today: outlined black circle (2 px, no fill)
- Selected: filled black circle, white text
- Future: `Colors.black26`, non-tappable

**Day markers** (3 dp above cell bottom edge):

| Condition | Marker |
|---|---|
| Any meal logged | Solid black circle 7×7 dp |
| Note logged (no meals) | Outlined black circle 6×6 dp, 1.5 px border |
| No data | No marker |

### Day detail panel

Separated from calendar by a 2 px full-width black `Divider`. Scrollable.

**No data state:**
- Centred date (titleMedium, bold)
- "Не додано" (`Colors.black38`, bodyMedium)
- **"Додати"** outlined button (2 px, radius 10) → opens `EditDayScreen`

**Future day:**
- Centred date label
- "Цей день ще не настав" (`Colors.black38`)

**Has data:**
- Centred date (bold)
- For each slot that has entries: slot name ALL-CAPS label (10 sp, 700, `Colors.black54`) + recipe names below (bodyLarge), one per line
- Note in italic `Colors.black54`, 14 sp, if present
- **"Змінити"** outlined button → opens `EditDayScreen`

---

## 6. Edit Day Screen

Full-screen sheet pushed via `MaterialPageRoute`.

### Header
- `IconButton` `arrow_back` left → `Navigator.pop()`
- Date label centred (headlineMedium)
- Uses `Stack` so back button does not shift the centred title

### Content (scrollable)

Same layout as Today View:
1. Four meal slots
2. Note field

Changes are held in local state — not persisted until save.

### Save button

Pinned to the bottom, outside the scroll area. Full-width, 52 dp, padding `fromLTRB(20, 8, 20, 20)`. Black fill, radius 12, "Зберегти", white 700 16 sp. Triggers `HapticFeedback.mediumImpact()`.

---

## 7. Recipes View (Рецепти)

### Header

| Element | Detail |
|---|---|
| Title | "Рецепти" — headlineLarge |
| Count label | "N рецептів" — bodyMedium, `Colors.black54` |

### Filter bar

A horizontal `SingleChildScrollView` row of tag chips directly below the header:

| Chip | Label |
|---|---|
| All | усі |
| Breakfast | Сніданок |
| Lunch | Обід |
| Dinner | Вечеря |
| Snack | Перекус |

Each chip: 2 px border, radius 20, padding `horizontal 12, vertical 6`. Active: black fill, white label. Inactive: white fill, black label.

### Recipe list

Each recipe is a 2 px bordered card (radius 8, padding 12–16):
- Recipe name (titleMedium, 600, left)
- Tag chips row below the name (same chip style but smaller: 8 sp, radius 14, padding `horizontal 8, vertical 3`)
- Short description snippet if present (bodyMedium, `Colors.black54`, max 2 lines)
- `chevron_right` icon (20 dp, `Colors.black38`, right-aligned, vertically centred)

Tapping a recipe opens **Recipe Detail** screen.

### "+" FAB (Floating Action Button)

A 56 dp square button, black fill, `add` icon (white, 24 dp), radius 14, pinned bottom-right (20 dp from edges). No elevation — `BorderSide(black, 2)` instead.

### Empty state

Centred column:
- `menu_book_outlined` icon (64 dp, `Colors.black26`)
- "Ще немає рецептів" (titleMedium, `Colors.black38`)
- "Додай свій перший рецепт" (bodyMedium, `Colors.black26`)
- "+ Новий рецепт" outlined button

---

## 8. Recipe Detail Screen

Full-screen, pushed via `MaterialPageRoute`.

### Header
- `arrow_back` back button
- Recipe name centred (headlineMedium)
- `edit_outlined` icon button right → opens **Edit Recipe** screen (same screen with pre-populated fields)

### Content (scrollable, 20 dp horizontal padding)

| Element | Detail |
|---|---|
| Tag chips | Same small chips as list view |
| Description | bodyLarge, `Colors.black87`, 1.6 line-height; hidden if empty |
| "Видалити рецепт" | Outlined red-free danger row: 2 px black border, radius 8, label in `Colors.black54`; tap opens confirmation dialog |

### Delete confirmation dialog
- Title: "Видалити рецепт?"
- Body: "Цей рецепт буде видалено. Записи про страви залишаться."
- Buttons: "Видалити" (black fill), "Скасувати" (text, `Colors.black54`)

---

## 9. Add / Edit Recipe Screen

Full-screen sheet.

### Header
- `arrow_back` back
- "Новий рецепт" or "Редагувати" centred (headlineMedium)

### Content (scrollable, 20 dp padding)

**Name field**

Section label "НАЗВА" (ALL-CAPS).  
`TextField` with 2 px `OutlineInputBorder` (radius 8), hint "Назва страви…", max 60 chars, counter shown.  
Inline error "Назва вже існує" shown in `Colors.black54` below the field on duplicate.

**Description field**

Section label "ОПИС (необов'язково)".  
Multiline `TextField`, filled style (black at 4% opacity), no border, radius 10, hint "Короткий опис", max 300 chars, counter shown.

**Meal type tags**

Section label "ПРИЙОМ ЇЖІ".  
A 2 px bordered container (radius 8) with 4 toggleable rows, each row using the same toggle style as Атенція health toggles: a full-width row divided by 2 px borders, active = black fill. Displayed as a 2×2 grid or a vertical list — 2 px borders between all cells.

| Tag | Label |
|---|---|
| `breakfast` | Сніданок |
| `lunch` | Обід |
| `dinner` | Вечеря |
| `snack` | Перекус |

Multiple tags may be selected simultaneously (independent toggles, not a segmented control).

### Save button

Pinned to bottom. Same style as Edit Day save button. Disabled (opacity 0.4) when name is empty. Label: "Зберегти".

---

## 10. Recipe Picker Bottom Sheet

Triggered from Today View and Edit Day "+ Додати" buttons.

`ModalBottomSheet` (white, top radius 16).

### Header
- Title "Додати {SlotName}" (titleMedium, bold, 600)
- `close` icon button top-right

### Filter row
Horizontally scrollable tag chip row (same style as §7 filter bar). Chips here filter to show only recipes tagged for the current slot by default; "Усі" chip also shown.

### Recipe list

Same card style as §7 recipe list but without description. Tapping a row:
1. Fires `HapticFeedback.mediumImpact()`
2. Adds recipe to the slot
3. Closes the sheet

"Рецепти відсутні" empty state if the filtered list is empty, with a link to go to the Recipes tab.

---

## 11. Report View (Звіт)

> This screen's content is provisional and to be refined with the user.

Scrollable column, 20 dp horizontal padding.

### Period selector

Same component as Атенція Stats:

| Button | Label |
|---|---|
| Тиждень | — |
| Місяць | — |
| Рік | — |

Active: black fill, white text, radius 8. Inactive: 2 px border. All equal width.

### Period navigator
Chevron left / centred label / chevron right. Same as Атенція.

### Empty state
Centred card: "Недостатньо даних за цей період" when no logs exist.

### Stat cards (when data exists)

All cards share: 2 px border, radius 12, padding 16, section title ALL-CAPS 11 sp 700 `Colors.black54`.

#### Fill rate card
- Large number "N/M днів" (headlineLarge) + percentage "X%" (bodyMedium, `Colors.black54`)
- `LinearProgressIndicator` (black, `Colors.black12` bg, height 8, radius 4)

#### Streak card
- "Поспіль: N дн." with `arrow_upward` icon if current streak ≥ 2
- "Найдовший: M дн." secondary line (`Colors.black54`, bodyMedium)

#### Top recipes card
Up to 5 recipes sorted by log count, each rendered as `_StatRow`:
- Name (14 sp 500 weight, max width 160 dp)
- `LinearProgressIndicator`
- Count "N разів" (13 sp 700, `Colors.black54`)

#### Meal slot distribution card
Four `_StatRow` entries: Сніданок / Обід / Вечеря / Перекус.

---

## 12. Settings View (Налаштування)

Scrollable column, `SafeArea`, padding `fromLTRB(20, 20, 20, 32)`.

### Username field

Section label "ЯК ДО ТЕБЕ ЗВЕРТАТИСЯ?".  
`TextField` with `OutlineInputBorder` (2 px, radius 8), hint "Введи ім'я тут…", `textCapitalization.words`, max 30 chars. Changes persisted immediately.

### Meal reminders

Section label "НАГАДУВАННЯ".

Three independent reminder blocks, one per slot. Each block: a 2 px bordered container (radius 8):

**Top row** (always visible):
- Left: slot name (bodyLarge, 600) + time hint (bodyMedium, `Colors.black38`)  
- Right: `Switch` (same style as Атенція)

**Time row** (visible when toggle is on):
- Full-width `GestureDetector` bordered container (radius 8, inside parent with 8 dp top gap)
- Left: "Час" (bodyLarge)
- Right: bold time "HH:MM" + `access_time` icon (18 dp)
- Tap → `showTimePicker` (24-hour, wrapped in `MediaQuery` override)

Toggling on for the first time → OS permission request. If denied, toggle snaps back.

### Action rows

Section label "ДАНІ".

Same style as Атенція action rows: 2 px bordered container, radius 8, horizontal padding 16, vertical 14.

| Row | Icon | Action |
|---|---|---|
| Експортувати дані | `download_outlined` | JSON export via share sheet |
| Імпортувати дані | `upload_outlined` | Opens import dialog |
| Видалити всі дані | `delete_outline` | Opens clear-data dialog |

### Dialogs

All dialogs: white, radius 14, title 18 sp 700, body 14 sp 1.6 line-height `Colors.black87`. Buttons: full-width `Column`, stretched.

**Export dialog** — "Експорт даних" / privacy note / "Зберегти" (black) + "Скасувати" (text).

**Import dialog** — "Імпорт даних" / instructions / "Обрати файл" (black) + "Скасувати" (text).

**Import success** — "Дані імпортовано" / "Записи успішно додано" / "Зрозуміло".

**Import error** — "Помилка імпорту" / error message / "Зрозуміло".

**Clear data dialog** — "Видалити всі дані?" / irreversibility warning / "Зберегти та видалити" + "Просто видалити" + "Скасувати".

**Clear done** — "Дані видалено" / confirmation / "Зрозуміло".

### App info (bottom)

Centred column:
- "Смаколист" — titleMedium bold
- "твій смачний список" — 13 sp `Colors.black54`
- 16 dp gap
- "Версія X.Y.Z" — 13 sp `Colors.black38`
- "© 2026 Denys Skvortsov" — 12 sp `Colors.black38`

---

## 13. Splash Screen

| Element | Detail |
|---|---|
| Background | White |
| Logo | `assets/smakolist-logo.png`, 72×72 |
| App name | headlineLarge, 42 sp, centred |
| Tagline | "твій смачний список" — headlineMedium, centred |
| Animation | Fade-in 900 ms, `Curves.easeIn` |

After 1 400 ms → `MainScreen` fade-transition (400 ms).  
After 1 800 ms on first launch → Onboarding fade-transition (400 ms).

---

## 14. Transitions & Motion Summary

| Transition | Mechanism | Duration |
|---|---|---|
| Splash → Onboarding / MainScreen | `FadeTransition` via `PageRouteBuilder` | 400 ms |
| Onboarding pages | `PageView.nextPage`, `Curves.easeInOut` | 350 ms |
| Onboarding dots | `AnimatedContainer` | 250 ms |
| Today → Edit Day / Calendar → Edit Day | `MaterialPageRoute` (default slide) | default |
| Recipes → Detail / Add / Edit | `MaterialPageRoute` (default slide) | default |
| Slot toggle / tag chip fill | `AnimatedContainer` | 140 ms |
| Recipe Picker sheet | `showModalBottomSheet` | default |
