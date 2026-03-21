import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('crm_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Version ကို 3 သို့ ပြောင်းထားပါသည် (Default Data များ ရှင်းလင်းရန်)
    return await openDatabase(
      path, 
      version: 3, 
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE crm_owners ADD COLUMN is_synced INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE crm_properties ADD COLUMN is_synced INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE crm_buyers ADD COLUMN is_synced INTEGER DEFAULT 0');
    }
    if (oldVersion < 3) {
      // အရင်က အလိုလိုထည့်ထားပေးသော Default Prefix (ရန်ကုန်, မန္တလေး, etc.) များကို ရှင်းလင်းမည်
      // သင်ကိုယ်တိုင် ထည့်ထားသော Data များ လုံးဝ (လုံးဝ) မပျက်ပါ။
      await db.execute("DELETE FROM crm_metadata WHERE id LIKE 'loc_%' OR id LIKE 'road_%' OR id LIKE 'house_%' OR id LIKE 'land_%'");
    }
  }

  Future _createDB(Database db, int version) async {
    const textType = 'TEXT';
    const intType = 'INTEGER';

    await db.execute('''
      CREATE TABLE crm_owners (
        id $textType PRIMARY KEY, name $textType NOT NULL, phones $textType, remark $textType,
        is_deleted $intType DEFAULT 0, extra_data $textType, is_synced $intType DEFAULT 0,
        created_at $textType, updated_at $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE crm_properties (
        id $textType PRIMARY KEY, title $textType NOT NULL, asking_price_lakhs $intType NOT NULL, bottom_price_lakhs $intType,
        status $textType DEFAULT 'Available', east_ft $intType, west_ft $intType, south_ft $intType, north_ft $intType,
        house_type $textType, road_type $textType, land_type $textType,
        location_id $textType, remark $textType, owner_id $textType, map_link $textType,
        is_deleted $intType DEFAULT 0, extra_data $textType, is_synced $intType DEFAULT 0,
        created_at $textType, updated_at $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE crm_buyers (
        id $textType PRIMARY KEY, name $textType NOT NULL, phones $textType, budget_lakhs $intType,
        preferred_location $textType, is_deleted $intType DEFAULT 0, extra_data $textType,
        is_synced $intType DEFAULT 0, created_at $textType, updated_at $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE crm_metadata (
        id $textType PRIMARY KEY, category $textType NOT NULL, value $textType NOT NULL, created_at $textType
      )
    ''');
    // Default data ထည့်သည့် စနစ်ကို အပြီးတိုင် ဖြုတ်ချလိုက်ပါပြီ။
  }

  // ================= READ (အချက်အလက်များ ဆွဲထုတ်ခြင်း) =================
  Future<List<Map<String, dynamic>>> getAllProperties() async {
    final db = await instance.database;
    return await db.query('crm_properties', where: 'is_deleted = ?', whereArgs: [0], orderBy: 'updated_at DESC');
  }

  Future<List<Map<String, dynamic>>> getAllOwners() async {
    final db = await instance.database;
    return await db.query('crm_owners', where: 'is_deleted = ?', whereArgs: [0], orderBy: 'updated_at DESC');
  }

  Future<List<Map<String, dynamic>>> getAllBuyers() async {
    final db = await instance.database;
    return await db.query('crm_buyers', where: 'is_deleted = ?', whereArgs: [0], orderBy: 'updated_at DESC');
  }

  // Dashboard Filter တွင် "လက်ရှိ အမှန်တကယ် သုံးထားသော" စာရင်းများကိုသာ ပြသရန်
  Future<List<String>> getDistinctPropertyValues(String column) async {
    final db = await instance.database;
    final result = await db.query('crm_properties', distinct: true, columns: [column], where: 'is_deleted = 0 AND $column IS NOT NULL AND $column != ""');
    return result.map((e) => e[column] as String).toList();
  }

  // ================= CREATE & UPDATE (အိမ်ခြံမြေ) =================
  Future<int> insertProperty(Map<String, dynamic> data) async {
    final db = await instance.database; data['is_synced'] = 0; 
    return await db.insert('crm_properties', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateProperty(Map<String, dynamic> data) async {
    final db = await instance.database; data['is_synced'] = 0; 
    return await db.update('crm_properties', data, where: 'id = ?', whereArgs: [data['id']]);
  }

  // ================= CREATE & UPDATE (ပိုင်ရှင်) =================
  Future<int> insertOwner(Map<String, dynamic> data) async {
    final db = await instance.database; data['is_synced'] = 0; 
    return await db.insert('crm_owners', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateOwner(Map<String, dynamic> data) async {
    final db = await instance.database; data['is_synced'] = 0; 
    return await db.update('crm_owners', data, where: 'id = ?', whereArgs: [data['id']]);
  }

  // ================= CREATE & UPDATE (ဝယ်လက်) =================
  Future<int> insertBuyer(Map<String, dynamic> data) async {
    final db = await instance.database; data['is_synced'] = 0; 
    return await db.insert('crm_buyers', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateBuyer(Map<String, dynamic> data) async {
    final db = await instance.database; data['is_synced'] = 0; 
    return await db.update('crm_buyers', data, where: 'id = ?', whereArgs: [data['id']]);
  }

  // ================= RECYCLE BIN (အမှိုက်ပုံး) =================
  Future<int> moveToRecycleBin(String table, String id) async {
    final db = await instance.database;
    return await db.update(table, {'is_deleted': 1, 'is_synced': 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> restoreFromRecycleBin(String table, String id) async {
    final db = await instance.database;
    return await db.update(table, {'is_deleted': 0, 'is_synced': 0}, where: 'id = ?', whereArgs: [id]);
  }

  // ================= METADATA (အမျိုးအစား ခေါင်းစဉ်များ) =================
  Future<List<String>> getMetadata(String category) async {
    final db = await instance.database;
    final result = await db.query('crm_metadata', columns: ['value'], where: 'category = ?', whereArgs: [category]);
    return result.map((e) => e['value'] as String).toList();
  }

  Future<void> insertMetadata(String category, String value) async {
    final db = await instance.database;
    await db.insert(
      'crm_metadata', 
      {'id': '${category}_${DateTime.now().millisecondsSinceEpoch}', 'category': category, 'value': value, 'created_at': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.ignore
    );
  }
    // ================= METADATA DELETE (အမျိုးအစားများ ဖျက်ရန်) =================
  Future<int> deleteMetadata(String category, String value) async {
    final db = await instance.database;
    // သက်ဆိုင်ရာ Category နှင့် Value ကိုက်ညီသော စာကြောင်းကိုသာ ဖျက်မည်
    return await db.delete(
      'crm_metadata',
      where: 'category = ? AND value = ?',
      whereArgs: [category, value],
    );
  }
}
