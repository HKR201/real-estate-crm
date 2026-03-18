import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../db/database_helper.dart';
import '../widgets/dynamic_dropdown.dart';
import 'owner_form_screen.dart'; // ပိုင်ရှင်အသစ် ထည့်ရန် ဖောင်ကို လှမ်းချိတ်ထားသည်

class PropertyFormScreen extends StatefulWidget {
  const PropertyFormScreen({super.key});

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

  String? _location;
  String? _houseType; // အိမ်အမျိုးအစား (အသစ်)
  String? _roadType;
  String? _landType;

  // ပိုင်ရှင်မှတ်သားရန် (အသစ်)
  String? _selectedOwnerId;
  String? _selectedOwnerName;

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
    super.dispose();
  }

  // --- ပိုင်ရှင်ရွေးချယ်မည့် Bottom Sheet ကို ခေါ်ရန် ---
  void _showOwnerSelectionSheet(BuildContext context) async {
    List<Map<String, dynamic>> owners = await DatabaseHelper.instance.getAllOwners();
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return _OwnerSelectionSheet(
          initialOwners: owners,
          onOwnerSelected: (id, name) {
            setState(() {
              _selectedOwnerId = id;
              _selectedOwnerName = name;
            });
          },
        );
      },
    );
  }

  Future<void> _saveProperty() async {
    if (_formKey.currentState!.validate()) {
      final newProperty = {
        'id': _uuid.v4(),
        'title': _titleController.text,
        'asking_price_lakhs': int.tryParse(_askingPriceController.text) ?? 0,
        'bottom_price_lakhs': int.tryParse(_bottomPriceController.text),
        'status': 'Available',
        'east_ft': int.tryParse(_eastController.text),
        'west_ft': int.tryParse(_westController.text),
        'south_ft': int.tryParse(_southController.text),
        'north_ft': int.tryParse(_northController.text),
        'house_type': _houseType, // အိမ်အမျိုးအစား သိမ်းမည်
        'road_type': _roadType,
        'land_type': _landType,
        'location_id': _location ?? 'မသိရ',
        'owner_id': _selectedOwnerId, // ရွေးချယ်ထားသော ပိုင်ရှင် ID သိမ်းမည်
        'remark': _remarkController.text,
        'is_deleted': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await DatabaseHelper.instance.insertProperty(newProperty);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('အိမ်ခြံမြေစာရင်း အောင်မြင်စွာ သိမ်းဆည်းပြီးပါပြီ')),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('အိမ်ခြံမြေ အသစ်ထည့်ရန်', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'ခေါင်းစဉ် (ဥပမာ - လှိုင် 2RC လုံးချင်းသစ်)'),
              validator: (value) => value!.isEmpty ? 'ခေါင်းစဉ် ထည့်ပေးပါ' : null,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(child: TextFormField(controller: _askingPriceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ခေါ်ဈေး (သိန်း)'), validator: (value) => value!.isEmpty ? 'လိုအပ်ပါသည်' : null)),
                const SizedBox(width: 16),
                Expanded(child: TextFormField(controller: _bottomPriceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'အောက်ဆုံးဈေး (သိန်း)'))),
              ],
            ),
            const SizedBox(height: 16),

            DynamicDropdown(label: 'မြို့နယ် / တည်နေရာ', category: 'location', selectedValue: _location, onChanged: (value) => setState(() => _location = value)),
            const SizedBox(height: 16),
            
            // --- အိမ်အမျိုးအစား အသစ်ထည့်သွင်းခြင်း ---
            DynamicDropdown(label: 'အိမ်/မြေ အမျိုးအစား', category: 'house_type', selectedValue: _houseType, onChanged: (value) => setState(() => _houseType = value)),
            const SizedBox(height: 16),

            const Text('အကျယ်အဝန်း (ပေ)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextFormField(controller: _eastController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'အရှေ့ (East)'))),
                const SizedBox(width: 16),
                Expanded(child: TextFormField(controller: _westController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'အနောက် (West)'))),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextFormField(controller: _southController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'တောင် (South)'))),
                const SizedBox(width: 16),
                Expanded(child: TextFormField(controller: _northController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'မြောက် (North)'))),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(child: DynamicDropdown(label: 'လမ်းအမျိုးအစား', category: 'road_type', selectedValue: _roadType, onChanged: (value) => setState(() => _roadType = value))),
                const SizedBox(width: 16),
                Expanded(child: DynamicDropdown(label: 'မြေအမျိုးအစား', category: 'land_type', selectedValue: _landType, onChanged: (value) => setState(() => _landType = value))),
              ],
            ),
            const SizedBox(height: 24),

            // --- ပိုင်ရှင်ရွေးချယ်သည့် နေရာ (အသစ်) ---
            const Text('ပိုင်ရှင်အချက်အလက်', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _showOwnerSelectionSheet(context),
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'ပိုင်ရှင်',
                  prefixIcon: const Icon(Icons.person),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  _selectedOwnerName ?? 'ပိုင်ရှင် ရွေးချယ်ပါ (သို့) အသစ်ထည့်ပါ',
                  style: TextStyle(color: _selectedOwnerName == null ? Colors.grey : Theme.of(context).colorScheme.onSurface, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            InkWell(
              onTap: () {},
              child: Container(
                height: 100, decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade400)),
                child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, color: Colors.grey, size: 32), SizedBox(height: 8), Text('ဓာတ်ပုံများ ထည့်ရန် (Max 5MB)', style: TextStyle(color: Colors.grey))]),
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
                child: const Text('သိမ်းမည်', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ပိုင်ရှင်ရွေးချယ်ရန် ပွင့်လာမည့် Bottom Sheet (Search & Add New ပါဝင်သည်)
// ============================================================================
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
  void initState() {
    super.initState();
    owners = widget.initialOwners;
  }

  // ပိုင်ရှင်အသစ်ထည့်ရန် Owner Form သို့ သွားမည်
  void _goToAddOwner() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const OwnerFormScreen()));
    
    if (result == true) {
      // အသစ်ထည့်ပြီး ပြန်လာပါက Database ကို ပြန်ဆွဲထုတ်မည်
      final updatedOwners = await DatabaseHelper.instance.getAllOwners();
      if (mounted) {
        setState(() {
          owners = updatedOwners;
        });
        // နောက်ဆုံးထည့်ထားသော ပိုင်ရှင်ကို အလိုအလျောက် ရွေးချယ်ပေးလိုက်မည် (orderBy created_at DESC ဖြစ်သောကြောင့် ပထမဆုံးအကောင်ဖြစ်သည်)
        if (owners.isNotEmpty) {
          widget.onOwnerSelected(owners.first['id'], owners.first['name']);
          Navigator.pop(context); // Sheet ကို ပိတ်မည်
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ရှာဖွေမှု စစ်ထုတ်ခြင်း
    final filteredOwners = owners.where((o) => (o['name'] as String).toLowerCase().contains(_searchController.text.toLowerCase())).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 24, left: 16, right: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ပိုင်ရှင် ရွေးချယ်ရန်', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          TextField(
            controller: _searchController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'အမည်ဖြင့် ရှာဖွေရန်', prefixIcon: Icon(Icons.search)),
            onChanged: (v) => setState(() {}),
          ),
          const SizedBox(height: 16),
          
          // ပိုင်ရှင်အသစ်ထည့်ရန် ခလုတ် (အမြဲပေါ်နေမည်)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white),
              onPressed: _goToAddOwner,
              icon: const Icon(Icons.person_add),
              label: const Text('ပိုင်ရှင်အသစ် ထည့်မည် (+)'),
            ),
          ),
          const SizedBox(height: 8),
            
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filteredOwners.length,
              itemBuilder: (context, index) {
                final owner = filteredOwners[index];
                List<dynamic> phones = [];
                try { phones = jsonDecode(owner['phones'] ?? '[]'); } catch (_) {}

                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(owner['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: phones.isNotEmpty ? Text(phones.first.toString()) : null,
                  onTap: () {
                    widget.onOwnerSelected(owner['id'], owner['name']);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
