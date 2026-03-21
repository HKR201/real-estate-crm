import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../db/database_helper.dart';
import '../main.dart';
import '../services/sync_service.dart'; 
import 'category_manager_screen.dart'; // ⚠️ Category Manager အသစ်ကို Import လုပ်ထားသည်

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isProcessing = false;
  String _statusMessage = "";
  String _currentTheme = 'system';

  @override
  void initState() { super.initState(); _loadCurrentTheme(); }

  void _loadCurrentTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() { _currentTheme = prefs.getString('themeMode') ?? 'system'; });
  }

  void _updateTheme(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', value);
    setState(() => _currentTheme = value);
    if (value == 'light') themeNotifier.value = ThemeMode.light;
    else if (value == 'dark') themeNotifier.value = ThemeMode.dark;
    else themeNotifier.value = ThemeMode.system;
  }

  Future<void> _startCloudSync() async {
    setState(() { _isProcessing = true; _statusMessage = "Cloud သို့ ဒေတာများ ပို့ဆောင်နေပါသည်..."; });
    try {
      await SyncService.syncAllData((msg) { setState(() => _statusMessage = msg); });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cloud ပေါ်သို့ အောင်မြင်စွာ တင်ပြီးပါပြီ'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() { _isProcessing = false; _statusMessage = ""; });
    }
  }

  Future<void> _startCloudDownload() async {
    setState(() { _isProcessing = true; _statusMessage = "Cloud မှ ဒေတာများ ရယူနေပါသည်..."; });
    try {
      await SyncService.downloadAllData((msg) { setState(() => _statusMessage = msg); });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cloud မှ အောင်မြင်စွာ ရယူပြီးပါပြီ'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() { _isProcessing = false; _statusMessage = ""; });
    }
  }

  Future<void> _exportBackup() async {
    setState(() { _isProcessing = true; _statusMessage = "Backup ထုပ်ပိုးနေပါသည်..."; });
    try {
      final db = await DatabaseHelper.instance.database;
      Map<String, dynamic> jsonData = { 'properties': await db.query('crm_properties'), 'owners': await db.query('crm_owners'), 'buyers': await db.query('crm_buyers'), 'metadata': await db.query('crm_metadata') };
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory(p.join(appDir.path, 'property_photos'));
      var encoder = ZipFileEncoder();
      final zipPath = p.join((await getTemporaryDirectory()).path, 'CRM_Full_Backup.zip');
      encoder.create(zipPath);
      final jsonFile = File(p.join((await getTemporaryDirectory()).path, 'data.json'));
      await jsonFile.writeAsString(jsonEncode(jsonData));
      encoder.addFile(jsonFile);
      if (await photosDir.exists()) encoder.addDirectory(photosDir);
      encoder.close();
      await Share.shareXFiles([XFile(zipPath)], text: 'Real Estate CRM Full Backup');
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    finally { setState(() { _isProcessing = false; _statusMessage = ""; }); }
  }

  Future<void> _importBackup() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['zip']);
    if (result == null) return;
    setState(() { _isProcessing = true; _statusMessage = "ပြန်လည်သွင်းယူနေပါသည်..."; });
    try {
      final bytes = await File(result.files.single.path!).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final appDir = await getApplicationDocumentsDirectory();
      final db = await DatabaseHelper.instance.database;
      Map<String, dynamic>? jsonData;
      for (final file in archive) {
        if (file.isFile) {
          final data = file.content as List<int>;
          if (file.name == 'data.json') jsonData = jsonDecode(utf8.decode(data));
          else if (file.name.contains('property_photos/')) {
            final f = File(p.join(appDir.path, file.name));
            await f.create(recursive: true); await f.writeAsBytes(data);
          }
        }
      }
      if (jsonData != null) {
        await db.transaction((txn) async {
          for (var k in ['properties', 'owners', 'buyers', 'metadata']) {
            if (jsonData![k] != null) { for (var item in jsonData[k]) await txn.insert('crm_$k', item, conflictAlgorithm: ConflictAlgorithm.replace); }
          }
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('အောင်မြင်စွာ ပြန်သွင်းပြီးပါပြီ'), backgroundColor: Colors.green));
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)); }
    finally { setState(() { _isProcessing = false; _statusMessage = ""; }); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Stack(
        children: [
          ListView(
            children: [
              const ListTile(title: Text('Appearance', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))),
              RadioListTile<String>(title: const Text('System Default'), value: 'system', groupValue: _currentTheme, onChanged: (v) => _updateTheme(v!)),
              RadioListTile<String>(title: const Text('Light Mode'), value: 'light', groupValue: _currentTheme, onChanged: (v) => _updateTheme(v!)),
              RadioListTile<String>(title: const Text('Dark Mode'), value: 'dark', groupValue: _currentTheme, onChanged: (v) => _updateTheme(v!)),
              
              const Divider(),
              // ⚠️ Data Management အပိုင်း အသစ်ထည့်သွင်းခြင်း
              const ListTile(title: Text('Data Management', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))),
              ListTile(
                leading: const Icon(Icons.category_outlined, color: Colors.orange),
                title: const Text('အမျိုးအစားများ စီမံရန် (Categories)'),
                subtitle: const Text('မြို့နယ်၊ လမ်း၊ အိမ် အမျိုးအစားဟောင်းများ ဖျက်ရန်'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryManagerScreen()));
                },
              ),

              const Divider(),
              const ListTile(title: Text('Data Synchronization', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))),
              ListTile(
                leading: const Icon(Icons.cloud_upload, color: Colors.teal),
                title: const Text('Upload to Cloud'),
                subtitle: const Text('ဖုန်းထဲမှ ဒေတာများကို Cloud ပေါ်သို့ တင်မည်'),
                onTap: _isProcessing ? null : _startCloudSync, 
              ),
              ListTile(
                leading: const Icon(Icons.cloud_download, color: Colors.blue),
                title: const Text('Download from Cloud (Restore)'),
                subtitle: const Text('Cloud ပေါ်မှ ဒေတာနှင့် ဓာတ်ပုံများကို ဖုန်းထဲသို့ ပြန်ယူမည်'),
                onTap: _isProcessing ? null : _startCloudDownload, 
              ),

              const Divider(),
              const ListTile(title: Text('Offline Backup', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))),
              ListTile(leading: const Icon(Icons.archive, color: Colors.grey), title: const Text('Export Backup (.zip)'), onTap: _isProcessing ? null : _exportBackup),
              ListTile(leading: const Icon(Icons.unarchive, color: Colors.grey), title: const Text('Import Backup (.zip)'), onTap: _isProcessing ? null : _importBackup),
            ],
          ),
          if (_isProcessing) 
            Container(color: Colors.black45, child: Center(child: Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [const CircularProgressIndicator(), const SizedBox(height: 10), Text(_statusMessage)]))))),
        ],
      ),
    );
  }
}
