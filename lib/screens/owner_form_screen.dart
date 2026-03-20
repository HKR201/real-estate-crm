import 'package:flutter/material.dart';
import '../db/database_helper.dart';

class OwnerFormScreen extends StatefulWidget {
  final Map<String, dynamic>? editData;
  final String? initialName;

  const OwnerFormScreen({super.key, this.editData, this.initialName});

  @override
  State<OwnerFormScreen> createState() => _OwnerFormScreenState();
}

class _OwnerFormScreenState extends State<OwnerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialName != null) {
      _nameController.text = widget.initialName!;
    }
    if (widget.editData != null) {
      _nameController.text = widget.editData!['name'] ?? '';
      // ⚠️ Database မှန်ကန်စေရန် phone ဟု ပြန်ပြင်ထားသည်
      _phoneController.text = widget.editData!['phone'] ?? '';
      _addressController.text = widget.editData!['address'] ?? '';
      _remarkController.text = widget.editData!['remark'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _saveOwner() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    Map<String, dynamic> data = {
      'id': widget.editData?['id'] ?? 'own_${DateTime.now().millisecondsSinceEpoch}',
      'name': _nameController.text.trim(),
      // ⚠️ Database မှန်ကန်စေရန် phone ဟု ပြန်ပြင်ထားသည်
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'remark': _remarkController.text.trim(),
      'is_deleted': 0,
      'is_synced': 0,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      if (widget.editData == null) {
        data['created_at'] = DateTime.now().toUtc().toIso8601String();
        await DatabaseHelper.instance.insertOwner(data);
      } else {
        data['created_at'] = widget.editData!['created_at'];
        await DatabaseHelper.instance.updateOwner(data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Save Owner Error: $e");
      if (mounted) {
        // ⚠️ Error တက်ပါက ချက်ချင်းသိနိုင်ရန် ပြသပေးမည်
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('သိမ်းဆည်းရန် မအောင်မြင်ပါ: $e')));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.editData == null ? 'ပိုင်ရှင်အသစ် ထည့်ရန်' : 'ပိုင်ရှင်အချက်အလက် ပြင်ရန်'),
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
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'ပိုင်ရှင်အမည် *', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'အမည် ထည့်ပါ' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: 'ဖုန်းနံပါတ် (တစ်ခုထက်ပိုပါက , သို့ / ခြား၍ရေးပါ)', 
                  border: OutlineInputBorder(),
                  hintText: 'ဥပမာ - 09123456, 09789012',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'နေရပ်လိပ်စာ', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _remarkController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'မှတ်ချက်', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color(0xFF2E6561), // Main Theme Color အတိုင်း ညှိထားသည်
                  foregroundColor: Colors.white,
                ),
                onPressed: _isSaving ? null : _saveOwner,
                child: const Text('သိမ်းမည်', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
