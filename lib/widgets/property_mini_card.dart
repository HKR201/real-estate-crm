import 'package:flutter/material.dart';

class PropertyMiniCard extends StatelessWidget {
  final Map<String, dynamic> property; // ဒေတာအုပ်စုတစ်ခုလုံးကို လက်ခံမည်
  final bool isSynced;

  const PropertyMiniCard({
    super.key,
    required this.property,
    this.isSynced = false,
  });

  // ကတ်ကို နှိပ်လိုက်လျှင် အောက်မှတက်လာမည့် Expanded Card (Bottom Sheet)
  void _showExpandedCard(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Half-screen ထက်ပိုတက်နိုင်ရန်
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final formattedPrice = (property['asking_price_lakhs'] ?? 0)
            .toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');

        return Padding(
          padding: const EdgeInsets.only(bottom: 24, top: 12, left: 16, right: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // အလယ်ဗဟိုက ဆွဲချလို့ရကြောင်း ပြသည့် မျဉ်းတိုလေး
              Center(
                child: Container(
                  width: 40, height: 4, 
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              
              // Photo Tray (ဓာတ်ပုံပြမည့်နေရာ - လောလောဆယ် Placeholder)
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                child: const Center(child: Icon(Icons.photo_library, size: 40, color: Colors.grey)),
              ),
              const SizedBox(height: 16),

              // Title နှင့် Map Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      property['title'] ?? 'အမည်မသိ',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.map, color: Colors.blue),
                    onPressed: () {
                      // နောက်ပိုင်းတွင် Google Maps သို့ သွားမည့် Code လာမည်
                    },
                  )
                ],
              ),
              
              // Values Only (Label မပါပါ) - ဥပမာ: ဂရန်မြေ • ကွန်ကရစ်လမ်း
              Text(
                '${property['land_type'] ?? '-'} • ${property['road_type'] ?? '-'}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // ခေါ်ဈေး (Bottom Price ကို လုံးဝ မပြပါ)
              Text(
                '$formattedPrice သိန်း',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 8),

              // အကျယ်အဝန်း
              Text(
                '${property['east_ft'] ?? 0} | ${property['west_ft'] ?? 0} | ${property['south_ft'] ?? 0} | ${property['north_ft'] ?? 0}',
                style: const TextStyle(fontSize: 16, letterSpacing: 2.0),
              ),
              const SizedBox(height: 24),

              // Actions Row (လုပ်ဆောင်ချက် ခလုတ် ၃ ခု)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary, 
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {}, // ပိုင်ရှင်စာမျက်နှာသို့ သွားမည်
                      child: const Text('OWNER', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Theme.of(context).colorScheme.primary),
                      ),
                      onPressed: () {}, // Edit Form သို့ သွားမည်
                      child: Text('Edit', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      // Soft Delete လုပ်မည့် Code လာမည်
                    },
                  )
                ],
              )
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    // UI ပေါ်တွင်ပြမည့် ဒေတာများကို Map ထဲမှ ပြန်ထုတ်ခြင်း
    final title = property['title'] ?? 'အမည်မသိ';
    final askingPriceLakhs = property['asking_price_lakhs'] ?? 0;
    final location = property['location_id'] ?? 'မသိရ';
    final status = property['status'] ?? 'Available';
    final east = property['east_ft'] ?? 0;
    final west = property['west_ft'] ?? 0;
    final south = property['south_ft'] ?? 0;
    final north = property['north_ft'] ?? 0;

    final bool isAvailable = status.toLowerCase() == 'available';
    final Color statusBgColor = isAvailable ? const Color(0xFFE6F4EA) : Colors.grey.shade200;
    final Color statusTextColor = isAvailable ? const Color(0xFF137333) : Colors.grey.shade700;
    final String formattedPrice = askingPriceLakhs.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');

    // InkWell ထည့်ထားသဖြင့် ကတ်ကို နှိပ်လိုက်လျှင် _showExpandedCard ပွင့်လာမည်
    return InkWell(
      onTap: () => _showExpandedCard(context),
      borderRadius: BorderRadius.circular(8),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      status,
                      style: TextStyle(color: statusTextColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$formattedPrice သိန်း • $location',
                style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$east | $west | $south | $north',
                    style: const TextStyle(fontSize: 13, color: Colors.grey, letterSpacing: 1.2),
                  ),
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
      ),
    );
  }
}
