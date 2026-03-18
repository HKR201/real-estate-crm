import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'dart:io'; // <--- File ကိုအသုံးပြုရန်
import 'package:image_picker/image_picker.dart'; // <--- ဓာတ်ပုံရွေးရန်

import '../db/database_helper.dart';
import '../widgets/dynamic_dropdown.dart';
import 'owner_form_screen.dart'; 

class PropertyFormScreen extends StatefulWidget {
  final Map<String, dynamic>? editData; 
  const PropertyFormScreen({super.key, this.editData});

  @override
  State<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends State<PropertyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  final _titleController = TextEditingController();
  final _askingPriceController = TextEditingController();
  final _bottomPriceController = TextEditingController();
  final _eastController = TextEditingController();
  final _westController = TextEditingController();
  final _southController = TextEditingController();
  final _northController = TextEditingController();
  final _remarkController = TextEditingController();
  final _mapLinkController = TextEditingController(); 

  String? _location;
  String? _roadType;
  String? _landType;
  String? _houseType; 

  String _status = 'Available'; 
  String? _propertyBaseType; 

  String? _selectedOwnerId;
  String? _selectedOwnerName;

  // --- ဓာတ်ပုံများအတွက် Variables ---
  final ImagePicker _picker = ImagePicker();
  List<String> _imagePaths = [];

