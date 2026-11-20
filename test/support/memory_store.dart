import 'package:cpns_journey/core/models.dart';
import 'package:cpns_journey/core/store_types.dart';

class MemoryStore implements LocalStore {
  final states = <String, Json>{};
  final operations = <String, List<String>>{};
  @override
  Future<Json?> read(String n) async =>
      states[n] == null ? null : deepCopy(states[n]!);
  @override
  Future<void> write(String n, Json data, String op) async {
    states[n] = deepCopy(data);
    (operations[n] ??= []).add(op);
  }

  @override
  Future<List<String>> pending(String n) async => operations[n] ?? [];
  @override
  Future<void> acknowledge(String n, List<String> ids) async {
    operations[n]?.removeWhere(ids.contains);
  }

  @override
  Future<void> remove(String n) async {
    states.remove(n);
    operations.remove(n);
  }

  @override
  Future<void> close() async {}
}
