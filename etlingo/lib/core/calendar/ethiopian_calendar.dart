/// Ethiopian (Ge'ez) calendar conversion + holiday labels for the Culture Path.
class EthiopianDate {
  final int year;
  final int month; // 1–13 (13 = Pagumen)
  final int day;
  const EthiopianDate(this.year, this.month, this.day);

  static const monthsAm = [
    'መስከረም', 'ጥቅምት', 'ኅዳር', 'ታኅሣሥ', 'ጥር', 'የካቲት',
    'መጋቢት', 'ሚያዝያ', 'ግንቦት', 'ሰኔ', 'ሐምሌ', 'ነሐሴ', 'ጳጉሜ',
  ];
  static const monthsEn = [
    'Meskerem', 'Tikimt', 'Hidar', 'Tahsas', 'Tir', 'Yekatit',
    'Megabit', 'Miyazya', 'Ginbot', 'Sene', 'Hamle', 'Nehase', 'Pagumen',
  ];

  String label({bool amharic = true}) {
    final names = amharic ? monthsAm : monthsEn;
    return '${names[(month - 1).clamp(0, 12)]} $day, $year';
  }

  String monthName({bool amharic = true}) {
    final names = amharic ? monthsAm : monthsEn;
    return names[(month - 1).clamp(0, 12)];
  }

  @override
  String toString() => label();
}

class EthiopianCalendar {
  /// Weekday names starting Sunday.
  static const weekdaysAm = [
    'እሁድ', 'ሰኞ', 'ማክሰኞ', 'ረቡዕ', 'ሐሙስ', 'ዓርብ', 'ቅዳሜ',
  ];
  static const weekdaysEn = [
    'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat',
  ];

  /// Major holidays on the Ethiopian calendar (month 1–13, day 1–30).
  static const ethiopicHolidays = <EthHoliday>[
    EthHoliday(1, 1, 'Enkutatash', 'እንቁጣጣሽ', 3),
    EthHoliday(1, 17, 'Meskel', 'መስቀል', 3),
    EthHoliday(4, 29, 'Genna (Christmas)', 'ገና', 2),
    EthHoliday(5, 11, 'Timkat', 'ጥምቀት', 3),
    EthHoliday(6, 23, 'Adwa Victory', 'አድዋ ድል', 2),
    EthHoliday(2, 24, 'Irreecha', 'ኢሬቻ', 2),
    EthHoliday(11, 27, 'Filseta (Dormition)', 'ፍልሰታ', 1),
    EthHoliday(12, 11, 'Aster (St. Mary)', 'አስቴር', 1),
  ];

  /// Julian Day Number for a Gregorian date at noon.
  static int _jdn(DateTime g) {
    final y = g.year;
    final m = g.month;
    final d = g.day;
    final a = (14 - m) ~/ 12;
    final y2 = y + 4800 - a;
    final m2 = m + 12 * a - 3;
    return d +
        ((153 * m2 + 2) ~/ 5) +
        365 * y2 +
        y2 ~/ 4 -
        y2 ~/ 100 +
        y2 ~/ 400 -
        32045;
  }

  static DateTime _fromJdn(int jdn) {
    var a = jdn + 32044;
    var b = (4 * a + 3) ~/ 146097;
    var c = a - (146097 * b) ~/ 4;
    var d = (4 * c + 3) ~/ 1461;
    var e = c - (1461 * d) ~/ 4;
    var m = (5 * e + 2) ~/ 153;
    final day = e - ((153 * m + 2) ~/ 5) + 1;
    final month = m + 3 - 12 * (m ~/ 10);
    final year = 100 * b + d - 4800 + m ~/ 10;
    return DateTime.utc(year, month, day);
  }

  /// Ethiopian epoch (Meskerem 1, year 1 EC) in JDN.
  static const _ethEpoch = 1723856;

  /// Leap year when year % 4 == 3 (6th epagomenal day in Pagumen).
  static bool isLeapYear(int ethYear) => (ethYear % 4) == 3;

  static int daysInMonth(int ethYear, int ethMonth) {
    if (ethMonth < 13) return 30;
    return isLeapYear(ethYear) ? 6 : 5;
  }

  /// Convert Gregorian → Ethiopian (JDN-based, accurate).
  static EthiopianDate fromGregorian(DateTime g) {
    final jdn = _jdn(DateTime.utc(g.year, g.month, g.day));
    return fromJdn(jdn);
  }

  static EthiopianDate fromJdn(int jdn) {
    final days = jdn - _ethEpoch;
    final year = ((4 * days + 1463) ~/ 1461);
    final yearStart = _ethEpoch + 365 * (year - 1) + ((year - 1) ~/ 4);
    final offset = jdn - yearStart;
    final month = offset ~/ 30 + 1;
    final day = offset % 30 + 1;
    if (month < 1 || month > 13) {
      return _approx(DateTime.utc(2000, 1, 1));
    }
    return EthiopianDate(year, month, day);
  }

