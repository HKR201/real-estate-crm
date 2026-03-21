import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../db/database_helper.dart';

class SyncService {
  static final _supabase = Supabase.instance.client;

  static Future<void> autoSyncBackground() async {
    final db = await DatabaseHelper.instance.database;
    try {
      final unsyncedProps = await db.query('crm_properties', where: 'is_synced = 0');
      for (var row in unsyncedProps) {
        var cloudRow = Map<String, dynamic>.from(row);
        cloudRow.remove('is_synced'); 
        
        if (cloudRow['extra_data'] != null) {
          try {
            final extraData = jsonDecode(cloudRow['extra_data'] as String);
            if (extraData['photos'] != null) {
              List<String> photoNames = List<String>.from(extraData['photos']);
              for (String fileName in photoNames) await _uploadPhoto(fileName);
            }
          } catch (_) {}
        }
        await _supabase.from('crm_properties').upsert(cloudRow);
        await db.update('crm_properties', {'is_synced': 1}, where: 'id = ?', whereArgs: [row['id']]);
      }

      final unsyncedOwners = await db.query('crm_owners', where: 'is_synced = 0');
      for (var row in unsyncedOwners) {
        var cloudRow = Map<String, dynamic>.from(row); cloudRow.remove('is_synced');
        await _supabase.from('crm_owners').upsert(cloudRow);
        await db.update('crm_owners', {'is_synced': 1}, where: 'id = ?', whereArgs: [row['id']]);
      }

      final unsyncedBuyers = await db.query('crm_buyers', where: 'is_synced = 0');
      for (var row in unsyncedBuyers) {
        var cloudRow = Map<String, dynamic>.from(row); cloudRow.remove('is_synced');
        await _supabase.from('crm_buyers').upsert(cloudRow);
        await db.update('crm_buyers', {'is_synced': 1}, where: 'id = ?', whereArgs: [row['id']]);
      }
    } catch (e) {
      debugPrint("Auto Sync Failed: $e");
    }
  }

  static Future<void> syncAllData(Function(String) onProgress) async {
    await autoSyncBackground(); 
    onProgress("ဒေတာများ အောင်မြင်စွာ ပို့ဆောင်ပြီးပါပြီ");
  }

  static Future<void> _uploadPhoto(String fileName) async {
    final appDir = await getApplicationDocumentsDirectory();
    final file = File('${appDir.path}/property_photos/$fileName');
    if (!await file.exists()) return;
    try {
      await _supabase.storage.from('property-photos').upload(fileName, file, fileOptions: const FileOptions(upsert: true));
    } catch (_) {}
  }

  static Future<void> downloadAllData(Function(String) onProgress) async {
    final db = await DatabaseHelper.instance.database;
    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${appDir.path}/property_photos');

    onProgress("Cloud မှ ပိုင်ရှင်စာရင်းများ ရယူနေသည်...");
    final owners = await _supabase.from('crm_owners').select();
    for (var row in owners) {
      // ⚠️ ပြင်ဆင်ချက်: Local မှာ မပို့ရသေးတဲ့ Data ရှိရင် Overwrite မလုပ်ပါနဲ့ (Silent Data Loss ကာကွယ်ခြင်း)
      final existing = await db.query('crm_owners', where: 'id = ?', whereArgs: [row['id']]);
      if (existing.isNotEmpty && existing.first['is_synced'] == 0) continue; 
      var localRow = Map<String, dynamic>.from(row); localRow['is_synced'] = 1;
      await db.insert('crm_owners', localRow, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    onProgress("Cloud မှ ဝယ်လက်စာရင်းများ ရယူနေသည်...");
    final buyers = await _supabase.from('crm_buyers').select();
    for (var row in buyers) {
      final existing = await db.query('crm_buyers', where: 'id = ?', whereArgs: [row['id']]);
      if (existing.isNotEmpty && existing.first['is_synced'] == 0) continue;
      var localRow = Map<String, dynamic>.from(row); localRow['is_synced'] = 1;
      await db.insert('crm_buyers', localRow, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    onProgress("Cloud မှ အိမ်ခြံမြေနှင့် ဓာတ်ပုံများ ရယူနေသည်...");
    final properties = await _supabase.from('crm_properties').select();
    for (var row in properties) {
      final existing = await db.query('crm_properties', where: 'id = ?', whereArgs: [row['id']]);
      if (existing.isNotEmpty && existing.first['is_synced'] == 0) continue;

      Map<String, dynamic> mutableRow = Map<String, dynamic>.from(row);
      mutableRow['is_synced'] = 1; 

      if (mutableRow['extra_data'] != null) {
        try {
          final extraData = jsonDecode(mutableRow['extra_data'] as String);
          if (extraData['photos'] != null) {
            List<String> photoNames = List<String>.from(extraData['photos']);
            for (String fileName in photoNames) {
              final savePath = '${photosDir.path}/$fileName';
              await _downloadPhoto(fileName, savePath);
            }
          }
        } catch (_) {}
      }
      await db.insert('crm_properties', mutableRow, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    onProgress("Cloud မှ အမျိုးအစားများ ရယူနေသည်...");
    final metadata = await _supabase.from('crm_metadata').select();
    for (var row in metadata) await db.insert('crm_metadata', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> _downloadPhoto(String fileName, String savePath) async {
    final file = File(savePath);
    if (await file.exists()) return; 
    try {
      final bytes = await _supabase.storage.from('property-photos').download(fileName);
      await file.parent.create(recursive: true); 
      await file.writeAsBytes(bytes); 
    } catch (_) {}
  }
}
