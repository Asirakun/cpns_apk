import 'models.dart';

abstract class LocalStore {
  Future<Json?> read(String namespace);
  Future<void> write(String namespace, Json data, String operationId);
  Future<List<String>> pending(String namespace);
  Future<void> acknowledge(String namespace, List<String> ids);
  Future<void> remove(String namespace);
  Future<void> close();
}