  @override
  void initState() {
    super.initState();
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
      _landType = d['land_type'];
      _houseType = d['house_type'];
      _propertyBaseType = (_houseType != null && _houseType!.isNotEmpty) ? 'အိမ်ပါသည်' : 'မြေကွက်သီးသန့်';
      _selectedOwnerId = d['owner_id'];
      
      if (_selectedOwnerId != null) _loadOwnerName(_selectedOwnerId!);

      // --- ယခင်သိမ်းထားသော ဓာတ်ပုံများကို ပြန်ဆွဲထုတ်ခြင်း ---
      if (d['extra_data'] != null) {
        try {
          final extraData = jsonDecode(d['extra_data']);
          if (extraData['photos'] != null) {
            _imagePaths = List<String>.from(extraData['photos']);
          }
        } catch (_) {}
      }
    }
  }

  Future<void> _loadOwnerName(String id) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('crm_owners', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty && mounted) {
      setState(() => _selectedOwnerName = result.first['name'] as String);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _askingPriceController.dispose();
    _bottomPriceController.dispose();
    _eastController.dispose();
    _westController.dispose();
    _southController.dispose();
    _northController.dispose();
    _remarkController.dispose();
    _mapLinkController.dispose();
    super.dispose();
  }

  // --- ဖုန်း Gallery မှ ဓာတ်ပုံရွေးမည့်စနစ် ---
  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage(); // ဓာတ်ပုံ အများကြီး ရွေးခွင့်ပေးမည်
    if (images.isNotEmpty) {
      setState(() {
        _imagePaths.addAll(images.map((e) => e.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
  }

  void _showOwnerSelectionSheet(BuildContext context) async {
    List<Map<String, dynamic>> owners = await DatabaseHelper.instance.getAllOwners();
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return _OwnerSelectionSheet(
          initialOwners: owners,
          onOwnerSelected: (id, name) { setState(() { _selectedOwnerId = id; _selectedOwnerName = name; }); },
        );
      },
    );
  }

  Future<void> _saveProperty() async {
    if (_formKey.currentState!.validate()) {
      // --- Extra Data အတွင်း ဓာတ်ပုံလမ်းကြောင်းများကို ထည့်သိမ်းမည် ---
      Map<String, dynamic> extraData = {};
      if (widget.editData != null && widget.editData!['extra_data'] != null) {
        try { extraData = jsonDecode(widget.editData!['extra_data']); } catch (_) {}
      }
      extraData['photos'] = _imagePaths;

      final propertyData = {
        'id': widget.editData?['id'] ?? _uuid.v4(),
        'title': _titleController.text,
        'asking_price_lakhs': int.tryParse(_askingPriceController.text) ?? 0,
        'bottom_price_lakhs': int.tryParse(_bottomPriceController.text),
        'status': _status, 
        'east_ft': int.tryParse(_eastController.text),
        'west_ft': int.tryParse(_westController.text),
        'south_ft': int.tryParse(_southController.text),
        'north_ft': int.tryParse(_northController.text),
        'house_type': _propertyBaseType == 'အိမ်ပါသည်' ? _houseType : null, 
        'road_type': _roadType,
        'land_type': _landType,
        'location_id': _location ?? 'မသိရ',
        'owner_id': _selectedOwnerId,
        'remark': _remarkController.text,
        'map_link': _mapLinkController.text, 
        'is_deleted': 0,
        'extra_data': jsonEncode(extraData), // JSON အဖြစ်ပြောင်း၍ သိမ်းမည်
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (widget.editData == null) {
        propertyData['created_at'] = DateTime.now().toIso8601String();
        await DatabaseHelper.instance.insertProperty(propertyData);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('အိမ်ခြံမြေစာရင်း အသစ် သိမ်းဆည်းပြီးပါပြီ')));
      } else {
        propertyData['created_at'] = widget.editData!['created_at']; 
        await DatabaseHelper.instance.updateProperty(propertyData);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('အိမ်ခြံမြေစာရင်း ပြင်ဆင်ပြီးပါပြီ')));
      }

      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editData == null ? 'အိမ်ခြံမြေ အသစ်ထည့်ရန်' : 'အိမ်ခြံမြေ ပြင်ဆင်ရန်', style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'ခေါင်းစဉ် (ဥပမာ - လှိုင် 2RC လုံးချင်းသစ်)', prefixIcon: Icon(Icons.title)), validator: (value) => value!.isEmpty ? 'ခေါင်းစဉ် ထည့်ပေးပါ' : null),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _status, decoration: InputDecoration(labelText: 'Status (အခြေအနေ)', prefixIcon: const Icon(Icons.info_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              items: ['Available', 'Pending', 'Sold Out'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (val) => setState(() => _status = val!),
            ),
            const SizedBox(height: 16),
            Row(children: [Expanded(child: TextFormField(controller: _askingPriceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ခေါ်ဈေး (သိန်း)'), validator: (value) => value!.isEmpty ? 'လိုအပ်ပါသည်' : null)), const SizedBox(width: 16), Expanded(child: TextFormField(controller: _bottomPriceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'အောက်ဆုံးဈေး (သိန်း)')))]),
            const SizedBox(height: 16),
            DynamicDropdown(label: 'မြို့နယ် / တည်နေရာ', category: 'location', selectedValue: _location, onChanged: (value) => setState(() => _location = value)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _propertyBaseType, decoration: InputDecoration(labelText: 'အမျိုးအစား', prefixIcon: const Icon(Icons.category), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              items: ['မြေကွက်သီးသန့်', 'အိမ်ပါသည်'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (val) => setState(() { _propertyBaseType = val; if (val == 'မြေကွက်သီးသန့်') _houseType = null; }),
            ),
            const SizedBox(height: 16),
            if (_propertyBaseType == 'အိမ်ပါသည်') ...[DynamicDropdown(label: 'အိမ်အမျိုးအစား (ဥပမာ - 2RC)', category: 'house_type', selectedValue: _houseType, onChanged: (value) => setState(() => _houseType = value)), const SizedBox(height: 16)],
            const Text('အကျယ်အဝန်း (ပေ)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), const SizedBox(height: 8),
            Row(children: [Expanded(child: TextFormField(controller: _eastController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'အရှေ့ (East)'))), const SizedBox(width: 16), Expanded(child: TextFormField(controller: _westController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'အနောက် (West)')))]), const SizedBox(height: 16),
            Row(children: [Expanded(child: TextFormField(controller: _southController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'တောင် (South)'))), const SizedBox(width: 16), Expanded(child: TextFormField(controller: _northController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'မြောက် (North)')))]), const SizedBox(height: 16),
            Row(children: [Expanded(child: DynamicDropdown(label: 'လမ်းအမျိုးအစား', category: 'road_type', selectedValue: _roadType, onChanged: (value) => setState(() => _roadType = value))), const SizedBox(width: 16), Expanded(child: DynamicDropdown(label: 'မြေအမျိုးအစား', category: 'land_type', selectedValue: _landType, onChanged: (value) => setState(() => _landType = value)))]), const SizedBox(height: 24),
            const Text('ပိုင်ရှင်အချက်အလက်', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), const SizedBox(height: 8),
            InkWell(
              onTap: () => _showOwnerSelectionSheet(context), borderRadius: BorderRadius.circular(8),
              child: InputDecorator(decoration: InputDecoration(labelText: 'ပိုင်ရှင်', prefixIcon: const Icon(Icons.person), suffixIcon: const Icon(Icons.arrow_drop_down), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))), child: Text(_selectedOwnerName ?? 'ပိုင်ရှင် ရွေးချယ်ပါ (သို့) အသစ်ထည့်ပါ', style: TextStyle(color: _selectedOwnerName == null ? Colors.grey : Theme.of(context).colorScheme.onSurface, fontSize: 16))),
            ),
            const SizedBox(height: 16),
            TextFormField(controller: _mapLinkController, decoration: const InputDecoration(labelText: 'မြေပုံလင့်ခ် (Google Maps URL)', prefixIcon: Icon(Icons.map))),
            const SizedBox(height: 24),

            // --- ဓာတ်ပုံရွေးရန် UI အသစ် ---
            const Text('ဓာတ်ပုံများ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            _imagePaths.isEmpty
                ? InkWell(
                    onTap: _pickImages,
                    child: Container(
                      height: 100, decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade400)),
                      child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, color: Colors.grey, size: 32), SizedBox(height: 8), Text('ဓာတ်ပုံများ ထည့်ရန်', style: TextStyle(color: Colors.grey))]),
                    ),
                  )
                : SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _imagePaths.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _imagePaths.length) {
                          return InkWell(
                            onTap: _pickImages,
                            child: Container(
                              width: 100, margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.add_a_photo, color: Colors.grey),
                            ),
                          );
                        }
                        return Stack(
                          children: [
                            Container(
                              width: 100, margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), image: DecorationImage(image: FileImage(File(_imagePaths[index])), fit: BoxFit.cover)),
                            ),
                            Positioned(
                              top: 4, right: 12,
                              child: InkWell(
                                onTap: () => _removeImage(index),
                                child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.close, size: 16, color: Colors.red)),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 16),

            TextFormField(controller: _remarkController, maxLines: 3, decoration: const InputDecoration(labelText: 'မှတ်ချက် (ဝယ်လက် မမြင်ရပါ)')),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Theme.of(context).colorScheme.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: _saveProperty,
                child: Text(widget.editData == null ? 'သိမ်းမည်' : 'ပြင်ဆင်ချက် သိမ်းမည်', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// Bottom Sheet Code (ယခင်အတိုင်း)
class _OwnerSelectionSheet extends StatefulWidget {
  final List<Map<String, dynamic>> initialOwners;
  final Function(String id, String name) onOwnerSelected;
  const _OwnerSelectionSheet({required this.initialOwners, required this.onOwnerSelected});
  @override
  State<_OwnerSelectionSheet> createState() => _OwnerSelectionSheetState();
}
class _OwnerSelectionSheetState extends State<_OwnerSelectionSheet> {
  late List<Map<String, dynamic>> owners;
  final TextEditingController _searchController = TextEditingController();
  @override
  void initState() { super.initState(); owners = widget.initialOwners; }
  void _goToAddOwner() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const OwnerFormScreen()));
    if (result == true) {
      final updatedOwners = await DatabaseHelper.instance.getAllOwners();
      if (mounted) { setState(() => owners = updatedOwners); if (owners.isNotEmpty) { widget.onOwnerSelected(owners.first['id'], owners.first['name']); Navigator.pop(context); } }
    }
  }
  @override
  Widget build(BuildContext context) {
    final filteredOwners = owners.where((o) => (o['name'] as String).toLowerCase().contains(_searchController.text.toLowerCase())).toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 24, left: 16, right: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ပိုင်ရှင် ရွေးချယ်ရန်', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 16),
          TextField(controller: _searchController, autofocus: true, decoration: const InputDecoration(labelText: 'အမည်ဖြင့် ရှာဖွေရန်', prefixIcon: Icon(Icons.search)), onChanged: (v) => setState(() {})), const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white), onPressed: _goToAddOwner, icon: const Icon(Icons.person_add), label: const Text('ပိုင်ရှင်အသစ် ထည့်မည် (+)'))), const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
            child: ListView.builder(shrinkWrap: true, itemCount: filteredOwners.length, itemBuilder: (context, index) {
                final owner = filteredOwners[index];
                List<dynamic> phones = []; try { phones = jsonDecode(owner['phones'] ?? '[]'); } catch (_) {}
                return ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text(owner['name'], style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: phones.isNotEmpty ? Text(phones.first.toString()) : null, onTap: () { widget.onOwnerSelected(owner['id'], owner['name']); Navigator.pop(context); });
              },
            ),
          ), const SizedBox(height: 16),
        ],
      ),
    );
  }
}
