import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../db/database_helper.dart';
import '../widgets/dynamic_dropdown.dart';

class BuyerFormScreen extends StatefulWidget {
  final Map<String, dynamic>? editData; // Edit Mode အတွက်
  const BuyerFormScreen({super.key, this.editData});

  @override
  State<BuyerFormScreen> createState() => _BuyerFormScreenState();
}

class _BuyerFormScreenState extends State<BuyerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  final _nameController = TextEditingController();
  final _budgetController = TextEditingController();
  List<TextEditingController> _phoneControllers = [TextEditingController()];
  String? _preferredLocation;

  @override
  void initState() {
    super.initState();
    if (widget.editData != null) {
      final d = widget.editData!;
      _nameController.text = d['name'] ?? '';
      _budgetController.text = (d['budget_lakhs'] ?? '').toString();
      _preferredLocation = d['preferred_location'];
      try {
        List<dynamic> phones = jsonDecode(d['phones'] ?? '[]');
        if (phones.isNotEmpty) {
          _phoneControllers.clear();
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
    _budgetController.dispose();
    for (var controller in _phoneControllers) controller.dispose();
    super.dispose();
  }

  void _addPhoneField() => setState(() => _phoneControllers.add(TextEditingController()));
  void _removePhoneField(int index) => setState(() { _phoneControllers[index].dispose(); _phoneControllers.removeAt(index); });

  Future<void> _saveBuyer() async {
    if (_formKey.currentState!.validate()) {
      final phones = _phoneControllers.map((c) => c.text.trim()).where((text) => text.isNotEmpty).toList();
      final buyerData = {
        'id': widget.editData?['id'] ?? _uuid.v4(),
        'name': _nameController.text.trim(),
        'phones': jsonEncode(phones),
        'budget_lakhs': int.tryParse(_budgetController.text) ?? 0,
        'preferred_location': _preferredLocation ?? 'မသိရ',
        'is_deleted': 0,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (widget.editData == null) {
        buyerData['created_at'] = DateTime.now().toIso8601String();
        await DatabaseHelper.instance.insertBuyer(buyerData);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ဝယ်လက်စာရင်း အသစ် သိမ်းဆည်းပြီးပါပြီ')));
      } else {
        buyerData['created_at'] = widget.editData!['created_at'];
        await DatabaseHelper.instance.updateBuyer(buyerData);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ဝယ်လက်စာရင်း ပြင်ဆင်ပြီးပါပြီ')));
      }
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editData == null ? 'ဝယ်လက်အသစ် မှတ်သားရန်' : 'ဝယ်လက်စာရင်း ပြင်ဆင်ရန်', style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'ဝယ်လက်အမည်', prefixIcon: Icon(Icons.person_search)), validator: (value) => value!.isEmpty ? 'အမည် ထည့်ပေးပါ' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _budgetController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ဘတ်ဂျက် (သိန်း)', prefixIcon: Icon(Icons.account_balance_wallet))),
            const SizedBox(height: 16),
            DynamicDropdown(label: 'အဓိကရှာဖွေနေသော မြို့နယ်/နေရာ', category: 'location', selectedValue: _preferredLocation, onChanged: (value) => setState(() => _preferredLocation = value)),
            const SizedBox(height: 24),
            const Text('ဖုန်းနံပါတ်များ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _phoneControllers.length,
              itemBuilder: (context, index) {
                return Padding(padding: const EdgeInsets.only(bottom: 12.0), child: Row(children: [Expanded(child: TextFormField(controller: _phoneControllers[index], keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'ဖုန်းနံပါတ် ${index + 1}', prefixIcon: const Icon(Icons.phone)))), if (_phoneControllers.length > 1) IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => _removePhoneField(index))]));
              },
            ),
            Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: _addPhoneField, icon: const Icon(Icons.add), label: const Text('ဖုန်းနံပါတ် ထပ်ထည့်မည်'), style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary))),
            const SizedBox(height: 32),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Theme.of(context).colorScheme.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), onPressed: _saveBuyer, child: Text(widget.editData == null ? 'သိမ်းမည်' : 'ပြင်ဆင်ချက် သိမ်းမည်', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
