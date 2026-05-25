import 'package:intl/intl.dart';

class DateFormatter {
  /// Formats a date into a relative time string (e.g., "Just now", "5m", "2h", "Yesterday", or "May 20")
  /// This is optimized for chat list snippets.
  static String formatRelativeTime(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24 && now.day == date.day) {
      return DateFormat('h:mm a').format(date); // e.g. 2:30 PM if it's the same day
    } else if (difference.inDays == 1 || (difference.inHours < 48 && now.day != date.day)) {
      return 'Yesterday';
    } else if (now.year == date.year) {
      return DateFormat('MMM d').format(date); // e.g. May 20
    } else {
      return DateFormat('MMM d, yyyy').format(date); // e.g. May 20, 2025
    }
  }

  /// Formats a date into a sticky header for chat details (e.g. "Today", "Yesterday", "May 20, 2026")
  static String formatChatHeaderDate(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    
    if (now.year == date.year && now.month == date.month && now.day == date.day) {
      return 'Today';
    }
    
    final yesterday = now.subtract(const Duration(days: 1));
    if (yesterday.year == date.year && yesterday.month == date.month && yesterday.day == date.day) {
      return 'Yesterday';
    }

    if (now.year == date.year) {
      return DateFormat('MMMM d').format(date); // e.g. May 20
    }

    return DateFormat('MMMM d, yyyy').format(date);
  }

  /// Check if two dates fall on the exact same day (to group messages)
  static bool isSameDay(DateTime? date1, DateTime? date2) {
    if (date1 == null || date2 == null) return false;
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}
