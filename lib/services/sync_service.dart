import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';

class SyncService {
  static final _supabase = Supabase.instance.client;

  // ==========================================
  // ၁။ UPLOAD (ဖုန်းမှ Cloud သို့ ဒေတာတင်ခြင်း)
  // ==========================================
  static Future<void> syncAllData(Function(String) onProgress) async {
    final db = await DatabaseHelper.instance.database;

    onProgress("Owners စာရင်းများကို Cloud သို့ ပို့နေသည်...");
    final owners = await db.query('crm_owners');
    for (var row in owners) await _supabase.from('crm_owners').upsert(row);

    onProgress("Buyers စာရင်းများကို Cloud သို့ ပို့နေသည်...");
    final buyers = await db.query('crm_buyers');
    for (var row in buyers) await _supabase.from('crm_buyers').upsert(row);

    onProgress("အိမ်ခြံမြေနှင့် ဓာတ်ပုံများကို Cloud သို့ ပို့နေသည်...");
    final properties = await db.query('crm_properties');
    for (var row in properties) {
      if (row['extra_data'] != null) {
        try {
          final extraData = jsonDecode(row['extra_data'] as String);
          if (extraData['photos'] != null) {
            List<String> photoPaths = List<String>.from(extraData['photos']);
            for (String localPath in photoPaths) await _uploadPhoto(localPath);
          }
        } catch (_) {}
      }
      await _supabase.from('crm_properties').upsert(row);
    }

    onProgress("အမျိုးအစား စာရင်းများကို Cloud သို့ ပို့နေသည်...");
    final metadata = await db.query('crm_metadata');
    for (var row in metadata) await _supabase.from('crm_metadata').upsert(row);
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
  // ၂။ DOWNLOAD (Cloud မှ ဖုန်းသို့ ဒေတာပြန်ယူခြင်း)
  // ==========================================
  static Future<void> downloadAllData(Function(String) onProgress) async {
    final db = await DatabaseHelper.instance.database;

    onProgress("Cloud မှ ပိုင်ရှင်စာရင်းများ ရယူနေသည်...");
    final owners = await _supabase.from('crm_owners').select();
    for (var row in owners) await db.insert('crm_owners', row, conflictAlgorithm: ConflictAlgorithm.replace);

    onProgress("Cloud မှ ဝယ်လက်စာရင်းများ ရယူနေသည်...");
    final buyers = await _supabase.from('crm_buyers').select();
    for (var row in buyers) await db.insert('crm_buyers', row, conflictAlgorithm: ConflictAlgorithm.replace);

    onProgress("Cloud မှ အိမ်ခြံမြေနှင့် ဓာတ်ပုံများ ရယူနေသည်...");
    final properties = await _supabase.from('crm_properties').select();
    for (var row in properties) {
      await db.insert('crm_properties', row, conflictAlgorithm: ConflictAlgorithm.replace);
      
      // ဓာတ်ပုံများကို Cloud မှ ပြန်လည်ဒေါင်းလုဒ်လုပ်ခြင်း
      if (row['extra_data'] != null) {
        try {
          final extraData = jsonDecode(row['extra_data'] as String);
          if (extraData['photos'] != null) {
            List<String> photoPaths = List<String>.from(extraData['photos']);
            for (String localPath in photoPaths) await _downloadPhoto(localPath);
          }
        } catch (_) {}
      }
    }

    onProgress("Cloud မှ အမျိုးအစားများ ရယူနေသည်...");
    final metadata = await _supabase.from('crm_metadata').select();
    for (var row in metadata) await db.insert('crm_metadata', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> _downloadPhoto(String localPath) async {
    final file = File(localPath);
    if (await file.exists()) return; // ဖုန်းထဲမှာ ပုံရှိပြီးသားဆိုရင် ထပ်မဒေါင်းတော့ပါ

    final fileName = localPath.split('/').last;
    try {
      final bytes = await _supabase.storage.from('property-photos').download(fileName);
      await file.parent.create(recursive: true); // Folder မရှိသေးရင် တည်ဆောက်မည်
      await file.writeAsBytes(bytes); // ဓာတ်ပုံဖိုင်ကို ဖုန်းထဲ သိမ်းမည်
    } catch (_) {}
  }
}
