import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:convert';
import '../db/database_helper.dart';
import '../widgets/dynamic_dropdown.dart';
import 'owner_form_screen.dart';

class PropertyFormScreen extends StatefulWidget {
  final Map<String, dynamic>? editData;
  const PropertyFormScreen({super.key, this.editData});

  @override
  State<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends State<PropertyFormScreen> with WidgetsBindingObserver {
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
  final TextEditingController _ownerSearchController = TextEditingController();

  String? _status = 'Available';
  String? _propertyType = 'အိမ်အပါ';
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
    WidgetsBinding.instance.addObserver(this);

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
          if (extra['property_type'] != null) _propertyType = extra['property_type'];
          if (extra['photos'] != null) _photoPaths = List<String>.from(extra['photos']);
        } catch (e) {
          debugPrint("JSON Parse Error: ${e.toString()}");
        }
      }
    }
    _loadOwners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _titleController.dispose();
    _askingPriceController.dispose();
    _bottomPriceController.dispose();
    _eastController.dispose();
    _westController.dispose();
    _southController.dispose();
    _northController.dispose();
    _remarkController.dispose();
    _mapLinkController.dispose();
    _ownerSearchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  Future<void> _loadOwners() async {
    try {
      final owners = await DatabaseHelper.instance.getAllOwners();
      if (mounted) {
        setState(() {
          _owners = owners;
          if (_ownerId != null && _ownerSearchController.text.isEmpty) {
            final match = _owners.where((o) => o['id'] == _ownerId).toList();
            if (match.isNotEmpty) _ownerSearchController.text = match.first['name'];
          }
        });
      }
    } catch (e) {
      debugPrint("Load Owner Error: ${e.toString()}");
    }
  }

  Future<void> _pickImages(bool isCamera) async {
    try {
      final picker = ImagePicker();
      List<XFile> pickedFiles = [];

      if (isCamera) {
        final file = await picker.pickImage(source: ImageSource.camera);
        if (file != null) pickedFiles.add(file);
      } else {
        pickedFiles = await picker.pickMultiImage();
      }

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
            setState(() => _photoPaths.add(newFile.path));
          }
        }
      }
    } catch (e) {
      debugPrint("Image Pick Error: ${e.toString()}");
    }
  }

  void _showImageSourceBottomSheet() {
    FocusManager.instance.primaryFocus?.unfocus();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('ပက်ကင် (Gallery) မှ ရွေးရန်'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImages(false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('ကင်မရာ (Camera) ဖြင့် ရိုက်ရန်'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImages(true);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openGoogleMaps() async {
    String urlStr = _mapLinkController.text.trim();
    if (urlStr.isEmpty) urlStr = 'https://maps.google.com';
    try {
      await launchUrl(Uri.parse(urlStr), mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Launch Map Error: ${e.toString()}");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('မြေပုံ ဖွင့်၍ မရပါ')));
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
      'house_type': _propertyType == 'ခြံသီးသန့်' ? null : _houseType,
      'land_type': _landType,
      'owner_id': _ownerId,
      'is_deleted': 0,
      'is_synced': 0,
      'extra_data': jsonEncode({
        'photos': _photoPaths,
        'property_type': _propertyType,
      }),
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
      debugPrint("Save Property Error: ${e.toString()}");
      setState(() => _isSaving = false);
    }
  }
    @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.editData == null ? 'အိမ်ခြံမြေ အသစ်ထည့်ရန်' : 'အိမ်ခြံမြေ ပြင်ဆင်ရန်', style: const TextStyle(fontSize: 18)),
          actions: [
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'ခေါင်းစဉ် *', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'ခေါင်းစဉ် ထည့်ပါ' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _propertyType,
                decoration: const InputDecoration(labelText: 'အမျိုးအစား', border: OutlineInputBorder()),
                items: ['အိမ်အပါ', 'ခြံသီးသန့်'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() {
                  _propertyType = v;
                  if (v == 'ခြံသီးသန့်') _houseType = null;
                }),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _askingPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'ခေါ်ဈေး (သိန်း) *', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'ဈေးနှုန်း ထည့်ပါ' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _bottomPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'အောက်ဆုံးဈေး (သိန်း)', border: OutlineInputBorder()),
                    ),
                  ),
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

              if (_propertyType != 'ခြံသီးသန့်')
                Column(
                  children: [
                    DynamicDropdown(label: 'အိမ်အမျိုးအစား', category: 'house_type', selectedValue: _houseType, onChanged: (v) => setState(() => _houseType = v)),
                    const SizedBox(height: 16),
                  ],
                ),

              const Text('ပိုင်ရှင်အချက်အလက်', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),

              Autocomplete<Map<String, dynamic>>(
                // ⚠️ အရေးကြီး: Field ထဲတွင် ပြမည့်စာသားကို ဤနေရာက ထိန်းချုပ်သည် (ရုပ်ဆိုးသော စာသားမဝင်စေရန် raw_name ကိုသာ သုံးမည်)
                displayStringForOption: (option) => option['id'] == '__ADD_NEW__' ? option['raw_name'] : option['name'],
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) return const Iterable<Map<String, dynamic>>.empty();
                  
                  final query = textEditingValue.text.toLowerCase();
                  final matches = _owners.where((owner) {
                    return (owner['name'] as String).toLowerCase().contains(query);
                  }).toList();

                  // ရှာတွေ့သော နာမည် အတိအကျမရှိမှသာ Add New ကို ပြမည်
                  final exactMatch = _owners.any((owner) => (owner['name'] as String).toLowerCase() == query);
                  if (!exactMatch) {
                    matches.add({
                      'id': '__ADD_NEW__',
                      'name': '➕ "${textEditingValue.text}" ကို အသစ်ထည့်မည်',
                      'raw_name': textEditingValue.text
                    });
                  }
                  return matches;
                },
                onSelected: (Map<String, dynamic> selection) async {
                  if (selection['id'] == '__ADD_NEW__') {
                    setState(() => _ownerId = null);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => OwnerFormScreen(initialName: selection['raw_name'])),
                    );
                    if (result == true) {
                      await _loadOwners();
                      _ownerSearchController.clear();
                    } else {
                      _ownerSearchController.clear();
                    }
                  } else {
                    setState(() {
                      _ownerId = selection['id'];
                      _ownerSearchController.text = selection['name'];
                    });
                    FocusManager.instance.primaryFocus?.unfocus();
                  }
                },
                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                  if (_ownerSearchController.text.isNotEmpty && controller.text.isEmpty) {
                    controller.text = _ownerSearchController.text;
                  }
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: 'ပိုင်ရှင်အမည် ရှာရန် (သို့) အသစ်ရိုက်ထည့်ရန်',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.person, color: Colors.grey),
                      suffixIcon: controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                controller.clear();
                                _ownerSearchController.clear();
                                setState(() => _ownerId = null);
                              },
                            )
                          : null,
                    ),
                    onChanged: (val) {
                       _ownerSearchController.text = val;
                       if (val.isEmpty) setState(() => _ownerId = null);
                    },
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  final theme = Theme.of(context);
                  final isDark = theme.brightness == Brightness.dark;
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      color: theme.cardColor, 
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: 250, maxWidth: MediaQuery.of(context).size.width - 32),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final option = options.elementAt(index);
                            final isAddNew = option['id'] == '__ADD_NEW__';
                            return ListTile(
                              leading: Icon(
                                isAddNew ? Icons.add_circle_outline : Icons.person, 
                                color: isAddNew ? theme.colorScheme.primary : Colors.grey
                              ),
                              title: Text(
                                option['name'], 
                                style: TextStyle(
                                  color: isAddNew ? theme.colorScheme.primary : theme.textTheme.bodyLarge?.color,
                                  fontWeight: isAddNew ? FontWeight.bold : FontWeight.normal
                                )
                              ),
                              onTap: () => onSelected(option),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _mapLinkController,
                decoration: InputDecoration(
                  labelText: 'မြေပုံလင့်ခ် (Google Maps URL)',
                  border: const OutlineInputBorder(),
                  prefixIcon: IconButton(icon: const Icon(Icons.map, color: Colors.blue), tooltip: 'Google Maps ဖွင့်ရန်', onPressed: _openGoogleMaps),
                ),
              ),
              const SizedBox(height: 16),
              const Text('ဓာတ်ပုံများ:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _showImageSourceBottomSheet,
                child: Container(
                  height: 80,
                  width: double.infinity,
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, color: Colors.grey),
                      SizedBox(height: 4),
                      Text('ဓာတ်ပုံများ ထည့်ရန်', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),

              if (_photoPaths.isNotEmpty) const SizedBox(height: 16),
              if (_photoPaths.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _photoPaths.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_photoPaths[index]),
                                fit: BoxFit.cover,
                                cacheWidth: 300,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 12,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _photoPaths.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

              const SizedBox(height: 16),
              TextFormField(
                controller: _remarkController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'မှတ်ချက်', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              SafeArea(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: const Color(0xFF008080),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isSaving ? null : _saveProperty,
                  child: const Text('သိမ်းမည်', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
