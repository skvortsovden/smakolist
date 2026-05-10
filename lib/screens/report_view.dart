import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/recipe.dart';
import '../providers/app_provider.dart';

enum _Period { week, month, year }

class ReportView extends StatefulWidget {
  const ReportView({super.key});

  @override
  State<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<ReportView> {
  _Period _period = _Period.week;
  int _offset = 0; // 0 = current, -1 = previous, etc.

  DateTimeRange _range() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_period) {
      case _Period.week:
        final start =
            today.subtract(Duration(days: today.weekday - 1 + _offset.abs() * 7));
        return DateTimeRange(
            start: start, end: start.add(const Duration(days: 6)));
      case _Period.month:
        final month = DateTime(now.year, now.month + _offset);
        final end = DateTime(month.year, month.month + 1, 0);
        return DateTimeRange(start: DateTime(month.year, month.month, 1), end: end);
      case _Period.year:
        final year = now.year + _offset;
        return DateTimeRange(
            start: DateTime(year, 1, 1), end: DateTime(year, 12, 31));
    }
  }

  String _periodLabel(DateTimeRange range) {
    switch (_period) {
      case _Period.week:
        final s = DateFormat('d MMM', S.locale).format(range.start);
        final e = DateFormat('d MMM', S.locale).format(range.end);
        return '$s – $e';
      case _Period.month:
        return DateFormat('LLLL yyyy', S.locale).format(range.start);
      case _Period.year:
        return '${range.start.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final range = _range();
    final today = DateTime.now();
    final clampedEnd =
        range.end.isAfter(today) ? today : range.end;
    final dates = provider.datesInRange(range.start, clampedEnd);
    final filled = provider.filledDays(dates);
    final total = dates.length;
    final hasData = filled > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(S.reportTitle,
                  style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 20),
              // Period selector
              _PeriodSelector(
                current: _period,
                onChanged: (p) => setState(() {
                  _period = p;
                  _offset = 0;
                }),
              ),
              const SizedBox(height: 16),
              // Period navigator
              _PeriodNavigator(
                label: _periodLabel(range),
                canGoForward: _offset < 0,
                onBack: () => setState(() => _offset--),
                onForward: () => setState(() => _offset++),
              ),
              const SizedBox(height: 20),
              if (!hasData)
                _NoData()
              else ...[
                // Fill rate
                _StatCard(
                  title: S.reportSectionFill,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            S.reportFillDays(filled, total),
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            total > 0
                                ? '${(filled / total * 100).round()}%'
                                : '0%',
                            style: const TextStyle(
                              fontFamily: 'FixelText',
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: total > 0 ? filled / total : 0,
                          minHeight: 8,
                          backgroundColor: Colors.black12,
                          valueColor: const AlwaysStoppedAnimation(Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Streak
                _StatCard(
                  title: S.reportSectionStreak,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            S.reportStreakCurrent(provider.currentStreak()),
                            style: const TextStyle(
                              fontFamily: 'FixelText',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (provider.currentStreak() >= 2)
                            const Icon(Icons.arrow_upward,
                                size: 16, color: Colors.black),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        S.reportStreakLongest(
                            provider.longestStreak(dates)),
                        style: const TextStyle(
                          fontFamily: 'FixelText',
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Top recipes
                _TopRecipesCard(provider: provider, dates: dates),
                const SizedBox(height: 12),
                // Slot distribution
                _SlotDistributionCard(provider: provider, dates: dates),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final _Period current;
  final void Function(_Period) onChanged;

  const _PeriodSelector({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final periods = [
      (_Period.week, S.reportPeriodWeek),
      (_Period.month, S.reportPeriodMonth),
      (_Period.year, S.reportPeriodYear),
    ];

    return Row(
      children: periods.map((p) {
        final isActive = current == p.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(p.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? Colors.black : Colors.white,
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                p.$2,
                style: TextStyle(
                  fontFamily: 'FixelText',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isActive ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PeriodNavigator extends StatelessWidget {
  final String label;
  final bool canGoForward;
  final VoidCallback onBack;
  final VoidCallback onForward;

  const _PeriodNavigator({
    required this.label,
    required this.canGoForward,
    required this.onBack,
    required this.onForward,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: onBack,
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'FixelText',
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right,
              color: canGoForward ? Colors.black : Colors.black26),
          onPressed: canGoForward ? onForward : null,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _StatCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'FixelText',
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 1.2,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _TopRecipesCard extends StatelessWidget {
  final AppProvider provider;
  final List<String> dates;

  const _TopRecipesCard({required this.provider, required this.dates});

  @override
  Widget build(BuildContext context) {
    final top = provider.topRecipes(dates);
    if (top.isEmpty) return const SizedBox.shrink();

    final maxCount = top.values.reduce((a, b) => a > b ? a : b);

    return _StatCard(
      title: S.reportSectionTop,
      child: Column(
        children: top.entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 160,
                  child: Text(
                    e.key,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'FixelText',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: maxCount > 0 ? e.value / maxCount : 0,
                      minHeight: 6,
                      backgroundColor: Colors.black12,
                      valueColor:
                          const AlwaysStoppedAnimation(Colors.black),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${e.value} ${S.reportTimesSuffix}',
                  style: const TextStyle(
                    fontFamily: 'FixelText',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SlotDistributionCard extends StatelessWidget {
  final AppProvider provider;
  final List<String> dates;

  const _SlotDistributionCard({required this.provider, required this.dates});

  @override
  Widget build(BuildContext context) {
    final dist = provider.slotDistribution(dates);
    final total = dist.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    return _StatCard(
      title: S.reportSectionSlots,
      child: Column(
        children: MealType.values.map((t) {
          final count = dist[t] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    S.mealLabel(t),
                    style: const TextStyle(
                      fontFamily: 'FixelText',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: total > 0 ? count / total : 0,
                      minHeight: 6,
                      backgroundColor: Colors.black12,
                      valueColor:
                          const AlwaysStoppedAnimation(Colors.black),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$count',
                  style: const TextStyle(
                    fontFamily: 'FixelText',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NoData extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            S.reportNoData,
            style: const TextStyle(
              fontFamily: 'FixelText',
              fontSize: 14,
              color: Colors.black38,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
