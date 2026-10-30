import 'package:drift/drift.dart';

class PendingChangeTable extends Table {
  @override
  String get tableName => 'pending_changes';

  // Autoincrement keeps strict creation order even within the same second.
  late final pendingChangeId = integer().autoIncrement()();
  late final entity = text()();
  late final entityId = text()();
  late final action = text()();
  late final payload = text().nullable()();
  late final status = text().withDefault(const Constant('pending'))();
  late final rejectionReason = text().nullable()();
  late final createdAt = dateTime().withDefault(currentDateAndTime)();
  late final lastModifiedDate = dateTime().withDefault(currentDateAndTime)();
}
