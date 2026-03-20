import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'dart:io';
import '../utils/time_helper.dart';
import '../screens/property_form_screen.dart';

class PropertyMiniCard extends StatelessWidget {
  final Map<String, dynamic> property;
  final bool isSynced;
  final VoidCallback onDelete;
  final VoidCallback onEditCompleted;

  const PropertyMiniCard({
    super.key,
    required this.property,
    required this.isSynced,
    required this.onDelete,
    required this.onEditCompleted,
  });

  @override
  Widget build(BuildContext context) {
    List<String> photos = [];
    if (property['extra_data'] != null) {
      try {
        final extra = jsonDecode(property['extra_data']);
        if (extra['photos'] != null) {
          photos = List<String>.from(extra['photos']);
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          // Edit ဖောင်သို့ သွားမည်
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PropertyFormScreen(editData: property)),
          );
          if (result == true) onEditCompleted();
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ⚠️ ဓာတ်ပုံပြသသည့် အပိုင်း (Image Caching စနစ် အသုံးပြုထားသည်)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: photos.isNotEmpty
                      ? _buildImage(photos.first)
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported, color: Colors.grey),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              
              // အချက်အလက်ပြသသည့် အပိုင်း
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property['title'] ?? 'ခေါင်းစဉ်မရှိ',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${property['asking_price_lakhs']} သိန်း',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            property['location_id'] ?? 'နေရာမသိရ',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          TimeHelper.getRelativeTime(property['updated_at']),
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        Row(
                          children: [
                            Icon(
                              isSynced ? Icons.cloud_done : Icons.cloud_off,
                              size: 14,
                              color: isSynced ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: onDelete,
                              child: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ⚠️ Local Path နှင့် Cloud URL (Supabase) နှစ်မျိုးလုံးကို လက်ခံနိုင်သော Function
  Widget _buildImage(String imagePath) {
    if (imagePath.startsWith('http')) {
      // Cloud ပုံဖြစ်ပါက CachedNetworkImage ဖြင့် ဆွဲတင်မည်
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey.shade100,
          child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    } else {
      // ဖုန်းထဲမှ Local ပုံဖြစ်ပါက Memory သက်သာအောင် cacheWidth ဖြင့် ပြမည်
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        cacheWidth: 200, // Memory မပြည့်စေရန်
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }
  }
}
