abstract class BaseDatabaseService<T> {
  // CRUD Operations
  Future<String> create(T item);
  Future<void> update(String id, T item);
  Future<void> delete(String id);
  Future<T?> get(String id);
  Future<List<T>> getAll();

  // Real-time Streams
  Stream<T?> watch(String id);
  Stream<List<T>> watchAll();

  // Specialized queries
  Stream<List<T>> watchByMess(String messId);
  Stream<List<T>> watchByUser(String uniqueId);

  // Sync methods
  Future<void> pushPendingOperations();
  Future<void> pullLatestData();
}

abstract class Syncable {
  String? get id;
  String? get syncStatus;
  DateTime? get lastUpdated;
  Map<String, dynamic> toJson();
}