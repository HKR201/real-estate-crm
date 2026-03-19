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

    // Version ကို 2 သို့ ပြောင်းထားပါသည် (is_synced ထည့်ရန်)
    return await openDatabase(
      path, 
      version: 2, 
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
  }

  Future _createDB(Database db, int version) async {
    const textType = 'TEXT';
    const intType = 'INTEGER';

    await db.execute('''
      CREATE TABLE crm_owners (
        id $textType PRIMARY KEY,
        name $textType NOT NULL,
        phones $textType,
        remark $textType,
        is_deleted $intType DEFAULT 0,
        extra_data $textType,
        is_synced $intType DEFAULT 0,
        created_at $textType,
        updated_at $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE crm_properties (
        id $textType PRIMARY KEY,
        title $textType NOT NULL,
        asking_price_lakhs $intType NOT NULL,
        bottom_price_lakhs $intType,
        status $textType DEFAULT 'Available',
        east_ft $intType, west_ft $intType, south_ft $intType, north_ft $intType,
        house_type $textType, road_type $textType, land_type $textType,
        location_id $textType, remark $textType, owner_id $textType, map_link $textType,
        is_deleted $intType DEFAULT 0,
        extra_data $textType,
        is_synced $intType DEFAULT 0,
        created_at $textType,
        updated_at $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE crm_buyers (
        id $textType PRIMARY KEY,
        name $textType NOT NULL,
        phones $textType,
        budget_lakhs $intType,
        preferred_location $textType,
        is_deleted $intType DEFAULT 0,
        extra_data $textType,
        is_synced $intType DEFAULT 0,
        created_at $textType,
        updated_at $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE crm_metadata (
        id $textType PRIMARY KEY,
        category $textType NOT NULL,
        value $textType NOT NULL,
        created_at $textType
      )
    ''');

    _insertInitialMetadata(db);
  }

  Future<void> _insertInitialMetadata(Database db) async {
    final batch = db.batch();
    List<String> locations = ['ပုသိမ်', 'ရန်ကုန်', 'မန္တလေး', 'နေပြည်တော်'];
    for (int i = 0; i < locations.length; i++) {
      batch.insert('crm_metadata', {'id': 'loc_$i', 'category': 'location', 'value': locations[i], 'created_at': DateTime.now().toIso8601String()});
    }
    List<String> roadTypes = ['ကွန်ကရစ်လမ်း', 'ကတ္တရာလမ်း', 'မြေသားလမ်း'];
    for (int i = 0; i < roadTypes.length; i++) {
      batch.insert('crm_metadata', {'id': 'road_$i', 'category': 'road_type', 'value': roadTypes[i], 'created_at': DateTime.now().toIso8601String()});
    }
    List<String> houseTypes = ['ပျဉ်ထောင်အိမ်', 'တိုက်အိမ်', 'RC', 'Steel Structure'];
    for (int i = 0; i < houseTypes.length; i++) {
      batch.insert('crm_metadata', {'id': 'house_$i', 'category': 'house_type', 'value': houseTypes[i], 'created_at': DateTime.now().toIso8601String()});
    }
    List<String> landTypes = ['ဂရန်မြေ', 'ဘိုးဘွားပိုင်မြေ', 'ပါမစ်မြေ', 'စလစ်မြေ', 'လယ်ယာမြေ'];
    for (int i = 0; i < landTypes.length; i++) {
      batch.insert('crm_metadata', {'id': 'land_$i', 'category': 'land_type', 'value': landTypes[i], 'created_at': DateTime.now().toIso8601String()});
    }
    await batch.commit(noResult: true);
  }

  // Common CRUD
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

  Future<int> insertProperty(Map<String, dynamic> data) async {
    final db = await instance.database;
    data['is_synced'] = 0; // အသစ်ထည့်လျှင် Cloud မရောက်သေးဟု သတ်မှတ်သည်
    return await db.insert('crm_properties', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateProperty(Map<String, dynamic> data) async {
    final db = await instance.database;
    data['is_synced'] = 0; // ပြင်ဆင်လျှင် Cloud ပြန်တင်ရမည်ဟု သတ်မှတ်သည်
    return await db.update('crm_properties', data, where: 'id = ?', whereArgs: [data['id']]);
  }

  Future<int> moveToRecycleBin(String table, String id) async {
    final db = await instance.database;
    return await db.update(table, {'is_deleted': 1, 'is_synced': 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> restoreFromRecycleBin(String table, String id) async {
    final db = await instance.database;
    return await db.update(table, {'is_deleted': 0, 'is_synced': 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<String>> getMetadata(String category) async {
    final db = await instance.database;
    final result = await db.query('crm_metadata', columns: ['value'], where: 'category = ?', whereArgs: [category]);
    return result.map((e) => e['value'] as String).toList();
  }
}
