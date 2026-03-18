import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart'; 
import '../db/database_helper.dart';
import 'owner_form_screen.dart';

class OwnerListScreen extends StatefulWidget {
  final String? highlightOwnerId; // <--- Redirect လုပ်လာပါက ပြသမည့် ပိုင်ရှင် ID
  const OwnerListScreen({super.key, this.highlightOwnerId});

  @override
  State<OwnerListScreen> createState() => _OwnerListScreenState();
}

class _OwnerListScreenState extends State<OwnerListScreen> {
  List<Map<String, dynamic>> _owners = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _loadOwners(); }

  Future<void> _loadOwners() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllOwners();
    setState(() { _owners = List<Map<String, dynamic>>.from(data); _isLoading = false; });
  }

  void _deleteOwner(Map<String, dynamic> owner) async {
    setState(() => _owners.removeWhere((o) => o['id'] == owner['id']));
    await DatabaseHelper.instance.moveToRecycleBin('crm_owners', owner['id']);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating, // <--- Floating ဖြစ်အောင် ပြင်ထားသည်
      content: const Text('ပိုင်ရှင်စာရင်းကို ဖျက်လိုက်ပါပြီ'), 
      duration: const Duration(seconds: 4), 
      action: SnackBarAction(label: 'Undo (ပြန်ယူမည်)', textColor: Colors.yellow, onPressed: () async { await DatabaseHelper.instance.restoreFromRecycleBin('crm_owners', owner['id']); _loadOwners(); })
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ပိုင်ရှင်စာရင်းများ', style: TextStyle(fontWeight: FontWeight.bold))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _owners.isEmpty
              ? const Center(child: Text('ပိုင်ရှင်စာရင်း မရှိသေးပါ။\nအပေါင်း (+) ကိုနှိပ်၍ အသစ်ထည့်ပါ။', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)))
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80), itemCount: _owners.length,
                  itemBuilder: (context, index) {
                    final owner = _owners[index];
                    List<dynamic> phones = []; try { phones = jsonDecode(owner['phones'] ?? '[]'); } catch (_) {}
                    
                    // Highlight လုပ်ရမည့် ပိုင်ရှင်ဖြစ်မဖြစ် စစ်ဆေးခြင်း
                    final isHighlighted = owner['id'] == widget.highlightOwnerId;

                    return Card(
                      color: isHighlighted ? Theme.of(context).colorScheme.primaryContainer : null, // <--- Highlight အရောင်ပြောင်းမည်
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: isHighlighted ? 4 : 1,
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1), child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary)),
                        title: Text(owner['name'] ?? 'အမည်မသိ', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            if (phones.isNotEmpty)
                              InkWell(
                                onTap: () => launchUrl(Uri.parse('tel:${phones.first}')), 
                                child: Text(phones.join(', '), style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontWeight: FontWeight.w600)),
                              ),
                            if ((owner['remark'] ?? '').isNotEmpty) Text(owner['remark'], style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary, size: 20),
                              onPressed: () async {
                                final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => OwnerFormScreen(editData: owner)));
                                if (result == true) _loadOwners();
                              },
                            ),
                            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => _deleteOwner(owner)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Theme.of(context).colorScheme.onPrimary, onPressed: () async { final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const OwnerFormScreen())); if (result == true) _loadOwners(); }, child: const Icon(Icons.add)),
    );
  }
}
