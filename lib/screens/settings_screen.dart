import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart';
import 'package:archive/archive_io.dart'; // Zip library
import 'package:path/path.dart' as p;
import '../db/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isProcessing = false;
  String _statusMessage = "";

  // --- ဒေတာရော၊ ဓာတ်ပုံရော Zip အဖြစ် ထုတ်ယူခြင်း ---
  Future<void> _exportBackup() async {
    setState(() { _isProcessing = true; _statusMessage = "Backup ထုပ်ပိုးနေပါသည်..."; });
    try {
      final db = await DatabaseHelper.instance.database;
      final properties = await db.query('crm_properties');
      final owners = await db.query('crm_owners');
      final buyers = await db.query('crm_buyers');
      final metadata = await db.query('crm_metadata');

      Map<String, dynamic> jsonData = {
        'properties': properties,
        'owners': owners,
        'buyers': buyers,
        'metadata': metadata,
      };

      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory(p.join(appDir.path, 'property_photos'));
      
      // Zip ထုပ်ပိုးရန် ပြင်ဆင်ခြင်း
      var encoder = ZipFileEncoder();
      final zipPath = p.join((await getTemporaryDirectory()).path, 'CRM_Full_Backup_${DateTime.now().millisecondsSinceEpoch}.zip');
      encoder.create(zipPath);

      // ၁။ JSON ဒေတာဖိုင်ကို ထည့်မည်
      final jsonFile = File(p.join((await getTemporaryDirectory()).path, 'data.json'));
      await jsonFile.writeAsString(jsonEncode(jsonData));
      encoder.addFile(jsonFile);

      // ၂။ ဓာတ်ပုံများရှိလျှင် ဓာတ်ပုံ Folder တစ်ခုလုံးကို ထည့်မည်
      if (await photosDir.exists()) {
        encoder.addDirectory(photosDir);
      }

      encoder.close();
      await Share.shareXFiles([XFile(zipPath)], text: 'Real Estate CRM Full Backup (Images Included)');

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() { _isProcessing = false; _statusMessage = ""; });
    }
  }

  // --- Zip Backup ဖိုင်ကို ပြန်သွင်းခြင်း ---
  Future<void> _importBackup() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['zip']);
    if (result == null) return;

    setState(() { _isProcessing = true; _statusMessage = "ဒေတာများ ပြန်သွင်းနေပါသည်..."; });
    try {
      final bytes = await File(result.files.single.path!).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final appDir = await getApplicationDocumentsDirectory();
      final db = await DatabaseHelper.instance.database;
      Map<String, dynamic>? jsonData;

      // Zip ထဲက ဖိုင်တွေကို တစ်ခုချင်း ပြန်ထုတ်မည်
      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          
          if (filename == 'data.json') {
            jsonData = jsonDecode(utf8.decode(data));
          } else if (filename.contains('property_photos/')) {
            // ဓာတ်ပုံဖိုင်များကို property_photos folder ထဲသို့ ပြန်ထည့်မည်
            final String relativePath = filename; // e.g. property_photos/123.jpg
            final File f = File(p.join(appDir.path, relativePath));
            await f.create(recursive: true);
            await f.writeAsBytes(data);
          }
        }
      }

      // Database ထဲသို့ ဒေတာများ သွင်းမည်
      if (jsonData != null) {
        await db.transaction((txn) async {
          if (jsonData!['properties'] != null) {
            for (var item in jsonData['properties']) {
              var mutableItem = Map<String, dynamic>.from(item);
              // မှတ်ချက် - ဖုန်းအသစ်မှာ App Path ပြောင်းနိုင်သဖြင့် Path ကို Update လုပ်ရန် လိုအပ်နိုင်သည်
              await txn.insert('crm_properties', mutableItem, conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
          if (jsonData['owners'] != null) {
            for (var item in jsonData['owners']) await txn.insert('crm_owners', item, conflictAlgorithm: ConflictAlgorithm.replace);
          }
          if (jsonData['buyers'] != null) {
            for (var item in jsonData['buyers']) await txn.insert('crm_buyers', item, conflictAlgorithm: ConflictAlgorithm.replace);
          }
          if (jsonData['metadata'] != null) {
            for (var item in jsonData['metadata']) await txn.insert('crm_metadata', item, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ဒေတာနှင့် ဓာတ်ပုံများ အားလုံး ပြန်သွင်းပြီးပါပြီ'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() { _isProcessing = false; _statusMessage = ""; });
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
              const ListTile(title: Text('Full Offline Backup (ဓာတ်ပုံများပါဝင်သည်)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))),
              ListTile(
                leading: const Icon(Icons.archive, color: Colors.blue),
                title: const Text('Export Full Backup (.zip)'),
                subtitle: const Text('ဒေတာနှင့် ဓာတ်ပုံများအားလုံးကို Zip ထုပ်၍ သိမ်းမည်'),
                onTap: _isProcessing ? null : _exportBackup,
              ),
              ListTile(
                leading: const Icon(Icons.unarchive, color: Colors.orange),
                title: const Text('Import Full Backup (.zip)'),
                subtitle: const Text('Zip ဖိုင်မှ ဒေတာနှင့် ဓာတ်ပုံများ ပြန်သွင်းမည်'),
                onTap: _isProcessing ? null : _importBackup,
              ),
            ],
          ),
          if (_isProcessing) 
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(_statusMessage),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
