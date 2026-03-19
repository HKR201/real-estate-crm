class TimeHelper {
  static String getRelativeTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      // Database မှလာသော အချိန်ကို Local Time သို့ ပြောင်းပြီး ယခုအချိန်နှင့် နှိုင်းယှဉ်မည်
      DateTime date = DateTime.parse(dateString).toLocal();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.isNegative) return 'Just now';
      if (difference.inSeconds < 60) return 'Just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes} mins ago';
      if (difference.inHours < 24) return '${difference.inHours} hrs ago';
      if (difference.inDays < 7) return '${difference.inDays} days ago';
      if (difference.inDays < 30) return '${(difference.inDays / 7).floor()} weeks ago';
      if (difference.inDays < 365) return '${(difference.inDays / 30).floor()} months ago';
      return '${(difference.inDays / 365).floor()} years ago';
    } catch (e) {
      return '';
    }
  }
}
