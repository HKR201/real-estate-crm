import 'package:flutter/material.dart';

class PropertyFormScreen extends StatefulWidget {
  const PropertyFormScreen({super.key});

  @override
  State<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends State<PropertyFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // စာရိုက်ထည့်မည့် အကွက်များအတွက် မှတ်သားမည့် ကိရိယာများ
  final _titleController = TextEditingController();
  final _askingPriceController = TextEditingController();
  final _bottomPriceController = TextEditingController();
  final _eastController = TextEditingController();
  final _westController = TextEditingController();
  final _southController = TextEditingController();
  final _northController = TextEditingController();
  final _remarkController = TextEditingController();

  // ရွေးချယ်စရာ Dropdown များအတွက်
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('အိမ်ခြံမြေ အသစ်ထည့်ရန်', style: TextStyle(fontWeight: FontWeight.bold)),
        // နောက်ပြန်ဆုတ်မည့် ခလုတ် (Back Button)
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

            // ၃။ အကျယ်အဝန်း (2x2 Grid)
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

            // ၄။ လမ်းအမျိုးအစား နှင့် မြေအမျိုးအစား (Swapped Fields: Road Left, Land Right)
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

            // ၅။ ဓာတ်ပုံရွေးရန်နေရာ (UI Placeholder)
            InkWell(
              onTap: () {
                // နောက်ပိုင်းတွင် Multi-image picker လာပါမည်
              },
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

            // ၆။ မှတ်ချက် (Remark)
            TextFormField(
              controller: _remarkController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'မှတ်ချက် (ဝယ်လက် မမြင်ရပါ)'),
            ),
            const SizedBox(height: 24),

            // ၇။ သိမ်းမည် ခလုတ်
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // နောက်ပိုင်းတွင် Database သို့ သိမ်းမည့် Code လာပါမည်
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('သိမ်းဆည်းနေပါသည်...')));
                  }
                },
                child: const Text('သိမ်းမည်', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40), // ဖုန်းအောက်ခြေ Navigation Bar ဖြင့် မကွယ်စေရန်
          ],
        ),
      ),
    );
  }
}
