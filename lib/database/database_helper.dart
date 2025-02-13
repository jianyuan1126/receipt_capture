import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('scanner.db');
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
      CREATE TABLE scans(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        filename TEXT NOT NULL,
        location TEXT,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        api_return_code TEXT
      )
    ''');
  }

  Future<int> insertScan({
    required String filename,
    required String location,
    required String date,
    required String time,
    required int fileSize,
    String? apiReturnCode,
  }) async {
    final db = await instance.database;
    return await db.insert('scans', {
      'filename': filename,
      'location': location,
      'date': date,
      'time': time,
      'file_size': fileSize,
      'api_return_code': apiReturnCode,
    });
  }

  Future<List<Map<String, dynamic>>> getAllScans() async {
    final db = await instance.database;
    return await db.query('scans', orderBy: 'date DESC, time DESC');
  }

  Future<int> deleteScan(int id) async {
    final db = await instance.database;
    return await db.delete(
      'scans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, dynamic>?> getScanById(int id) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> results = await db.query(
      'scans',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }
} 