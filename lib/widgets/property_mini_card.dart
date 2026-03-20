import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import '../utils/time_helper.dart';
import '../screens/property_form_screen.dart';
import '../screens/owner_form_screen.dart';
import '../db/database_helper.dart';

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

  Color _getStatusColor(String? status) {
    if (status == 'Available') return Colors.green;
    if (status == 'Pending') return Colors.orange;
    if (status == 'Sold Out') return Colors.red;
    return Colors.grey;
  }

  void _showPropertyDetails(BuildContext context, List<String> photos) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).padding.bottom),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Drag Handle
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  
                  // ⚠️ Image Section (PageView ဖြင့် ပုံများစွာကို ပွတ်ဆွဲကြည့်နိုင်သည်)
                  if (photos.isNotEmpty)
                    SizedBox(
                      height: 220,
                      child: PageView.builder(
                        itemCount: photos.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              // ⚠️ ပုံကိုနှိပ်လျှင် Full Screen ချဲ့ကြည့်နိုင်မည်
                              Navigator.push(
                                context, 
                                MaterialPageRoute(builder: (_) => FullScreenImageViewer(imagePath: photos[index]))
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _buildImage(photos[index]),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      width: double.infinity, height: 220,
                      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                    ),
                  
                  // ပုံအများကြီးပါလျှင် အစက်လေးများ ပြရန်
                  if (photos.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Center(
                        child: Text('${photos.length} ပုံ ပါဝင်သည် (ဘေးသို့ဆွဲကြည့်ပါ)', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Title & Map Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          property['title'] ?? 'Test',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (property['map_link'] != null && property['map_link'].toString().isNotEmpty)
                        IconButton(
                          onPressed: () async {
                            try {
                              await launchUrl(Uri.parse(property['map_link']), mode: LaunchMode.externalApplication);
                            } catch (_) {}
                          },
                          icon: const Icon(Icons.map, color: Colors.blue),
                        ),
                    ],
                  ),
                  
                  // Time
                  Text(
                    TimeHelper.getRelativeTime(property['updated_at']),
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  
                  // Location details
                  Text(
                    '${property['location_id'] ?? 'Unknown'} • ${property['road_type'] ?? '-'}',
                    style: const TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  
                  // Price
                  Text(
                    '${property['asking_price_lakhs']} သိန်း',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 8),
                  
                  // Dimensions
                  Text(
                    '${property['east_ft'] ?? 0} | ${property['west_ft'] ?? 0} | ${property['south_ft'] ?? 0} | ${property['north_ft'] ?? 0}',
                    style: const TextStyle(fontSize: 16, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 24),
                  
                  // Action Buttons (Beta 1 Design)
                  Row(
                    children: [
                      // OWNER Button
                      Expanded(
                        flex: 3,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E6561),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () async {
                            if (property['owner_id'] != null) {
                              final ownerData = await DatabaseHelper.instance.getAllOwners();
                              final owner = ownerData.firstWhere((o) => o['id'] == property['owner_id'], orElse: () => {});
                              if (owner.isNotEmpty && ctx.mounted) {
                                Navigator.pop(ctx);
                                Navigator.push(context, MaterialPageRoute(builder: (_) => OwnerFormScreen(editData: owner)));
                              }
                            }
                          },
                          child: const Text('OWNER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.0)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Edit Button
                      Expanded(
                        flex: 3,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2E6561),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFF2E6561), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyFormScreen(editData: property)));
                            if (result == true) onEditCompleted();
                          },
                          child: const Text('Edit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // Delete Button
                      IconButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          onDelete();
                        },
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ⚠️ Image Error ရှင်းလင်းထားသော Function
  Widget _buildImage(String imagePath) {
    if (imagePath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: Colors.grey.shade100, child: const Center(child: CircularProgressIndicator())),
        errorWidget: (context, url, error) => Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image, color: Colors.grey, size: 50)),
      );
    } else {
      final file = File(imagePath);
      // ပုံဖိုင် တကယ်မရှိပါက Error မတက်စေရန် စစ်ဆေးခြင်း
      if (!file.existsSync()) {
        return Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 50));
      }
      return Image.file(
        file,
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
        // ⚠️ ဤနေရာမှ cacheWidth ကို ဖြုတ်လိုက်ပါပြီ (အချို့ဖုန်းများတွင် ပုံပျောက်သွားတတ်သောကြောင့်ဖြစ်သည်)
        errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image, color: Colors.grey, size: 50)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> photos = [];
    if (property['extra_data'] != null) {
      try {
        final extra = jsonDecode(property['extra_data']);
        if (extra['photos'] != null) photos = List<String>.from(extra['photos']);
      } catch (e) {
        debugPrint(e.toString());
      }
    }

    final status = property['status'] ?? 'Available';
    final statusColor = _getStatusColor(status);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showPropertyDetails(context, photos),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      property['title'] ?? 'Test',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: TextStyle(fontSize: 15, fontFamily: theme.textTheme.bodyMedium?.fontFamily),
                  children: [
                    TextSpan(
                      text: '${property['asking_price_lakhs']} သိန်း',
                      style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: ' • ${property['location_id'] ?? 'Test'}',
                      style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${property['east_ft'] ?? 0} | ${property['west_ft'] ?? 0} | ${property['south_ft'] ?? 0} | ${property['north_ft'] ?? 0}',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  Row(
                    children: [
                      Text(TimeHelper.getRelativeTime(property['updated_at']), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: 4),
                      Icon(isSynced ? Icons.cloud_done : Icons.cloud_off, size: 14, color: isSynced ? Colors.green : Colors.orange),
                    ],
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

// ⚠️ ဓာတ်ပုံကို Full Screen ချဲ့ကြည့်ရန် Class အသစ် (Zoom ဆွဲကြည့်နိုင်သည်)
class FullScreenImageViewer extends StatelessWidget {
  final String imagePath;
  const FullScreenImageViewer({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0, // လေးဆ အထိ Zoom ဆွဲချဲ့ကြည့်နိုင်မည်
          child: imagePath.startsWith('http')
              ? CachedNetworkImage(imageUrl: imagePath, fit: BoxFit.contain)
              : Image.file(File(imagePath), fit: BoxFit.contain),
        ),
      ),
    );
  }
}
