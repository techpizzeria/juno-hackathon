import 'package:intl/intl.dart';

/// Calendar-day helpers.
///
/// Log entries key on local calendar days stored as `yyyy-MM-dd` strings;
/// comparing those strings sidesteps timezone and midnight-boundary bugs
/// that comparing full [DateTime]s invites.
final DateFormat _ymdFormat = DateFormat('yyyy-MM-dd');

/// Formats [date] as a local `yyyy-MM-dd` string.
String ymd(DateTime date) => _ymdFormat.format(date);

/// Today's local calendar day as `yyyy-MM-dd`.
String todayYmd() => ymd(DateTime.now());

/// Parses a `yyyy-MM-dd` string back into a (local, midnight) [DateTime].
DateTime parseYmd(String value) => _ymdFormat.parse(value);

/// Whether two dates fall on the same local calendar day.
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Short label for a 1=Monday..7=Sunday weekday index.
String weekdayShortLabel(int weekday) =>
    const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday - 1];
