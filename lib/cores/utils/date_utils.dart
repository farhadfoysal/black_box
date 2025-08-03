import 'package:intl/intl.dart';

class AppDateUtils {
  static String formatDate(DateTime date, {String pattern = 'yyyy-MM-dd'}) {
    return DateFormat(pattern).format(date);
  }

  static DateTime parse(String dateString, {String pattern = 'yyyy-MM-dd'}) {
    return DateFormat(pattern).parse(dateString);
  }

  static String timeAgo(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inDays > 0) return "${difference.inDays} day(s) ago";
    if (difference.inHours > 0) return "${difference.inHours} hour(s) ago";
    if (difference.inMinutes > 0) return "${difference.inMinutes} min(s) ago";
    return "Just now";
  }
}
