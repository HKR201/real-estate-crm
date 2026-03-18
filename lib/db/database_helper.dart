import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Singleton pattern - Database ကို တစ်နေရာတည်းကနေပဲ ခေါ်သုံးနိုင်ရန်
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('crm_local.db');
    return _database!;
  }

  // Database ဖိုင်ကို ဖုန်းထဲတွင် ဖန်တီးခြင်း
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // Table (ဇယား) များ တည်ဆောက်ခြင်း
  Future _createDB(Database db, int version) async {
    // မှတ်ချက် - SQLite တွင် Boolean မရှိပါသဖြင့် is_deleted အား INTEGER (0 သို့မဟုတ် 1) ဖြင့် သိမ်းပါမည်။
    // JSONB မရှိပါသဖြင့် extra_data အား TEXT ဖြင့် သိမ်းပါမည်။

    // 1. Properties (အိမ်ခြံမြေစာရင်း)
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

    // 2. Owners (ပိုင်ရှင်စာရင်း)
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

    // 3. Buyers (ဝယ်လက်စာရင်း)
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

    // 4. Metadata (ရွေးချယ်စရာ အမျိုးအစားများ)
    await db.execute('''
      CREATE TABLE crm_metadata (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        value TEXT NOT NULL,
        created_at TEXT
      )
    ''');

    // 5. Sync Logs (အင်တာနက်နှင့် ချိတ်ဆက်မှု မှတ်တမ်း)
    await db.execute('''
      CREATE TABLE crm_sync_logs (
        id TEXT PRIMARY KEY,
        last_sync_time TEXT NOT NULL,
        status TEXT,
        details TEXT
      )
    ''');
  }

  // Database ကို ပိတ်ရန် (Memory မစားစေရန်)
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
