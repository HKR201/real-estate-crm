import 'package:flutter/material.dart';
import 'dart:convert';
import '../db/database_helper.dart';

class PropertyMiniCard extends StatelessWidget {
  final Map<String, dynamic> property; 
  final bool isSynced;
  final VoidCallback onDelete;

  const PropertyMiniCard({
    super.key,
    required this.property,
    this.isSynced = false,
    required this.onDelete,
  });

  // ပိုင်ရှင် အချက်အလက်ကို Database မှ ဆွဲထုတ်၍ ပြသမည်
  void _showOwnerDetails(BuildContext context) async {
    final ownerId = property['owner_id'];
    
    // ပိုင်ရှင် ချိတ်ဆက်ထားခြင်း မရှိလျှင်
    if (ownerId == null || ownerId.toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ဤအိမ်ခြံမြေအတွက် ပိုင်ရှင် ချိတ်ဆက်ထားခြင်း မရှိပါ')));
      return;
    }

    final db = await DatabaseHelper.instance.database;
    final result = await db.query('crm_owners', where: 'id = ?', whereArgs: [ownerId]);

    if (!context.mounted) return;

    if (result.isNotEmpty) {
      final owner = result.first;
      List<dynamic> phones = [];
      try { phones = jsonDecode(owner['phones'] as String); } catch (_) {}

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text('ပိုင်ရှင် အချက်အလက်', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('အမည်: ${owner['name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              const Text('ဖုန်းနံပါတ်များ:', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 4),
              Text(phones.isEmpty ? 'မရှိပါ' : phones.join(', '), style: const TextStyle(fontSize: 15)),
              
              if ((owner['remark'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('မှတ်ချက်:', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                Text(owner['remark'].toString(), style: const TextStyle(fontSize: 14)),
              ]
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ပိတ်မည်'),
            )
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ပိုင်ရှင် အချက်အလက် ရှာမတွေ့ပါ')));
    }
  }

  void _showExpandedCard(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        final formattedPrice = (property['asking_price_lakhs'] ?? 0)
            .toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
        
        // အိမ်အမျိုးအစား ရှိမရှိ စစ်ဆေးမည်
        final houseType = property['house_type'];
        final hasHouse = houseType != null && houseType.toString().isNotEmpty;

        return Padding(
          padding: const EdgeInsets.only(bottom: 24, top: 12, left: 16, right: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Container(
                height: 180, width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                child: const Center(child: Icon(Icons.photo_library, size: 40, color: Colors.grey)),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(property['title'] ?? 'အမည်မသိ', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                  IconButton(icon: const Icon(Icons.map, color: Colors.blue), onPressed: () {})
                ],
              ),
              // အိမ်အမျိုးအစားပါလျှင် ထည့်ပြမည်
              Text(hasHouse 
                  ? '${property['land_type'] ?? '-'} • ${property['road_type'] ?? '-'} • $houseType'
                  : '${property['land_type'] ?? '-'} • ${property['road_type'] ?? '-'}', 
                  style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 16),
              Text('$formattedPrice သိန်း', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
              const SizedBox(height: 8),
              Text('${property['east_ft'] ?? 0} | ${property['west_ft'] ?? 0} | ${property['south_ft'] ?? 0} | ${property['north_ft'] ?? 0}', style: const TextStyle(fontSize: 16, letterSpacing: 2.0)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white),
                      onPressed: () => _showOwnerDetails(context), // OWNER ကို နှိပ်လျှင် အပေါ်က Function ကို ခေါ်မည်
                      child: const Text('OWNER', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(side: BorderSide(color: Theme.of(context).colorScheme.primary)),
                      onPressed: () {}, 
                      child: Text('Edit', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      Navigator.pop(context); 
                      onDelete(); 
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
    final title = property['title'] ?? 'အမည်မသိ';
    final askingPriceLakhs = property['asking_price_lakhs'] ?? 0;
    final location = property['location_id'] ?? 'မသိရ';
    final status = property['status'] ?? 'Available';
    final east = property['east_ft'] ?? 0;
    final west = property['west_ft'] ?? 0;
    final south = property['south_ft'] ?? 0;
    final north = property['north_ft'] ?? 0;

    final bool isAvailable = status.toLowerCase() == 'available';
    // Status အရောင်များကို သတ်မှတ်ခြင်း
    final Color statusBgColor = status.toLowerCase() == 'sold out' ? Colors.red.shade50 : isAvailable ? const Color(0xFFE6F4EA) : Colors.orange.shade50;
    final Color statusTextColor = status.toLowerCase() == 'sold out' ? Colors.red : isAvailable ? const Color(0xFF137333) : Colors.orange.shade800;
    final String formattedPrice = askingPriceLakhs.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');

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
                  Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(4)),
                    child: Text(status, style: TextStyle(color: statusTextColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('$formattedPrice သိန်း • $location', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$east | $west | $south | $north', style: const TextStyle(fontSize: 13, color: Colors.grey, letterSpacing: 1.2)),
                  Icon(isSynced ? Icons.cloud_done : Icons.cloud_upload, size: 16, color: isSynced ? Colors.grey.shade400 : Theme.of(context).colorScheme.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
