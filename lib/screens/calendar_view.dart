import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../l10n/strings.dart';
import '../models/meal_log.dart';
import '../models/recipe.dart';
import '../providers/app_provider.dart';
import '../widgets/meal_slot_card.dart';
import 'edit_day_screen.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  bool _isFuture(DateTime day) {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final dayMidnight = DateTime(day.year, day.month, day.day);
    return dayMidnight.isAfter(todayMidnight);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final today = DateTime.now();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Text(S.tabCalendar,
                  style: Theme.of(context).textTheme.headlineLarge),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: SizedBox(
                height: 345,
                child: TableCalendar(
                  locale: S.localeTag,
                  firstDay: DateTime(2020),
                  lastDay: today,
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  rowHeight: 44,
                  daysOfWeekHeight: 22,
                  availableGestures: AvailableGestures.horizontalSwipe,
                  onDaySelected: (selected, focused) {
                    if (!_isFuture(selected)) {
                      setState(() {
                        _selectedDay = selected;
                        _focusedDay = focused;
                      });
                    }
                  },
                  onPageChanged: (focused) {
                    setState(() => _focusedDay = focused);
                  },
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (ctx, day, events) {
                      final key = AppProvider.dateKey(day);
                      final log = provider.logs[key];
                      if (log == null) return null;
                      final hasMeals =
                          log.slots.values.any((list) => list.isNotEmpty);
                      final hasNote =
                          log.note != null && log.note!.isNotEmpty;
                      if (!hasMeals && !hasNote) return null;
                      return Positioned(
                        bottom: 3,
                        child: hasMeals
                            ? Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.black, width: 1.5),
                                ),
                              ),
                      );
                    },
                  ),
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    cellMargin: const EdgeInsets.all(1),
                    todayDecoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    todayTextStyle: const TextStyle(
                      fontFamily: 'FixelText',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle: const TextStyle(
                      fontFamily: 'FixelText',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    defaultTextStyle: const TextStyle(
                      fontFamily: 'FixelText',
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    weekendTextStyle: const TextStyle(
                      fontFamily: 'FixelText',
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                    disabledTextStyle: const TextStyle(
                      fontFamily: 'FixelText',
                      fontSize: 16,
                      color: Colors.black26,
                    ),
                    outsideTextStyle: const TextStyle(
                      fontFamily: 'FixelText',
                      fontSize: 16,
                      color: Colors.black26,
                    ),
                  ),
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      fontFamily: 'FixelText',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Colors.black,
                    ),
                    weekendStyle: TextStyle(
                      fontFamily: 'FixelText',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    headerMargin: EdgeInsets.zero,
                    headerPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    titleTextStyle: Theme.of(context)
                        .textTheme
                        .titleMedium!
                        .copyWith(
                          fontFamily: 'FixelText',
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                    leftChevronIcon: const Icon(Icons.chevron_left,
                        size: 20, color: Colors.black),
                    rightChevronIcon: const Icon(Icons.chevron_right,
                        size: 20, color: Colors.black),
                  ),
                  enabledDayPredicate: (day) => !_isFuture(day),
                ),
              ),
            ),
            const Divider(thickness: 2, height: 2, color: Colors.black),
            Expanded(
              child: _DayDetailPanel(
                selectedDay: _selectedDay,
                isFuture: _selectedDay != null && _isFuture(_selectedDay!),
                provider: provider,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayDetailPanel extends StatelessWidget {
  final DateTime? selectedDay;
  final bool isFuture;
  final AppProvider provider;

  const _DayDetailPanel({
    required this.selectedDay,
    required this.isFuture,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedDay == null) {
      return const SizedBox.shrink();
    }

    final dateStr = DateFormat('d MMMM yyyy', S.locale).format(selectedDay!);

    if (isFuture) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dateStr,
              style: const TextStyle(
                fontFamily: 'FixelText',
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              S.calendarFutureDay,
              style: const TextStyle(
                fontFamily: 'FixelText',
                fontSize: 14,
                color: Colors.black38,
              ),
            ),
          ],
        ),
      );
    }

    final key = AppProvider.dateKey(selectedDay!);
    final log = provider.logs[key];
    final hasData = log != null &&
        (log.slots.values.any((list) => list.isNotEmpty) ||
            (log.note != null && log.note!.isNotEmpty));

    if (!hasData) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              dateStr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'FixelText',
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              S.calendarNoData,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'FixelText',
                fontSize: 14,
                color: Colors.black38,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EditDayScreen(date: selectedDay!),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  S.calendarBtnAdd,
                  style: TextStyle(
                    fontFamily: 'FixelText',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            dateStr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'FixelText',
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          ...MealType.values.expand((slot) {
            final entries = log.slots[slot] ?? [];
            if (entries.isEmpty) return const <Widget>[];
            return [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MealSlotCard(
                  slot: slot,
                  entries: entries,
                ),
              ),
            ];
          }),
          if (log.note != null && log.note!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              log.note!,
              style: const TextStyle(
                fontFamily: 'FixelText',
                fontSize: 14,
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EditDayScreen(date: selectedDay!),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                S.calendarBtnEdit,
                style: const TextStyle(
                  fontFamily: 'FixelText',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

