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
    
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating, 
      content: const Text('ပိုင်ရှင်စာရင်းကို ဖျက်လိုက်ပါပြီ'), 
      duration: const Duration(seconds: 3),
      action: SnackBarAction(label: 'Undo', textColor: Colors.yellow, onPressed: () async { await DatabaseHelper.instance.restoreFromRecycleBin('crm_owners', owner['id']); _loadOwners(); })
    ));

    Future.delayed(const Duration(seconds: 3), () { if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar(); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ပိုင်ရှင်စာရင်းများ', style: TextStyle(fontWeight: FontWeight.bold))),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
        padding: const EdgeInsets.all(8), itemCount: _owners.length,
        itemBuilder: (context, index) {
          final o = _owners[index];
          final isHighlighted = o['id'] == widget.highlightOwnerId;
          return Card(
            color: isHighlighted ? Colors.teal.shade50 : null,
            child: ListTile(
              title: Text(o['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
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
