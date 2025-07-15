import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'note_model.dart';

// PUBLIC_INTERFACE
class NotesDatabase {
  static final NotesDatabase instance = NotesDatabase._internal();
  static Database? _database;

  NotesDatabase._internal();

  // PUBLIC_INTERFACE
  Future<void> initDb() async {
    if (_database != null) return;
    _database = await _initDatabase();
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'notesapp_v1.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
            CREATE TABLE notes (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              content TEXT NOT NULL,
              createdAt TEXT NOT NULL,
              updatedAt TEXT NOT NULL
            )
          ''');
      },
    );
  }

  // PUBLIC_INTERFACE
  Future<List<Note>> getNotes({String query = ''}) async {
    final db = _database ?? await _initDatabase();
    List<Map<String, dynamic>> maps;
    if (query.isNotEmpty) {
      maps = await db.query(
        'notes',
        where: 'title LIKE ? OR content LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'updatedAt DESC',
      );
    } else {
      maps = await db.query(
        'notes',
        orderBy: 'updatedAt DESC',
      );
    }
    return maps.map((m) => Note.fromMap(m)).toList();
  }

  // PUBLIC_INTERFACE
  Future<Note?> getNote(int id) async {
    final db = _database ?? await _initDatabase();
    final maps = await db.query('notes', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Note.fromMap(maps.first);
    }
    return null;
  }

  // PUBLIC_INTERFACE
  Future<int> insertNote(Note note) async {
    final db = _database ?? await _initDatabase();
    note = note.copyWith(
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return await db.insert('notes', note.toMap());
  }

  // PUBLIC_INTERFACE
  Future<int> updateNote(Note note) async {
    final db = _database ?? await _initDatabase();
    note = note.copyWith(updatedAt: DateTime.now());
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  // PUBLIC_INTERFACE
  Future<int> deleteNote(int id) async {
    final db = _database ?? await _initDatabase();
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  // PUBLIC_INTERFACE
  Future<void> close() async {
    final db = _database;
    if (db != null) await db.close();
    _database = null;
  }
}
