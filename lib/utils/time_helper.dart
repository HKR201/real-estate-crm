class TimeHelper {
  static String getRelativeTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    final date = DateTime.tryParse(isoString);
    if (date == null) return '';
    
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min${diff.inMinutes > 1 ? 's' : ''} ago';
    if (diff.inHours < 24) return '${diff.inHours} hr${diff.inHours > 1 ? 's' : ''} ago';
    if (diff.inDays < 30) return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    }
    final years = (diff.inDays / 365).floor();
    return '$years year${years > 1 ? 's' : ''} ago';
  }
}
