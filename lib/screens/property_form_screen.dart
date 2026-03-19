import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:convert';
import '../db/database_helper.dart';
import '../widgets/dynamic_dropdown.dart';

class PropertyFormScreen extends StatefulWidget {
  final Map<String, dynamic>? editData;
  const PropertyFormScreen({super.key, this.editData});

  @override
  State<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends State<PropertyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _askingPriceController = TextEditingController();
  final TextEditingController _bottomPriceController = TextEditingController();
  final TextEditingController _eastController = TextEditingController();
  final TextEditingController _westController = TextEditingController();
  final TextEditingController _southController = TextEditingController();
  final TextEditingController _northController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _mapLinkController = TextEditingController();

  String? _status = 'Available';
  String? _location;
  String? _roadType;
  String? _houseType;
  String? _landType;
  String? _ownerId;

  List<String> _photoPaths = [];
  List<Map<String, dynamic>> _owners = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadOwners();
    if (widget.editData != null) {
      final d = widget.editData!;
      _titleController.text = d['title'] ?? '';
      _askingPriceController.text = (d['asking_price_lakhs'] ?? '').toString();
      _bottomPriceController.text = (d['bottom_price_lakhs'] ?? '').toString();
      _eastController.text = (d['east_ft'] ?? '').toString();
      _westController.text = (d['west_ft'] ?? '').toString();
      _southController.text = (d['south_ft'] ?? '').toString();
      _northController.text = (d['north_ft'] ?? '').toString();
      _remarkController.text = d['remark'] ?? '';
      _mapLinkController.text = d['map_link'] ?? '';
      _status = d['status'] ?? 'Available';
      _location = d['location_id'];
      _roadType = d['road_type'];
      _houseType = d['house_type'];
      _landType = d['land_type'];
      _ownerId = d['owner_id'];

      if (d['extra_data'] != null) {
        try {
          final extra = jsonDecode(d['extra_data']);
          if (extra['photos'] != null) {
            _photoPaths = List<String>.from(extra['photos']);
          }
        } catch (_) {}
      }
    }
  }

  Future<void> _loadOwners() async {
    final owners = await DatabaseHelper.instance.getAllOwners();
    setState(() {
      _owners = owners;
    });
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      final appDir = await getApplicationDocumentsDirectory();
      final photoDir = Directory('${appDir.path}/property_photos');
      if (!await photoDir.exists()) await photoDir.create(recursive: true);

      for (var file in pickedFiles) {
        final bytes = await file.readAsBytes();
        img.Image? image = img.decodeImage(bytes);
        if (image != null) {
          img.Image resized = img.copyResize(image, width: 800);
          final newFile = File('${photoDir.path}/${DateTime.now().millisecondsSinceEpoch}_${file.name}');
          await newFile.writeAsBytes(img.encodeJpg(resized, quality: 80));
          setState(() {
            _photoPaths.add(newFile.path);
          });
        }
      }
    }
  }

  // Google Maps ဖွင့်ရန် Function
  void _openGoogleMaps() async {
    String urlStr = _mapLinkController.text.trim();
    if (urlStr.isEmpty) {
      urlStr = 'https://maps.google.com'; // လင့်ခ်မရှိလျှင် မြေပုံအလွတ်ဖွင့်မည်
    }
    final Uri url = Uri.parse(urlStr);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('မြေပုံ ဖွင့်၍ မရပါ')));
      }
    }
  }

  Future<void> _saveProperty() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    Map<String, dynamic> data = {
      'id': widget.editData?['id'] ?? 'prop_${DateTime.now().millisecondsSinceEpoch}',
      'title': _titleController.text.trim(),
      'asking_price_lakhs': int.tryParse(_askingPriceController.text) ?? 0,
      'bottom_price_lakhs': int.tryParse(_bottomPriceController.text),
      'east_ft': int.tryParse(_eastController.text),
      'west_ft': int.tryParse(_westController.text),
      'south_ft': int.tryParse(_southController.text),
      'north_ft': int.tryParse(_northController.text),
      'remark': _remarkController.text.trim(),
      'map_link': _mapLinkController.text.trim(),
      'status': _status,
      'location_id': _location,
      'road_type': _roadType,
      'house_type': _houseType,
      'land_type': _landType,
      'owner_id': _ownerId,
      'is_deleted': 0,
      'is_synced': 0, // Auto sync အတွက် 0 မှတ်ပါမည်
      'extra_data': jsonEncode({'photos': _photoPaths}),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (widget.editData == null) {
      data['created_at'] = DateTime.now().toUtc().toIso8601String();
      await DatabaseHelper.instance.insertProperty(data);
    } else {
      data['created_at'] = widget.editData!['created_at'];
      await DatabaseHelper.instance.updateProperty(data);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ⚠️ Keyboard Bug အမြစ်ပြတ်ရှင်းရန် GestureDetector ဖြင့် အုပ်ထားခြင်း
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.editData == null ? 'အိမ်ခြံမြေ အသစ်ထည့်ရန်' : 'အိမ်ခြံမြေ ပြင်ဆင်ရန်', style: const TextStyle(fontSize: 18)),
          actions: [
            if (_isSaving) const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(), // Scroll ပို Smooth ဖြစ်စေရန်
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'ခေါင်းစဉ် *', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'ခေါင်းစဉ် ထည့်ပါ' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _askingPriceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ခေါ်ဈေး (သိန်း) *', border: OutlineInputBorder()), validator: (v) => v == null || v.isEmpty ? 'ဈေးနှုန်း ထည့်ပါ' : null)),
                  const SizedBox(width: 16),
                  Expanded(child: TextFormField(controller: _bottomPriceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'အောက်ဆုံးဈေး (သိန်း)', border: OutlineInputBorder()))),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                items: ['Available', 'Pending', 'Sold Out'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _status = v),
              ),
              const SizedBox(height: 16),
              const Text('အကျယ်အဝန်း (ပေ)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _eastController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'အရှေ့', border: OutlineInputBorder()))), const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: _westController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'အနောက်', border: OutlineInputBorder()))), const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: _southController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'တောင်', border: OutlineInputBorder()))), const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: _northController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'မြောက်', border: OutlineInputBorder()))),
                ],
              ),
              const SizedBox(height: 16),
              DynamicDropdown(label: 'မြို့နယ်/တည်နေရာ', category: 'location', selectedValue: _location, onChanged: (v) => setState(() => _location = v)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: DynamicDropdown(label: 'လမ်းအမျိုးအစား', category: 'road_type', selectedValue: _roadType, onChanged: (v) => setState(() => _roadType = v))),
                  const SizedBox(width: 16),
                  Expanded(child: DynamicDropdown(label: 'မြေအမျိုးအစား', category: 'land_type', selectedValue: _landType, onChanged: (v) => setState(() => _landType = v))),
                ],
              ),
              const SizedBox(height: 16),
              DynamicDropdown(label: 'အိမ်အမျိုးအစား', category: 'house_type', selectedValue: _houseType, onChanged: (v) => setState(() => _houseType = v)),
              const SizedBox(height: 16),
              
              const Text('ပိုင်ရှင်အချက်အလက်', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _ownerId,
                decoration: const InputDecoration(labelText: 'ပိုင်ရှင် ရွေးချယ်ပါ', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem(value: null, child: Text('မရွေးချယ်ပါ')),
                  ..._owners.map((o) => DropdownMenuItem(value: o['id'] as String, child: Text(o['name']))).toList()
                ],
                onChanged: (v) => setState(() => _ownerId = v),
              ),
              const SizedBox(height: 16),

              // ⚠️ မြေပုံလင့်ခ် (Map ခလုတ်ပါဝင်သည်)
              TextFormField(
                controller: _mapLinkController,
                decoration: InputDecoration(
                  labelText: 'မြေပုံလင့်ခ် (Google Maps URL)',
                  border: const OutlineInputBorder(),
                  prefixIcon: IconButton(
                    icon: const Icon(Icons.map, color: Colors.blue),
                    tooltip: 'Google Maps ဖွင့်ရန်',
                    onPressed: _openGoogleMaps, // ခလုတ်နှိပ်လျှင် Google Maps သို့ သွားမည်
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              const Text('ဓာတ်ပုံများ:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickImages,
                child: Container(
                  height: 80,
                  width: double.infinity,
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                  child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, color: Colors.grey), SizedBox(height: 4), Text('ဓာတ်ပုံများ ထည့်ရန်', style: TextStyle(color: Colors.grey))]),
                ),
              ),
              if (_photoPaths.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _photoPaths.length,
                    itemBuilder: (context, index) => Stack(
                      children: [
                        Container(margin: const EdgeInsets.only(right: 8), width: 100, height: 100, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), image: DecorationImage(image: FileImage(File(_photoPaths[index])), fit: BoxFit.cover))),
                        Positioned(top: 4, right: 12, child: InkWell(onTap: () => setState(() => _photoPaths.removeAt(index)), child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 16)))),
                      ],
                    ),
                  ),
                )
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _remarkController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'မှတ်ချက်', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: const Color(0xFF008080), foregroundColor: Colors.white),
                onPressed: _isSaving ? null : _saveProperty,
                child: const Text('သိမ်းမည်', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
