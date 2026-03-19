import 'package:flutter/material.dart';
import '../db/database_helper.dart';

class OwnerFormScreen extends StatefulWidget {
  final Map<String, dynamic>? editData;
  final String? initialName; // ⚠️ အသစ်ထပ်တိုးထားသော Parameter
  
  const OwnerFormScreen({super.key, this.editData, this.initialName});

  @override
  State<OwnerFormScreen> createState() => _OwnerFormScreenState();
}

// ⚠️ Keyboard Bug ရှင်းရန် WidgetsBindingObserver ကို သုံးထားသည်
class _OwnerFormScreenState extends State<OwnerFormScreen> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // App အဝင်/အထွက် စောင့်ကြည့်မည်

    if (widget.editData != null) {
      _nameController.text = widget.editData!['name'] ?? '';
      _remarkController.text = widget.editData!['remark'] ?? '';
      // ဖုန်းနံပါတ်များ
      try {
        final phones = widget.editData!['phones'];
        if (phones != null && phones.toString().length > 2) {
          _phoneController.text = phones.toString().replaceAll('[', '').replaceAll(']', '').replaceAll('"', '');
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    } else if (widget.initialName != null) {
      // ⚠️ Property Form မှ ရိုက်လက်စ နာမည်ပါလာပါက အလိုလို ဖြည့်ပေးမည်
      _nameController.text = widget.initialName!;
    }
  }

  // 1. Memory Management (Critical)
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    _phoneController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  // ⚠️ အခြား App သို့ ထွက်သွားပါက Keyboard ကို အလိုလို ဖြုတ်ချမည် (ပြန်ဝင်လာလျှင် Keyboard Error မတက်စေရန်)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  Future<void> _saveOwner() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    List<String> phoneList = _phoneController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    Map<String, dynamic> data = {
      'id': widget.editData?['id'] ?? 'owner_${DateTime.now().millisecondsSinceEpoch}',
      'name': _nameController.text.trim(),
      'phones': '["${phoneList.join('","')}"]',
      'remark': _remarkController.text.trim(),
      'is_deleted': 0,
      'is_synced': 0,
      'updated_at': DateTime.now().toUtc().toIso8601String(), // Last edit time
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
      debugPrint("Owner Save Error: ${e.toString()}");
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.editData == null ? 'ပိုင်ရှင်အသစ် ထည့်ရန်' : 'ပိုင်ရှင်အချက်အလက် ပြင်ရန်', style: const TextStyle(fontSize: 18)),
          actions: [ if (_isSaving) const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))) ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'အမည် *', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'အမည် ထည့်ပါ' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'ဖုန်းနံပါတ် (ခွဲရေးရန် ကော်မာခံပါ)', border: OutlineInputBorder()),
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
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: const Color(0xFF008080), foregroundColor: Colors.white),
                  onPressed: _isSaving ? null : _saveOwner,
                  child: const Text('သိမ်းမည်', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
