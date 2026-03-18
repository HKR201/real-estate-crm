import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // ID အသစ်များ ဖန်တီးရန်
import '../db/database_helper.dart'; // Database နှင့် ချိတ်ဆက်ရန်

class PropertyFormScreen extends StatefulWidget {
  const PropertyFormScreen({super.key});

  @override
  State<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends State<PropertyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid(); // ID ထုတ်ပေးမည့် စက်လေး

  final _titleController = TextEditingController();
  final _askingPriceController = TextEditingController();
  final _bottomPriceController = TextEditingController();
  final _eastController = TextEditingController();
  final _westController = TextEditingController();
  final _southController = TextEditingController();
  final _northController = TextEditingController();
  final _remarkController = TextEditingController();

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

  // Database ထဲသို့ သိမ်းမည့် Function
  Future<void> _saveProperty() async {
    if (_formKey.currentState!.validate()) {
      // ၁။ ယူရမည့် ဒေတာများကို Map (အုပ်စု) အနေဖြင့် စုစည်းခြင်း
      final newProperty = {
        'id': _uuid.v4(), // မထပ်သော ID အသစ် ဖန်တီးခြင်း
        'title': _titleController.text,
        'asking_price_lakhs': int.tryParse(_askingPriceController.text) ?? 0,
        'bottom_price_lakhs': int.tryParse(_bottomPriceController.text),
        'status': 'Available', // ပုံမှန်အားဖြင့် ရောင်းရန်ရှိသည် ဟု သတ်မှတ်မည်
        'east_ft': int.tryParse(_eastController.text),
        'west_ft': int.tryParse(_westController.text),
        'south_ft': int.tryParse(_southController.text),
        'north_ft': int.tryParse(_northController.text),
        'road_type': _roadType,
        'land_type': _landType,
        'location_id': 'ရန်ကုန်', // လောလောဆယ် Default အနေဖြင့် ထားပါမည် (နောက်မှ Location ရွေးရန် ထည့်မည်)
        'remark': _remarkController.text,
        'is_deleted': 0, // 0 = မဖျက်ရသေးပါ
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // ၂။ DatabaseHelper ကိုလှမ်းခေါ်ပြီး Save လုပ်ခိုင်းခြင်း
      await DatabaseHelper.instance.insertProperty(newProperty);

      // ၃။ ပီးလျှင် အောင်မြင်ကြောင်း စာတန်းလေးပြပြီး Home သို့ ပြန်ထွက်ခြင်း
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('အိမ်ခြံမြေစာရင်း အောင်မြင်စွာ သိမ်းဆည်းပြီးပါပြီ')),
        );
        Navigator.pop(context, true); // true ဟု ပြန်ပို့ခြင်းသည် Home စာမျက်နှာကို Refresh လုပ်ရန် အချက်ပြခြင်းဖြစ်သည်
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
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'ခေါင်းစဉ် (ဥပမာ - လှိုင် 2RC လုံးချင်းသစ်)'),
              validator: (value) => value!.isEmpty ? 'ခေါင်းစဉ် ထည့်ပေးပါ' : null,
            ),
            const SizedBox(height: 16),

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
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'လမ်းအမျိုးအစား'),
                    items: ['ကွန်ကရစ်လမ်း', 'ကတ္တရာလမ်း', 'မြေသားလမ်း'].map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value, overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: (newValue) => setState(() => _roadType = newValue),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'မြေအမျိုးအစား'),
                    items: ['ဂရန်မြေ', 'ရွာမြေ', 'ပါမစ်မြေ'].map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value, overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: (newValue) => setState(() => _landType = newValue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

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

            TextFormField(
              controller: _remarkController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'မှတ်ချက် (ဝယ်လက် မမြင်ရပါ)'),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                // ခလုတ်နှိပ်လျှင် အပေါ်တွင်ရေးထားသော Database သို့သိမ်းမည့် Function ကို ခေါ်မည်
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
