import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/login_log_model.dart';

class DatabaseHelper {
  // Singleton pattern (agar hanya ada 1 koneksi database yang terbuka)
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  // Getter untuk mengambil database
  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('myfilms_local.db');
    return _database!;
  }

  // Inisialisasi Database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  // Membuat Tabel saat pertama kali aplikasi dijalankan
  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';

    // Tabel Log Login
    await db.execute('''
      CREATE TABLE login_logs ( 
        id $idType, 
        username $textType,
        login_time $textType
      )
    ''');

    // Jika nanti mau nambah tabel lain (misal favorites), tambahkan di sini
  }

  // ---------------------------------------------------------------------------
  // CRUD METHODS UNTUK LOGIN LOG
  // ---------------------------------------------------------------------------

  // 1. Simpan Log Baru
  Future<int> insertLoginLog(LoginLog log) async {
    final db = await instance.database;

    return await db.insert(
      'login_logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace, // Jika ID sama, timpa
    );
  }

  // 2. Ambil Log Terakhir berdasarkan Username
  Future<LoginLog?> getLastLogin(String username) async {
    final db = await instance.database;

    final maps = await db.query(
      'login_logs',
      columns: ['id', 'username', 'login_time'],
      where: 'username = ?',
      whereArgs: [username],
      orderBy: 'id DESC', // Urutkan dari ID terbesar (paling baru)
      limit: 1, // Ambil 1 saja
    );

    if (maps.isNotEmpty) {
      return LoginLog.fromMap(maps.first);
    } else {
      return null;
    }
  }

  // 3. Menutup Database (Opsional, jarang dipanggil manual)
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
