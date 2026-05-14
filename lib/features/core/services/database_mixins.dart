import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

mixin Timestamps on Table {
  late final createdAt = dateTime().withDefault(currentDateAndTime)();
  late final lastModifiedDate = dateTime().withDefault(currentDateAndTime)();
  late final enabled = boolean().withDefault(const Constant(true))();
}
