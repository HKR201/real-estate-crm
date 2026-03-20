import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart'; // ⚠️ Map Icon နှိပ်လျှင် Google Map ဖွင့်ရန်
import '../db/database_helper.dart';
import 'owner_form_screen.dart';

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
  final _ownerSearchCtrl = TextEditingController();

  String _propertyType = 'ခြံသီးသန့်';
  String _status = 'Available';
  String? _houseType;
  String? _locationId;
  String? _roadType;
  String? _landType;
  String? _ownerId;

  List<String> _photos = [];
  bool _isSaving = false;
  bool _isLoading = true;

  List<String> _locations = [];
  List<String> _roadTypes = [];
  List<String> _landTypes = [];
  List<String> _houseTypes = [];
  List<Map<String, dynamic>> _owners = [];

  final List<String> _propertyTypes = ['ခြံသီးသန့်', 'အိမ်အပါ'];
  final List<String> _statusList = ['Available', 'Pending', 'Sold Out'];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (widget.editData != null) {
      _loadEditData(widget.editData!);
    }
    await _loadMetadata();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
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
    _houseType = data['house_type'];
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

  Future<void> _loadMetadata() async {
    final locMeta = await DatabaseHelper.instance.getMetadata('location');
    final roadMeta = await DatabaseHelper.instance.getMetadata('road_type');
    final landMeta = await DatabaseHelper.instance.getMetadata('land_type');
    final houseMeta = await DatabaseHelper.instance.getMetadata('house_type');

    final locDistinct = await DatabaseHelper.instance.getDistinctPropertyValues('location_id');
    final roadDistinct = await DatabaseHelper.instance.getDistinctPropertyValues('road_type');
    final landDistinct = await DatabaseHelper.instance.getDistinctPropertyValues('land_type');
    final houseDistinct = await DatabaseHelper.instance.getDistinctPropertyValues('house_type');

    final owners = await DatabaseHelper.instance.getAllOwners();

    setState(() {
      _locations = {...locMeta, ...locDistinct}.toList();
      _roadTypes = {...roadMeta, ...roadDistinct}.toList();
      _landTypes = {...landMeta, ...landDistinct}.toList();
      _houseTypes = {...houseMeta, ...houseDistinct}.toList();
      _owners = owners;
    });

    if (_ownerId != null) {
      final owner = _owners.where((o) => o['id'] == _ownerId).toList();
      if (owner.isNotEmpty) {
        _ownerSearchCtrl.text = owner.first['name'] ?? '';
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('ကင်မရာဖြင့် ရိုက်မည်'),
              onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Gallery မှ ရွေးမည်'),
              onTap: () { Navigator.pop(ctx); _pickMultiImages(); },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, imageQuality: 80);
    if (image != null) setState(() => _photos.add(image.path));
  }

  Future<void> _pickMultiImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty) setState(() => _photos.addAll(images.map((e) => e.path)));
  }

  Future<void> _addNewMetadata(String category, String title) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$title', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ပယ်ဖျက်')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('ထည့်မည်')),
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
        if (category == 'house_type') _houseType = result;
      });
    }
  }

  Future<void> _saveProperty() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final savedHouseType = _propertyType == 'ခြံသီးသန့်' ? null : _houseType;
    final extraData = jsonEncode({'photos': _photos, 'property_type': _propertyType});

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
      'house_type': savedHouseType,
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
    // ⚠️ Suffix Icon ထည့်သွင်းနိုင်ရန် ပြင်ဆင်ထားသည်
  Widget _buildTextField(TextEditingController ctrl, String label, {bool isNumber = false, double fontSize = 13, bool isRequired = false, Widget? suffixIcon}) {
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
        suffixIcon: suffixIcon,
      ),
      validator: isRequired ? (v) => v == null || v.isEmpty ? 'လိုအပ်ပါသည်' : null : null,
    );
  }

  // ⚠️ Add New စာသားကို စိတ်ကြိုက်ပြောင်းနိုင်ရန် addTextLabel ကို ထည့်သွင်းထားသည်
  Widget _buildDropdown(String label, String? value, List<String> items, Function(String?) onChanged, {String? addCategory, String? addTextLabel, double fontSize = 13}) {
    final theme = Theme.of(context);
    final validValue = (value != null && items.contains(value)) ? value : null;
    final displayAddText = addTextLabel ?? '$label အသစ်ထည့်မည်';

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
            child: Row(
              children: [
                Icon(Icons.add, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(displayAddText, style: TextStyle(color: theme.colorScheme.primary, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
      ],
      onChanged: (v) {
        if (v == 'ADD_NEW' && addCategory != null) {
          _addNewMetadata(addCategory, displayAddText);
        } else {
          onChanged(v);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);

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
              _buildTextField(_titleCtrl, 'ခေါင်းစဉ် *', fontSize: 14, isRequired: true),
              const SizedBox(height: 16),
              
              _buildDropdown('အမျိုးအစား', _propertyType, _propertyTypes, (v) => setState(() => _propertyType = v!), fontSize: 14),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(child: _buildTextField(_askingPriceCtrl, 'ခေါ်ဈေး(သိန်း)', isNumber: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(_bottomPriceCtrl, 'အောက်ဆုံး(သိန်း)', isNumber: true)),
                ],
              ),
              const SizedBox(height: 16),

              _buildDropdown('Status', _status, _statusList, (v) => setState(() => _status = v!), fontSize: 14),
              const SizedBox(height: 24),

              const Text('အကျယ်အဝန်း (ပေ)', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildTextField(_eastCtrl, 'အရှေ့', isNumber: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTextField(_westCtrl, 'အနောက်', isNumber: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTextField(_southCtrl, 'တောင်', isNumber: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTextField(_northCtrl, 'မြောက်', isNumber: true)),
                ],
              ),
              const SizedBox(height: 16),

              _buildDropdown('မြို့နယ်/တည်နေရာ', _locationId, _locations, (v) => setState(() => _locationId = v), addCategory: 'location', addTextLabel: 'မြို့နယ်/တည်နေရာ အသစ်ထည့်မည်', fontSize: 14),
              const SizedBox(height: 16),

              Row(
                children: [
                  // ⚠️ လမ်းအမျိုးအစား ဆိုပြီး ရှည်မနေစေရန် "လမ်း အသစ်ထည့်မည်" ဟု ပြင်ဆင်ထားသည်
                  Expanded(child: _buildDropdown('လမ်းအမျိုးအစား', _roadType, _roadTypes, (v) => setState(() => _roadType = v), addCategory: 'road_type', addTextLabel: 'လမ်း အသစ်ထည့်မည်')),
                  const SizedBox(width: 12),
                  // ⚠️ မြေအမျိုးအစား ဆိုပြီး ရှည်မနေစေရန် "မြေ အသစ်ထည့်မည်" ဟု ပြင်ဆင်ထားသည်
                  Expanded(child: _buildDropdown('မြေအမျိုးအစား', _landType, _landTypes, (v) => setState(() => _landType = v), addCategory: 'land_type', addTextLabel: 'မြေ အသစ်ထည့်မည်')),
                ],
              ),
              const SizedBox(height: 16),

              if (_propertyType == 'အိမ်အပါ') ...[
                _buildDropdown('အိမ်အမျိုးအစား', _houseType, _houseTypes, (v) => setState(() => _houseType = v), addCategory: 'house_type', addTextLabel: 'အိမ် အသစ်ထည့်မည်', fontSize: 14),
                const SizedBox(height: 16),
              ],

              const Text('ပိုင်ရှင်အချက်အလက်', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) => Autocomplete<Map<String, dynamic>>(
                  initialValue: TextEditingValue(text: _ownerSearchCtrl.text),
                  displayStringForOption: (option) => option['name'] ?? '',
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    final query = textEditingValue.text.trim();
                    if (query.isEmpty) return const Iterable<Map<String, dynamic>>.empty();
                    final matches = _owners.where((o) => (o['name'] ?? '').toLowerCase().contains(query.toLowerCase())).toList();
                    matches.add({'id': '__ADD_NEW__', 'name': query});
                    return matches;
                  },
                  onSelected: (option) async {
                    if (option['id'] == '__ADD_NEW__') {
                      _ownerSearchCtrl.text = ''; 
                      final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => OwnerFormScreen(initialName: option['name'])));
                      if (result == true) {
                        setState(() => _isLoading = true);
                        await _loadMetadata();
                        final newOwner = _owners.firstWhere((o) => o['name'] == option['name'], orElse: () => {});
                        if (newOwner.isNotEmpty) {
                          setState(() {
                            _ownerId = newOwner['id'];
                            _ownerSearchCtrl.text = newOwner['name'];
                            _isLoading = false;
                          });
                        } else {
                          setState(() => _isLoading = false);
                        }
                      }
                    } else {
                      setState(() {
                        _ownerId = option['id'];
                        _ownerSearchCtrl.text = option['name'];
                      });
                    }
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: 250, maxWidth: constraints.maxWidth),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              if (option['id'] == '__ADD_NEW__') {
                                return ListTile(
                                  leading: Icon(Icons.add, color: theme.colorScheme.primary),
                                  title: Text('"${option['name']}" ကို အသစ်ထည့်မည်', style: TextStyle(color: theme.colorScheme.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                                  onTap: () => onSelected(option),
                                );
                              }
                              return ListTile(
                                leading: const Icon(Icons.person, size: 20),
                                title: Text(option['name'] ?? ''),
                                subtitle: Text(option['phones'] ?? 'ဖုန်းမရှိပါ', style: const TextStyle(fontSize: 12)),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                  fieldViewBuilder: (context, controller, node, onSubmitted) {
                    return TextFormField(
                      controller: controller,
                      focusNode: node,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'ပိုင်ရှင်ရှာရန် (သို့) အသစ်ရိုက်ထည့်ပါ',
                        prefixIcon: const Icon(Icons.person_search, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                        suffixIcon: _ownerId != null ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { setState(() { _ownerId = null; controller.clear(); }); }) : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // ⚠️ Beta 1 မှ Google Map Icon ကို ပြန်လည်ထည့်သွင်းပေးထားသည်
              _buildTextField(
                _mapLinkCtrl, 
                'Google Map Link (Optional)', 
                fontSize: 14,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.map, color: Colors.blue),
                  onPressed: () async {
                    final url = _mapLinkCtrl.text.trim();
                    final uri = url.isNotEmpty && url.startsWith('http') 
                        ? Uri.parse(url) 
                        : Uri.parse('https://maps.google.com');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Map ဖွင့်၍ မရပါ')));
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _remarkCtrl,
                maxLines: 3,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(labelText: 'မှတ်ချက်', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ဓာတ်ပုံများ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  TextButton.icon(onPressed: _showImagePickerOptions, icon: const Icon(Icons.add_a_photo, size: 18), label: const Text('ထည့်မည်')),
                ],
              ),
              if (_photos.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _photos.length,
                    itemBuilder: (ctx, i) => Stack(
                      children: [
                        Container(margin: const EdgeInsets.only(right: 8), width: 100, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), image: DecorationImage(image: _photos[i].startsWith('http') ? NetworkImage(_photos[i]) : FileImage(File(_photos[i])) as ImageProvider, fit: BoxFit.cover))),
                        Positioned(top: 4, right: 12, child: InkWell(onTap: () => setState(() => _photos.removeAt(i)), child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, size: 14, color: Colors.white)))),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: const Color(0xFF2E6561), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: _isSaving ? null : _saveProperty,
                child: const Text('သိမ်းဆည်းမည်', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
