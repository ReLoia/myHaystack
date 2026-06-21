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
}
