import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'models.dart';
import 'store_types.dart';

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
  DriftStore([JourneyDatabase? database]) : _db = database ?? JourneyDatabase();
  final JourneyDatabase _db;
  @override
  Future<Json?> read(String namespace) async {
    final r = await _db
        .customSelect(
          'SELECT payload FROM local_state WHERE namespace=?',
          variables: [Variable(namespace)],
        )
        .getSingleOrNull();
    return r == null ? null : jsonDecode(r.read<String>('payload')) as Json;
  }

  @override
  Future<void> write(String namespace, Json data, String operationId) =>
      _db.transaction(() async {
        await _db.customStatement(
          'INSERT INTO local_state VALUES(?,?) ON CONFLICT(namespace) DO UPDATE SET payload=excluded.payload',
          [namespace, jsonEncode(data)],
        );
        await _db.customStatement(
          'INSERT OR IGNORE INTO outbox VALUES(?,?,?)',
          [operationId, namespace, DateTime.now().toUtc().toIso8601String()],
        );
      });
  @override
  Future<List<String>> pending(String namespace) async =>
      (await _db
              .customSelect(
                'SELECT operation_id FROM outbox WHERE namespace=? ORDER BY created_at',
                variables: [Variable(namespace)],
              )
              .get())
          .map((r) => r.read<String>('operation_id'))
          .toList();
  @override
  Future<void> acknowledge(String namespace, List<String> ids) =>
      _db.transaction(() async {
        for (final id in ids) {
          await _db.customStatement(
            'DELETE FROM outbox WHERE namespace=? AND operation_id=?',
            [namespace, id],
          );
        }
      });
  @override
  Future<void> remove(String namespace) => _db.transaction(() async {
    await _db.customStatement('DELETE FROM local_state WHERE namespace=?', [
      namespace,
    ]);
    await _db.customStatement('DELETE FROM outbox WHERE namespace=?', [
      namespace,
    ]);
  });
  @override
  Future<void> close() => _db.close();
}
