import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/time_helper.dart';
import '../screens/property_form_screen.dart';
import '../screens/owner_list_screen.dart'; 
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

  void _shareProperty() {
    final title = property['title'] ?? 'ခေါင်းစဉ်မရှိ';
    final price = '${property['asking_price_lakhs'] ?? 0} သိန်း';
    final area = '${property['east_ft'] ?? 0} x ${property['west_ft'] ?? 0} x ${property['south_ft'] ?? 0} x ${property['north_ft'] ?? 0} ပေ';
    final location = property['location_id'] ?? '-';
    final road = property['road_type'] ?? '-';
    Share.share('$title\nဈေးနှုန်း - $price\nအကျယ်အဝန်း - $area\nနေရာ - $location\nလမ်းအမျိုးအစား - $road');
  }

  Widget _buildImage(String fileName) {
    if (fileName.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: fileName,
        width: double.infinity, height: 220, fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: Colors.grey.shade100, child: const Center(child: CircularProgressIndicator())),
        errorWidget: (context, url, error) => Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image, color: Colors.grey, size: 50)),
      );
    } else {
      return FutureBuilder<Directory>(
        future: getApplicationDocumentsDirectory(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Container(color: Colors.grey.shade100, child: const Center(child: CircularProgressIndicator()));
          final file = File('${snapshot.data!.path}/property_photos/$fileName');
          if (!file.existsSync()) return Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 50));
          return Image.file(
            file, width: double.infinity, height: 220, fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image, color: Colors.grey, size: 50)),
          );
        }
      );
    }
  }

  void _showPropertyDetails(BuildContext context, List<String> photos) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).padding.bottom),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                children: [
                  Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                  if (photos.isNotEmpty)
                    SizedBox(
                      height: 220,
                      child: PageView.builder(
                        itemCount: photos.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImageViewer(photos: photos, initialIndex: index))); },
                            child: ClipRRect(borderRadius: BorderRadius.circular(12), child: _buildImage(photos[index])),
                          );
                        },
                      ),
                    )
                  else
                    Container(width: double.infinity, height: 220, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey)),
                  
                  if (photos.length > 1) Padding(padding: const EdgeInsets.only(top: 8), child: Center(child: Text('${photos.length} ပုံ ပါဝင်သည် (ဘေးသို့ဆွဲကြည့်ပါ)', style: const TextStyle(fontSize: 12, color: Colors.grey)))),
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Expanded(child: Text(property['title'] ?? 'Test', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))), Row(mainAxisSize: MainAxisSize.min, children: [ IconButton(onPressed: _shareProperty, icon: const Icon(Icons.share, color: Colors.blue)), if (property['map_link'] != null && property['map_link'].toString().isNotEmpty) IconButton(onPressed: () async { try { await launchUrl(Uri.parse(property['map_link']), mode: LaunchMode.externalApplication); } catch (_) {} }, icon: const Icon(Icons.map, color: Colors.blue)) ]) ]),
                  Text(TimeHelper.getRelativeTime(property['updated_at']), style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text('${property['location_id'] ?? 'Unknown'} • ${property['road_type'] ?? '-'}', style: const TextStyle(color: Colors.grey, fontSize: 15)),
                  const SizedBox(height: 12),
                  Text('${property['asking_price_lakhs']} သိန်း', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                  const SizedBox(height: 8),
                  Text('${property['east_ft'] ?? 0} | ${property['west_ft'] ?? 0} | ${property['south_ft'] ?? 0} | ${property['north_ft'] ?? 0}', style: const TextStyle(fontSize: 16, letterSpacing: 1.5)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(flex: 3, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E6561), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), onPressed: () { Navigator.pop(ctx); if (property['owner_id'] != null) { Navigator.push(context, MaterialPageRoute(builder: (_) => OwnerListScreen(highlightOwnerId: property['owner_id']))); } else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ပိုင်ရှင် သတ်မှတ်ထားခြင်း မရှိပါ'))); } }, child: const Text('OWNER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.0)))),
                      const SizedBox(width: 12),
                      Expanded(flex: 3, child: OutlinedButton(style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF2E6561), padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: Color(0xFF2E6561), width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), onPressed: () async { Navigator.pop(ctx); final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyFormScreen(editData: property))); if (result == true) onEditCompleted(); }, child: const Text('Edit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))),
                      const SizedBox(width: 8),
                      IconButton(onPressed: () { Navigator.pop(ctx); onDelete(); }, icon: const Icon(Icons.delete_outline, color: Colors.red)),
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

  @override
  Widget build(BuildContext context) {
    List<String> photos = [];
    if (property['extra_data'] != null) {
      try {
        final extra = jsonDecode(property['extra_data']);
        if (extra['photos'] != null) photos = List<String>.from(extra['photos']);
      } catch (e) { debugPrint(e.toString()); }
    }
    final status = property['status'] ?? 'Available';
    final statusColor = _getStatusColor(status);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showPropertyDetails(context, photos),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Expanded(child: Text(property['title'] ?? 'Test', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis)), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold))) ]),
              const SizedBox(height: 8),
              RichText(maxLines: 1, overflow: TextOverflow.ellipsis, text: TextSpan(style: TextStyle(fontSize: 15, fontFamily: theme.textTheme.bodyMedium?.fontFamily), children: [ TextSpan(text: '${property['asking_price_lakhs']} သိန်း', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)), TextSpan(text: ' • ${property['location_id'] ?? 'Test'}', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)) ])),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Text('${property['east_ft'] ?? 0} | ${property['west_ft'] ?? 0} | ${property['south_ft'] ?? 0} | ${property['north_ft'] ?? 0}', style: const TextStyle(color: Colors.grey, fontSize: 14)), Row(children: [ Text(TimeHelper.getRelativeTime(property['updated_at']), style: const TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(width: 4), Icon(isSynced ? Icons.cloud_done : Icons.cloud_off, size: 14, color: isSynced ? Colors.green : Colors.orange) ]) ]),
            ],
          ),
        ),
      ),
    );
  }
}

class FullScreenImageViewer extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;
  const FullScreenImageViewer({super.key, required this.photos, required this.initialIndex});

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() { _pageController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white), title: Text('${_currentIndex + 1} / ${widget.photos.length}', style: const TextStyle(color: Colors.white, fontSize: 16)), centerTitle: true),
      body: FutureBuilder<Directory>(
        future: getApplicationDocumentsDirectory(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return PageView.builder(
            controller: _pageController, itemCount: widget.photos.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              final fileName = widget.photos[index];
              return Center(
                child: InteractiveViewer(
                  minScale: 0.5, maxScale: 4.0,
                  child: fileName.startsWith('http')
                      ? CachedNetworkImage(imageUrl: fileName, fit: BoxFit.contain, placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.white)), errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white, size: 50))
                      : Image.file(File('${snapshot.data!.path}/property_photos/$fileName'), fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.white, size: 50)),
                ),
              );
            },
          );
        }
      ),
    );
  }
}
