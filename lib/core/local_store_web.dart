import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'store_types.dart';

LocalStore createStore() => BrowserStore();

// Browser preview only; the Android application uses transactional Drift/SQLite.
class BrowserStore implements LocalStore {
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();
  @override
  Future<Json?> read(String namespace) async {
    final text = (await _prefs).getString('cpns:$namespace');
    return text == null ? null : jsonDecode(text) as Json;
  }

  @override
  Future<void> write(String namespace, Json data, String operationId) async {
    final p = await _prefs;
    final ids = p.getStringList('outbox:$namespace') ?? [];
    await p.setString('cpns:$namespace', jsonEncode(data));
    await p.setStringList('outbox:$namespace', [...ids, operationId]);
  }

  @override
  Future<List<String>> pending(String namespace) async =>
      (await _prefs).getStringList('outbox:$namespace') ?? [];
  @override
  Future<void> acknowledge(String namespace, List<String> ids) async {
    final p = await _prefs;
    await p.setStringList(
      'outbox:$namespace',
      (p.getStringList('outbox:$namespace') ?? [])
          .where((i) => !ids.contains(i))
          .toList(),
    );
  }

  @override
  Future<void> remove(String namespace) async {
    final p = await _prefs;
    await p.remove('cpns:$namespace');
    await p.remove('outbox:$namespace');
  }

  @override
  Future<void> close() async {}
}
