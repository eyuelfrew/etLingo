import 'package:flutter/material.dart';
import '../../core/calendar/ethiopian_calendar.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/et_strings.dart';

/// Full Ethiopian (Ge'ez) calendar — month grid, holidays, Gregorian twin.
class EthiopianCalendarScreen extends StatefulWidget {
  const EthiopianCalendarScreen({super.key});

  @override
  State<EthiopianCalendarScreen> createState() =>
      _EthiopianCalendarScreenState();
}

class _EthiopianCalendarScreenState extends State<EthiopianCalendarScreen> {
  late EthiopianDate _month;
  EthiopianDate? _selected;

  @override
  void initState() {
    super.initState();
    final today = EthiopianCalendar.fromGregorian(DateTime.now());
    _month = EthiopianDate(today.year, today.month, 1);
    _selected = today;
  }

  void _goMonth(int delta) {
    setState(() {
      var y = _month.year;
      var m = _month.month + delta;
      while (m < 1) {
        m += 13;
        y -= 1;
      }
      while (m > 13) {
        m -= 13;
        y += 1;
      }
      _month = EthiopianDate(y, m, 1);
    });
  }

  void _goToday() {
    final t = EthiopianCalendar.fromGregorian(DateTime.now());
    setState(() {
      _month = EthiopianDate(t.year, t.month, 1);
      _selected = t;
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = EthiopianCalendar.daysInMonth(_month.year, _month.month);
    final firstWeekday = EthiopianCalendar.weekdayIndex(
        EthiopianDate(_month.year, _month.month, 1));
    final todayEth = EthiopianCalendar.fromGregorian(DateTime.now());
    final selected = _selected ?? todayEth;
    final selectedGreg = EthiopianCalendar.toGregorian(selected);
    final holiday = EthiopianCalendar.holidaysOn(selected);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: EtColors.ink,
        elevation: 0,
        title: Text(EtStrings.ethiopianCalendar),
        actions: [
          TextButton(onPressed: _goToday, child: Text(EtStrings.today)),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Month nav
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _goMonth(-1),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${_month.monthName()} ${_month.year}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          EthiopianCalendar.toGregorian(
                                  EthiopianDate(_month.year, _month.month, 1))
                              .toString()
                              .substring(0, 10),
                          style: const TextStyle(
                            fontSize: 12,
                            color: EtColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _goMonth(1),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ),
            // Weekday headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: List.generate(7, (i) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        EthiopianCalendar.weekdaysAm[i],
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: EtColors.muted,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 6),
            // Day grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 0.9,
                ),
                itemCount: (firstWeekday + days).clamp(35, 42),
                itemBuilder: (ctx, i) {
                  final dayNum = i - firstWeekday + 1;
                  if (dayNum < 1 || dayNum > days) {
                    return const SizedBox.shrink();
                  }
                  final date =
                      EthiopianDate(_month.year, _month.month, dayNum);
                  final isToday = date.year == todayEth.year &&
                      date.month == todayEth.month &&
                      date.day == todayEth.day;
                  final isSel = date.year == selected.year &&
                      date.month == selected.month &&
                      date.day == selected.day;
                  final isHoliday =
                      EthiopianCalendar.holidaysOn(date).isNotEmpty;
                  final greg = EthiopianCalendar.toGregorian(date);

                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _selected = date),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSel
                            ? EtColors.green
                            : isToday
                                ? EtColors.green.withValues(alpha: 0.12)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isHoliday && !isSel
                              ? EtColors.red.withValues(alpha: 0.5)
                              : Colors.transparent,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$dayNum',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isSel ? Colors.white : EtColors.ink,
                            ),
                          ),
                          Text(
                            '${greg.month}/${greg.day}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: isSel
                                  ? Colors.white70
                                  : EtColors.locked,
                            ),
                          ),
                          if (isHoliday)
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: isSel ? Colors.white : EtColors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Selected day details
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: EtColors.cream,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: EtColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${selected.label()} · '
                    '${EthiopianCalendar.weekdaysAm[EthiopianCalendar.weekdayIndex(selected)]}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gregorian: ${selectedGreg.year}-${selectedGreg.month.toString().padLeft(2, '0')}-${selectedGreg.day.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      color: EtColors.muted,
                    ),
                  ),
                  if (holiday.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ...holiday.map(
                      (h) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: EtColors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.celebration_rounded,
                                size: 18, color: EtColors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${h.nameAm} · ${h.name}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: EtColors.redDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Text(
                      EtStrings.noHolidayToday,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: EtColors.muted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  // Upcoming this year
                  _UpcomingHolidays(year: _month.year, current: selected),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingHolidays extends StatelessWidget {
  final int year;
  final EthiopianDate current;
  const _UpcomingHolidays({required this.year, required this.current});

  @override
  Widget build(BuildContext context) {
    final items = <Map<String, Object?>>[];
    for (final h in EthiopianCalendar.ethiopicHolidays) {
      // show same year and next (for months near year end)
      for (final y in [year, year + 1]) {
        if (y != current.year && y != year) continue;
        final d = EthiopianDate(y, h.month, h.day);
        final diffDays = _daysBetween(current, d);
        if (diffDays < -7 || diffDays > 200) continue;
        items.add({'h': h, 'd': d, 'diff': diffDays});
      }
    }
    items.sort((a, b) => (a['diff'] as int).compareTo(b['diff'] as int));
    final show = items.take(4).toList();
    if (show.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          EtStrings.upcomingHolidays,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: EtColors.muted,
          ),
        ),
        const SizedBox(height: 6),
        ...show.map((e) {
          final h = e['h'] as EthHoliday;
          final d = e['d'] as EthiopianDate;
          final diff = e['diff'] as int;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${h.nameAm} · ${h.name}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  d.label(),
                  style: const TextStyle(
                      fontSize: 11, color: EtColors.muted),
                ),
                const SizedBox(width: 8),
                Text(
                  diff == 0
                      ? EtStrings.today
                      : diff > 0
                          ? 'in $diff d'
                          : '${-diff} d ago',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: diff == 0 ? EtColors.red : EtColors.locked,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  int _daysBetween(EthiopianDate a, EthiopianDate b) {
    return EthiopianCalendar.toGregorian(b)
        .difference(EthiopianCalendar.toGregorian(a))
        .inDays;
  }
}
