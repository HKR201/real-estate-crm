import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../db/database_helper.dart';

class SyncService {
  static final _supabase = Supabase.instance.client;

  // --- အကုန်လုံးကို တစ်ပြိုင်တည်း Sync လုပ်မည့် ပင်မ Function ---
  static Future<void> syncAllData(Function(String) onProgress) async {
    final db = await DatabaseHelper.instance.database;

    // ၁။ Owners Sync
    onProgress("Owners စာရင်းများကို Cloud သို့ ပို့နေသည်...");
    final owners = await db.query('crm_owners');
    for (var row in owners) {
      await _supabase.from('crm_owners').upsert(row);
    }

    // ၂။ Buyers Sync
    onProgress("Buyers စာရင်းများကို Cloud သို့ ပို့နေသည်...");
    final buyers = await db.query('crm_buyers');
    for (var row in buyers) {
      await _supabase.from('crm_buyers').upsert(row);
    }

    // ၃။ Properties Sync (Photos အပါအဝင်)
    onProgress("အိမ်ခြံမြေနှင့် ဓာတ်ပုံများကို Cloud သို့ ပို့နေသည်...");
    final properties = await db.query('crm_properties');
    for (var row in properties) {
      // ဓာတ်ပုံများ Upload လုပ်ခြင်း
      if (row['extra_data'] != null) {
        // Error တက်သည့်နေရာအား 'as String' ဖြင့် ပြင်ဆင်ထားပါသည်
        final extraData = jsonDecode(row['extra_data'] as String);
        if (extraData['photos'] != null) {
          List<String> photoPaths = List<String>.from(extraData['photos']);
          for (String localPath in photoPaths) {
            await _uploadPhoto(localPath);
          }
        }
      }
      await _supabase.from('crm_properties').upsert(row);
    }

    // ၄။ Metadata Sync
    onProgress("အမျိုးအစား စာရင်းများကို Cloud သို့ ပို့နေသည်...");
    final metadata = await db.query('crm_metadata');
    for (var row in metadata) {
      await _supabase.from('crm_metadata').upsert(row);
    }
  }

  // --- ဓာတ်ပုံတစ်ပုံချင်းစီကို Cloud Storage သို့ တင်ခြင်း ---
  static Future<void> _uploadPhoto(String localPath) async {
    final file = File(localPath);
    if (!await file.exists()) return;

    final fileName = localPath.split('/').last;
    try {
      // Bucket ထဲမှာ ရှိပြီးသားဆိုရင် ကျော်သွားမည် (upsert: true)
      await _supabase.storage.from('property-photos').upload(
        fileName, 
        file, 
        fileOptions: const FileOptions(upsert: true)
      );
    } catch (_) {
      // Upload မအောင်မြင်ပါက ကျော်သွားမည်
    }
  }
}
