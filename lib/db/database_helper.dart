import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('crm_local.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE crm_properties (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        asking_price_lakhs INTEGER NOT NULL,
        bottom_price_lakhs INTEGER,
        status TEXT DEFAULT 'Available',
        east_ft INTEGER,
        west_ft INTEGER,
        south_ft INTEGER,
        north_ft INTEGER,
        house_type TEXT,
        road_type TEXT,
        land_type TEXT,
        location_id TEXT,
        remark TEXT,
        owner_id TEXT,
        is_deleted INTEGER DEFAULT 0,
        extra_data TEXT DEFAULT '{}',
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE crm_owners (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phones TEXT DEFAULT '[]',
        remark TEXT,
        is_deleted INTEGER DEFAULT 0,
        extra_data TEXT DEFAULT '{}',
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE crm_buyers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phones TEXT DEFAULT '[]',
        budget_lakhs INTEGER,
        preferred_location TEXT,
        is_deleted INTEGER DEFAULT 0,
        extra_data TEXT DEFAULT '{}',
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE crm_metadata (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        value TEXT NOT NULL,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE crm_sync_logs (
        id TEXT PRIMARY KEY,
        last_sync_time TEXT NOT NULL,
        status TEXT,
        details TEXT
      )
    ''');
  }

  Future<int> insertProperty(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('crm_properties', row);
  }

  Future<List<Map<String, dynamic>>> getAllProperties() async {
    Database db = await instance.database;
    return await db.query('crm_properties', where: 'is_deleted = ?', whereArgs: [0], orderBy: 'created_at DESC');
  }

  Future<List<String>> getMetadata(String category) async {
    Database db = await instance.database;
    final result = await db.query('crm_metadata', where: 'category = ?', whereArgs: [category], orderBy: 'value ASC');
    return result.map((e) => e['value'] as String).toList();
  }

  Future<void> insertMetadata(String category, String value) async {
    Database db = await instance.database;
    final existing = await db.query('crm_metadata', where: 'category = ? AND value = ?', whereArgs: [category, value]);
    if (existing.isEmpty) {
      await db.insert('crm_metadata', {
        'id': const Uuid().v4(),
        'category': category,
        'value': value,
        'created_at': DateTime.now().toIso8601String()
      });
    }
  }

  Future<int> insertOwner(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('crm_owners', row);
  }

  Future<List<Map<String, dynamic>>> getAllOwners() async {
    Database db = await instance.database;
    return await db.query('crm_owners', where: 'is_deleted = ?', whereArgs: [0], orderBy: 'created_at DESC');
  }

  Future<int> insertBuyer(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('crm_buyers', row);
  }

  Future<List<Map<String, dynamic>>> getAllBuyers() async {
    Database db = await instance.database;
    return await db.query('crm_buyers', where: 'is_deleted = ?', whereArgs: [0], orderBy: 'created_at DESC');
  }

  // ========================================================
  // --- အမှိုက်ပုံးထဲသို့ ခေတ္တပို့ခြင်း နှင့် ပြန်ယူခြင်း (Soft Delete) ---
  // ========================================================
  
  Future<void> moveToRecycleBin(String tableName, String id) async {
    Database db = await instance.database;
    await db.update(
      tableName, 
      {'is_deleted': 1, 'updated_at': DateTime.now().toIso8601String()}, 
      where: 'id = ?', 
      whereArgs: [id]
    );
  }

  Future<void> restoreFromRecycleBin(String tableName, String id) async {
    Database db = await instance.database;
    await db.update(
      tableName, 
      {'is_deleted': 0, 'updated_at': DateTime.now().toIso8601String()}, 
      where: 'id = ?', 
      whereArgs: [id]
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
