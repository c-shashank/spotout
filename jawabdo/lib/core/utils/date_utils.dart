import 'package:intl/intl.dart';

class Jawab DoDateUtils {
  Jawab DoDateUtils._();

  static String fullDateTime(DateTime dt) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt.toLocal());
  }

  static String shortDate(DateTime dt) {
    return DateFormat('dd MMM yyyy').format(dt.toLocal());
  }

  static int daysBetween(DateTime from, DateTime to) {
    final f = DateTime(from.year, from.month, from.day);
    final t = DateTime(to.year, to.month, to.day);
    return t.difference(f).inDays;
  }

  static int daysAgo(DateTime dt) {
    return daysBetween(dt, DateTime.now());
  }

  static bool isOverdue(DateTime createdAt, {int targetDays = 7}) {
    return daysAgo(createdAt) > targetDays;
  }
}
