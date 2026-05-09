import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../l10n/strings.dart';
import '../models/recipe.dart';
import '../providers/app_provider.dart';
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
          children: [
            TableCalendar(
              locale: 'uk_UA',
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
                              border:
                                  Border.all(color: Colors.black, width: 1.5),
                            ),
                          ),
                  );
                },
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                todayDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                ),
                todayTextStyle: const TextStyle(
                  fontFamily: 'FixelText',
                  color: Colors.black,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(
                  fontFamily: 'FixelText',
                  color: Colors.white,
                ),
                defaultTextStyle: const TextStyle(
                  fontFamily: 'FixelText',
                  color: Colors.black,
                ),
                weekendTextStyle: const TextStyle(
                  fontFamily: 'FixelText',
                  color: Colors.black54,
                ),
                disabledTextStyle: const TextStyle(
                  fontFamily: 'FixelText',
                  color: Colors.black26,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontFamily: 'FixelText',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                leftChevronIcon:
                    Icon(Icons.chevron_left, size: 20, color: Colors.black),
                rightChevronIcon:
                    Icon(Icons.chevron_right, size: 20, color: Colors.black),
              ),
              enabledDayPredicate: (day) => !_isFuture(day),
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

    final dateStr = DateFormat('d MMMM yyyy', 'uk').format(selectedDay!);

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
    final hasData =
        log != null && !log.isEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            dateStr,
            style: const TextStyle(
              fontFamily: 'FixelText',
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (!hasData) ...[
            Text(
              S.calendarNoData,
              style: const TextStyle(
                fontFamily: 'FixelText',
                fontSize: 14,
                color: Colors.black38,
              ),
            ),
            const SizedBox(height: 16),
            _OutlinedActionButton(
              label: S.calendarBtnAdd,
              onTap: () => _openEdit(context),
            ),
          ] else ...[
            // Show slot data
            ...MealType.values.where((t) {
              final entries = log.slots[t];
              return entries != null && entries.isNotEmpty;
            }).map((t) {
              final entries = log.slots[t]!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.label.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'FixelText',
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: 1.2,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...entries.map(
                      (e) => Text(
                        e.recipeName,
                        style: const TextStyle(
                          fontFamily: 'FixelText',
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (log.note != null && log.note!.isNotEmpty) ...[
              Text(
                log.note!,
                style: const TextStyle(
                  fontFamily: 'FixelText',
                  fontSize: 14,
                  color: Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
            ],
            _OutlinedActionButton(
              label: S.calendarBtnEdit,
              onTap: () => _openEdit(context),
            ),
          ],
        ],
      ),
    );
  }

  void _openEdit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditDayScreen(date: selectedDay!),
      ),
    );
  }
}

class _OutlinedActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _OutlinedActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black,
        side: const BorderSide(color: Colors.black, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'FixelText',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}
