import 'package:flutter/material.dart';
import 'dart:convert'; 
import 'package:uuid/uuid.dart';
import '../db/database_helper.dart';

class OwnerFormScreen extends StatefulWidget {
  final Map<String, dynamic>? editData; // Edit Mode အတွက် ဒေတာလက်ခံရန် နေရာ

  const OwnerFormScreen({super.key, this.editData});

  @override
  State<OwnerFormScreen> createState() => _OwnerFormScreenState();
}

class _OwnerFormScreenState extends State<OwnerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  final _nameController = TextEditingController();
  final _remarkController = TextEditingController();
  
  List<TextEditingController> _phoneControllers = [TextEditingController()];

  @override
  void initState() {
    super.initState();
    // Edit Mode ဖြစ်ပါက ယခင်ဒေတာများ ဖြည့်သွင်းမည်
    if (widget.editData != null) {
      final d = widget.editData!;
      _nameController.text = d['name'] ?? '';
      _remarkController.text = d['remark'] ?? '';
      
      try {
        List<dynamic> phones = jsonDecode(d['phones'] ?? '[]');
        if (phones.isNotEmpty) {
          _phoneControllers.clear(); // ပုံမှန်ပါနေသည့် ၁ ကွက်ကို ဖျက်မည်
          for (var p in phones) {
            _phoneControllers.add(TextEditingController(text: p.toString()));
          }
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _remarkController.dispose();
    for (var controller in _phoneControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addPhoneField() {
    setState(() {
      _phoneControllers.add(TextEditingController());
    });
  }

  void _removePhoneField(int index) {
    setState(() {
      _phoneControllers[index].dispose();
      _phoneControllers.removeAt(index);
    });
  }

  Future<void> _saveOwner() async {
    if (_formKey.currentState!.validate()) {
      final phones = _phoneControllers.map((c) => c.text.trim()).where((text) => text.isNotEmpty).toList();

      final ownerData = {
        'id': widget.editData?['id'] ?? _uuid.v4(), // အဟောင်းဆိုလျှင် ID အဟောင်းသုံးမည်
        'name': _nameController.text.trim(),
        'phones': jsonEncode(phones), 
        'remark': _remarkController.text.trim(),
        'is_deleted': 0,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (widget.editData == null) {
        // အသစ်ထည့်ခြင်း
        ownerData['created_at'] = DateTime.now().toIso8601String();
        await DatabaseHelper.instance.insertOwner(ownerData);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ပိုင်ရှင်စာရင်း အောင်မြင်စွာ သိမ်းဆည်းပြီးပါပြီ')));
      } else {
        // အဟောင်းကို ပြင်ဆင်ခြင်း
        ownerData['created_at'] = widget.editData!['created_at'];
        await DatabaseHelper.instance.updateOwner(ownerData);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ပိုင်ရှင်စာရင်း ပြင်ဆင်ပြီးပါပြီ')));
      }

      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editData == null ? 'ပိုင်ရှင်အသစ် မှတ်သားရန်' : 'ပိုင်ရှင်စာရင်း ပြင်ဆင်ရန်', style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'ပိုင်ရှင်အမည်', prefixIcon: Icon(Icons.person)),
              validator: (value) => value!.isEmpty ? 'အမည် ထည့်ပေးပါ' : null,
            ),
            const SizedBox(height: 24),

            const Text('ဖုန်းနံပါတ်များ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(), 
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
                          decoration: InputDecoration(labelText: 'ဖုန်းနံပါတ် ${index + 1}', prefixIcon: const Icon(Icons.phone)),
                        ),
                      ),
                      if (_phoneControllers.length > 1)
                        IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => _removePhoneField(index)),
                    ],
                  ),
                );
              },
            ),
            
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addPhoneField, icon: const Icon(Icons.add), label: const Text('ဖုန်းနံပါတ် ထပ်ထည့်မည်'),
                style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(controller: _remarkController, maxLines: 3, decoration: const InputDecoration(labelText: 'မှတ်ချက်', alignLabelWithHint: true)),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Theme.of(context).colorScheme.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: _saveOwner,
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
