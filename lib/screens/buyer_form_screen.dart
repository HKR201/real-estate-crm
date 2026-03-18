import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../db/database_helper.dart';
import '../widgets/dynamic_dropdown.dart'; // မြို့နယ်ရွေးရန်အတွက်

class BuyerFormScreen extends StatefulWidget {
  const BuyerFormScreen({super.key});

  @override
  State<BuyerFormScreen> createState() => _BuyerFormScreenState();
}

class _BuyerFormScreenState extends State<BuyerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  final _nameController = TextEditingController();
  final _budgetController = TextEditingController(); // ဘတ်ဂျက်အတွက်
  final List<TextEditingController> _phoneControllers = [TextEditingController()];
  
  String? _preferredLocation; // နှစ်သက်သော မြို့နယ်

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    for (var controller in _phoneControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addPhoneField() {
    setState(() => _phoneControllers.add(TextEditingController()));
  }

  void _removePhoneField(int index) {
    setState(() {
      _phoneControllers[index].dispose();
      _phoneControllers.removeAt(index);
    });
  }

  Future<void> _saveBuyer() async {
    if (_formKey.currentState!.validate()) {
      final phones = _phoneControllers.map((c) => c.text.trim()).where((text) => text.isNotEmpty).toList();

      final newBuyer = {
        'id': _uuid.v4(),
        'name': _nameController.text.trim(),
        'phones': jsonEncode(phones),
        'budget_lakhs': int.tryParse(_budgetController.text) ?? 0,
        'preferred_location': _preferredLocation ?? 'မသိရ',
        'is_deleted': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await DatabaseHelper.instance.insertBuyer(newBuyer);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ဝယ်လက်စာရင်း အောင်မြင်စွာ သိမ်းဆည်းပြီးပါပြီ')),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ဝယ်လက်အသစ် မှတ်သားရန်', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // ဝယ်လက်အမည်
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'ဝယ်လက်အမည်', prefixIcon: Icon(Icons.person_search)),
              validator: (value) => value!.isEmpty ? 'အမည် ထည့်ပေးပါ' : null,
            ),
            const SizedBox(height: 16),

            // ဘတ်ဂျက်
            TextFormField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'ဘတ်ဂျက် (သိန်း)', prefixIcon: Icon(Icons.account_balance_wallet)),
            ),
            const SizedBox(height: 16),

            // နှစ်သက်သော မြို့နယ် (Dynamic Dropdown)
            DynamicDropdown(
              label: 'အဓိကရှာဖွေနေသော မြို့နယ်/နေရာ',
              category: 'location',
              selectedValue: _preferredLocation,
              onChanged: (value) => setState(() => _preferredLocation = value),
            ),
            const SizedBox(height: 24),

            // ဖုန်းနံပါတ်များ
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
            const SizedBox(height: 32),

            // သိမ်းမည် ခလုတ်
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _saveBuyer,
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
