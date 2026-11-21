import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'models.dart';
import 'store_types.dart';
import 'state_cipher.dart';

LocalStore createStore() => DriftStore();

class JourneyDatabase extends GeneratedDatabase {
  JourneyDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'cpns_journey'));
  @override
  int get schemaVersion => 1;
  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => [];
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [];
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (_) async {
      await customStatement(
        'CREATE TABLE local_state(namespace TEXT PRIMARY KEY,payload TEXT NOT NULL)',
      );
      await customStatement(
        'CREATE TABLE outbox(operation_id TEXT PRIMARY KEY,namespace TEXT NOT NULL,created_at TEXT NOT NULL)',
      );
    },
  );
}

class DriftStore implements LocalStore {
  DriftStore([JourneyDatabase? database, StateCipher? cipher])
    : _db = database ?? JourneyDatabase(),
      _cipher = cipher ?? StateCipher.device;
  final JourneyDatabase _db;
  final StateCipher _cipher;
  Future<void>? _ready;

  Future<void> _prepare() => _ready ??= _encryptLegacyRows();

  Future<void> _encryptLegacyRows() async {
    await _db.customStatement('PRAGMA secure_delete = ON');
    var migrated = false;
    await _db.transaction(() async {
      final rows = await _db
          .customSelect('SELECT namespace,payload FROM local_state')
          .get();
      for (final row in rows) {
        final payload = row.read<String>('payload');
        if (payload.startsWith(StateCipher.prefix)) continue;
        // An unknown/corrupt envelope must never be silently replaced.
        if (jsonDecode(payload) is! Map<String, dynamic>) {
          throw const FormatException('Data perangkat tidak valid.');
        }
        final namespace = row.read<String>('namespace');
        final encrypted = await _cipher.encrypt(namespace, payload);
        await _db.customStatement(
          'UPDATE local_state SET payload=? WHERE namespace=?',
          [encrypted, namespace],
        );
        migrated = true;
      }
    });
    if (migrated) {
      await _db.customStatement('VACUUM');
      await _db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
    }
  }

  @override
  Future<Json?> read(String namespace) async {
    await _prepare();
    final r = await _db
        .customSelect(
          'SELECT payload FROM local_state WHERE namespace=?',
          variables: [Variable(namespace)],
        )
        .getSingleOrNull();
    return r == null
        ? null
        : jsonDecode(
            await _cipher.decrypt(namespace, r.read<String>('payload')),
          ) as Json;
  }

  @override
  Future<void> write(String namespace, Json data, String operationId) async {
    await _prepare();
    final payload = await _cipher.encrypt(namespace, jsonEncode(data));
    await _db.transaction(() async {
      await _db.customStatement(
        'INSERT INTO local_state VALUES(?,?) ON CONFLICT(namespace) DO UPDATE SET payload=excluded.payload',
        [namespace, payload],
      );
      await _db.customStatement('INSERT OR IGNORE INTO outbox VALUES(?,?,?)', [
        operationId,
        namespace,
        DateTime.now().toUtc().toIso8601String(),
      ]);
    });
  }

  @override
  Future<List<String>> pending(String namespace) async {
    await _prepare();
    return (await _db
            .customSelect(
              'SELECT operation_id FROM outbox WHERE namespace=? ORDER BY created_at',
              variables: [Variable(namespace)],
            )
            .get())
        .map((r) => r.read<String>('operation_id'))
        .toList();
  }

  @override
  Future<void> acknowledge(String namespace, List<String> ids) async {
    await _prepare();
    await _db.transaction(() async {
      for (final id in ids) {
        await _db.customStatement(
          'DELETE FROM outbox WHERE namespace=? AND operation_id=?',
          [namespace, id],
        );
      }
    });
  }

  @override
  Future<void> remove(String namespace) async {
    await _prepare();
    await _db.transaction(() async {
      await _db.customStatement('DELETE FROM local_state WHERE namespace=?', [
        namespace,
      ]);
      await _db.customStatement('DELETE FROM outbox WHERE namespace=?', [
        namespace,
      ]);
    });
  }

  @override
  Future<void> close() => _db.close();
}
