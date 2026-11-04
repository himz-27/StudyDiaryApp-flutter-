import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Opens the local SQLite database and provides study log insert, read, update, and delete methods.
class StudyDatabase {
  StudyDatabase._();

  static final StudyDatabase instance = StudyDatabase._();
  static const _databaseName = 'studydiary.db';
  static const _tableName = 'study_logs';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    // Opening a missing database creates it; onCreate adds the study_logs table.
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            subject TEXT NOT NULL,
            activity TEXT NOT NULL,
            minutes INTEGER NOT NULL,
            understanding INTEGER NOT NULL,
            notes TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
    return _database!;
  }

  Future<int> insertLog({
    required String title,
    required String subject,
    required String activity,
    required int minutes,
    required int understanding,
    required String notes,
  }) async {
    // The returned row ID indicates that SQLite inserted the record.
    final db = await database;
    return db.insert(_tableName, {
      'title': title,
      'subject': subject,
      'activity': activity,
      'minutes': minutes,
      'understanding': understanding,
      'notes': notes,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, Object?>>> getLogs({
    required int limit,
    required int offset,
  }) async {
    final db = await database;
    // Limit and offset let the list request one page at a time.
    return db.query(
      _tableName,
      orderBy: 'created_at DESC, id DESC',
      limit: limit,
      offset: offset,
    );
  }

  Future<int> getLogCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM $_tableName',
    );
    return (result.first['count'] as num).toInt();
  }

  Future<int> updateLog({
    required int id,
    required String title,
    required String subject,
    required String activity,
    required int minutes,
    required int understanding,
    required String notes,
  }) async {
    // Only the row with this id changes; created_at is kept as the original time.
    final db = await database;
    return db.update(
      _tableName,
      {
        'title': title,
        'subject': subject,
        'activity': activity,
        'minutes': minutes,
        'understanding': understanding,
        'notes': notes,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteLog(int id) async {
    final db = await database;
    return db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }
}