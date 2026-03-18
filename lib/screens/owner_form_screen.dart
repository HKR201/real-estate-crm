import 'package:flutter/material.dart';
import 'dart:convert'; // List ကို JSON ပြောင်းရန်
import 'package:uuid/uuid.dart';
import '../db/database_helper.dart';

class OwnerFormScreen extends StatefulWidget {
  const OwnerFormScreen({super.key});

  @override
  State<OwnerFormScreen> createState() => _OwnerFormScreenState();
}

class _OwnerFormScreenState extends State<OwnerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  final _nameController = TextEditingController();
  final _remarkController = TextEditingController();
  
  // ဖုန်းနံပါတ်များအတွက် Controllers များကို List အနေဖြင့် သိမ်းထားမည် (အစပိုင်းတွင် အကွက် ၁ ခု အသင့်ပါမည်)
  final List<TextEditingController> _phoneControllers = [TextEditingController()];

  @override
  void dispose() {
    _nameController.dispose();
    _remarkController.dispose();
    for (var controller in _phoneControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // ဖုန်းနံပါတ်အကွက် အသစ်တိုးရန်
  void _addPhoneField() {
    setState(() {
      _phoneControllers.add(TextEditingController());
    });
  }

  // ဖုန်းနံပါတ်အကွက်ကို ပြန်ဖျက်ရန်
  void _removePhoneField(int index) {
    setState(() {
      _phoneControllers[index].dispose();
      _phoneControllers.removeAt(index);
    });
  }

  // Database သို့ သိမ်းမည်
  Future<void> _saveOwner() async {
    if (_formKey.currentState!.validate()) {
      // ၁။ ရိုက်ထည့်ထားသော ဖုန်းနံပါတ်များထဲမှ အလွတ် (Blank) များကို ဖယ်ရှားပြီး စုစည်းမည်
      final phones = _phoneControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      // ၂။ ဒေတာစုစည်းမည်
      final newOwner = {
        'id': _uuid.v4(),
        'name': _nameController.text.trim(),
        'phones': jsonEncode(phones), // SQLite တွင် TEXT အဖြစ် သိမ်းရန် JSON string အဖြစ် ပြောင်းသည်
        'remark': _remarkController.text.trim(),
        'is_deleted': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // ၃။ Database သို့ သိမ်းမည်
      await DatabaseHelper.instance.insertOwner(newOwner);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ပိုင်ရှင်စာရင်း အောင်မြင်စွာ သိမ်းဆည်းပြီးပါပြီ')),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ပိုင်ရှင်အသစ် မှတ်သားရန်', style: TextStyle(fontWeight: FontWeight.bold)),
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
            // ၁။ အမည်
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'ပိုင်ရှင်အမည်',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) => value!.isEmpty ? 'အမည် ထည့်ပေးပါ' : null,
            ),
            const SizedBox(height: 24),

            // ၂။ ဖုန်းနံပါတ်များ (Dynamic List)
            const Text('ဖုန်းနံပါတ်များ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(), // အတွင်းဘက်တွင် လွတ်လပ်စွာ Scroll မလုပ်ရန်
              itemCount: _phoneControllers.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _phoneControllers[index],
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'ဖုန်းနံပါတ် ${index + 1}',
                            prefixIcon: const Icon(Icons.phone),
                          ),
                        ),
                      ),
                      // ပထမဆုံး အကွက်မဟုတ်လျှင် ဖျက်သည့် ကြက်ခြေခတ် ခလုတ်ပြမည်
                      if (_phoneControllers.length > 1)
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => _removePhoneField(index),
                        ),
                    ],
                  ),
                );
              },
            ),
            
            // ဖုန်းနံပါတ် အသစ်ထပ်ထည့်ရန် ခလုတ်
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addPhoneField,
                icon: const Icon(Icons.add),
                label: const Text('ဖုန်းနံပါတ် ထပ်ထည့်မည်'),
                style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary),
              ),
            ),
            const SizedBox(height: 16),

            // ၃။ မှတ်ချက်
            TextFormField(
              controller: _remarkController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'မှတ်ချက်',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),

            // ၄။ သိမ်းမည် ခလုတ်
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _saveOwner,
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
