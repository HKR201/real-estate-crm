import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../db/database_helper.dart';

class PropertyFormScreen extends StatefulWidget {
  final Map<String, dynamic>? editData;
  const PropertyFormScreen({super.key, this.editData});

  @override
  State<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends State<PropertyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _titleCtrl = TextEditingController();
  final _askingPriceCtrl = TextEditingController();
  final _bottomPriceCtrl = TextEditingController();
  final _eastCtrl = TextEditingController();
  final _westCtrl = TextEditingController();
  final _southCtrl = TextEditingController();
  final _northCtrl = TextEditingController();
  final _remarkCtrl = TextEditingController();
  final _mapLinkCtrl = TextEditingController();

  // ⚠️ Default ကို သင်သတ်မှတ်ထားသည့်အတိုင်း "ခြံသီးသန့်" ဟု ပြောင်းထားပါသည်
  String _propertyType = 'ခြံသီးသန့်';
  String _status = 'Available';
  String? _locationId;
  String? _roadType;
  String? _landType;
  String? _ownerId;

  List<String> _photos = [];
  bool _isSaving = false;

  List<String> _locations = [];
  List<String> _roadTypes = [];
  List<String> _landTypes = [];
  List<Map<String, dynamic>> _owners = [];

  final List<String> _propertyTypes = ['ခြံသီးသန့်', 'အိမ်အပါ', 'တိုက်ခန်း', 'ကွန်ဒို', 'စက်မှုဇုန်', 'ဂိုဒေါင်'];
  final List<String> _statusList = ['Available', 'Pending', 'Sold Out'];

  @override
  void initState() {
    super.initState();
    _loadMetadata();
    if (widget.editData != null) {
      _loadEditData(widget.editData!);
    }
  }

  Future<void> _loadMetadata() async {
    final locs = await DatabaseHelper.instance.getMetadata('location');
    final roads = await DatabaseHelper.instance.getMetadata('road_type');
    final lands = await DatabaseHelper.instance.getMetadata('land_type');
    final owners = await DatabaseHelper.instance.getAllOwners();

    setState(() {
      _locations = locs;
      _roadTypes = roads;
      _landTypes = lands;
      _owners = owners;
    });
  }

