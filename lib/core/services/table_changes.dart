import 'dart:async';

import 'package:drift/drift.dart';

/// Emits once when listened to and again after every write to one of
/// [tables], for reads that span several queries and are run again as a
/// whole.
///
/// Not `customSelect('SELECT 1', readsFrom: ...).watch()`: drift shares
/// watched queries by their SQL and variables alone, so every such stream
/// got the tables of whichever was listened to first and missed its own.
Stream<void> watchTables(
  GeneratedDatabase db,
  Iterable<ResultSetImplementation<dynamic, dynamic>> tables,
) {
  late final StreamController<void> controller;
  StreamSubscription<void>? updates;
  // Writes seen while the listener is paused (a covered screen, or a read
  // still running) are told as one event when it resumes.
  var pendingWhilePaused = false;
  controller = StreamController<void>(
    onListen: () {
      // Subscribed before the first event, so no write is missed while the
      // first read runs.
      updates = db
          .tableUpdates(TableUpdateQuery.onAllTables(tables))
          .listen(
            (_) {
              if (controller.isPaused) {
                pendingWhilePaused = true;
              } else {
                controller.add(null);
              }
            },
            onError: controller.addError,
            onDone: controller.close,
          );
      controller.add(null);
    },
    onResume: () {
      if (!pendingWhilePaused) return;
      pendingWhilePaused = false;
      controller.add(null);
    },
    onCancel: () => updates?.cancel(),
  );
  return controller.stream;
}
