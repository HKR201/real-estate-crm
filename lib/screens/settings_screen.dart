import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../db/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;

  // --- ဒေတာအားလုံးကို JSON ဖိုင်အဖြစ် ထုတ်ယူခြင်း (Export) ---
  Future<void> _exportBackup() async {
    setState(() => _isExporting = true);
    try {
      final properties = await DatabaseHelper.instance.getAllProperties();
      final owners = await DatabaseHelper.instance.getAllOwners();
      final buyers = await DatabaseHelper.instance.getAllBuyers();

      Map<String, dynamic> backupData = {
        'version': '1.0',
        'export_date': DateTime.now().toIso8601String(),
        'properties': properties,
        'owners': owners,
        'buyers': buyers,
      };

      final String jsonString = jsonEncode(backupData);
      final directory = await getTemporaryDirectory();
      final File backupFile = File('${directory.path}/CRM_Backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await backupFile.writeAsString(jsonString);

      await Share.shareXFiles([XFile(backupFile.path)], text: 'CRM App Offline Backup');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup လုပ်၍မရပါ - $e')));
    } finally {
      setState(() => _isExporting = false);
    }
  }

  // --- Backup ဖိုင်ကို ပြန်သွင်းခြင်း (Restore) ---
  Future<void> _importBackup() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (result == null) return;

    try {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(content);

      // Database ထဲသို့ တစ်ခုချင်း ပြန်သွင်းခြင်း
      final db = await DatabaseHelper.instance.database;
      
      // ဤနေရာတွင် ရိုးရှင်းစေရန် ID တူလျှင် အဟောင်းကို ဖျက်ပြီး အသစ်သွင်းသည့်ပုံစံ သုံးမည်
      for (var p in data['properties']) await db.insert('crm_properties', p, conflictAlgorithm: ConflictAlgorithm.replace);
      for (var o in data['owners']) await db.insert('crm_owners', o, conflictAlgorithm: ConflictAlgorithm.replace);
      for (var b in data['buyers']) await db.insert('crm_buyers', b, conflictAlgorithm: ConflictAlgorithm.replace);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ဒေတာများ ပြန်သွင်းပြီးပါပြီ'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore လုပ်၍မရပါ - $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings & Sync')),
      body: ListView(
        children: [
          const ListTile(title: Text('Cloud Synchronization', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))),
          ListTile(
            leading: const Icon(Icons.cloud_upload),
            title: const Text('Manual Cloud Sync'),
            subtitle: const Text('အခုချက်ချင်း Cloud ပေါ်သို့ ဒေတာတင်မည်'),
            onTap: () {
               // Supabase Sync Logic ကို နောက်တဆင့်တွင် ထည့်ပါမည်
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cloud Sync လုပ်ဆောင်နေပါသည်...')));
            },
          ),
          const Divider(),
          const ListTile(title: Text('Offline Backup (အင်တာနက်မလိုပါ)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))),
          ListTile(
            leading: const Icon(Icons.sd_storage),
            title: const Text('Export Data (Backup)'),
            subtitle: const Text('ဒေတာများကို ဖိုင်အဖြစ် ထုတ်ယူသိမ်းဆည်းမည်'),
            onTap: _isExporting ? null : _exportBackup,
          ),
          ListTile(
            leading: const Icon(Icons.settings_backup_restore),
            title: const Text('Import Data (Restore)'),
            subtitle: const Text('သိမ်းထားသော Backup ဖိုင်မှ ဒေတာများ ပြန်သွင်းမည်'),
            onTap: _importBackup,
          ),
        ],
      ),
    );
  }
}
