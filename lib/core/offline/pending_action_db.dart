import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

enum PendingActionType { homeVisit, doseConfirmation }

extension PendingActionTypeX on PendingActionType {
  String get key => switch (this) {
        PendingActionType.homeVisit => 'HOME_VISIT',
        PendingActionType.doseConfirmation => 'DOSE_CONFIRMATION',
      };

  static PendingActionType fromKey(String key) => switch (key) {
        'HOME_VISIT' => PendingActionType.homeVisit,
        'DOSE_CONFIRMATION' => PendingActionType.doseConfirmation,
        _ => throw ArgumentError('Unknown pending action type: $key'),
      };
}

class PendingAction {
  final int? id;
  final PendingActionType type;
  final String path;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;

  const PendingAction({
    this.id,
    required this.type,
    required this.path,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> _toRow() => {
        'action_type': type.key,
        'request_path': path,
        'payload_json': jsonEncode(payload),
        'created_at': createdAt.toIso8601String(),
        'retry_count': retryCount,
      };

  static PendingAction _fromRow(Map<String, Object?> row) => PendingAction(
        id: row['id'] as int,
        type: PendingActionTypeX.fromKey(row['action_type'] as String),
        path: row['request_path'] as String,
        payload: jsonDecode(row['payload_json'] as String) as Map<String, dynamic>,
        createdAt: DateTime.parse(row['created_at'] as String),
        retryCount: row['retry_count'] as int,
      );
}

/// Local outbox for actions recorded while offline — home visits and dose
/// confirmations only (see SyncManager). Each row is one queued API call.
class PendingActionDb {
  static Database? _db;
  static const _maxRetries = 8;

  static Future<Database> _open() async {
    if (kIsWeb) throw UnsupportedError('PendingActionDb not available on web');
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    _db = await openDatabase(
      join(dir, 'hivtb_pending_actions.db'),
      version: 1,
      onCreate: (db, version) => db.execute('''
        CREATE TABLE pending_actions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          action_type TEXT NOT NULL,
          request_path TEXT NOT NULL,
          payload_json TEXT NOT NULL,
          created_at TEXT NOT NULL,
          retry_count INTEGER NOT NULL DEFAULT 0
        )
      '''),
    );
    return _db!;
  }

  static Future<void> enqueue(PendingAction action) async {
    if (kIsWeb) return;
    final db = await _open();
    await db.insert('pending_actions', action._toRow());
  }

  static Future<List<PendingAction>> getAll() async {
    if (kIsWeb) return [];
    final db = await _open();
    final rows = await db.query('pending_actions', orderBy: 'created_at ASC');
    return rows.map(PendingAction._fromRow).toList();
  }

  static Future<int> count() async {
    if (kIsWeb) return 0;
    final db = await _open();
    final result = await db.rawQuery('SELECT COUNT(*) AS c FROM pending_actions');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  static Future<void> remove(int id) async {
    if (kIsWeb) return;
    final db = await _open();
    await db.delete('pending_actions', where: 'id = ?', whereArgs: [id]);
  }

  /// Returns true if the action has exceeded its retry budget and was dropped.
  static Future<bool> recordFailureAndMaybeDrop(int id, int currentRetryCount) async {
    if (kIsWeb) return false;
    final db = await _open();
    if (currentRetryCount + 1 >= _maxRetries) {
      await db.delete('pending_actions', where: 'id = ?', whereArgs: [id]);
      return true;
    }
    await db.rawUpdate(
        'UPDATE pending_actions SET retry_count = retry_count + 1 WHERE id = ?', [id]);
    return false;
  }
}
