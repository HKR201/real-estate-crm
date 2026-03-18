import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isProcessing = false;

  Future<void> _exportBackup() async {
    setState(() => _isProcessing = true);
    try {
      final db = await DatabaseHelper.instance.database;
      final properties = await db.query('crm_properties');
      final owners = await db.query('crm_owners');
      final buyers = await db.query('crm_buyers');
      final metadata = await db.query('crm_metadata');

      Map<String, dynamic> backupData = {
        'export_date': DateTime.now().toIso8601String(),
        'properties': properties,
        'owners': owners,
        'buyers': buyers,
        'metadata': metadata,
      };

      final String jsonString = jsonEncode(backupData);
      final directory = await getTemporaryDirectory();
      final File file = File('${directory.path}/CRM_Backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);

      await Share.shareXFiles([XFile(file.path)], text: 'Real Estate CRM Backup File');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _importBackup() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (result == null) return;

    setState(() => _isProcessing = true);
    try {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(content);

      final db = await DatabaseHelper.instance.database;
      await db.transaction((txn) async {
        if (data['properties'] != null) {
          for (var item in data['properties']) await txn.insert('crm_properties', item, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        if (data['owners'] != null) {
          for (var item in data['owners']) await txn.insert('crm_owners', item, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        if (data['buyers'] != null) {
          for (var item in data['buyers']) await txn.insert('crm_buyers', item, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        if (data['metadata'] != null) {
          for (var item in data['metadata']) await txn.insert('crm_metadata', item, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ဒေတာများ အောင်မြင်စွာ ပြန်သွင်းပြီးပါပြီ'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings & Sync')),
      body: Stack(
        children: [
          ListView(
            children: [
              const ListTile(title: Text('Cloud Services', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))),
              ListTile(
                leading: const Icon(Icons.cloud_sync),
                title: const Text('Manual Cloud Sync'),
                subtitle: const Text('Supabase Cloud ပေါ်သို့ အခုချက်ချင်း ဒေတာတင်မည်'),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cloud Sync လုပ်ဆောင်ချက်ကို နောက်တစ်ဆင့်တွင် ထည့်သွင်းပေးပါမည်'))),
              ),
              const Divider(),
              const ListTile(title: Text('Offline Backup & Restore', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))),
              ListTile(
                leading: const Icon(Icons.download_for_offline, color: Colors.blue),
                title: const Text('Export Data (Backup)'),
                subtitle: const Text('ဒေတာအားလုံးကို JSON ဖိုင်အဖြစ် ထုတ်ယူမည်'),
                onTap: _isProcessing ? null : _exportBackup,
              ),
              ListTile(
                leading: const Icon(Icons.upload_file, color: Colors.orange),
                title: const Text('Import Data (Restore)'),
                subtitle: const Text('သိမ်းထားသော ဖိုင်မှ ဒေတာများ ပြန်သွင်းမည်'),
                onTap: _isProcessing ? null : _importBackup,
              ),
            ],
          ),
          if (_isProcessing) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
