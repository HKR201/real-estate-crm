import 'package:flutter/material.dart';
import 'dart:convert';
import '../db/database_helper.dart';
import 'owner_form_screen.dart'; // ပိုင်ရှင်အသစ်ထည့်မည့် ဖောင်ကို လှမ်းချိတ်ခြင်း

class OwnerListScreen extends StatefulWidget {
  const OwnerListScreen({super.key});

  @override
  State<OwnerListScreen> createState() => _OwnerListScreenState();
}

class _OwnerListScreenState extends State<OwnerListScreen> {
  List<Map<String, dynamic>> _owners = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOwners();
  }

  // Database ထဲမှ ပိုင်ရှင်စာရင်းများကို ဆွဲထုတ်မည်
  Future<void> _loadOwners() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllOwners();
    setState(() {
      _owners = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ပိုင်ရှင်စာရင်းများ', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _owners.isEmpty
              ? const Center(
                  child: Text('ပိုင်ရှင်စာရင်း မရှိသေးပါ။\nအပေါင်း (+) ကိုနှိပ်၍ အသစ်ထည့်ပါ။',
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)))
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: _owners.length,
                  itemBuilder: (context, index) {
                    final owner = _owners[index];
                    
                    // JSON အဖြစ် သိမ်းထားသော ဖုန်းနံပါတ်များကို List အဖြစ် ပြန်ပြောင်းယူခြင်း
                    List<dynamic> phones = [];
                    try {
                      phones = jsonDecode(owner['phones'] ?? '[]');
                    } catch (e) {
                      phones = [];
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 1,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                        ),
                        title: Text(owner['name'] ?? 'အမည်မသိ', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            // ဖုန်းနံပါတ်များကို ကော်မာ (,) ခံ၍ ပြသမည်
                            if (phones.isNotEmpty)
                              Text(phones.join(', '), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                            if ((owner['remark'] ?? '').isNotEmpty)
                              Text(owner['remark'], style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red, size: 20), // အနီရောင် ကြက်ခြေခတ် ✕
                          onPressed: () {
                            // နောက်ပိုင်းတွင် ဖျက်မည့် (Soft Delete) Code လာမည်
                          },
                        ),
                      ),
                    );
                  },
                ),
      // ပိုင်ရှင်အသစ်ထည့်ရန် ခလုတ်
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const OwnerFormScreen()),
          );
          if (result == true) {
            _loadOwners(); // အသစ်ထည့်ပြီး ပြန်လာပါက စာရင်းကို Refresh လုပ်မည်
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