  /// Ethiopian → Gregorian.
  static DateTime toGregorian(EthiopianDate e) {
    final jdn = _ethEpoch +
        365 * (e.year - 1) +
        ((e.year - 1) ~/ 4) +
        30 * (e.month - 1) +
        e.day -
        1;
    return _fromJdn(jdn);
  }

  /// 0=Sunday … 6=Saturday for an Ethiopian date.
  static int weekdayIndex(EthiopianDate e) {
    final jdn = _jdn(toGregorian(e));
    // JDN 0 was a Monday → (jdn + 1) % 7 == 0 on Sunday
    return (jdn + 1) % 7;
  }

  /// Holidays on this Ethiopian day (spans `days` from start).
  static List<EthHoliday> holidaysOn(EthiopianDate e) {
    final out = <EthHoliday>[];
    for (final h in ethiopicHolidays) {
      final span = h.days;
      for (var i = 0; i < span; i++) {
        final startDay = h.day;
        final d = startDay + i;
        if (h.month == e.month && d == e.day) {
          out.add(h);
        }
      }
    }
    return out;
  }

  static EthHoliday? holidayStarting(EthiopianDate e) {
    for (final h in ethiopicHolidays) {
      if (h.month == e.month && h.day == e.day) return h;
    }
    return null;
  }

  static EthiopianDate _approx(DateTime g) {
    var ethYear = g.year - 8;
    if (g.month < 9 || (g.month == 9 && g.day < 11)) ethYear = g.year - 7;
    var ethMonth = g.month >= 9 ? g.month - 8 : g.month + 4;
    if (ethMonth > 13) ethMonth = 13;
    return EthiopianDate(ethYear, ethMonth, g.day.clamp(1, 30));
  }

  /// Human holiday label for this Gregorian day (or nearby).
  static String? holidayLabel(DateTime g, {bool amharic = true}) {
    final h = _matchHoliday(g);
    if (h == null) return null;
    return amharic ? '${h.nameAm} · ${h.name}' : h.name;
  }

  static ({String key, String name, String nameAm, int days})? _matchHoliday(
    DateTime g,
  ) {
    final fixed = [
      (key: 'genna', name: 'Genna (Christmas)', nameAm: 'ገና', m: 1, d: 7, days: 2),
      (key: 'timkat', name: 'Timkat', nameAm: 'ጥምቀት', m: 1, d: 19, days: 3),
      (key: 'adwa', name: 'Adwa Victory', nameAm: 'አድዋ ድል', m: 3, d: 2, days: 2),
      (key: 'meskel', name: 'Meskel', nameAm: 'መስቀል', m: 9, d: 27, days: 3),
      (key: 'enkutatash', name: 'Enkutatash', nameAm: 'እንቁጣጣሽ', m: 9, d: 11, days: 3),
      (key: 'irreecha', name: 'Irreecha', nameAm: 'ኢሬቻ', m: 10, d: 5, days: 2),
    ];
    for (final h in fixed) {
      final start = DateTime(g.year, h.m, h.d);
      for (final s in [
        start,
        DateTime(g.year - 1, h.m, h.d),
      ]) {
        final diff = DateTime(g.year, g.month, g.day)
            .difference(DateTime(s.year, s.month, s.day))
            .inDays;
        if (diff >= 0 && diff < h.days) {
          return (key: h.key, name: h.name, nameAm: h.nameAm, days: h.days);
        }
      }
    }
    // Movable (approx Gregorian anchors)
    final movable = <String, ({String key, String name, String nameAm, int days})>{
      '2025-04-18': (key: 'siklet', name: 'Siklet', nameAm: 'ስቅለት', days: 1),
      '2025-04-20': (key: 'fasika', name: 'Fasika', nameAm: 'ፋሲካ', days: 3),
      '2026-04-10': (key: 'siklet', name: 'Siklet', nameAm: 'ስቅለት', days: 1),
      '2026-04-12': (key: 'fasika', name: 'Fasika', nameAm: 'ፋሲካ', days: 3),
      '2027-05-02': (key: 'fasika', name: 'Fasika', nameAm: 'ፋሲካ', days: 3),
    };
    for (final entry in movable.entries) {
      final parts = entry.key.split('-').map(int.parse).toList();
      final start = DateTime(parts[0], parts[1], parts[2]);
      final diff = DateTime(g.year, g.month, g.day)
          .difference(DateTime(start.year, start.month, start.day))
          .inDays;
      if (diff >= 0 && diff < entry.value.days) return entry.value;
    }
    return null;
  }

  /// True when a holiday XP event is live (2× culture XP).
  static bool get holidayXpActive => _matchHoliday(DateTime.now()) != null;
}

class EthHoliday {
  final int month;
  final int day;
  final String name;
  final String nameAm;
  final int days;
  const EthHoliday(this.month, this.day, this.name, this.nameAm, this.days);
}
