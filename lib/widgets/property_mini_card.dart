import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import '../utils/time_helper.dart';
import '../screens/property_form_screen.dart';

class PropertyMiniCard extends StatefulWidget {
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
  State<PropertyMiniCard> createState() => _PropertyMiniCardState();
}

class _PropertyMiniCardState extends State<PropertyMiniCard> {
  // ⚠️ Beta 1 Logic: Card ကို နှိပ်လျှင် Expand ဖြစ်မည့် State
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    List<String> photos = [];
    String? propertyType = 'အိမ်အပါ';

    if (widget.property['extra_data'] != null) {
      try {
        final extra = jsonDecode(widget.property['extra_data']);
        if (extra['photos'] != null) photos = List<String>.from(extra['photos']);
        if (extra['property_type'] != null) propertyType = extra['property_type'];
      } catch (e) {
        debugPrint(e.toString());
      }
    }

    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: _isExpanded ? 4 : 2, // Expand ဖြစ်လျှင် အရိပ်ပိုထွက်မည်
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // ⚠️ Beta 1 Flow: နှိပ်လိုက်လျှင် Expand အဖွင့်/အပိတ် လုပ်မည်
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- (၁) အပေါ်ပိုင်း (အမြဲပေါ်နေမည့် အပိုင်း) ---
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ဓာတ်ပုံ (Image Caching စနစ်)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: photos.isNotEmpty
                            ? _buildImage(photos.first)
                            : Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported, color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // ခေါင်းစဉ် နှင့် အခြေခံအချက်အလက်
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.property['title'] ?? 'ခေါင်းစဉ်မရှိ',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                _isExpanded ? Icons.expand_less : Icons.expand_more,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.property['asking_price_lakhs']} သိန်း',
                            style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.property['location_id'] ?? 'နေရာမသိရ',
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
                              Text(TimeHelper.getRelativeTime(widget.property['updated_at']), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              Icon(widget.isSynced ? Icons.cloud_done : Icons.cloud_off, size: 14, color: widget.isSynced ? Colors.green : Colors.orange),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // --- (၂) အောက်ပိုင်း (Expand ဖြစ်မှသာ ပေါ်မည့် အသေးစိတ် အပိုင်း) ---
              if (_isExpanded) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // အကျယ်အဝန်း နှင့် အမျိုးအစားများ
                      _buildDetailRow(Icons.aspect_ratio, 'အကျယ်', '${widget.property['east_ft'] ?? '-'} x ${widget.property['west_ft'] ?? '-'} x ${widget.property['south_ft'] ?? '-'} x ${widget.property['north_ft'] ?? '-'} ပေ'),
                      _buildDetailRow(Icons.category, 'အမျိုးအစား', propertyType ?? '-'),
                      _buildDetailRow(Icons.signpost, 'လမ်း/မြေ', '${widget.property['road_type'] ?? '-'} / ${widget.property['land_type'] ?? '-'}'),
                      if (propertyType != 'ခြံသီးသန့်') _buildDetailRow(Icons.house, 'အိမ်အမျိုးအစား', widget.property['house_type'] ?? '-'),
                      _buildDetailRow(Icons.info_outline, 'Status', widget.property['status'] ?? '-'),
                      
                      const SizedBox(height: 8),
                      // မှတ်ချက်
                      if (widget.property['remark'] != null && widget.property['remark'].toString().isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                          child: Text(widget.property['remark'], style: const TextStyle(fontSize: 13)),
                        ),
                      
                      const SizedBox(height: 16),
                      // Action ခလုတ်များ (Map, Edit, Delete)
                      Row(
                        children: [
                          if (widget.property['map_link'] != null && widget.property['map_link'].toString().isNotEmpty)
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.map, size: 16),
                                label: const Text('မြေပုံ'),
                                onPressed: () async {
                                  try {
                                    await launchUrl(Uri.parse(widget.property['map_link']), mode: LaunchMode.externalApplication);
                                  } catch (_) {}
                                },
                              ),
                            )
                          else
                            const Spacer(),
                          
                          const SizedBox(width: 8),
                          // ပြင်မည်
                          TextButton.icon(
                            icon: const Icon(Icons.edit, color: Colors.blue, size: 16),
                            label: const Text('ပြင်မည်', style: TextStyle(color: Colors.blue)),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => PropertyFormScreen(editData: widget.property)),
                              );
                              if (result == true) widget.onEditCompleted();
                            },
                          ),
                          // ဖျက်မည်
                          TextButton.icon(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                            label: const Text('ဖျက်မည်', style: TextStyle(color: Colors.red)),
                            onPressed: widget.onDelete,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ⚠️ Local Path နှင့် Cloud URL (Supabase) နှစ်မျိုးလုံးကို လက်ခံနိုင်သော Caching Function
  Widget _buildImage(String imagePath) {
    if (imagePath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: Colors.grey.shade100, child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))),
        errorWidget: (context, url, error) => Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image, color: Colors.grey)),
      );
    } else {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        cacheWidth: 300, 
        errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image, color: Colors.grey)),
      );
    }
  }

  // အသေးစိတ်အချက်အလက်များကို Minimalist ပုံစံဖြင့် ပြသရန်
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          SizedBox(width: 90, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }
}
