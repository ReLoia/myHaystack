import 'package:intl/intl.dart';

extension DateTimeFormatting on DateTime {
  String timeAgo() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (!difference.isNegative && difference.inMinutes <= 30) {
      if (difference.inMinutes == 0) return 'Just now';
      if (difference.inMinutes == 1) return '1 minute ago';
      return '${difference.inMinutes} minutes ago';
    }

    return DateFormat('dd MMM HH:mm').format(this);
  }

  DateTime get dateOnly => DateTime(year, month, day);

  String get formatDateTitle {
    final today = DateTime.now().dateOnly;
    final target = dateOnly;

    if (target == today) return "Today";
    if (target == today.subtract(const Duration(days: 1))) return "Yesterday";

    return DateFormat('MMM d, yyyy').format(this);
  }
}
