import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/session_model.dart';

class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'session.db');
    return await openDatabase(path, version: 1, onCreate: _createDatabase);
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        user_name TEXT NOT NULL,
        user_email TEXT NOT NULL,
        user_photo TEXT,
        is_logged_in INTEGER NOT NULL,
        last_login TEXT NOT NULL,
        expires_at TEXT
      )
    ''');
  }

  // Save session when user logs in
  Future<void> saveSession(Session session) async {
    final db = await database;

    // First, set all sessions to logged out
    await db.update('sessions', {'is_logged_in': 0});

    // Then insert or update the current session
    await db.insert(
      'sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get current active session
  Future<Session?> getCurrentSession() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sessions',
      where: 'is_logged_in = ?',
      whereArgs: [1],
      orderBy: 'last_login DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      final session = Session.fromMap(maps.first);
      // Check if session is still valid
      if (session.isValid) {
        return session;
      } else {
        // Session expired, log out
        await logout();
        return null;
      }
    }
    return null;
  }

  // Logout - clear session
  Future<void> logout() async {
    final db = await database;
    await db.update('sessions', {'is_logged_in': 0});
  }

  // Clear all sessions (for testing or cleanup)
  Future<void> clearAllSessions() async {
    final db = await database;
    await db.delete('sessions');
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final session = await getCurrentSession();
    return session != null;
  }

  // Update session data (e.g., when profile is updated)
  Future<void> updateSessionUserData({
    required String userId,
    String? userName,
    String? userPhoto,
  }) async {
    final db = await database;

    final updateData = <String, dynamic>{};
    if (userName != null) updateData['user_name'] = userName;
    if (userPhoto != null) updateData['user_photo'] = userPhoto;

    if (updateData.isNotEmpty) {
      await db.update(
        'sessions',
        updateData,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    }
  }
}
