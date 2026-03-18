import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../db/database_helper.dart';
import '../widgets/dynamic_dropdown.dart'; // ခုနကရေးထားသော စမတ်ကျသည့် Dropdown ကို ခေါ်ယူခြင်း

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

  // ရွေးချယ်စရာများအတွက် မှတ်သားမည့် နေရာများ
  String? _location;
  String? _roadType;
  String? _landType;

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
        'road_type': _roadType,
        'land_type': _landType,
        'location_id': _location ?? 'မသိရ', // ယခု ရွေးချယ်ထားသော မြို့နယ်ကို သိမ်းမည်
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // ၁။ ခေါင်းစဉ်
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'ခေါင်းစဉ် (ဥပမာ - လှိုင် 2RC လုံးချင်းသစ်)'),
              validator: (value) => value!.isEmpty ? 'ခေါင်းစဉ် ထည့်ပေးပါ' : null,
            ),
            const SizedBox(height: 16),

            // ၂။ ဈေးနှုန်း (Side-by-side)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _askingPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'ခေါ်ဈေး (သိန်း)'),
                    validator: (value) => value!.isEmpty ? 'လိုအပ်ပါသည်' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _bottomPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'အောက်ဆုံးဈေး (သိန်း)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ၃။ မြို့နယ် / တည်နေရာ (Dynamic Dropdown အသစ်)
            DynamicDropdown(
              label: 'မြို့နယ် / တည်နေရာ',
              category: 'location',
              selectedValue: _location,
              onChanged: (value) => setState(() => _location = value),
            ),
            const SizedBox(height: 16),

            // ၄။ အကျယ်အဝန်း
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

            // ၅။ လမ်းအမျိုးအစား နှင့် မြေအမျိုးအစား (Dynamic Dropdowns)
            Row(
              children: [
                Expanded(
                  child: DynamicDropdown(
                    label: 'လမ်းအမျိုးအစား',
                    category: 'road_type',
                    selectedValue: _roadType,
                    onChanged: (value) => setState(() => _roadType = value),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DynamicDropdown(
                    label: 'မြေအမျိုးအစား',
                    category: 'land_type',
                    selectedValue: _landType,
                    onChanged: (value) => setState(() => _landType = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ၆။ ဓာတ်ပုံရွေးရန်နေရာ
            InkWell(
              onTap: () {},
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, color: Colors.grey, size: 32),
                    SizedBox(height: 8),
                    Text('ဓာတ်ပုံများ ထည့်ရန် (Max 5MB)', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ၇။ မှတ်ချက်
            TextFormField(
              controller: _remarkController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'မှတ်ချက် (ဝယ်လက် မမြင်ရပါ)'),
            ),
            const SizedBox(height: 24),

            // ၈။ သိမ်းမည် ခလုတ်
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
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
