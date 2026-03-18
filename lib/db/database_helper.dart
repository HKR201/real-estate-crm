import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
    // 1. Properties Table
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

    // 2. Owners Table
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

    // 3. Buyers Table
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

    // 4. Metadata Table
    await db.execute('''
      CREATE TABLE crm_metadata (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        value TEXT NOT NULL,
        created_at TEXT
      )
    ''');

    // 5. Sync Logs Table
    await db.execute('''
      CREATE TABLE crm_sync_logs (
        id TEXT PRIMARY KEY,
        last_sync_time TEXT NOT NULL,
        status TEXT,
        details TEXT
      )
    ''');
  }

  // ========================================================
  // အသစ်ထည့်သွင်းလိုက်သော လုပ်ဆောင်ချက်များ (CRUD Operations)
  // ========================================================

  // ၁။ အိမ်ခြံမြေအသစ်ကို Database ထဲသို့ သိမ်းဆည်းရန် (Insert)
  Future<int> insertProperty(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('crm_properties', row);
  }

  // ၂။ Database ထဲမှ အိမ်ခြံမြေစာရင်းများကို ပြန်လည်ဆွဲထုတ်ရန် (Read)
  // (ဖျက်ထားသော is_deleted = 1 များကို မယူဘဲ၊ နောက်ဆုံးထည့်ထားသည့် အိမ်ကို အပေါ်ဆုံးတွင်ပြမည်)
  Future<List<Map<String, dynamic>>> getAllProperties() async {
    Database db = await instance.database;
    return await db.query(
      'crm_properties',
      where: 'is_deleted = ?',
      whereArgs: [0],
      orderBy: 'created_at DESC', // အသစ်ဆုံးကို အပေါ်ဆုံးမှာ ပြရန်
    );
  }

  // Database ကို ပိတ်ရန်
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
