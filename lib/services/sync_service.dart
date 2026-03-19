import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../db/database_helper.dart';

class SyncService {
  static final _supabase = Supabase.instance.client;

  // ==========================================
  // နောက်ကွယ်မှ အလိုအလျောက် Sync လုပ်ခြင်း (Auto Sync)
  // ==========================================
  static Future<void> autoSyncBackground() async {
    final db = await DatabaseHelper.instance.database;

    try {
      // is_synced = 0 ဖြစ်နေသော (မပို့ရသေးသော) အိမ်ခြံမြေများကို ရှာမည်
      final unsyncedProps = await db.query('crm_properties', where: 'is_synced = 0');
      for (var row in unsyncedProps) {
        var cloudRow = Map<String, dynamic>.from(row);
        cloudRow.remove('is_synced'); // Cloud ပေါ်တွင် is_synced column မလိုပါ
        
        // ဓာတ်ပုံများရှိလျှင် အရင်တင်မည်
        if (cloudRow['extra_data'] != null) {
          try {
            final extraData = jsonDecode(cloudRow['extra_data'] as String);
            if (extraData['photos'] != null) {
              List<String> photoPaths = List<String>.from(extraData['photos']);
              for (String localPath in photoPaths) await _uploadPhoto(localPath);
            }
          } catch (_) {}
        }
        
        // Cloud သို့ ပို့မည်
        await _supabase.from('crm_properties').upsert(cloudRow);
        // ပို့တာ အောင်မြင်သွားမှ Database တွင် is_synced = 1 ဟု ပြန်မှတ်မည်
        await db.update('crm_properties', {'is_synced': 1}, where: 'id = ?', whereArgs: [row['id']]);
      }

      // ထိုနည်းတူ Owners များ
      final unsyncedOwners = await db.query('crm_owners', where: 'is_synced = 0');
      for (var row in unsyncedOwners) {
        var cloudRow = Map<String, dynamic>.from(row); cloudRow.remove('is_synced');
        await _supabase.from('crm_owners').upsert(cloudRow);
        await db.update('crm_owners', {'is_synced': 1}, where: 'id = ?', whereArgs: [row['id']]);
      }

      // Buyers များ
      final unsyncedBuyers = await db.query('crm_buyers', where: 'is_synced = 0');
      for (var row in unsyncedBuyers) {
        var cloudRow = Map<String, dynamic>.from(row); cloudRow.remove('is_synced');
        await _supabase.from('crm_buyers').upsert(cloudRow);
        await db.update('crm_buyers', {'is_synced': 1}, where: 'id = ?', whereArgs: [row['id']]);
      }
    } catch (e) {
      debugPrint("Auto Sync Failed: $e"); // Error တက်လျှင် လွှတ်ထားမည် (နောက်တစ်ကြိမ် ပြန်ကြိုးစားမည်)
    }
  }

  // ==========================================
  // Manual Sync (Settings မှ နှိပ်လျှင်)
  // ==========================================
  static Future<void> syncAllData(Function(String) onProgress) async {
    await autoSyncBackground(); // Auto Sync logic ကိုပဲ ပြန်ခေါ်သုံးလိုက်ပါသည်
    onProgress("ဒေတာများ အောင်မြင်စွာ ပို့ဆောင်ပြီးပါပြီ");
  }

  static Future<void> _uploadPhoto(String localPath) async {
    final file = File(localPath);
    if (!await file.exists()) return;
    final fileName = localPath.split('/').last;
    try {
      await _supabase.storage.from('property-photos').upload(fileName, file, fileOptions: const FileOptions(upsert: true));
    } catch (_) {}
  }

  // ==========================================
  // DOWNLOAD (Cloud မှ ဖုန်းသို့ ဒေတာပြန်ယူခြင်း)
  // ==========================================
  static Future<void> downloadAllData(Function(String) onProgress) async {
    final db = await DatabaseHelper.instance.database;
    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${appDir.path}/property_photos');

    onProgress("Cloud မှ ပိုင်ရှင်စာရင်းများ ရယူနေသည်...");
    final owners = await _supabase.from('crm_owners').select();
    for (var row in owners) {
      var localRow = Map<String, dynamic>.from(row); localRow['is_synced'] = 1;
      await db.insert('crm_owners', localRow, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    onProgress("Cloud မှ ဝယ်လက်စာရင်းများ ရယူနေသည်...");
    final buyers = await _supabase.from('crm_buyers').select();
    for (var row in buyers) {
      var localRow = Map<String, dynamic>.from(row); localRow['is_synced'] = 1;
      await db.insert('crm_buyers', localRow, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    onProgress("Cloud မှ အိမ်ခြံမြေနှင့် ဓာတ်ပုံများ ရယူနေသည်...");
    final properties = await _supabase.from('crm_properties').select();
    for (var row in properties) {
      Map<String, dynamic> mutableRow = Map<String, dynamic>.from(row);
      mutableRow['is_synced'] = 1; // Cloud မှ လာသောကြောင့် Synced ဖြစ်သည်ဟု မှတ်မည်

      if (mutableRow['extra_data'] != null) {
        try {
          final extraData = jsonDecode(mutableRow['extra_data'] as String);
          if (extraData['photos'] != null) {
            List<String> photoPaths = List<String>.from(extraData['photos']);
            List<String> newPhotoPaths = [];
            for (String localPath in photoPaths) {
              final fileName = localPath.split('/').last;
              final newLocalPath = '${photosDir.path}/$fileName';
              newPhotoPaths.add(newLocalPath);
              await _downloadPhoto(fileName, newLocalPath);
            }
            extraData['photos'] = newPhotoPaths;
            mutableRow['extra_data'] = jsonEncode(extraData);
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
