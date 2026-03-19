class TimeHelper {
  static String getRelativeTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      // Database မှလာသော အချိန်ကို Local Time သို့ သေချာပြောင်းလဲခြင်း
      DateTime date = DateTime.parse(dateString).toLocal();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inSeconds < 60) return 'ယခုလေးတင်';
      if (difference.inMinutes < 60) return '${difference.inMinutes} မိနစ်အကြာ';
      if (difference.inHours < 24) return '${difference.inHours} နာရီအကြာ';
      if (difference.inDays < 7) return '${difference.inDays} ရက်အကြာ';
      if (difference.inDays < 30) return '${(difference.inDays / 7).floor()} ပတ်အကြာ';
      if (difference.inDays < 365) return '${(difference.inDays / 30).floor()} လအကြာ';
      return '${(difference.inDays / 365).floor()} နှစ်အကြာ';
    } catch (e) {
      return '';
    }
  }
}
