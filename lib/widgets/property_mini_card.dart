import 'package:flutter/material.dart';

class PropertyMiniCard extends StatelessWidget {
  final String title;
  final int askingPriceLakhs;
  final String location;
  final String status;
  final int east, west, south, north;
  final bool isSynced;

  const PropertyMiniCard({
    super.key,
    required this.title,
    required this.askingPriceLakhs,
    required this.location,
    required this.status,
    required this.east,
    required this.west,
    required this.south,
    required this.north,
    this.isSynced = true, // ပုံမှန်အားဖြင့် Cloud ပေါ်ရောက်ပြီးသားဟု သတ်မှတ်ထားမည်
  });

  @override
  Widget build(BuildContext context) {
    // Status အရောင် သတ်မှတ်ခြင်း (Available ဆိုလျှင် အစိမ်း၊ ကျန်တာဆိုလျှင် မီးခိုး)
    final bool isAvailable = status.toLowerCase() == 'available';
    final Color statusBgColor = isAvailable ? const Color(0xFFE6F4EA) : Colors.grey.shade200;
    final Color statusTextColor = isAvailable ? const Color(0xFF137333) : Colors.grey.shade700;

    // သိန်းဂဏန်းကို ကော်မာ (,) ဖြင့်လှပစွာပြရန် (ဥပမာ - 1500 -> 1,500)
    final String formattedPrice = askingPriceLakhs.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      // Blueprint အရ 8px Rounded Corners
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 1, // Ultra-compact ဖြစ်စေရန် အရိပ်အနည်းငယ်သာ သုံးထားပါသည်
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // အပေါ်ဆုံးတန်း - Title နှင့် Status Badge (Micro)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis, // စာရှည်လျှင် အစက်လေးများဖြင့်ဖြတ်ပြရန်
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusTextColor,
                      fontSize: 10, // Micro Status badge
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // အလယ်တန်း - ဈေးနှုန်း (သိန်း) နှင့် နေရာ
            Text(
              '$formattedPrice သိန်း • $location',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.primary, // Teal အရောင်သုံးထားသည်
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            // အောက်ဆုံးတန်း - အကျယ်အဝန်း (E | W | S | N) နှင့် Sync Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$east | $west | $south | $north',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
                // Cloud Sync Icon
                Icon(
                  isSynced ? Icons.cloud_done : Icons.cloud_upload,
                  size: 16,
                  color: isSynced ? Colors.grey.shade400 : Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
