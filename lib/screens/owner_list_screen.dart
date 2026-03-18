import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart'; 
import '../db/database_helper.dart';
import 'owner_form_screen.dart';

class OwnerListScreen extends StatefulWidget {
  final String? highlightOwnerId; 
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
    
    // Snackbar ရှင်းလင်းမှု စနစ်သစ်
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.clearSnackBars();
    scaffoldMessenger.showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating, 
      content: const Text('ပိုင်ရှင်စာရင်းကို ဖျက်လိုက်ပါပြီ'), 
      duration: const Duration(seconds: 3),
      action: SnackBarAction(label: 'Undo', textColor: Colors.yellow, onPressed: () async { 
        await DatabaseHelper.instance.restoreFromRecycleBin('crm_owners', owner['id']); 
        _loadOwners(); 
      })
    ));
    
    // အတင်းအကျပ် ဖျောက်ချခြင်း
    Future.delayed(const Duration(seconds: 3), () => scaffoldMessenger.hideCurrentSnackBar());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ပိုင်ရှင်စာရင်းများ', style: TextStyle(fontWeight: FontWeight.bold))),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8), itemCount: _owners.length,
        itemBuilder: (context, index) {
          final o = _owners[index];
          final isHighlighted = o['id'] == widget.highlightOwnerId;
          
          List<dynamic> phones = [];
          try { phones = jsonDecode(o['phones'] ?? '[]'); } catch (_) {}

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            // Highlight ကို ပိုပြတ်သားအောင် ဘောင်ခတ်လိုက်ပါသည်
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isHighlighted 
                  ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.5) 
                  : BorderSide.none,
            ),
            color: isHighlighted ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5) : null,
            child: ListTile(
              leading: CircleAvatar(child: const Icon(Icons.person)),
              title: Text(o['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  // ဖုန်းနံပါတ် ပြသခြင်း
                  if (phones.isNotEmpty)
                    InkWell(
                      onTap: () => launchUrl(Uri.parse('tel:${phones.first}')),
                      child: Text(phones.join(', '), style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                    )
                  else
                    const Text('ဖုန်းနံပါတ်မရှိပါ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteOwner(o)),
              onTap: () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => OwnerFormScreen(editData: o)));
                if (result == true) _loadOwners();
              },
            ),
          );
        },
      ),
    );
  }
}
