import 'package:firebase_database/firebase_database.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseConfig {
  static const _databaseName = "mess_database.db";
  static const _databaseVersion = 3;

  static final DatabaseConfig instance = DatabaseConfig._privateConstructor();
  static Database? _database;

  DatabaseConfig._privateConstructor();

  // Firebase reference
  static DatabaseReference get firebaseRef => FirebaseDatabase.instance.ref();

  static Future<Database> initSQLite() async {
    return await DatabaseConfig.instance.database;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE mess_main (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      m_id TEXT,
      mess_id TEXT UNIQUE,
      mess_name TEXT,
      mess_address TEXT,
      mess_pass TEXT,
      mess_admin_id TEXT,
      meal_update_status TEXT,
      admin_phone TEXT,
      start_date TEXT,
      sum_of_all_trx TEXT,
      u_perm TEXT,
      qr TEXT,
      currentMonth TEXT,
      sync_status TEXT DEFAULT 'synced',
      last_updated TEXT DEFAULT CURRENT_TIMESTAMP
    )
  ''');

    await db.execute('''
    CREATE TABLE mess_user (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      unique_id TEXT UNIQUE,
      user_id TEXT,
      phone TEXT,
      email TEXT,
      user_type TEXT,
      phone_pass TEXT,
      mess_id TEXT,
      active_status TEXT,
      bazar_start TEXT,
      bazar_end TEXT,
      qr TEXT,
      img TEXT,
      sync_status TEXT DEFAULT 'synced',
      last_updated TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (mess_id) REFERENCES mess_main (mess_id)
    )
  ''');

    await db.execute('''
    CREATE TABLE bazar_list (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      list_id TEXT UNIQUE,
      unique_id TEXT,
      mess_id TEXT,
      phone TEXT,
      list_details TEXT,
      amount TEXT,
      date_time TEXT,
      admin_notify TEXT,
      sync_status TEXT DEFAULT 'synced',
      last_updated TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (mess_id) REFERENCES mess_main (mess_id),
      FOREIGN KEY (unique_id) REFERENCES mess_user (unique_id)
    )
  ''');

    await db.execute('''
    CREATE TABLE my_meals (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      unique_id TEXT,
      mess_id TEXT,
      date TEXT,
      time TEXT,
      morning TEXT DEFAULT '0',
      launce TEXT DEFAULT '0',
      dinner TEXT DEFAULT '0',
      meal_update TEXT,
      sum_meal TEXT,
      meal_reset TEXT,
      sync_status TEXT DEFAULT 'synced',
      last_updated TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (unique_id) REFERENCES mess_user (unique_id),
      FOREIGN KEY (mess_id) REFERENCES mess_main (mess_id)
    )
  ''');

    await db.execute('''
    CREATE TABLE account_print (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      unique_id TEXT,
      user_name TEXT,
      phone TEXT,
      mess_month_ex TEXT,
      my_expense TEXT,
      meal_expense TEXT,
      my_month_meal TEXT,
      pay_or_recieve TEXT,
      trx_clear_id TEXT,
      sync_status TEXT DEFAULT 'synced',
      last_updated TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (unique_id) REFERENCES mess_user (unique_id)
    )
  ''');

    await db.execute('''
    CREATE TABLE mess_fees (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      mess_id TEXT,
      fee_type TEXT,
      amount TEXT,
      admin_id TEXT,
      date TEXT,
      status TEXT,
      sync_status TEXT DEFAULT 'synced',
      last_updated TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (mess_id) REFERENCES mess_main (mess_id)
    )
  ''');

    await db.execute('''
    CREATE TABLE others_fee (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      unique_id TEXT,
      mess_id TEXT,
      fee_type TEXT,
      amount TEXT,
      admin_id TEXT,
      date TEXT,
      status TEXT,
      sync_status TEXT DEFAULT 'synced',
      last_updated TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (unique_id) REFERENCES mess_user (unique_id),
      FOREIGN KEY (mess_id) REFERENCES mess_main (mess_id)
    )
  ''');

    await db.execute('''
    CREATE TABLE payment (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      unique_id TEXT,
      admin_id TEXT,
      mess_id TEXT,
      phone TEXT,
      date_m TEXT,
      trx_id TEXT,
      amount TEXT,
      clear_trx TEXT,
      print INTEGER,
      time TEXT,
      sync_status TEXT DEFAULT 'synced',
      last_updated TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (unique_id) REFERENCES mess_user (unique_id),
      FOREIGN KEY (admin_id) REFERENCES mess_user (unique_id),
      FOREIGN KEY (mess_id) REFERENCES mess_main (mess_id)
    )
  ''');

    await db.execute('''
    CREATE TABLE pending_operations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      table_name TEXT,
      operation TEXT,  -- 'create', 'update', 'delete'
      item_id TEXT,
      item_data TEXT,  -- JSON string
      created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
  ''');
  }


  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Use a transaction to ensure atomic upgrades
    await db.transaction((txn) async {
      if (oldVersion < 2) {
        // Example: Add a new column or table in version 2
        // await txn.execute("ALTER TABLE mess_user ADD COLUMN new_column TEXT;");
        // Or create a new table
        // await txn.execute('''CREATE TABLE new_table (...);''');
        // You can leave blank if no schema changes in version 2
      }

      if (oldVersion < 3) {
        // Version 3 schema upgrade: Create new tables missing in previous versions
        // Assuming in version 3 you added my_meals, account_print, mess_fees, others_fee, payment tables

        await txn.execute('''
        CREATE TABLE IF NOT EXISTS my_meals (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          unique_id TEXT,
          mess_id TEXT,
          date TEXT,
          time TEXT,
          morning TEXT DEFAULT '0',
          launce TEXT DEFAULT '0',
          dinner TEXT DEFAULT '0',
          meal_update TEXT,
          sum_meal TEXT,
          meal_reset TEXT,
          sync_status TEXT DEFAULT 'synced',
          last_updated TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (unique_id) REFERENCES mess_user (unique_id),
          FOREIGN KEY (mess_id) REFERENCES mess_main (mess_id)
        )
      ''');

        await txn.execute('''
        CREATE TABLE IF NOT EXISTS account_print (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          unique_id TEXT,
          user_name TEXT,
          phone TEXT,
          mess_month_ex TEXT,
          my_expense TEXT,
          meal_expense TEXT,
          my_month_meal TEXT,
          pay_or_recieve TEXT,
          trx_clear_id TEXT,
          sync_status TEXT DEFAULT 'synced',
          last_updated TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (unique_id) REFERENCES mess_user (unique_id)
        )
      ''');

        await txn.execute('''
        CREATE TABLE IF NOT EXISTS mess_fees (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          mess_id TEXT,
          fee_type TEXT,
          amount TEXT,
          admin_id TEXT,
          date TEXT,
          status TEXT,
          sync_status TEXT DEFAULT 'synced',
          last_updated TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (mess_id) REFERENCES mess_main (mess_id)
        )
      ''');

        await txn.execute('''
        CREATE TABLE IF NOT EXISTS others_fee (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          unique_id TEXT,
          mess_id TEXT,
          fee_type TEXT,
          amount TEXT,
          admin_id TEXT,
          date TEXT,
          status TEXT,
          sync_status TEXT DEFAULT 'synced',
          last_updated TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (unique_id) REFERENCES mess_user (unique_id),
          FOREIGN KEY (mess_id) REFERENCES mess_main (mess_id)
        )
      ''');

        await txn.execute('''
        CREATE TABLE IF NOT EXISTS payment (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          unique_id TEXT,
          admin_id TEXT,
          mess_id TEXT,
          phone TEXT,
          date_m TEXT,
          trx_id TEXT,
          amount TEXT,
          clear_trx TEXT,
          print INTEGER,
          time TEXT,
          sync_status TEXT DEFAULT 'synced',
          last_updated TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (unique_id) REFERENCES mess_user (unique_id),
          FOREIGN KEY (admin_id) REFERENCES mess_user (unique_id),
          FOREIGN KEY (mess_id) REFERENCES mess_main (mess_id)
        )
      ''');
      }
    });
  }

}