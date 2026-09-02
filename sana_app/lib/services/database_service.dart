import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/acoustic_event.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  static Database? _database;
  final List<AcousticEvent> _webMemoryEvents = [];

  DatabaseService._internal();

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database?> _initDatabase() async {
    if (kIsWeb) return null;
    try {
      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, 'sana_acoustic_journal.db');

      return await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE acoustic_events (
              event_id INTEGER PRIMARY KEY AUTOINCREMENT,
              timestamp TEXT NOT NULL,
              sound_class TEXT NOT NULL,
              confidence REAL NOT NULL,
              priority_score REAL NOT NULL,
              priority_tier TEXT NOT NULL,
              latitude REAL,
              longitude REAL,
              geofence_zone TEXT NOT NULL,
              time_of_day_label TEXT NOT NULL
            )
          ''');

          await db.execute('CREATE INDEX idx_events_timestamp ON acoustic_events(timestamp)');
          await db.execute('CREATE INDEX idx_events_class ON acoustic_events(sound_class)');
          await db.execute('CREATE INDEX idx_events_tier ON acoustic_events(priority_tier)');
        },
      );
    } catch (_) {
      return null;
    }
  }

  Future<int> insertEvent(AcousticEvent event) async {
    if (kIsWeb) {
      _webMemoryEvents.insert(0, event);
      return _webMemoryEvents.length;
    }

    final db = await database;
    if (db != null) {
      return await db.insert('acoustic_events', event.toMap());
    } else {
      _webMemoryEvents.insert(0, event);
      return _webMemoryEvents.length;
    }
  }

  Future<List<AcousticEvent>> getRecentEvents({int limit = 100}) async {
    if (kIsWeb) {
      return _webMemoryEvents.take(limit).toList();
    }

    final db = await database;
    if (db != null) {
      final maps = await db.query(
        'acoustic_events',
        orderBy: 'timestamp DESC',
        limit: limit,
      );
      return maps.map((m) => AcousticEvent.fromMap(m)).toList();
    }
    return _webMemoryEvents.take(limit).toList();
  }

  Future<List<AcousticEvent>> getAllEvents() async {
    if (kIsWeb) {
      return List.from(_webMemoryEvents);
    }

    final db = await database;
    if (db != null) {
      final maps = await db.query(
        'acoustic_events',
        orderBy: 'timestamp DESC',
      );
      return maps.map((m) => AcousticEvent.fromMap(m)).toList();
    }
    return List.from(_webMemoryEvents);
  }

  Future<List<AcousticEvent>> filterEvents({
    String? soundClass,
    String? priorityTier,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (kIsWeb) {
      return _webMemoryEvents.where((e) {
        if (soundClass != null && soundClass != 'All' && e.soundClass != soundClass) return false;
        if (priorityTier != null && priorityTier != 'All' && e.priorityTier != priorityTier) return false;
        if (startDate != null && e.timestamp.isBefore(startDate)) return false;
        if (endDate != null && e.timestamp.isAfter(endDate)) return false;
        return true;
      }).toList();
    }

    final db = await database;
    if (db != null) {
      String whereClause = '1=1';
      List<dynamic> whereArgs = [];

      if (soundClass != null && soundClass != 'All') {
        whereClause += ' AND sound_class = ?';
        whereArgs.add(soundClass);
      }
      if (priorityTier != null && priorityTier != 'All') {
        whereClause += ' AND priority_tier = ?';
        whereArgs.add(priorityTier);
      }
      if (startDate != null) {
        whereClause += ' AND timestamp >= ?';
        whereArgs.add(startDate.toIso8601String());
      }
      if (endDate != null) {
        whereClause += ' AND timestamp <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      final maps = await db.query(
        'acoustic_events',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'timestamp DESC',
      );
      return maps.map((m) => AcousticEvent.fromMap(m)).toList();
    }
    return _webMemoryEvents;
  }

  Future<int> getEventCount() async {
    if (kIsWeb) return _webMemoryEvents.length;
    final db = await database;
    if (db != null) {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM acoustic_events');
      return Sqflite.firstIntValue(result) ?? 0;
    }
    return _webMemoryEvents.length;
  }

  Future<void> clearAllEvents() async {
    _webMemoryEvents.clear();
    final db = await database;
    if (db != null) {
      await db.delete('acoustic_events');
    }
  }
}
