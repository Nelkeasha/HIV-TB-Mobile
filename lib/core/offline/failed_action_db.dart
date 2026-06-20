import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'pending_action_db.dart' show PendingActionType, PendingActionTypeX;

class FailedAction {
  final int? id;
  final PendingActionType type;
  final Map<String, dynamic> payload;
  final String reason;
  final DateTime failedAt;

  const FailedAction({
    this.id,
    required this.type,
    required this.payload,
    required this.reason,
    required this.failedAt,
  });

  Map<String, dynamic> _toRow() => {
        'action_type': type.key,
        'payload_json': jsonEncode(payload),
        'reason': reason,
        'failed_at': failedAt.toIso8601String(),
      };

  static FailedAction _fromRow(Map<String, Object?> row) => FailedAction(
        id: row['id'] as int,
        type: PendingActionTypeX.fromKey(row['action_type'] as String),
        payload: jsonDecode(row['payload_json'] as String) as Map<String, dynamic>,
        reason: row['reason'] as String,
        failedAt: DateTime.parse(row['failed_at'] as String),
      );
}

/// Local record of offline actions (home visits, dose confirmations) the
/// server permanently rejected after sync — e.g. a duplicate confirmation,
/// or a transient failure that exhausted its retry budget. Kept visible to
/// the CHW/patient as "Needs Attention" instead of being silently dropped,
/// since [PendingActionDb] used to do before this existed. See SyncManager,
/// which also makes a best-effort report to the backend for supervisor/
/// facility-provider visibility.
class FailedActionDb {
  static Database? _db;

  static Future<Database> _open() async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    _db = await openDatabase(
      join(dir, 'hivtb_failed_actions.db'),
      version: 1,
      onCreate: (db, version) => db.execute('''
        CREATE TABLE failed_actions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          action_type TEXT NOT NULL,
          payload_json TEXT NOT NULL,
          reason TEXT NOT NULL,
          failed_at TEXT NOT NULL
        )
      '''),
    );
    return _db!;
  }

  static Future<void> add(FailedAction action) async {
    final db = await _open();
    await db.insert('failed_actions', action._toRow());
  }

  static Future<List<FailedAction>> getAll() async {
    final db = await _open();
    final rows = await db.query('failed_actions', orderBy: 'failed_at DESC');
    return rows.map(FailedAction._fromRow).toList();
  }

  static Future<int> count() async {
    final db = await _open();
    final result = await db.rawQuery('SELECT COUNT(*) AS c FROM failed_actions');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  static Future<void> dismiss(int id) async {
    final db = await _open();
    await db.delete('failed_actions', where: 'id = ?', whereArgs: [id]);
  }
}