  void _loadEditData(Map<String, dynamic> data) {
    _titleCtrl.text = data['title'] ?? '';
    _askingPriceCtrl.text = (data['asking_price_lakhs'] ?? '').toString();
    _bottomPriceCtrl.text = (data['bottom_price_lakhs'] ?? '').toString();
    _status = data['status'] ?? 'Available';
    _eastCtrl.text = (data['east_ft'] ?? '').toString();
    _westCtrl.text = (data['west_ft'] ?? '').toString();
    _southCtrl.text = (data['south_ft'] ?? '').toString();
    _northCtrl.text = (data['north_ft'] ?? '').toString();
    
    _locationId = data['location_id'];
    _roadType = data['road_type'];
    _landType = data['land_type'];
    _ownerId = data['owner_id'];
    _mapLinkCtrl.text = data['map_link'] ?? '';
    _remarkCtrl.text = data['remark'] ?? '';

    if (data['extra_data'] != null) {
      try {
        final extra = jsonDecode(data['extra_data']);
        if (extra['photos'] != null) _photos = List<String>.from(extra['photos']);
        if (extra['property_type'] != null) _propertyType = extra['property_type'];
      } catch (_) {}
    }
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _photos.addAll(images.map((e) => e.path));
      });
    }
  }

  Future<void> _addNewMetadata(String category, String title) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$title အသစ်ထည့်မည်', style: const TextStyle(fontSize: 16)),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ပယ်ဖျက်')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), 
            child: const Text('ထည့်မည်')
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await DatabaseHelper.instance.insertMetadata(category, result);
      await _loadMetadata();
      setState(() {
        if (category == 'location') _locationId = result;
        if (category == 'road_type') _roadType = result;
        if (category == 'land_type') _landType = result;
      });
    }
  }

  Future<void> _saveProperty() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final extraData = jsonEncode({
      'photos': _photos,
      'property_type': _propertyType,
    });

    final data = {
      'id': widget.editData?['id'] ?? 'prop_${DateTime.now().millisecondsSinceEpoch}',
      'title': _titleCtrl.text.trim(),
      'asking_price_lakhs': int.tryParse(_askingPriceCtrl.text.trim()) ?? 0,
      'bottom_price_lakhs': int.tryParse(_bottomPriceCtrl.text.trim()),
      'status': _status,
      'east_ft': int.tryParse(_eastCtrl.text.trim()),
      'west_ft': int.tryParse(_westCtrl.text.trim()),
      'south_ft': int.tryParse(_southCtrl.text.trim()),
      'north_ft': int.tryParse(_northCtrl.text.trim()),
      'location_id': _locationId,
      'road_type': _roadType,
      'land_type': _landType,
      'owner_id': _ownerId,
      'map_link': _mapLinkCtrl.text.trim(),
      'remark': _remarkCtrl.text.trim(),
      'extra_data': extraData,
      'is_deleted': 0,
      'is_synced': 0,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      if (widget.editData == null) {
        data['created_at'] = DateTime.now().toUtc().toIso8601String();
        await DatabaseHelper.instance.insertProperty(data);
      } else {
        data['created_at'] = widget.editData!['created_at'];
        await DatabaseHelper.instance.updateProperty(data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Save Property Error: $e");
      setState(() => _isSaving = false);
    }
  }

  // ⚠️ Font Size ညီညာစေရန်နှင့် စာလုံးမပြတ်စေရန် Standard TextField Widget
  Widget _buildTextField(TextEditingController ctrl, String label, {bool isNumber = false, double fontSize = 14, bool isRequired = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: fontSize),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        isDense: true,
      ),
      validator: isRequired ? (v) => v == null || v.isEmpty ? 'လိုအပ်ပါသည်' : null : null,
    );
  }

  // ⚠️ Minimalist Add Button ပါဝင်သော Standard Dropdown Widget
  Widget _buildDropdown(String label, String? value, List<String> items, Function(String?) onChanged, {String? addCategory, double fontSize = 14}) {
    final theme = Theme.of(context);
    // Value သည် items ထဲတွင်မရှိပါက null ထားမည်
    final validValue = (value != null && items.contains(value)) ? value : null;

    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: validValue,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: fontSize),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      ),
      items: [
        ...items.map((e) => DropdownMenuItem(
              value: e,
              child: Text(e, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
            )),
        if (addCategory != null)
          DropdownMenuItem(
            value: 'ADD_NEW',
            // ⚠️ Bulky မဖြစ်စေရန် သေးသေးရှင်းရှင်းလေး ပြင်ဆင်ထားသည် (ပုံ ၅၀၂၉ အတိုင်း)
            child: Row(
              children: [
                Icon(Icons.add, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('$label အသစ်ထည့်မည်', style: TextStyle(color: theme.colorScheme.primary, fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
      ],
      onChanged: (v) {
        if (v == 'ADD_NEW' && addCategory != null) {
          _addNewMetadata(addCategory, label);
        } else {
          onChanged(v);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.editData == null ? 'အိမ်ခြံမြေ အသစ်ထည့်ရန်' : 'အိမ်ခြံမြေ ပြင်ဆင်ရန်', style: const TextStyle(fontSize: 18)),
          actions: [
            if (_isSaving) const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            children: [
              _buildTextField(_titleCtrl, 'ခေါင်းစဉ် *', isRequired: true),
              const SizedBox(height: 16),
              
              _buildDropdown('အမျိုးအစား', _propertyType, _propertyTypes, (v) => setState(() => _propertyType = v!)),
              const SizedBox(height: 16),

              // ⚠️ စာလုံးပြတ်မသွားစေရန် Label နှင့် Font Size ကို ညှိထားသည်
              Row(
                children: [
                  Expanded(child: _buildTextField(_askingPriceCtrl, 'ခေါ်ဈေး(သိန်း)', isNumber: true, fontSize: 13)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(_bottomPriceCtrl, 'အောက်ဆုံး(သိန်း)', isNumber: true, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 16),

              _buildDropdown('Status', _status, _statusList, (v) => setState(() => _status = v!)),
              const SizedBox(height: 24),

              const Text('အကျယ်အဝန်း (ပေ)', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              // ⚠️ တောင်၊ မြောက် အတိအကျ ဖြည့်စွက်ပေးထားသည်
              Row(
                children: [
                  Expanded(child: _buildTextField(_eastCtrl, 'အရှေ့', isNumber: true, fontSize: 13)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTextField(_westCtrl, 'အနောက်', isNumber: true, fontSize: 13)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTextField(_southCtrl, 'တောင်', isNumber: true, fontSize: 13)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTextField(_northCtrl, 'မြောက်', isNumber: true, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 16),

              _buildDropdown('မြို့နယ်/တည်နေရာ', _locationId, _locations, (v) => setState(() => _locationId = v), addCategory: 'location'),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(child: _buildDropdown('လမ်းအမျိုးအစား', _roadType, _roadTypes, (v) => setState(() => _roadType = v), addCategory: 'road_type', fontSize: 13)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDropdown('မြေအမျိုးအစား', _landType, _landTypes, (v) => setState(() => _landType = v), addCategory: 'land_type', fontSize: 13)),
                ],
              ),
              const SizedBox(height: 16),

              // Owner Dropdown (ပိုင်ရှင်စာရင်း)
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: (_ownerId != null && _owners.any((o) => o['id'] == _ownerId)) ? _ownerId : null,
                decoration: InputDecoration(
                  labelText: 'ပိုင်ရှင်အချက်အလက် (ရွေးချယ်ရန်)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: [
                  ..._owners.map((o) => DropdownMenuItem(
                        value: o['id'] as String,
                        child: Text('${o['name']} (${o['phones'] ?? '-'})', style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
                      )),
                ],
                onChanged: (v) => setState(() => _ownerId = v),
              ),
              const SizedBox(height: 16),

              _buildTextField(_mapLinkCtrl, 'Google Map Link (Optional)'),
              const SizedBox(height: 16),

              TextFormField(
                controller: _remarkCtrl,
                maxLines: 3,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'မှတ်ချက်',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 24),

              // Photos Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ဓာတ်ပုံများ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  TextButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.add_a_photo, size: 18),
                    label: const Text('ထည့်မည်'),
                  ),
                ],
              ),
              if (_photos.isNotEmpty)
                Container(
                  height: 100,
                  margin: const EdgeInsets.only(top: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _photos.length,
                    itemBuilder: (ctx, i) {
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: _photos[i].startsWith('http') ? NetworkImage(_photos[i]) : FileImage(File(_photos[i])) as ImageProvider,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4, right: 12,
                            child: InkWell(
                              onTap: () => setState(() => _photos.removeAt(i)),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color(0xFF2E6561),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _saveProperty,
                child: const Text('သိမ်းဆည်းမည်', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
