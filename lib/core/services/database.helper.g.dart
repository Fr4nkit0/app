// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.helper.dart';

// ignore_for_file: type=lint
class $CustomerTableTable extends CustomerTable
    with TableInfo<$CustomerTableTable, CustomerTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomerTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastModifiedDateMeta = const VerificationMeta(
    'lastModifiedDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastModifiedDate =
      GeneratedColumn<DateTime>(
        'last_modified_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => uuid.v4(),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    createdAt,
    lastModifiedDate,
    enabled,
    serverId,
    customerId,
    name,
    phone,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customers';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomerTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('last_modified_date')) {
      context.handle(
        _lastModifiedDateMeta,
        lastModifiedDate.isAcceptableOrUnknown(
          data['last_modified_date']!,
          _lastModifiedDateMeta,
        ),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {customerId};
  @override
  CustomerTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomerTableData(
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastModifiedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified_date'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
    );
  }

  @override
  $CustomerTableTable createAlias(String alias) {
    return $CustomerTableTable(attachedDatabase, alias);
  }
}

class CustomerTableData extends DataClass
    implements Insertable<CustomerTableData> {
  final DateTime createdAt;
  final DateTime lastModifiedDate;
  final bool enabled;
  final int? serverId;
  final String customerId;
  final String name;
  final String? phone;
  const CustomerTableData({
    required this.createdAt,
    required this.lastModifiedDate,
    required this.enabled,
    this.serverId,
    required this.customerId,
    required this.name,
    this.phone,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_modified_date'] = Variable<DateTime>(lastModifiedDate);
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['customer_id'] = Variable<String>(customerId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    return map;
  }

  CustomerTableCompanion toCompanion(bool nullToAbsent) {
    return CustomerTableCompanion(
      createdAt: Value(createdAt),
      lastModifiedDate: Value(lastModifiedDate),
      enabled: Value(enabled),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      customerId: Value(customerId),
      name: Value(name),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
    );
  }

  factory CustomerTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomerTableData(
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastModifiedDate: serializer.fromJson<DateTime>(json['lastModifiedDate']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      customerId: serializer.fromJson<String>(json['customerId']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String?>(json['phone']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastModifiedDate': serializer.toJson<DateTime>(lastModifiedDate),
      'enabled': serializer.toJson<bool>(enabled),
      'serverId': serializer.toJson<int?>(serverId),
      'customerId': serializer.toJson<String>(customerId),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String?>(phone),
    };
  }

  CustomerTableData copyWith({
    DateTime? createdAt,
    DateTime? lastModifiedDate,
    bool? enabled,
    Value<int?> serverId = const Value.absent(),
    String? customerId,
    String? name,
    Value<String?> phone = const Value.absent(),
  }) => CustomerTableData(
    createdAt: createdAt ?? this.createdAt,
    lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
    enabled: enabled ?? this.enabled,
    serverId: serverId.present ? serverId.value : this.serverId,
    customerId: customerId ?? this.customerId,
    name: name ?? this.name,
    phone: phone.present ? phone.value : this.phone,
  );
  CustomerTableData copyWithCompanion(CustomerTableCompanion data) {
    return CustomerTableData(
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastModifiedDate: data.lastModifiedDate.present
          ? data.lastModifiedDate.value
          : this.lastModifiedDate,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomerTableData(')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedDate: $lastModifiedDate, ')
          ..write('enabled: $enabled, ')
          ..write('serverId: $serverId, ')
          ..write('customerId: $customerId, ')
          ..write('name: $name, ')
          ..write('phone: $phone')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    createdAt,
    lastModifiedDate,
    enabled,
    serverId,
    customerId,
    name,
    phone,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerTableData &&
          other.createdAt == this.createdAt &&
          other.lastModifiedDate == this.lastModifiedDate &&
          other.enabled == this.enabled &&
          other.serverId == this.serverId &&
          other.customerId == this.customerId &&
          other.name == this.name &&
          other.phone == this.phone);
}

class CustomerTableCompanion extends UpdateCompanion<CustomerTableData> {
  final Value<DateTime> createdAt;
  final Value<DateTime> lastModifiedDate;
  final Value<bool> enabled;
  final Value<int?> serverId;
  final Value<String> customerId;
  final Value<String> name;
  final Value<String?> phone;
  final Value<int> rowid;
  const CustomerTableCompanion({
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.serverId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomerTableCompanion.insert({
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.serverId = const Value.absent(),
    this.customerId = const Value.absent(),
    required String name,
    this.phone = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name);
  static Insertable<CustomerTableData> custom({
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastModifiedDate,
    Expression<bool>? enabled,
    Expression<int>? serverId,
    Expression<String>? customerId,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (lastModifiedDate != null) 'last_modified_date': lastModifiedDate,
      if (enabled != null) 'enabled': enabled,
      if (serverId != null) 'server_id': serverId,
      if (customerId != null) 'customer_id': customerId,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomerTableCompanion copyWith({
    Value<DateTime>? createdAt,
    Value<DateTime>? lastModifiedDate,
    Value<bool>? enabled,
    Value<int?>? serverId,
    Value<String>? customerId,
    Value<String>? name,
    Value<String?>? phone,
    Value<int>? rowid,
  }) {
    return CustomerTableCompanion(
      createdAt: createdAt ?? this.createdAt,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      enabled: enabled ?? this.enabled,
      serverId: serverId ?? this.serverId,
      customerId: customerId ?? this.customerId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastModifiedDate.present) {
      map['last_modified_date'] = Variable<DateTime>(lastModifiedDate.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomerTableCompanion(')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedDate: $lastModifiedDate, ')
          ..write('enabled: $enabled, ')
          ..write('serverId: $serverId, ')
          ..write('customerId: $customerId, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomerAddressTableTable extends CustomerAddressTable
    with TableInfo<$CustomerAddressTableTable, CustomerAddressTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomerAddressTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastModifiedDateMeta = const VerificationMeta(
    'lastModifiedDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastModifiedDate =
      GeneratedColumn<DateTime>(
        'last_modified_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressIdMeta = const VerificationMeta(
    'addressId',
  );
  @override
  late final GeneratedColumn<String> addressId = GeneratedColumn<String>(
    'address_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => uuid.v4(),
  );
  static const VerificationMeta _streetMeta = const VerificationMeta('street');
  @override
  late final GeneratedColumn<String> street = GeneratedColumn<String>(
    'street',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _apartmentMeta = const VerificationMeta(
    'apartment',
  );
  @override
  late final GeneratedColumn<String> apartment = GeneratedColumn<String>(
    'apartment',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _floorMeta = const VerificationMeta('floor');
  @override
  late final GeneratedColumn<String> floor = GeneratedColumn<String>(
    'floor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _visualReferenceMeta = const VerificationMeta(
    'visualReference',
  );
  @override
  late final GeneratedColumn<String> visualReference = GeneratedColumn<String>(
    'visual_reference',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPrimaryMeta = const VerificationMeta(
    'isPrimary',
  );
  @override
  late final GeneratedColumn<bool> isPrimary = GeneratedColumn<bool>(
    'is_primary',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_primary" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => uuid.v4(),
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _neighborhoodMeta = const VerificationMeta(
    'neighborhood',
  );
  @override
  late final GeneratedColumn<String> neighborhood = GeneratedColumn<String>(
    'neighborhood',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    createdAt,
    lastModifiedDate,
    enabled,
    serverId,
    addressId,
    street,
    apartment,
    floor,
    visualReference,
    isPrimary,
    customerId,
    latitude,
    longitude,
    neighborhood,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customer_addresses';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomerAddressTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('last_modified_date')) {
      context.handle(
        _lastModifiedDateMeta,
        lastModifiedDate.isAcceptableOrUnknown(
          data['last_modified_date']!,
          _lastModifiedDateMeta,
        ),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('address_id')) {
      context.handle(
        _addressIdMeta,
        addressId.isAcceptableOrUnknown(data['address_id']!, _addressIdMeta),
      );
    }
    if (data.containsKey('street')) {
      context.handle(
        _streetMeta,
        street.isAcceptableOrUnknown(data['street']!, _streetMeta),
      );
    }
    if (data.containsKey('apartment')) {
      context.handle(
        _apartmentMeta,
        apartment.isAcceptableOrUnknown(data['apartment']!, _apartmentMeta),
      );
    }
    if (data.containsKey('floor')) {
      context.handle(
        _floorMeta,
        floor.isAcceptableOrUnknown(data['floor']!, _floorMeta),
      );
    }
    if (data.containsKey('visual_reference')) {
      context.handle(
        _visualReferenceMeta,
        visualReference.isAcceptableOrUnknown(
          data['visual_reference']!,
          _visualReferenceMeta,
        ),
      );
    }
    if (data.containsKey('is_primary')) {
      context.handle(
        _isPrimaryMeta,
        isPrimary.isAcceptableOrUnknown(data['is_primary']!, _isPrimaryMeta),
      );
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('neighborhood')) {
      context.handle(
        _neighborhoodMeta,
        neighborhood.isAcceptableOrUnknown(
          data['neighborhood']!,
          _neighborhoodMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {addressId};
  @override
  CustomerAddressTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomerAddressTableData(
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastModifiedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified_date'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      addressId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address_id'],
      )!,
      street: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}street'],
      ),
      apartment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}apartment'],
      ),
      floor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}floor'],
      ),
      visualReference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visual_reference'],
      ),
      isPrimary: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_primary'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      neighborhood: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}neighborhood'],
      ),
    );
  }

  @override
  $CustomerAddressTableTable createAlias(String alias) {
    return $CustomerAddressTableTable(attachedDatabase, alias);
  }
}

class CustomerAddressTableData extends DataClass
    implements Insertable<CustomerAddressTableData> {
  final DateTime createdAt;
  final DateTime lastModifiedDate;
  final bool enabled;
  final int? serverId;
  final String addressId;
  final String? street;
  final String? apartment;
  final String? floor;
  final String? visualReference;
  final bool isPrimary;
  final String customerId;
  final double? latitude;
  final double? longitude;
  final String? neighborhood;
  const CustomerAddressTableData({
    required this.createdAt,
    required this.lastModifiedDate,
    required this.enabled,
    this.serverId,
    required this.addressId,
    this.street,
    this.apartment,
    this.floor,
    this.visualReference,
    required this.isPrimary,
    required this.customerId,
    this.latitude,
    this.longitude,
    this.neighborhood,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_modified_date'] = Variable<DateTime>(lastModifiedDate);
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['address_id'] = Variable<String>(addressId);
    if (!nullToAbsent || street != null) {
      map['street'] = Variable<String>(street);
    }
    if (!nullToAbsent || apartment != null) {
      map['apartment'] = Variable<String>(apartment);
    }
    if (!nullToAbsent || floor != null) {
      map['floor'] = Variable<String>(floor);
    }
    if (!nullToAbsent || visualReference != null) {
      map['visual_reference'] = Variable<String>(visualReference);
    }
    map['is_primary'] = Variable<bool>(isPrimary);
    map['customer_id'] = Variable<String>(customerId);
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    if (!nullToAbsent || neighborhood != null) {
      map['neighborhood'] = Variable<String>(neighborhood);
    }
    return map;
  }

  CustomerAddressTableCompanion toCompanion(bool nullToAbsent) {
    return CustomerAddressTableCompanion(
      createdAt: Value(createdAt),
      lastModifiedDate: Value(lastModifiedDate),
      enabled: Value(enabled),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      addressId: Value(addressId),
      street: street == null && nullToAbsent
          ? const Value.absent()
          : Value(street),
      apartment: apartment == null && nullToAbsent
          ? const Value.absent()
          : Value(apartment),
      floor: floor == null && nullToAbsent
          ? const Value.absent()
          : Value(floor),
      visualReference: visualReference == null && nullToAbsent
          ? const Value.absent()
          : Value(visualReference),
      isPrimary: Value(isPrimary),
      customerId: Value(customerId),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      neighborhood: neighborhood == null && nullToAbsent
          ? const Value.absent()
          : Value(neighborhood),
    );
  }

  factory CustomerAddressTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomerAddressTableData(
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastModifiedDate: serializer.fromJson<DateTime>(json['lastModifiedDate']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      addressId: serializer.fromJson<String>(json['addressId']),
      street: serializer.fromJson<String?>(json['street']),
      apartment: serializer.fromJson<String?>(json['apartment']),
      floor: serializer.fromJson<String?>(json['floor']),
      visualReference: serializer.fromJson<String?>(json['visualReference']),
      isPrimary: serializer.fromJson<bool>(json['isPrimary']),
      customerId: serializer.fromJson<String>(json['customerId']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      neighborhood: serializer.fromJson<String?>(json['neighborhood']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastModifiedDate': serializer.toJson<DateTime>(lastModifiedDate),
      'enabled': serializer.toJson<bool>(enabled),
      'serverId': serializer.toJson<int?>(serverId),
      'addressId': serializer.toJson<String>(addressId),
      'street': serializer.toJson<String?>(street),
      'apartment': serializer.toJson<String?>(apartment),
      'floor': serializer.toJson<String?>(floor),
      'visualReference': serializer.toJson<String?>(visualReference),
      'isPrimary': serializer.toJson<bool>(isPrimary),
      'customerId': serializer.toJson<String>(customerId),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'neighborhood': serializer.toJson<String?>(neighborhood),
    };
  }

  CustomerAddressTableData copyWith({
    DateTime? createdAt,
    DateTime? lastModifiedDate,
    bool? enabled,
    Value<int?> serverId = const Value.absent(),
    String? addressId,
    Value<String?> street = const Value.absent(),
    Value<String?> apartment = const Value.absent(),
    Value<String?> floor = const Value.absent(),
    Value<String?> visualReference = const Value.absent(),
    bool? isPrimary,
    String? customerId,
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    Value<String?> neighborhood = const Value.absent(),
  }) => CustomerAddressTableData(
    createdAt: createdAt ?? this.createdAt,
    lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
    enabled: enabled ?? this.enabled,
    serverId: serverId.present ? serverId.value : this.serverId,
    addressId: addressId ?? this.addressId,
    street: street.present ? street.value : this.street,
    apartment: apartment.present ? apartment.value : this.apartment,
    floor: floor.present ? floor.value : this.floor,
    visualReference: visualReference.present
        ? visualReference.value
        : this.visualReference,
    isPrimary: isPrimary ?? this.isPrimary,
    customerId: customerId ?? this.customerId,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    neighborhood: neighborhood.present ? neighborhood.value : this.neighborhood,
  );
  CustomerAddressTableData copyWithCompanion(
    CustomerAddressTableCompanion data,
  ) {
    return CustomerAddressTableData(
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastModifiedDate: data.lastModifiedDate.present
          ? data.lastModifiedDate.value
          : this.lastModifiedDate,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      addressId: data.addressId.present ? data.addressId.value : this.addressId,
      street: data.street.present ? data.street.value : this.street,
      apartment: data.apartment.present ? data.apartment.value : this.apartment,
      floor: data.floor.present ? data.floor.value : this.floor,
      visualReference: data.visualReference.present
          ? data.visualReference.value
          : this.visualReference,
      isPrimary: data.isPrimary.present ? data.isPrimary.value : this.isPrimary,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      neighborhood: data.neighborhood.present
          ? data.neighborhood.value
          : this.neighborhood,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomerAddressTableData(')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedDate: $lastModifiedDate, ')
          ..write('enabled: $enabled, ')
          ..write('serverId: $serverId, ')
          ..write('addressId: $addressId, ')
          ..write('street: $street, ')
          ..write('apartment: $apartment, ')
          ..write('floor: $floor, ')
          ..write('visualReference: $visualReference, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('customerId: $customerId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('neighborhood: $neighborhood')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    createdAt,
    lastModifiedDate,
    enabled,
    serverId,
    addressId,
    street,
    apartment,
    floor,
    visualReference,
    isPrimary,
    customerId,
    latitude,
    longitude,
    neighborhood,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerAddressTableData &&
          other.createdAt == this.createdAt &&
          other.lastModifiedDate == this.lastModifiedDate &&
          other.enabled == this.enabled &&
          other.serverId == this.serverId &&
          other.addressId == this.addressId &&
          other.street == this.street &&
          other.apartment == this.apartment &&
          other.floor == this.floor &&
          other.visualReference == this.visualReference &&
          other.isPrimary == this.isPrimary &&
          other.customerId == this.customerId &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.neighborhood == this.neighborhood);
}

class CustomerAddressTableCompanion
    extends UpdateCompanion<CustomerAddressTableData> {
  final Value<DateTime> createdAt;
  final Value<DateTime> lastModifiedDate;
  final Value<bool> enabled;
  final Value<int?> serverId;
  final Value<String> addressId;
  final Value<String?> street;
  final Value<String?> apartment;
  final Value<String?> floor;
  final Value<String?> visualReference;
  final Value<bool> isPrimary;
  final Value<String> customerId;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<String?> neighborhood;
  final Value<int> rowid;
  const CustomerAddressTableCompanion({
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.serverId = const Value.absent(),
    this.addressId = const Value.absent(),
    this.street = const Value.absent(),
    this.apartment = const Value.absent(),
    this.floor = const Value.absent(),
    this.visualReference = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.customerId = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.neighborhood = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomerAddressTableCompanion.insert({
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.serverId = const Value.absent(),
    this.addressId = const Value.absent(),
    this.street = const Value.absent(),
    this.apartment = const Value.absent(),
    this.floor = const Value.absent(),
    this.visualReference = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.customerId = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.neighborhood = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  static Insertable<CustomerAddressTableData> custom({
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastModifiedDate,
    Expression<bool>? enabled,
    Expression<int>? serverId,
    Expression<String>? addressId,
    Expression<String>? street,
    Expression<String>? apartment,
    Expression<String>? floor,
    Expression<String>? visualReference,
    Expression<bool>? isPrimary,
    Expression<String>? customerId,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? neighborhood,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (lastModifiedDate != null) 'last_modified_date': lastModifiedDate,
      if (enabled != null) 'enabled': enabled,
      if (serverId != null) 'server_id': serverId,
      if (addressId != null) 'address_id': addressId,
      if (street != null) 'street': street,
      if (apartment != null) 'apartment': apartment,
      if (floor != null) 'floor': floor,
      if (visualReference != null) 'visual_reference': visualReference,
      if (isPrimary != null) 'is_primary': isPrimary,
      if (customerId != null) 'customer_id': customerId,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (neighborhood != null) 'neighborhood': neighborhood,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomerAddressTableCompanion copyWith({
    Value<DateTime>? createdAt,
    Value<DateTime>? lastModifiedDate,
    Value<bool>? enabled,
    Value<int?>? serverId,
    Value<String>? addressId,
    Value<String?>? street,
    Value<String?>? apartment,
    Value<String?>? floor,
    Value<String?>? visualReference,
    Value<bool>? isPrimary,
    Value<String>? customerId,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<String?>? neighborhood,
    Value<int>? rowid,
  }) {
    return CustomerAddressTableCompanion(
      createdAt: createdAt ?? this.createdAt,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      enabled: enabled ?? this.enabled,
      serverId: serverId ?? this.serverId,
      addressId: addressId ?? this.addressId,
      street: street ?? this.street,
      apartment: apartment ?? this.apartment,
      floor: floor ?? this.floor,
      visualReference: visualReference ?? this.visualReference,
      isPrimary: isPrimary ?? this.isPrimary,
      customerId: customerId ?? this.customerId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      neighborhood: neighborhood ?? this.neighborhood,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastModifiedDate.present) {
      map['last_modified_date'] = Variable<DateTime>(lastModifiedDate.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (addressId.present) {
      map['address_id'] = Variable<String>(addressId.value);
    }
    if (street.present) {
      map['street'] = Variable<String>(street.value);
    }
    if (apartment.present) {
      map['apartment'] = Variable<String>(apartment.value);
    }
    if (floor.present) {
      map['floor'] = Variable<String>(floor.value);
    }
    if (visualReference.present) {
      map['visual_reference'] = Variable<String>(visualReference.value);
    }
    if (isPrimary.present) {
      map['is_primary'] = Variable<bool>(isPrimary.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (neighborhood.present) {
      map['neighborhood'] = Variable<String>(neighborhood.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomerAddressTableCompanion(')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedDate: $lastModifiedDate, ')
          ..write('enabled: $enabled, ')
          ..write('serverId: $serverId, ')
          ..write('addressId: $addressId, ')
          ..write('street: $street, ')
          ..write('apartment: $apartment, ')
          ..write('floor: $floor, ')
          ..write('visualReference: $visualReference, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('customerId: $customerId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('neighborhood: $neighborhood, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomerPreferenceTableTable extends CustomerPreferenceTable
    with TableInfo<$CustomerPreferenceTableTable, CustomerPreferenceTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomerPreferenceTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastModifiedDateMeta = const VerificationMeta(
    'lastModifiedDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastModifiedDate =
      GeneratedColumn<DateTime>(
        'last_modified_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerPreferenceIdMeta =
      const VerificationMeta('customerPreferenceId');
  @override
  late final GeneratedColumn<String> customerPreferenceId =
      GeneratedColumn<String>(
        'customer_preference_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        clientDefault: () => uuid.v4(),
      );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => uuid.v4(),
  );
  static const VerificationMeta _dayOfWeekMeta = const VerificationMeta(
    'dayOfWeek',
  );
  @override
  late final GeneratedColumn<int> dayOfWeek = GeneratedColumn<int>(
    'day_of_week',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: () => 0,
  );
  static const VerificationMeta _timeWindowStartMeta = const VerificationMeta(
    'timeWindowStart',
  );
  @override
  late final GeneratedColumn<String> timeWindowStart = GeneratedColumn<String>(
    'time_window_start',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeWindowEndMeta = const VerificationMeta(
    'timeWindowEnd',
  );
  @override
  late final GeneratedColumn<String> timeWindowEnd = GeneratedColumn<String>(
    'time_window_end',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    createdAt,
    lastModifiedDate,
    enabled,
    serverId,
    customerPreferenceId,
    customerId,
    dayOfWeek,
    timeWindowStart,
    timeWindowEnd,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customer_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomerPreferenceTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('last_modified_date')) {
      context.handle(
        _lastModifiedDateMeta,
        lastModifiedDate.isAcceptableOrUnknown(
          data['last_modified_date']!,
          _lastModifiedDateMeta,
        ),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('customer_preference_id')) {
      context.handle(
        _customerPreferenceIdMeta,
        customerPreferenceId.isAcceptableOrUnknown(
          data['customer_preference_id']!,
          _customerPreferenceIdMeta,
        ),
      );
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    }
    if (data.containsKey('day_of_week')) {
      context.handle(
        _dayOfWeekMeta,
        dayOfWeek.isAcceptableOrUnknown(data['day_of_week']!, _dayOfWeekMeta),
      );
    }
    if (data.containsKey('time_window_start')) {
      context.handle(
        _timeWindowStartMeta,
        timeWindowStart.isAcceptableOrUnknown(
          data['time_window_start']!,
          _timeWindowStartMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timeWindowStartMeta);
    }
    if (data.containsKey('time_window_end')) {
      context.handle(
        _timeWindowEndMeta,
        timeWindowEnd.isAcceptableOrUnknown(
          data['time_window_end']!,
          _timeWindowEndMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {customerPreferenceId};
  @override
  CustomerPreferenceTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomerPreferenceTableData(
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastModifiedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified_date'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      customerPreferenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_preference_id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      )!,
      dayOfWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_of_week'],
      )!,
      timeWindowStart: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_window_start'],
      )!,
      timeWindowEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_window_end'],
      ),
    );
  }

  @override
  $CustomerPreferenceTableTable createAlias(String alias) {
    return $CustomerPreferenceTableTable(attachedDatabase, alias);
  }
}

class CustomerPreferenceTableData extends DataClass
    implements Insertable<CustomerPreferenceTableData> {
  final DateTime createdAt;
  final DateTime lastModifiedDate;
  final bool enabled;
  final int? serverId;
  final String customerPreferenceId;
  final String customerId;
  final int dayOfWeek;
  final String timeWindowStart;
  final String? timeWindowEnd;
  const CustomerPreferenceTableData({
    required this.createdAt,
    required this.lastModifiedDate,
    required this.enabled,
    this.serverId,
    required this.customerPreferenceId,
    required this.customerId,
    required this.dayOfWeek,
    required this.timeWindowStart,
    this.timeWindowEnd,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_modified_date'] = Variable<DateTime>(lastModifiedDate);
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['customer_preference_id'] = Variable<String>(customerPreferenceId);
    map['customer_id'] = Variable<String>(customerId);
    map['day_of_week'] = Variable<int>(dayOfWeek);
    map['time_window_start'] = Variable<String>(timeWindowStart);
    if (!nullToAbsent || timeWindowEnd != null) {
      map['time_window_end'] = Variable<String>(timeWindowEnd);
    }
    return map;
  }

  CustomerPreferenceTableCompanion toCompanion(bool nullToAbsent) {
    return CustomerPreferenceTableCompanion(
      createdAt: Value(createdAt),
      lastModifiedDate: Value(lastModifiedDate),
      enabled: Value(enabled),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      customerPreferenceId: Value(customerPreferenceId),
      customerId: Value(customerId),
      dayOfWeek: Value(dayOfWeek),
      timeWindowStart: Value(timeWindowStart),
      timeWindowEnd: timeWindowEnd == null && nullToAbsent
          ? const Value.absent()
          : Value(timeWindowEnd),
    );
  }

  factory CustomerPreferenceTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomerPreferenceTableData(
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastModifiedDate: serializer.fromJson<DateTime>(json['lastModifiedDate']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      customerPreferenceId: serializer.fromJson<String>(
        json['customerPreferenceId'],
      ),
      customerId: serializer.fromJson<String>(json['customerId']),
      dayOfWeek: serializer.fromJson<int>(json['dayOfWeek']),
      timeWindowStart: serializer.fromJson<String>(json['timeWindowStart']),
      timeWindowEnd: serializer.fromJson<String?>(json['timeWindowEnd']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastModifiedDate': serializer.toJson<DateTime>(lastModifiedDate),
      'enabled': serializer.toJson<bool>(enabled),
      'serverId': serializer.toJson<int?>(serverId),
      'customerPreferenceId': serializer.toJson<String>(customerPreferenceId),
      'customerId': serializer.toJson<String>(customerId),
      'dayOfWeek': serializer.toJson<int>(dayOfWeek),
      'timeWindowStart': serializer.toJson<String>(timeWindowStart),
      'timeWindowEnd': serializer.toJson<String?>(timeWindowEnd),
    };
  }

  CustomerPreferenceTableData copyWith({
    DateTime? createdAt,
    DateTime? lastModifiedDate,
    bool? enabled,
    Value<int?> serverId = const Value.absent(),
    String? customerPreferenceId,
    String? customerId,
    int? dayOfWeek,
    String? timeWindowStart,
    Value<String?> timeWindowEnd = const Value.absent(),
  }) => CustomerPreferenceTableData(
    createdAt: createdAt ?? this.createdAt,
    lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
    enabled: enabled ?? this.enabled,
    serverId: serverId.present ? serverId.value : this.serverId,
    customerPreferenceId: customerPreferenceId ?? this.customerPreferenceId,
    customerId: customerId ?? this.customerId,
    dayOfWeek: dayOfWeek ?? this.dayOfWeek,
    timeWindowStart: timeWindowStart ?? this.timeWindowStart,
    timeWindowEnd: timeWindowEnd.present
        ? timeWindowEnd.value
        : this.timeWindowEnd,
  );
  CustomerPreferenceTableData copyWithCompanion(
    CustomerPreferenceTableCompanion data,
  ) {
    return CustomerPreferenceTableData(
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastModifiedDate: data.lastModifiedDate.present
          ? data.lastModifiedDate.value
          : this.lastModifiedDate,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      customerPreferenceId: data.customerPreferenceId.present
          ? data.customerPreferenceId.value
          : this.customerPreferenceId,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      dayOfWeek: data.dayOfWeek.present ? data.dayOfWeek.value : this.dayOfWeek,
      timeWindowStart: data.timeWindowStart.present
          ? data.timeWindowStart.value
          : this.timeWindowStart,
      timeWindowEnd: data.timeWindowEnd.present
          ? data.timeWindowEnd.value
          : this.timeWindowEnd,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomerPreferenceTableData(')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedDate: $lastModifiedDate, ')
          ..write('enabled: $enabled, ')
          ..write('serverId: $serverId, ')
          ..write('customerPreferenceId: $customerPreferenceId, ')
          ..write('customerId: $customerId, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('timeWindowStart: $timeWindowStart, ')
          ..write('timeWindowEnd: $timeWindowEnd')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    createdAt,
    lastModifiedDate,
    enabled,
    serverId,
    customerPreferenceId,
    customerId,
    dayOfWeek,
    timeWindowStart,
    timeWindowEnd,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerPreferenceTableData &&
          other.createdAt == this.createdAt &&
          other.lastModifiedDate == this.lastModifiedDate &&
          other.enabled == this.enabled &&
          other.serverId == this.serverId &&
          other.customerPreferenceId == this.customerPreferenceId &&
          other.customerId == this.customerId &&
          other.dayOfWeek == this.dayOfWeek &&
          other.timeWindowStart == this.timeWindowStart &&
          other.timeWindowEnd == this.timeWindowEnd);
}

class CustomerPreferenceTableCompanion
    extends UpdateCompanion<CustomerPreferenceTableData> {
  final Value<DateTime> createdAt;
  final Value<DateTime> lastModifiedDate;
  final Value<bool> enabled;
  final Value<int?> serverId;
  final Value<String> customerPreferenceId;
  final Value<String> customerId;
  final Value<int> dayOfWeek;
  final Value<String> timeWindowStart;
  final Value<String?> timeWindowEnd;
  final Value<int> rowid;
  const CustomerPreferenceTableCompanion({
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.serverId = const Value.absent(),
    this.customerPreferenceId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.dayOfWeek = const Value.absent(),
    this.timeWindowStart = const Value.absent(),
    this.timeWindowEnd = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomerPreferenceTableCompanion.insert({
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.serverId = const Value.absent(),
    this.customerPreferenceId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.dayOfWeek = const Value.absent(),
    required String timeWindowStart,
    this.timeWindowEnd = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : timeWindowStart = Value(timeWindowStart);
  static Insertable<CustomerPreferenceTableData> custom({
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastModifiedDate,
    Expression<bool>? enabled,
    Expression<int>? serverId,
    Expression<String>? customerPreferenceId,
    Expression<String>? customerId,
    Expression<int>? dayOfWeek,
    Expression<String>? timeWindowStart,
    Expression<String>? timeWindowEnd,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (lastModifiedDate != null) 'last_modified_date': lastModifiedDate,
      if (enabled != null) 'enabled': enabled,
      if (serverId != null) 'server_id': serverId,
      if (customerPreferenceId != null)
        'customer_preference_id': customerPreferenceId,
      if (customerId != null) 'customer_id': customerId,
      if (dayOfWeek != null) 'day_of_week': dayOfWeek,
      if (timeWindowStart != null) 'time_window_start': timeWindowStart,
      if (timeWindowEnd != null) 'time_window_end': timeWindowEnd,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomerPreferenceTableCompanion copyWith({
    Value<DateTime>? createdAt,
    Value<DateTime>? lastModifiedDate,
    Value<bool>? enabled,
    Value<int?>? serverId,
    Value<String>? customerPreferenceId,
    Value<String>? customerId,
    Value<int>? dayOfWeek,
    Value<String>? timeWindowStart,
    Value<String?>? timeWindowEnd,
    Value<int>? rowid,
  }) {
    return CustomerPreferenceTableCompanion(
      createdAt: createdAt ?? this.createdAt,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      enabled: enabled ?? this.enabled,
      serverId: serverId ?? this.serverId,
      customerPreferenceId: customerPreferenceId ?? this.customerPreferenceId,
      customerId: customerId ?? this.customerId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      timeWindowStart: timeWindowStart ?? this.timeWindowStart,
      timeWindowEnd: timeWindowEnd ?? this.timeWindowEnd,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastModifiedDate.present) {
      map['last_modified_date'] = Variable<DateTime>(lastModifiedDate.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (customerPreferenceId.present) {
      map['customer_preference_id'] = Variable<String>(
        customerPreferenceId.value,
      );
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (dayOfWeek.present) {
      map['day_of_week'] = Variable<int>(dayOfWeek.value);
    }
    if (timeWindowStart.present) {
      map['time_window_start'] = Variable<String>(timeWindowStart.value);
    }
    if (timeWindowEnd.present) {
      map['time_window_end'] = Variable<String>(timeWindowEnd.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomerPreferenceTableCompanion(')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedDate: $lastModifiedDate, ')
          ..write('enabled: $enabled, ')
          ..write('serverId: $serverId, ')
          ..write('customerPreferenceId: $customerPreferenceId, ')
          ..write('customerId: $customerId, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('timeWindowStart: $timeWindowStart, ')
          ..write('timeWindowEnd: $timeWindowEnd, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RouteTableTable extends RouteTable
    with TableInfo<$RouteTableTable, RouteTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RouteTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastModifiedDateMeta = const VerificationMeta(
    'lastModifiedDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastModifiedDate =
      GeneratedColumn<DateTime>(
        'last_modified_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _routeIdMeta = const VerificationMeta(
    'routeId',
  );
  @override
  late final GeneratedColumn<String> routeId = GeneratedColumn<String>(
    'route_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => uuid.v4(),
  );
  static const VerificationMeta _driverNameMeta = const VerificationMeta(
    'driverName',
  );
  @override
  late final GeneratedColumn<String> driverName = GeneratedColumn<String>(
    'driver_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _route_dateMeta = const VerificationMeta(
    'route_date',
  );
  @override
  late final GeneratedColumn<String> route_date = GeneratedColumn<String>(
    'route_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _started_atMeta = const VerificationMeta(
    'started_at',
  );
  @override
  late final GeneratedColumn<int> started_at = GeneratedColumn<int>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _completed_atMeta = const VerificationMeta(
    'completed_at',
  );
  @override
  late final GeneratedColumn<String> completed_at = GeneratedColumn<String>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _last_modifiedMeta = const VerificationMeta(
    'last_modified',
  );
  @override
  late final GeneratedColumn<String> last_modified = GeneratedColumn<String>(
    'last_modified',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _availableMeta = const VerificationMeta(
    'available',
  );
  @override
  late final GeneratedColumn<String> available = GeneratedColumn<String>(
    'available',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    createdAt,
    lastModifiedDate,
    enabled,
    serverId,
    routeId,
    driverName,
    route_date,
    started_at,
    completed_at,
    last_modified,
    available,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'routes';
  @override
  VerificationContext validateIntegrity(
    Insertable<RouteTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('last_modified_date')) {
      context.handle(
        _lastModifiedDateMeta,
        lastModifiedDate.isAcceptableOrUnknown(
          data['last_modified_date']!,
          _lastModifiedDateMeta,
        ),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('route_id')) {
      context.handle(
        _routeIdMeta,
        routeId.isAcceptableOrUnknown(data['route_id']!, _routeIdMeta),
      );
    }
    if (data.containsKey('driver_name')) {
      context.handle(
        _driverNameMeta,
        driverName.isAcceptableOrUnknown(data['driver_name']!, _driverNameMeta),
      );
    }
    if (data.containsKey('route_date')) {
      context.handle(
        _route_dateMeta,
        route_date.isAcceptableOrUnknown(data['route_date']!, _route_dateMeta),
      );
    } else if (isInserting) {
      context.missing(_route_dateMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _started_atMeta,
        started_at.isAcceptableOrUnknown(data['started_at']!, _started_atMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completed_atMeta,
        completed_at.isAcceptableOrUnknown(
          data['completed_at']!,
          _completed_atMeta,
        ),
      );
    }
    if (data.containsKey('last_modified')) {
      context.handle(
        _last_modifiedMeta,
        last_modified.isAcceptableOrUnknown(
          data['last_modified']!,
          _last_modifiedMeta,
        ),
      );
    }
    if (data.containsKey('available')) {
      context.handle(
        _availableMeta,
        available.isAcceptableOrUnknown(data['available']!, _availableMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {routeId};
  @override
  RouteTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RouteTableData(
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastModifiedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified_date'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      routeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route_id'],
      )!,
      driverName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}driver_name'],
      ),
      route_date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route_date'],
      )!,
      started_at: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at'],
      )!,
      completed_at: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}completed_at'],
      ),
      last_modified: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_modified'],
      ),
      available: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}available'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      ),
    );
  }

  @override
  $RouteTableTable createAlias(String alias) {
    return $RouteTableTable(attachedDatabase, alias);
  }
}

class RouteTableData extends DataClass implements Insertable<RouteTableData> {
  final DateTime createdAt;
  final DateTime lastModifiedDate;
  final bool enabled;
  final int? serverId;
  final String routeId;
  final String? driverName;
  final String route_date;
  final int started_at;
  final String? completed_at;
  final String? last_modified;
  final String? available;
  final String? status;
  const RouteTableData({
    required this.createdAt,
    required this.lastModifiedDate,
    required this.enabled,
    this.serverId,
    required this.routeId,
    this.driverName,
    required this.route_date,
    required this.started_at,
    this.completed_at,
    this.last_modified,
    this.available,
    this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_modified_date'] = Variable<DateTime>(lastModifiedDate);
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['route_id'] = Variable<String>(routeId);
    if (!nullToAbsent || driverName != null) {
      map['driver_name'] = Variable<String>(driverName);
    }
    map['route_date'] = Variable<String>(route_date);
    map['started_at'] = Variable<int>(started_at);
    if (!nullToAbsent || completed_at != null) {
      map['completed_at'] = Variable<String>(completed_at);
    }
    if (!nullToAbsent || last_modified != null) {
      map['last_modified'] = Variable<String>(last_modified);
    }
    if (!nullToAbsent || available != null) {
      map['available'] = Variable<String>(available);
    }
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    return map;
  }

  RouteTableCompanion toCompanion(bool nullToAbsent) {
    return RouteTableCompanion(
      createdAt: Value(createdAt),
      lastModifiedDate: Value(lastModifiedDate),
      enabled: Value(enabled),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      routeId: Value(routeId),
      driverName: driverName == null && nullToAbsent
          ? const Value.absent()
          : Value(driverName),
      route_date: Value(route_date),
      started_at: Value(started_at),
      completed_at: completed_at == null && nullToAbsent
          ? const Value.absent()
          : Value(completed_at),
      last_modified: last_modified == null && nullToAbsent
          ? const Value.absent()
          : Value(last_modified),
      available: available == null && nullToAbsent
          ? const Value.absent()
          : Value(available),
      status: status == null && nullToAbsent
          ? const Value.absent()
          : Value(status),
    );
  }

  factory RouteTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RouteTableData(
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastModifiedDate: serializer.fromJson<DateTime>(json['lastModifiedDate']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      routeId: serializer.fromJson<String>(json['routeId']),
      driverName: serializer.fromJson<String?>(json['driverName']),
      route_date: serializer.fromJson<String>(json['route_date']),
      started_at: serializer.fromJson<int>(json['started_at']),
      completed_at: serializer.fromJson<String?>(json['completed_at']),
      last_modified: serializer.fromJson<String?>(json['last_modified']),
      available: serializer.fromJson<String?>(json['available']),
      status: serializer.fromJson<String?>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastModifiedDate': serializer.toJson<DateTime>(lastModifiedDate),
      'enabled': serializer.toJson<bool>(enabled),
      'serverId': serializer.toJson<int?>(serverId),
      'routeId': serializer.toJson<String>(routeId),
      'driverName': serializer.toJson<String?>(driverName),
      'route_date': serializer.toJson<String>(route_date),
      'started_at': serializer.toJson<int>(started_at),
      'completed_at': serializer.toJson<String?>(completed_at),
      'last_modified': serializer.toJson<String?>(last_modified),
      'available': serializer.toJson<String?>(available),
      'status': serializer.toJson<String?>(status),
    };
  }

  RouteTableData copyWith({
    DateTime? createdAt,
    DateTime? lastModifiedDate,
    bool? enabled,
    Value<int?> serverId = const Value.absent(),
    String? routeId,
    Value<String?> driverName = const Value.absent(),
    String? route_date,
    int? started_at,
    Value<String?> completed_at = const Value.absent(),
    Value<String?> last_modified = const Value.absent(),
    Value<String?> available = const Value.absent(),
    Value<String?> status = const Value.absent(),
  }) => RouteTableData(
    createdAt: createdAt ?? this.createdAt,
    lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
    enabled: enabled ?? this.enabled,
    serverId: serverId.present ? serverId.value : this.serverId,
    routeId: routeId ?? this.routeId,
    driverName: driverName.present ? driverName.value : this.driverName,
    route_date: route_date ?? this.route_date,
    started_at: started_at ?? this.started_at,
    completed_at: completed_at.present ? completed_at.value : this.completed_at,
    last_modified: last_modified.present
        ? last_modified.value
        : this.last_modified,
    available: available.present ? available.value : this.available,
    status: status.present ? status.value : this.status,
  );
  RouteTableData copyWithCompanion(RouteTableCompanion data) {
    return RouteTableData(
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastModifiedDate: data.lastModifiedDate.present
          ? data.lastModifiedDate.value
          : this.lastModifiedDate,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      routeId: data.routeId.present ? data.routeId.value : this.routeId,
      driverName: data.driverName.present
          ? data.driverName.value
          : this.driverName,
      route_date: data.route_date.present
          ? data.route_date.value
          : this.route_date,
      started_at: data.started_at.present
          ? data.started_at.value
          : this.started_at,
      completed_at: data.completed_at.present
          ? data.completed_at.value
          : this.completed_at,
      last_modified: data.last_modified.present
          ? data.last_modified.value
          : this.last_modified,
      available: data.available.present ? data.available.value : this.available,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RouteTableData(')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedDate: $lastModifiedDate, ')
          ..write('enabled: $enabled, ')
          ..write('serverId: $serverId, ')
          ..write('routeId: $routeId, ')
          ..write('driverName: $driverName, ')
          ..write('route_date: $route_date, ')
          ..write('started_at: $started_at, ')
          ..write('completed_at: $completed_at, ')
          ..write('last_modified: $last_modified, ')
          ..write('available: $available, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    createdAt,
    lastModifiedDate,
    enabled,
    serverId,
    routeId,
    driverName,
    route_date,
    started_at,
    completed_at,
    last_modified,
    available,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RouteTableData &&
          other.createdAt == this.createdAt &&
          other.lastModifiedDate == this.lastModifiedDate &&
          other.enabled == this.enabled &&
          other.serverId == this.serverId &&
          other.routeId == this.routeId &&
          other.driverName == this.driverName &&
          other.route_date == this.route_date &&
          other.started_at == this.started_at &&
          other.completed_at == this.completed_at &&
          other.last_modified == this.last_modified &&
          other.available == this.available &&
          other.status == this.status);
}

class RouteTableCompanion extends UpdateCompanion<RouteTableData> {
  final Value<DateTime> createdAt;
  final Value<DateTime> lastModifiedDate;
  final Value<bool> enabled;
  final Value<int?> serverId;
  final Value<String> routeId;
  final Value<String?> driverName;
  final Value<String> route_date;
  final Value<int> started_at;
  final Value<String?> completed_at;
  final Value<String?> last_modified;
  final Value<String?> available;
  final Value<String?> status;
  final Value<int> rowid;
  const RouteTableCompanion({
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.serverId = const Value.absent(),
    this.routeId = const Value.absent(),
    this.driverName = const Value.absent(),
    this.route_date = const Value.absent(),
    this.started_at = const Value.absent(),
    this.completed_at = const Value.absent(),
    this.last_modified = const Value.absent(),
    this.available = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RouteTableCompanion.insert({
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.serverId = const Value.absent(),
    this.routeId = const Value.absent(),
    this.driverName = const Value.absent(),
    required String route_date,
    this.started_at = const Value.absent(),
    this.completed_at = const Value.absent(),
    this.last_modified = const Value.absent(),
    this.available = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : route_date = Value(route_date);
  static Insertable<RouteTableData> custom({
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastModifiedDate,
    Expression<bool>? enabled,
    Expression<int>? serverId,
    Expression<String>? routeId,
    Expression<String>? driverName,
    Expression<String>? route_date,
    Expression<int>? started_at,
    Expression<String>? completed_at,
    Expression<String>? last_modified,
    Expression<String>? available,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (lastModifiedDate != null) 'last_modified_date': lastModifiedDate,
      if (enabled != null) 'enabled': enabled,
      if (serverId != null) 'server_id': serverId,
      if (routeId != null) 'route_id': routeId,
      if (driverName != null) 'driver_name': driverName,
      if (route_date != null) 'route_date': route_date,
      if (started_at != null) 'started_at': started_at,
      if (completed_at != null) 'completed_at': completed_at,
      if (last_modified != null) 'last_modified': last_modified,
      if (available != null) 'available': available,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RouteTableCompanion copyWith({
    Value<DateTime>? createdAt,
    Value<DateTime>? lastModifiedDate,
    Value<bool>? enabled,
    Value<int?>? serverId,
    Value<String>? routeId,
    Value<String?>? driverName,
    Value<String>? route_date,
    Value<int>? started_at,
    Value<String?>? completed_at,
    Value<String?>? last_modified,
    Value<String?>? available,
    Value<String?>? status,
    Value<int>? rowid,
  }) {
    return RouteTableCompanion(
      createdAt: createdAt ?? this.createdAt,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      enabled: enabled ?? this.enabled,
      serverId: serverId ?? this.serverId,
      routeId: routeId ?? this.routeId,
      driverName: driverName ?? this.driverName,
      route_date: route_date ?? this.route_date,
      started_at: started_at ?? this.started_at,
      completed_at: completed_at ?? this.completed_at,
      last_modified: last_modified ?? this.last_modified,
      available: available ?? this.available,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastModifiedDate.present) {
      map['last_modified_date'] = Variable<DateTime>(lastModifiedDate.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (routeId.present) {
      map['route_id'] = Variable<String>(routeId.value);
    }
    if (driverName.present) {
      map['driver_name'] = Variable<String>(driverName.value);
    }
    if (route_date.present) {
      map['route_date'] = Variable<String>(route_date.value);
    }
    if (started_at.present) {
      map['started_at'] = Variable<int>(started_at.value);
    }
    if (completed_at.present) {
      map['completed_at'] = Variable<String>(completed_at.value);
    }
    if (last_modified.present) {
      map['last_modified'] = Variable<String>(last_modified.value);
    }
    if (available.present) {
      map['available'] = Variable<String>(available.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RouteTableCompanion(')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedDate: $lastModifiedDate, ')
          ..write('enabled: $enabled, ')
          ..write('serverId: $serverId, ')
          ..write('routeId: $routeId, ')
          ..write('driverName: $driverName, ')
          ..write('route_date: $route_date, ')
          ..write('started_at: $started_at, ')
          ..write('completed_at: $completed_at, ')
          ..write('last_modified: $last_modified, ')
          ..write('available: $available, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RouteStopTableTable extends RouteStopTable
    with TableInfo<$RouteStopTableTable, RouteStopTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RouteStopTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastModifiedDateMeta = const VerificationMeta(
    'lastModifiedDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastModifiedDate =
      GeneratedColumn<DateTime>(
        'last_modified_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _routeStopIdMeta = const VerificationMeta(
    'routeStopId',
  );
  @override
  late final GeneratedColumn<String> routeStopId = GeneratedColumn<String>(
    'route_stop_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => uuid.v4(),
  );
  static const VerificationMeta _routeIdMeta = const VerificationMeta(
    'routeId',
  );
  @override
  late final GeneratedColumn<String> routeId = GeneratedColumn<String>(
    'route_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES routes (route_id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES customers (customer_id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _customerAddressIdMeta = const VerificationMeta(
    'customerAddressId',
  );
  @override
  late final GeneratedColumn<String> customerAddressId =
      GeneratedColumn<String>(
        'customer_address_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES customer_addresses (address_id) ON DELETE SET NULL',
        ),
      );
  static const VerificationMeta _sequenceMeta = const VerificationMeta(
    'sequence',
  );
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
    'sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _scheduledAtMeta = const VerificationMeta(
    'scheduledAt',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledAt = GeneratedColumn<DateTime>(
    'scheduled_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visitedAtMeta = const VerificationMeta(
    'visitedAt',
  );
  @override
  late final GeneratedColumn<DateTime> visitedAt = GeneratedColumn<DateTime>(
    'visited_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scheduledTimeMeta = const VerificationMeta(
    'scheduledTime',
  );
  @override
  late final GeneratedColumn<String> scheduledTime = GeneratedColumn<String>(
    'scheduled_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rescheduledFromStopIdMeta =
      const VerificationMeta('rescheduledFromStopId');
  @override
  late final GeneratedColumn<String> rescheduledFromStopId =
      GeneratedColumn<String>(
        'rescheduled_from_stop_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    createdAt,
    lastModifiedDate,
    enabled,
    serverId,
    routeStopId,
    routeId,
    customerId,
    customerAddressId,
    sequence,
    status,
    scheduledAt,
    visitedAt,
    notes,
    scheduledTime,
    rescheduledFromStopId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'route_stops';
  @override
  VerificationContext validateIntegrity(
    Insertable<RouteStopTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('last_modified_date')) {
      context.handle(
        _lastModifiedDateMeta,
        lastModifiedDate.isAcceptableOrUnknown(
          data['last_modified_date']!,
          _lastModifiedDateMeta,
        ),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('route_stop_id')) {
      context.handle(
        _routeStopIdMeta,
        routeStopId.isAcceptableOrUnknown(
          data['route_stop_id']!,
          _routeStopIdMeta,
        ),
      );
    }
    if (data.containsKey('route_id')) {
      context.handle(
        _routeIdMeta,
        routeId.isAcceptableOrUnknown(data['route_id']!, _routeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_routeIdMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('customer_address_id')) {
      context.handle(
        _customerAddressIdMeta,
        customerAddressId.isAcceptableOrUnknown(
          data['customer_address_id']!,
          _customerAddressIdMeta,
        ),
      );
    }
    if (data.containsKey('sequence')) {
      context.handle(
        _sequenceMeta,
        sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta),
      );
    } else if (isInserting) {
      context.missing(_sequenceMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('scheduled_at')) {
      context.handle(
        _scheduledAtMeta,
        scheduledAt.isAcceptableOrUnknown(
          data['scheduled_at']!,
          _scheduledAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledAtMeta);
    }
    if (data.containsKey('visited_at')) {
      context.handle(
        _visitedAtMeta,
        visitedAt.isAcceptableOrUnknown(data['visited_at']!, _visitedAtMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('scheduled_time')) {
      context.handle(
        _scheduledTimeMeta,
        scheduledTime.isAcceptableOrUnknown(
          data['scheduled_time']!,
          _scheduledTimeMeta,
        ),
      );
    }
    if (data.containsKey('rescheduled_from_stop_id')) {
      context.handle(
        _rescheduledFromStopIdMeta,
        rescheduledFromStopId.isAcceptableOrUnknown(
          data['rescheduled_from_stop_id']!,
          _rescheduledFromStopIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {routeStopId};
  @override
  RouteStopTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RouteStopTableData(
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastModifiedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified_date'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      routeStopId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route_stop_id'],
      )!,
      routeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route_id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      )!,
      customerAddressId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_address_id'],
      ),
      sequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      scheduledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_at'],
      )!,
      visitedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}visited_at'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      scheduledTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scheduled_time'],
      ),
      rescheduledFromStopId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rescheduled_from_stop_id'],
      ),
    );
  }

  @override
  $RouteStopTableTable createAlias(String alias) {
    return $RouteStopTableTable(attachedDatabase, alias);
  }
}

class RouteStopTableData extends DataClass
    implements Insertable<RouteStopTableData> {
  final DateTime createdAt;
  final DateTime lastModifiedDate;
  final bool enabled;
  final int? serverId;
  final String routeStopId;
  final String routeId;
  final String customerId;
  final String? customerAddressId;
  final int sequence;
  final String status;
  final DateTime scheduledAt;
  final DateTime? visitedAt;
  final String? notes;
  final String? scheduledTime;
  final String? rescheduledFromStopId;
  const RouteStopTableData({
    required this.createdAt,
    required this.lastModifiedDate,
    required this.enabled,
    this.serverId,
    required this.routeStopId,
    required this.routeId,
    required this.customerId,
    this.customerAddressId,
    required this.sequence,
    required this.status,
    required this.scheduledAt,
    this.visitedAt,
    this.notes,
    this.scheduledTime,
    this.rescheduledFromStopId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_modified_date'] = Variable<DateTime>(lastModifiedDate);
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['route_stop_id'] = Variable<String>(routeStopId);
    map['route_id'] = Variable<String>(routeId);
    map['customer_id'] = Variable<String>(customerId);
    if (!nullToAbsent || customerAddressId != null) {
      map['customer_address_id'] = Variable<String>(customerAddressId);
    }
    map['sequence'] = Variable<int>(sequence);
    map['status'] = Variable<String>(status);
    map['scheduled_at'] = Variable<DateTime>(scheduledAt);
    if (!nullToAbsent || visitedAt != null) {
      map['visited_at'] = Variable<DateTime>(visitedAt);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || scheduledTime != null) {
      map['scheduled_time'] = Variable<String>(scheduledTime);
    }
    if (!nullToAbsent || rescheduledFromStopId != null) {
      map['rescheduled_from_stop_id'] = Variable<String>(rescheduledFromStopId);
    }
    return map;
  }

  RouteStopTableCompanion toCompanion(bool nullToAbsent) {
    return RouteStopTableCompanion(
      createdAt: Value(createdAt),
      lastModifiedDate: Value(lastModifiedDate),
      enabled: Value(enabled),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      routeStopId: Value(routeStopId),
      routeId: Value(routeId),
      customerId: Value(customerId),
      customerAddressId: customerAddressId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerAddressId),
      sequence: Value(sequence),
      status: Value(status),
      scheduledAt: Value(scheduledAt),
      visitedAt: visitedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(visitedAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      scheduledTime: scheduledTime == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledTime),
      rescheduledFromStopId: rescheduledFromStopId == null && nullToAbsent
          ? const Value.absent()
          : Value(rescheduledFromStopId),
    );
  }

  factory RouteStopTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RouteStopTableData(
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastModifiedDate: serializer.fromJson<DateTime>(json['lastModifiedDate']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      routeStopId: serializer.fromJson<String>(json['routeStopId']),
      routeId: serializer.fromJson<String>(json['routeId']),
      customerId: serializer.fromJson<String>(json['customerId']),
      customerAddressId: serializer.fromJson<String?>(
        json['customerAddressId'],
      ),
      sequence: serializer.fromJson<int>(json['sequence']),
      status: serializer.fromJson<String>(json['status']),
      scheduledAt: serializer.fromJson<DateTime>(json['scheduledAt']),
      visitedAt: serializer.fromJson<DateTime?>(json['visitedAt']),
      notes: serializer.fromJson<String?>(json['notes']),
      scheduledTime: serializer.fromJson<String?>(json['scheduledTime']),
      rescheduledFromStopId: serializer.fromJson<String?>(
        json['rescheduledFromStopId'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastModifiedDate': serializer.toJson<DateTime>(lastModifiedDate),
      'enabled': serializer.toJson<bool>(enabled),
      'serverId': serializer.toJson<int?>(serverId),
      'routeStopId': serializer.toJson<String>(routeStopId),
      'routeId': serializer.toJson<String>(routeId),
      'customerId': serializer.toJson<String>(customerId),
      'customerAddressId': serializer.toJson<String?>(customerAddressId),
      'sequence': serializer.toJson<int>(sequence),
      'status': serializer.toJson<String>(status),
      'scheduledAt': serializer.toJson<DateTime>(scheduledAt),
      'visitedAt': serializer.toJson<DateTime?>(visitedAt),
      'notes': serializer.toJson<String?>(notes),
      'scheduledTime': serializer.toJson<String?>(scheduledTime),
      'rescheduledFromStopId': serializer.toJson<String?>(
        rescheduledFromStopId,
      ),
    };
  }

  RouteStopTableData copyWith({
    DateTime? createdAt,
    DateTime? lastModifiedDate,
    bool? enabled,
    Value<int?> serverId = const Value.absent(),
    String? routeStopId,
    String? routeId,
    String? customerId,
    Value<String?> customerAddressId = const Value.absent(),
    int? sequence,
    String? status,
    DateTime? scheduledAt,
    Value<DateTime?> visitedAt = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> scheduledTime = const Value.absent(),
    Value<String?> rescheduledFromStopId = const Value.absent(),
  }) => RouteStopTableData(
    createdAt: createdAt ?? this.createdAt,
    lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
    enabled: enabled ?? this.enabled,
    serverId: serverId.present ? serverId.value : this.serverId,
    routeStopId: routeStopId ?? this.routeStopId,
    routeId: routeId ?? this.routeId,
    customerId: customerId ?? this.customerId,
    customerAddressId: customerAddressId.present
        ? customerAddressId.value
        : this.customerAddressId,
    sequence: sequence ?? this.sequence,
    status: status ?? this.status,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    visitedAt: visitedAt.present ? visitedAt.value : this.visitedAt,
    notes: notes.present ? notes.value : this.notes,
    scheduledTime: scheduledTime.present
        ? scheduledTime.value
        : this.scheduledTime,
    rescheduledFromStopId: rescheduledFromStopId.present
        ? rescheduledFromStopId.value
        : this.rescheduledFromStopId,
  );
  RouteStopTableData copyWithCompanion(RouteStopTableCompanion data) {
    return RouteStopTableData(
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastModifiedDate: data.lastModifiedDate.present
          ? data.lastModifiedDate.value
          : this.lastModifiedDate,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      routeStopId: data.routeStopId.present
          ? data.routeStopId.value
          : this.routeStopId,
      routeId: data.routeId.present ? data.routeId.value : this.routeId,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      customerAddressId: data.customerAddressId.present
          ? data.customerAddressId.value
          : this.customerAddressId,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      status: data.status.present ? data.status.value : this.status,
      scheduledAt: data.scheduledAt.present
          ? data.scheduledAt.value
          : this.scheduledAt,
      visitedAt: data.visitedAt.present ? data.visitedAt.value : this.visitedAt,
      notes: data.notes.present ? data.notes.value : this.notes,
      scheduledTime: data.scheduledTime.present
          ? data.scheduledTime.value
          : this.scheduledTime,
      rescheduledFromStopId: data.rescheduledFromStopId.present
          ? data.rescheduledFromStopId.value
          : this.rescheduledFromStopId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RouteStopTableData(')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedDate: $lastModifiedDate, ')
          ..write('enabled: $enabled, ')
          ..write('serverId: $serverId, ')
          ..write('routeStopId: $routeStopId, ')
          ..write('routeId: $routeId, ')
          ..write('customerId: $customerId, ')
          ..write('customerAddressId: $customerAddressId, ')
          ..write('sequence: $sequence, ')
          ..write('status: $status, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('visitedAt: $visitedAt, ')
          ..write('notes: $notes, ')
          ..write('scheduledTime: $scheduledTime, ')
          ..write('rescheduledFromStopId: $rescheduledFromStopId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    createdAt,
    lastModifiedDate,
    enabled,
    serverId,
    routeStopId,
    routeId,
    customerId,
    customerAddressId,
    sequence,
    status,
    scheduledAt,
    visitedAt,
    notes,
    scheduledTime,
    rescheduledFromStopId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RouteStopTableData &&
          other.createdAt == this.createdAt &&
          other.lastModifiedDate == this.lastModifiedDate &&
          other.enabled == this.enabled &&
          other.serverId == this.serverId &&
          other.routeStopId == this.routeStopId &&
          other.routeId == this.routeId &&
          other.customerId == this.customerId &&
          other.customerAddressId == this.customerAddressId &&
          other.sequence == this.sequence &&
          other.status == this.status &&
          other.scheduledAt == this.scheduledAt &&
          other.visitedAt == this.visitedAt &&
          other.notes == this.notes &&
          other.scheduledTime == this.scheduledTime &&
          other.rescheduledFromStopId == this.rescheduledFromStopId);
}

class RouteStopTableCompanion extends UpdateCompanion<RouteStopTableData> {
  final Value<DateTime> createdAt;
  final Value<DateTime> lastModifiedDate;
  final Value<bool> enabled;
  final Value<int?> serverId;
  final Value<String> routeStopId;
  final Value<String> routeId;
  final Value<String> customerId;
  final Value<String?> customerAddressId;
  final Value<int> sequence;
  final Value<String> status;
  final Value<DateTime> scheduledAt;
  final Value<DateTime?> visitedAt;
  final Value<String?> notes;
  final Value<String?> scheduledTime;
  final Value<String?> rescheduledFromStopId;
  final Value<int> rowid;
  const RouteStopTableCompanion({
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.serverId = const Value.absent(),
    this.routeStopId = const Value.absent(),
    this.routeId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.customerAddressId = const Value.absent(),
    this.sequence = const Value.absent(),
    this.status = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.visitedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.scheduledTime = const Value.absent(),
    this.rescheduledFromStopId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RouteStopTableCompanion.insert({
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.serverId = const Value.absent(),
    this.routeStopId = const Value.absent(),
    required String routeId,
    required String customerId,
    this.customerAddressId = const Value.absent(),
    required int sequence,
    this.status = const Value.absent(),
    required DateTime scheduledAt,
    this.visitedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.scheduledTime = const Value.absent(),
    this.rescheduledFromStopId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : routeId = Value(routeId),
       customerId = Value(customerId),
       sequence = Value(sequence),
       scheduledAt = Value(scheduledAt);
  static Insertable<RouteStopTableData> custom({
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastModifiedDate,
    Expression<bool>? enabled,
    Expression<int>? serverId,
    Expression<String>? routeStopId,
    Expression<String>? routeId,
    Expression<String>? customerId,
    Expression<String>? customerAddressId,
    Expression<int>? sequence,
    Expression<String>? status,
    Expression<DateTime>? scheduledAt,
    Expression<DateTime>? visitedAt,
    Expression<String>? notes,
    Expression<String>? scheduledTime,
    Expression<String>? rescheduledFromStopId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (lastModifiedDate != null) 'last_modified_date': lastModifiedDate,
      if (enabled != null) 'enabled': enabled,
      if (serverId != null) 'server_id': serverId,
      if (routeStopId != null) 'route_stop_id': routeStopId,
      if (routeId != null) 'route_id': routeId,
      if (customerId != null) 'customer_id': customerId,
      if (customerAddressId != null) 'customer_address_id': customerAddressId,
      if (sequence != null) 'sequence': sequence,
      if (status != null) 'status': status,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
      if (visitedAt != null) 'visited_at': visitedAt,
      if (notes != null) 'notes': notes,
      if (scheduledTime != null) 'scheduled_time': scheduledTime,
      if (rescheduledFromStopId != null)
        'rescheduled_from_stop_id': rescheduledFromStopId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RouteStopTableCompanion copyWith({
    Value<DateTime>? createdAt,
    Value<DateTime>? lastModifiedDate,
    Value<bool>? enabled,
    Value<int?>? serverId,
    Value<String>? routeStopId,
    Value<String>? routeId,
    Value<String>? customerId,
    Value<String?>? customerAddressId,
    Value<int>? sequence,
    Value<String>? status,
    Value<DateTime>? scheduledAt,
    Value<DateTime?>? visitedAt,
    Value<String?>? notes,
    Value<String?>? scheduledTime,
    Value<String?>? rescheduledFromStopId,
    Value<int>? rowid,
  }) {
    return RouteStopTableCompanion(
      createdAt: createdAt ?? this.createdAt,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      enabled: enabled ?? this.enabled,
      serverId: serverId ?? this.serverId,
      routeStopId: routeStopId ?? this.routeStopId,
      routeId: routeId ?? this.routeId,
      customerId: customerId ?? this.customerId,
      customerAddressId: customerAddressId ?? this.customerAddressId,
      sequence: sequence ?? this.sequence,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      visitedAt: visitedAt ?? this.visitedAt,
      notes: notes ?? this.notes,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      rescheduledFromStopId:
          rescheduledFromStopId ?? this.rescheduledFromStopId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastModifiedDate.present) {
      map['last_modified_date'] = Variable<DateTime>(lastModifiedDate.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (routeStopId.present) {
      map['route_stop_id'] = Variable<String>(routeStopId.value);
    }
    if (routeId.present) {
      map['route_id'] = Variable<String>(routeId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (customerAddressId.present) {
      map['customer_address_id'] = Variable<String>(customerAddressId.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (scheduledAt.present) {
      map['scheduled_at'] = Variable<DateTime>(scheduledAt.value);
    }
    if (visitedAt.present) {
      map['visited_at'] = Variable<DateTime>(visitedAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (scheduledTime.present) {
      map['scheduled_time'] = Variable<String>(scheduledTime.value);
    }
    if (rescheduledFromStopId.present) {
      map['rescheduled_from_stop_id'] = Variable<String>(
        rescheduledFromStopId.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RouteStopTableCompanion(')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedDate: $lastModifiedDate, ')
          ..write('enabled: $enabled, ')
          ..write('serverId: $serverId, ')
          ..write('routeStopId: $routeStopId, ')
          ..write('routeId: $routeId, ')
          ..write('customerId: $customerId, ')
          ..write('customerAddressId: $customerAddressId, ')
          ..write('sequence: $sequence, ')
          ..write('status: $status, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('visitedAt: $visitedAt, ')
          ..write('notes: $notes, ')
          ..write('scheduledTime: $scheduledTime, ')
          ..write('rescheduledFromStopId: $rescheduledFromStopId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductTableTable extends ProductTable
    with TableInfo<$ProductTableTable, ProductTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastModifiedDateMeta = const VerificationMeta(
    'lastModifiedDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastModifiedDate =
      GeneratedColumn<DateTime>(
        'last_modified_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => uuid.v4(),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stockMeta = const VerificationMeta('stock');
  @override
  late final GeneratedColumn<int> stock = GeneratedColumn<int>(
    'stock',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    createdAt,
    lastModifiedDate,
    enabled,
    serverId,
    productId,
    name,
    description,
    price,
    stock,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('last_modified_date')) {
      context.handle(
        _lastModifiedDateMeta,
        lastModifiedDate.isAcceptableOrUnknown(
          data['last_modified_date']!,
          _lastModifiedDateMeta,
        ),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('stock')) {
      context.handle(
        _stockMeta,
        stock.isAcceptableOrUnknown(data['stock']!, _stockMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {productId};
  @override
  ProductTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductTableData(
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastModifiedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified_date'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price'],
      )!,
      stock: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stock'],
      )!,
    );
  }

  @override
  $ProductTableTable createAlias(String alias) {
    return $ProductTableTable(attachedDatabase, alias);
  }
}

class ProductTableData extends DataClass
    implements Insertable<ProductTableData> {
  final DateTime createdAt;
  final DateTime lastModifiedDate;
  final bool enabled;
  final int? serverId;
  final String productId;
  final String name;
  final String? description;
  final double price;
  final int stock;
  const ProductTableData({
    required this.createdAt,
    required this.lastModifiedDate,
    required this.enabled,
    this.serverId,
    required this.productId,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_modified_date'] = Variable<DateTime>(lastModifiedDate);
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['product_id'] = Variable<String>(productId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['price'] = Variable<double>(price);
    map['stock'] = Variable<int>(stock);
    return map;
  }

  ProductTableCompanion toCompanion(bool nullToAbsent) {
    return ProductTableCompanion(
      createdAt: Value(createdAt),
      lastModifiedDate: Value(lastModifiedDate),
      enabled: Value(enabled),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      productId: Value(productId),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      price: Value(price),
      stock: Value(stock),
    );
  }

  factory ProductTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductTableData(
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastModifiedDate: serializer.fromJson<DateTime>(json['lastModifiedDate']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      productId: serializer.fromJson<String>(json['productId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      price: serializer.fromJson<double>(json['price']),
      stock: serializer.fromJson<int>(json['stock']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastModifiedDate': serializer.toJson<DateTime>(lastModifiedDate),
      'enabled': serializer.toJson<bool>(enabled),
      'serverId': serializer.toJson<int?>(serverId),
      'productId': serializer.toJson<String>(productId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'price': serializer.toJson<double>(price),
      'stock': serializer.toJson<int>(stock),
    };
  }

  ProductTableData copyWith({
    DateTime? createdAt,
    DateTime? lastModifiedDate,
    bool? enabled,
    Value<int?> serverId = const Value.absent(),
    String? productId,
    String? name,
    Value<String?> description = const Value.absent(),
    double? price,
    int? stock,
  }) => ProductTableData(
    createdAt: createdAt ?? this.createdAt,
    lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
    enabled: enabled ?? this.enabled,
    serverId: serverId.present ? serverId.value : this.serverId,
    productId: productId ?? this.productId,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    price: price ?? this.price,
    stock: stock ?? this.stock,
  );
  ProductTableData copyWithCompanion(ProductTableCompanion data) {
    return ProductTableData(
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastModifiedDate: data.lastModifiedDate.present
          ? data.lastModifiedDate.value
          : this.lastModifiedDate,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      productId: data.productId.present ? data.productId.value : this.productId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      price: data.price.present ? data.price.value : this.price,
      stock: data.stock.present ? data.stock.value : this.stock,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductTableData(')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedDate: $lastModifiedDate, ')
          ..write('enabled: $enabled, ')
          ..write('serverId: $serverId, ')
          ..write('productId: $productId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('price: $price, ')
          ..write('stock: $stock')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    createdAt,
    lastModifiedDate,
    enabled,
    serverId,
    productId,
    name,
    description,
    price,
    stock,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductTableData &&
          other.createdAt == this.createdAt &&
          other.lastModifiedDate == this.lastModifiedDate &&
          other.enabled == this.enabled &&
          other.serverId == this.serverId &&
          other.productId == this.productId &&
          other.name == this.name &&
          other.description == this.description &&
          other.price == this.price &&
          other.stock == this.stock);
}

class ProductTableCompanion extends UpdateCompanion<ProductTableData> {
  final Value<DateTime> createdAt;
  final Value<DateTime> lastModifiedDate;
  final Value<bool> enabled;
  final Value<int?> serverId;
  final Value<String> productId;
  final Value<String> name;
  final Value<String?> description;
  final Value<double> price;
  final Value<int> stock;
  final Value<int> rowid;
  const ProductTableCompanion({
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.serverId = const Value.absent(),
    this.productId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.price = const Value.absent(),
    this.stock = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductTableCompanion.insert({
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.serverId = const Value.absent(),
    this.productId = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    required double price,
    this.stock = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       price = Value(price);
  static Insertable<ProductTableData> custom({
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastModifiedDate,
    Expression<bool>? enabled,
    Expression<int>? serverId,
    Expression<String>? productId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<double>? price,
    Expression<int>? stock,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (lastModifiedDate != null) 'last_modified_date': lastModifiedDate,
      if (enabled != null) 'enabled': enabled,
      if (serverId != null) 'server_id': serverId,
      if (productId != null) 'product_id': productId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (price != null) 'price': price,
      if (stock != null) 'stock': stock,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductTableCompanion copyWith({
    Value<DateTime>? createdAt,
    Value<DateTime>? lastModifiedDate,
    Value<bool>? enabled,
    Value<int?>? serverId,
    Value<String>? productId,
    Value<String>? name,
    Value<String?>? description,
    Value<double>? price,
    Value<int>? stock,
    Value<int>? rowid,
  }) {
    return ProductTableCompanion(
      createdAt: createdAt ?? this.createdAt,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      enabled: enabled ?? this.enabled,
      serverId: serverId ?? this.serverId,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastModifiedDate.present) {
      map['last_modified_date'] = Variable<DateTime>(lastModifiedDate.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (stock.present) {
      map['stock'] = Variable<int>(stock.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductTableCompanion(')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedDate: $lastModifiedDate, ')
          ..write('enabled: $enabled, ')
          ..write('serverId: $serverId, ')
          ..write('productId: $productId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('price: $price, ')
          ..write('stock: $stock, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RouteInventoryTableTable extends RouteInventoryTable
    with TableInfo<$RouteInventoryTableTable, RouteInventoryTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RouteInventoryTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastModifiedDateMeta = const VerificationMeta(
    'lastModifiedDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastModifiedDate =
      GeneratedColumn<DateTime>(
        'last_modified_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inventoryMovementIdMeta =
      const VerificationMeta('inventoryMovementId');
  @override
  late final GeneratedColumn<String> inventoryMovementId =
      GeneratedColumn<String>(
        'inventory_movement_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        clientDefault: () => uuid.v4(),
      );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (product_id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _movementTypeMeta = const VerificationMeta(
    'movementType',
  );
  @override
  late final GeneratedColumn<String> movementType = GeneratedColumn<String>(
    'movement_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _movementDateMeta = const VerificationMeta(
    'movementDate',
  );
  @override
  late final GeneratedColumn<DateTime> movementDate = GeneratedColumn<DateTime>(
    'movement_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    createdAt,
    lastModifiedDate,
    enabled,
    serverId,
    inventoryMovementId,
    productId,
    movementType,
    quantity,
    reason,
    movementDate,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_movements';
  @override
  VerificationContext validateIntegrity(
    Insertable<RouteInventoryTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('last_modified_date')) {
      context.handle(
        _lastModifiedDateMeta,
        lastModifiedDate.isAcceptableOrUnknown(
          data['last_modified_date']!,
          _lastModifiedDateMeta,
        ),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('inventory_movement_id')) {
      context.handle(
        _inventoryMovementIdMeta,
        inventoryMovementId.isAcceptableOrUnknown(
          data['inventory_movement_id']!,
          _inventoryMovementIdMeta,
        ),
      );
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('movement_type')) {
      context.handle(
        _movementTypeMeta,
        movementType.isAcceptableOrUnknown(
          data['movement_type']!,
          _movementTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_movementTypeMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('movement_date')) {
      context.handle(
        _movementDateMeta,
        movementDate.isAcceptableOrUnknown(
          data['movement_date']!,
          _movementDateMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {inventoryMovementId};
  @override
  RouteInventoryTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RouteInventoryTableData(
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastModifiedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified_date'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      inventoryMovementId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inventory_movement_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      movementType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}movement_type'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      movementDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}movement_date'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $RouteInventoryTableTable createAlias(String alias) {
    return $RouteInventoryTableTable(attachedDatabase, alias);
  }
}

class RouteInventoryTableData extends DataClass
    implements Insertable<RouteInventoryTableData> {
  final DateTime createdAt;
  final DateTime lastModifiedDate;
  final bool enabled;
  final int? serverId;
  final String inventoryMovementId;
  final String productId;
  final String movementType;
  final int quantity;
  final String reason;
  final DateTime movementDate;
  final String? notes;
  const RouteInventoryTableData({
    required this.createdAt,
    required this.lastModifiedDate,
    required this.enabled,
    this.serverId,
    required this.inventoryMovementId,
    required this.productId,
    required this.movementType,
    required this.quantity,
    required this.reason,
    required this.movementDate,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_modified_date'] = Variable<DateTime>(lastModifiedDate);
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['inventory_movement_id'] = Variable<String>(inventoryMovementId);
    map['product_id'] = Variable<String>(productId);
    map['movement_type'] = Variable<String>(movementType);
    map['quantity'] = Variable<int>(quantity);
    map['reason'] = Variable<String>(reason);
    map['movement_date'] = Variable<DateTime>(movementDate);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  RouteInventoryTableCompanion toCompanion(bool nullToAbsent) {
    return RouteInventoryTableCompanion(
      createdAt: Value(createdAt),
      lastModifiedDate: Value(lastModifiedDate),
      enabled: Value(enabled),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      inventoryMovementId: Value(inventoryMovementId),
      productId: Value(productId),
      movementType: Value(movementType),
      quantity: Value(quantity),
      reason: Value(reason),
      movementDate: Value(movementDate),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory RouteInventoryTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RouteInventoryTableData(
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastModifiedDate: serializer.fromJson<DateTime>(json['lastModifiedDate']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      inventoryMovementId: serializer.fromJson<String>(
        json['inventoryMovementId'],
      ),
      productId: serializer.fromJson<String>(json['productId']),
      movementType: serializer.fromJson<String>(json['movementType']),
      quantity: serializer.fromJson<int>(json['quantity']),
      reason: serializer.fromJson<String>(json['reason']),
      movementDate: serializer.fromJson<DateTime>(json['movementDate']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastModifiedDate': serializer.toJson<DateTime>(lastModifiedDate),
      'enabled': serializer.toJson<bool>(enabled),
      'serverId': serializer.toJson<int?>(serverId),
      'inventoryMovementId': serializer.toJson<String>(inventoryMovementId),
      'productId': serializer.toJson<String>(productId),
      'movementType': serializer.toJson<String>(movementType),
      'quantity': serializer.toJson<int>(quantity),
      'reason': serializer.toJson<String>(reason),
      'movementDate': serializer.toJson<DateTime>(movementDate),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  RouteInventoryTableData copyWith({
    DateTime? createdAt,
    DateTime? lastModifiedDate,
    bool? enabled,
    Value<int?> serverId = const Value.absent(),
    String? inventoryMovementId,
    String? productId,
    String? movementType,
    int? quantity,
    String? reason,
    DateTime? movementDate,
    Value<String?> notes = const Value.absent(),
  }) => RouteInventoryTableData(
    createdAt: createdAt ?? this.createdAt,
    lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
    enabled: enabled ?? this.enabled,
    serverId: serverId.present ? serverId.value : this.serverId,
    inventoryMovementId: inventoryMovementId ?? this.inventoryMovementId,
    productId: productId ?? this.productId,
    movementType: movementType ?? this.movementType,
    quantity: quantity ?? this.quantity,
    reason: reason ?? this.reason,
    movementDate: movementDate ?? this.movementDate,
    notes: notes.present ? notes.value : this.notes,
  );
  RouteInventoryTableData copyWithCompanion(RouteInventoryTableCompanion data) {
    return RouteInventoryTableData(
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastModifiedDate: data.lastModifiedDate.present
          ? data.lastModifiedDate.value
          : this.lastModifiedDate,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      inventoryMovementId: data.inventoryMovementId.present
          ? data.inventoryMovementId.value
          : this.inventoryMovementId,
      productId: data.productId.present ? data.productId.value : this.productId,
      movementType: data.movementType.present
          ? data.movementType.value
          : this.movementType,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      reason: data.reason.present ? data.reason.value : this.reason,
      movementDate: data.movementDate.present
          ? data.movementDate.value
          : this.movementDate,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RouteInventoryTableData(')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedDate: $lastModifiedDate, ')
          ..write('enabled: $enabled, ')
          ..write('serverId: $serverId, ')
          ..write('inventoryMovementId: $inventoryMovementId, ')
          ..write('productId: $productId, ')
          ..write('movementType: $movementType, ')
          ..write('quantity: $quantity, ')
          ..write('reason: $reason, ')
          ..write('movementDate: $movementDate, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    createdAt,
    lastModifiedDate,
    enabled,
    serverId,
    inventoryMovementId,
    productId,
    movementType,
    quantity,
    reason,
    movementDate,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RouteInventoryTableData &&
          other.createdAt == this.createdAt &&
          other.lastModifiedDate == this.lastModifiedDate &&
          other.enabled == this.enabled &&
          other.serverId == this.serverId &&
          other.inventoryMovementId == this.inventoryMovementId &&
          other.productId == this.productId &&
          other.movementType == this.movementType &&
          other.quantity == this.quantity &&
          other.reason == this.reason &&
          other.movementDate == this.movementDate &&
          other.notes == this.notes);
}

class RouteInventoryTableCompanion
    extends UpdateCompanion<RouteInventoryTableData> {
  final Value<DateTime> createdAt;
  final Value<DateTime> lastModifiedDate;
  final Value<bool> enabled;
  final Value<int?> serverId;
  final Value<String> inventoryMovementId;
  final Value<String> productId;
  final Value<String> movementType;
  final Value<int> quantity;
  final Value<String> reason;
  final Value<DateTime> movementDate;
  final Value<String?> notes;
  final Value<int> rowid;
  const RouteInventoryTableCompanion({
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.serverId = const Value.absent(),
    this.inventoryMovementId = const Value.absent(),
    this.productId = const Value.absent(),
    this.movementType = const Value.absent(),
    this.quantity = const Value.absent(),
    this.reason = const Value.absent(),
    this.movementDate = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RouteInventoryTableCompanion.insert({
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.serverId = const Value.absent(),
    this.inventoryMovementId = const Value.absent(),
    required String productId,
    required String movementType,
    required int quantity,
    required String reason,
    this.movementDate = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : productId = Value(productId),
       movementType = Value(movementType),
       quantity = Value(quantity),
       reason = Value(reason);
  static Insertable<RouteInventoryTableData> custom({
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastModifiedDate,
    Expression<bool>? enabled,
    Expression<int>? serverId,
    Expression<String>? inventoryMovementId,
    Expression<String>? productId,
    Expression<String>? movementType,
    Expression<int>? quantity,
    Expression<String>? reason,
    Expression<DateTime>? movementDate,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (lastModifiedDate != null) 'last_modified_date': lastModifiedDate,
      if (enabled != null) 'enabled': enabled,
      if (serverId != null) 'server_id': serverId,
      if (inventoryMovementId != null)
        'inventory_movement_id': inventoryMovementId,
      if (productId != null) 'product_id': productId,
      if (movementType != null) 'movement_type': movementType,
      if (quantity != null) 'quantity': quantity,
      if (reason != null) 'reason': reason,
      if (movementDate != null) 'movement_date': movementDate,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RouteInventoryTableCompanion copyWith({
    Value<DateTime>? createdAt,
    Value<DateTime>? lastModifiedDate,
    Value<bool>? enabled,
    Value<int?>? serverId,
    Value<String>? inventoryMovementId,
    Value<String>? productId,
    Value<String>? movementType,
    Value<int>? quantity,
    Value<String>? reason,
    Value<DateTime>? movementDate,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return RouteInventoryTableCompanion(
      createdAt: createdAt ?? this.createdAt,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      enabled: enabled ?? this.enabled,
      serverId: serverId ?? this.serverId,
      inventoryMovementId: inventoryMovementId ?? this.inventoryMovementId,
      productId: productId ?? this.productId,
      movementType: movementType ?? this.movementType,
      quantity: quantity ?? this.quantity,
      reason: reason ?? this.reason,
      movementDate: movementDate ?? this.movementDate,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastModifiedDate.present) {
      map['last_modified_date'] = Variable<DateTime>(lastModifiedDate.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (inventoryMovementId.present) {
      map['inventory_movement_id'] = Variable<String>(
        inventoryMovementId.value,
      );
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (movementType.present) {
      map['movement_type'] = Variable<String>(movementType.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (movementDate.present) {
      map['movement_date'] = Variable<DateTime>(movementDate.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RouteInventoryTableCompanion(')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedDate: $lastModifiedDate, ')
          ..write('enabled: $enabled, ')
          ..write('serverId: $serverId, ')
          ..write('inventoryMovementId: $inventoryMovementId, ')
          ..write('productId: $productId, ')
          ..write('movementType: $movementType, ')
          ..write('quantity: $quantity, ')
          ..write('reason: $reason, ')
          ..write('movementDate: $movementDate, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VisitOutcomeTableTable extends VisitOutcomeTable
    with TableInfo<$VisitOutcomeTableTable, VisitOutcomeTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VisitOutcomeTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _triggersRescheduleMeta =
      const VerificationMeta('triggersReschedule');
  @override
  late final GeneratedColumn<bool> triggersReschedule = GeneratedColumn<bool>(
    'triggers_reschedule',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("triggers_reschedule" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    code,
    name,
    triggersReschedule,
    enabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'visit_outcomes';
  @override
  VerificationContext validateIntegrity(
    Insertable<VisitOutcomeTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('triggers_reschedule')) {
      context.handle(
        _triggersRescheduleMeta,
        triggersReschedule.isAcceptableOrUnknown(
          data['triggers_reschedule']!,
          _triggersRescheduleMeta,
        ),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VisitOutcomeTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VisitOutcomeTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      triggersReschedule: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}triggers_reschedule'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
    );
  }

  @override
  $VisitOutcomeTableTable createAlias(String alias) {
    return $VisitOutcomeTableTable(attachedDatabase, alias);
  }
}

class VisitOutcomeTableData extends DataClass
    implements Insertable<VisitOutcomeTableData> {
  final int id;

  /// Stable server code (absent, refused, reschedule) that picks how it is shown.
  final String? code;
  final String name;
  final bool triggersReschedule;
  final bool enabled;
  const VisitOutcomeTableData({
    required this.id,
    this.code,
    required this.name,
    required this.triggersReschedule,
    required this.enabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || code != null) {
      map['code'] = Variable<String>(code);
    }
    map['name'] = Variable<String>(name);
    map['triggers_reschedule'] = Variable<bool>(triggersReschedule);
    map['enabled'] = Variable<bool>(enabled);
    return map;
  }

  VisitOutcomeTableCompanion toCompanion(bool nullToAbsent) {
    return VisitOutcomeTableCompanion(
      id: Value(id),
      code: code == null && nullToAbsent ? const Value.absent() : Value(code),
      name: Value(name),
      triggersReschedule: Value(triggersReschedule),
      enabled: Value(enabled),
    );
  }

  factory VisitOutcomeTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VisitOutcomeTableData(
      id: serializer.fromJson<int>(json['id']),
      code: serializer.fromJson<String?>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      triggersReschedule: serializer.fromJson<bool>(json['triggersReschedule']),
      enabled: serializer.fromJson<bool>(json['enabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'code': serializer.toJson<String?>(code),
      'name': serializer.toJson<String>(name),
      'triggersReschedule': serializer.toJson<bool>(triggersReschedule),
      'enabled': serializer.toJson<bool>(enabled),
    };
  }

  VisitOutcomeTableData copyWith({
    int? id,
    Value<String?> code = const Value.absent(),
    String? name,
    bool? triggersReschedule,
    bool? enabled,
  }) => VisitOutcomeTableData(
    id: id ?? this.id,
    code: code.present ? code.value : this.code,
    name: name ?? this.name,
    triggersReschedule: triggersReschedule ?? this.triggersReschedule,
    enabled: enabled ?? this.enabled,
  );
  VisitOutcomeTableData copyWithCompanion(VisitOutcomeTableCompanion data) {
    return VisitOutcomeTableData(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      triggersReschedule: data.triggersReschedule.present
          ? data.triggersReschedule.value
          : this.triggersReschedule,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VisitOutcomeTableData(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('triggersReschedule: $triggersReschedule, ')
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, code, name, triggersReschedule, enabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VisitOutcomeTableData &&
          other.id == this.id &&
          other.code == this.code &&
          other.name == this.name &&
          other.triggersReschedule == this.triggersReschedule &&
          other.enabled == this.enabled);
}

class VisitOutcomeTableCompanion
    extends UpdateCompanion<VisitOutcomeTableData> {
  final Value<int> id;
  final Value<String?> code;
  final Value<String> name;
  final Value<bool> triggersReschedule;
  final Value<bool> enabled;
  const VisitOutcomeTableCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.triggersReschedule = const Value.absent(),
    this.enabled = const Value.absent(),
  });
  VisitOutcomeTableCompanion.insert({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    required String name,
    this.triggersReschedule = const Value.absent(),
    this.enabled = const Value.absent(),
  }) : name = Value(name);
  static Insertable<VisitOutcomeTableData> custom({
    Expression<int>? id,
    Expression<String>? code,
    Expression<String>? name,
    Expression<bool>? triggersReschedule,
    Expression<bool>? enabled,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (triggersReschedule != null) 'triggers_reschedule': triggersReschedule,
      if (enabled != null) 'enabled': enabled,
    });
  }

  VisitOutcomeTableCompanion copyWith({
    Value<int>? id,
    Value<String?>? code,
    Value<String>? name,
    Value<bool>? triggersReschedule,
    Value<bool>? enabled,
  }) {
    return VisitOutcomeTableCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      triggersReschedule: triggersReschedule ?? this.triggersReschedule,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (triggersReschedule.present) {
      map['triggers_reschedule'] = Variable<bool>(triggersReschedule.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VisitOutcomeTableCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('triggersReschedule: $triggersReschedule, ')
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }
}

class $VisitTableTable extends VisitTable
    with TableInfo<$VisitTableTable, VisitTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VisitTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastModifiedDateMeta = const VerificationMeta(
    'lastModifiedDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastModifiedDate =
      GeneratedColumn<DateTime>(
        'last_modified_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _visitIdMeta = const VerificationMeta(
    'visitId',
  );
  @override
  late final GeneratedColumn<String> visitId = GeneratedColumn<String>(
    'visit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => uuid.v4(),
  );
  static const VerificationMeta _routeStopIdMeta = const VerificationMeta(
    'routeStopId',
  );
  @override
  late final GeneratedColumn<String> routeStopId = GeneratedColumn<String>(
    'route_stop_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES route_stops (route_stop_id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES customers (customer_id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _visitTypeMeta = const VerificationMeta(
    'visitType',
  );
  @override
  late final GeneratedColumn<String> visitType = GeneratedColumn<String>(
    'visit_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outcomeIdMeta = const VerificationMeta(
    'outcomeId',
  );
  @override
  late final GeneratedColumn<int> outcomeId = GeneratedColumn<int>(
    'outcome_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES visit_outcomes (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _arrived_atMeta = const VerificationMeta(
    'arrived_at',
  );
  @override
  late final GeneratedColumn<DateTime> arrived_at = GeneratedColumn<DateTime>(
    'arrived_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _observationsMeta = const VerificationMeta(
    'observations',
  );
  @override
  late final GeneratedColumn<String> observations = GeneratedColumn<String>(
    'observations',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _amountCollectedMeta = const VerificationMeta(
    'amountCollected',
  );
  @override
  late final GeneratedColumn<double> amountCollected = GeneratedColumn<double>(
    'amount_collected',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    createdAt,
    lastModifiedDate,
    enabled,
    serverId,
    visitId,
    routeStopId,
    customerId,
    visitType,
    outcomeId,
    arrived_at,
    observations,
    amountCollected,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'visits';
  @override
  VerificationContext validateIntegrity(
    Insertable<VisitTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('last_modified_date')) {
      context.handle(
        _lastModifiedDateMeta,
        lastModifiedDate.isAcceptableOrUnknown(
          data['last_modified_date']!,
          _lastModifiedDateMeta,
        ),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('visit_id')) {
      context.handle(
        _visitIdMeta,
        visitId.isAcceptableOrUnknown(data['visit_id']!, _visitIdMeta),
      );
    }
    if (data.containsKey('route_stop_id')) {
      context.handle(
        _routeStopIdMeta,
        routeStopId.isAcceptableOrUnknown(
          data['route_stop_id']!,
          _routeStopIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_routeStopIdMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('visit_type')) {
      context.handle(
        _visitTypeMeta,
        visitType.isAcceptableOrUnknown(data['visit_type']!, _visitTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_visitTypeMeta);
    }
    if (data.containsKey('outcome_id')) {
      context.handle(
        _outcomeIdMeta,
        outcomeId.isAcceptableOrUnknown(data['outcome_id']!, _outcomeIdMeta),
      );
    }
    if (data.containsKey('arrived_at')) {
      context.handle(
        _arrived_atMeta,
        arrived_at.isAcceptableOrUnknown(data['arrived_at']!, _arrived_atMeta),
      );
    } else if (isInserting) {
      context.missing(_arrived_atMeta);
    }
    if (data.containsKey('observations')) {
      context.handle(
        _observationsMeta,
        observations.isAcceptableOrUnknown(
          data['observations']!,
          _observationsMeta,
        ),
      );
    }
    if (data.containsKey('amount_collected')) {
      context.handle(
        _amountCollectedMeta,
        amountCollected.isAcceptableOrUnknown(
          data['amount_collected']!,
          _amountCollectedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {visitId};
  @override
  VisitTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VisitTableData(
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastModifiedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified_date'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      visitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visit_id'],
      )!,
      routeStopId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route_stop_id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      )!,
      visitType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visit_type'],
      )!,
      outcomeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}outcome_id'],
      ),
      arrived_at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}arrived_at'],
      )!,
      observations: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}observations'],
      ),
      amountCollected: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount_collected'],
      )!,
    );
  }

  @override
  $VisitTableTable createAlias(String alias) {
    return $VisitTableTable(attachedDatabase, alias);
  }
}

class VisitTableData extends DataClass implements Insertable<VisitTableData> {
  final DateTime createdAt;
  final DateTime lastModifiedDate;
  final bool enabled;
  final int? serverId;
  final String visitId;
  final String routeStopId;
  final String customerId;
  final String visitType;
  final int? outcomeId;
  final DateTime arrived_at;
  final String? observations;
  final double amountCollected;
  const VisitTableData({
    required this.createdAt,
    required this.lastModifiedDate,
    required this.enabled,
    this.serverId,
    required this.visitId,
    required this.routeStopId,
    required this.customerId,
    required this.visitType,
    this.outcomeId,
    required this.arrived_at,
    this.observations,
    required this.amountCollected,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_modified_date'] = Variable<DateTime>(lastModifiedDate);
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['visit_id'] = Variable<String>(visitId);
    map['route_stop_id'] = Variable<String>(routeStopId);
    map['customer_id'] = Variable<String>(customerId);
    map['visit_type'] = Variable<String>(visitType);
    if (!nullToAbsent || outcomeId != null) {
      map['outcome_id'] = Variable<int>(outcomeId);
    }
    map['arrived_at'] = Variable<DateTime>(arrived_at);
    if (!nullToAbsent || observations != null) {
      map['observations'] = Variable<String>(observations);
    }
    map['amount_collected'] = Variable<double>(amountCollected);
    return map;
  }

  VisitTableCompanion toCompanion(bool nullToAbsent) {
    return VisitTableCompanion(
      createdAt: Value(createdAt),
      lastModifiedDate: Value(lastModifiedDate),
      enabled: Value(enabled),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      visitId: Value(visitId),
      routeStopId: Value(routeStopId),
      customerId: Value(customerId),
      visitType: Value(visitType),
      outcomeId: outcomeId == null && nullToAbsent
          ? const Value.absent()
          : Value(outcomeId),
      arrived_at: Value(arrived_at),
      observations: observations == null && nullToAbsent
          ? const Value.absent()
          : Value(observations),
      amountCollected: Value(amountCollected),
    );
  }

  factory VisitTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VisitTableData(
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastModifiedDate: serializer.fromJson<DateTime>(json['lastModifiedDate']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      visitId: serializer.fromJson<String>(json['visitId']),
      routeStopId: serializer.fromJson<String>(json['routeStopId']),
      customerId: serializer.fromJson<String>(json['customerId']),
      visitType: serializer.fromJson<String>(json['visitType']),
      outcomeId: serializer.fromJson<int?>(json['outcomeId']),
      arrived_at: serializer.fromJson<DateTime>(json['arrived_at']),
      observations: serializer.fromJson<String?>(json['observations']),
      amountCollected: serializer.fromJson<double>(json['amountCollected']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastModifiedDate': serializer.toJson<DateTime>(lastModifiedDate),
      'enabled': serializer.toJson<bool>(enabled),
      'serverId': serializer.toJson<int?>(serverId),
      'visitId': serializer.toJson<String>(visitId),
      'routeStopId': serializer.toJson<String>(routeStopId),
      'customerId': serializer.toJson<String>(customerId),
      'visitType': serializer.toJson<String>(visitType),
      'outcomeId': serializer.toJson<int?>(outcomeId),
      'arrived_at': serializer.toJson<DateTime>(arrived_at),
      'observations': serializer.toJson<String?>(observations),
      'amountCollected': serializer.toJson<double>(amountCollected),
    };
  }

  VisitTableData copyWith({
    DateTime? createdAt,
    DateTime? lastModifiedDate,
    bool? enabled,
    Value<int?> serverId = const Value.absent(),
    String? visitId,
    String? routeStopId,
    String? customerId,
    String? visitType,
    Value<int?> outcomeId = const Value.absent(),
    DateTime? arrived_at,
    Value<String?> observations = const Value.absent(),
    double? amountCollected,
  }) => VisitTableData(
    createdAt: createdAt ?? this.createdAt,
    lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
    enabled: enabled ?? this.enabled,
    serverId: serverId.present ? serverId.value : this.serverId,
    visitId: visitId ?? this.visitId,
    routeStopId: routeStopId ?? this.routeStopId,
    customerId: customerId ?? this.customerId,
    visitType: visitType ?? this.visitType,
    outcomeId: outcomeId.present ? outcomeId.value : this.outcomeId,
    arrived_at: arrived_at ?? this.arrived_at,
    observations: observations.present ? observations.value : this.observations,
    amountCollected: amountCollected ?? this.amountCollected,
  );
  VisitTableData copyWithCompanion(VisitTableCompanion data) {
    return VisitTableData(
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastModifiedDate: data.lastModifiedDate.present
          ? data.lastModifiedDate.value
          : this.lastModifiedDate,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      visitId: data.visitId.present ? data.visitId.value : this.visitId,
      routeStopId: data.routeStopId.present
          ? data.routeStopId.value
          : this.routeStopId,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      visitType: data.visitType.present ? data.visitType.value : this.visitType,
      outcomeId: data.outcomeId.present ? data.outcomeId.value : this.outcomeId,
      arrived_at: data.arrived_at.present
          ? data.arrived_at.value
          : this.arrived_at,
      observations: data.observations.present
          ? data.observations.value
          : this.observations,
      amountCollected: data.amountCollected.present
          ? data.amountCollected.value
          : this.amountCollected,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VisitTableData(')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedDate: $lastModifiedDate, ')
          ..write('enabled: $enabled, ')
          ..write('serverId: $serverId, ')
          ..write('visitId: $visitId, ')
          ..write('routeStopId: $routeStopId, ')
          ..write('customerId: $customerId, ')
          ..write('visitType: $visitType, ')
          ..write('outcomeId: $outcomeId, ')
          ..write('arrived_at: $arrived_at, ')
          ..write('observations: $observations, ')
          ..write('amountCollected: $amountCollected')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    createdAt,
    lastModifiedDate,
    enabled,
    serverId,
    visitId,
    routeStopId,
    customerId,
    visitType,
    outcomeId,
    arrived_at,
    observations,
    amountCollected,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VisitTableData &&
          other.createdAt == this.createdAt &&
          other.lastModifiedDate == this.lastModifiedDate &&
          other.enabled == this.enabled &&
          other.serverId == this.serverId &&
          other.visitId == this.visitId &&
          other.routeStopId == this.routeStopId &&
          other.customerId == this.customerId &&
          other.visitType == this.visitType &&
          other.outcomeId == this.outcomeId &&
          other.arrived_at == this.arrived_at &&
          other.observations == this.observations &&
          other.amountCollected == this.amountCollected);
}

class VisitTableCompanion extends UpdateCompanion<VisitTableData> {
  final Value<DateTime> createdAt;
  final Value<DateTime> lastModifiedDate;
  final Value<bool> enabled;
  final Value<int?> serverId;
  final Value<String> visitId;
  final Value<String> routeStopId;
  final Value<String> customerId;
  final Value<String> visitType;
  final Value<int?> outcomeId;
  final Value<DateTime> arrived_at;
  final Value<String?> observations;
  final Value<double> amountCollected;
  final Value<int> rowid;
  const VisitTableCompanion({
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.serverId = const Value.absent(),
    this.visitId = const Value.absent(),
    this.routeStopId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.visitType = const Value.absent(),
    this.outcomeId = const Value.absent(),
    this.arrived_at = const Value.absent(),
    this.observations = const Value.absent(),
    this.amountCollected = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VisitTableCompanion.insert({
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.serverId = const Value.absent(),
    this.visitId = const Value.absent(),
    required String routeStopId,
    required String customerId,
    required String visitType,
    this.outcomeId = const Value.absent(),
    required DateTime arrived_at,
    this.observations = const Value.absent(),
    this.amountCollected = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : routeStopId = Value(routeStopId),
       customerId = Value(customerId),
       visitType = Value(visitType),
       arrived_at = Value(arrived_at);
  static Insertable<VisitTableData> custom({
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastModifiedDate,
    Expression<bool>? enabled,
    Expression<int>? serverId,
    Expression<String>? visitId,
    Expression<String>? routeStopId,
    Expression<String>? customerId,
    Expression<String>? visitType,
    Expression<int>? outcomeId,
    Expression<DateTime>? arrived_at,
    Expression<String>? observations,
    Expression<double>? amountCollected,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (lastModifiedDate != null) 'last_modified_date': lastModifiedDate,
      if (enabled != null) 'enabled': enabled,
      if (serverId != null) 'server_id': serverId,
      if (visitId != null) 'visit_id': visitId,
      if (routeStopId != null) 'route_stop_id': routeStopId,
      if (customerId != null) 'customer_id': customerId,
      if (visitType != null) 'visit_type': visitType,
      if (outcomeId != null) 'outcome_id': outcomeId,
      if (arrived_at != null) 'arrived_at': arrived_at,
      if (observations != null) 'observations': observations,
      if (amountCollected != null) 'amount_collected': amountCollected,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VisitTableCompanion copyWith({
    Value<DateTime>? createdAt,
    Value<DateTime>? lastModifiedDate,
    Value<bool>? enabled,
    Value<int?>? serverId,
    Value<String>? visitId,
    Value<String>? routeStopId,
    Value<String>? customerId,
    Value<String>? visitType,
    Value<int?>? outcomeId,
    Value<DateTime>? arrived_at,
    Value<String?>? observations,
    Value<double>? amountCollected,
    Value<int>? rowid,
  }) {
    return VisitTableCompanion(
      createdAt: createdAt ?? this.createdAt,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      enabled: enabled ?? this.enabled,
      serverId: serverId ?? this.serverId,
      visitId: visitId ?? this.visitId,
      routeStopId: routeStopId ?? this.routeStopId,
      customerId: customerId ?? this.customerId,
      visitType: visitType ?? this.visitType,
      outcomeId: outcomeId ?? this.outcomeId,
      arrived_at: arrived_at ?? this.arrived_at,
      observations: observations ?? this.observations,
      amountCollected: amountCollected ?? this.amountCollected,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastModifiedDate.present) {
      map['last_modified_date'] = Variable<DateTime>(lastModifiedDate.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (visitId.present) {
      map['visit_id'] = Variable<String>(visitId.value);
    }
    if (routeStopId.present) {
      map['route_stop_id'] = Variable<String>(routeStopId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (visitType.present) {
      map['visit_type'] = Variable<String>(visitType.value);
    }
    if (outcomeId.present) {
      map['outcome_id'] = Variable<int>(outcomeId.value);
    }
    if (arrived_at.present) {
      map['arrived_at'] = Variable<DateTime>(arrived_at.value);
    }
    if (observations.present) {
      map['observations'] = Variable<String>(observations.value);
    }
    if (amountCollected.present) {
      map['amount_collected'] = Variable<double>(amountCollected.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VisitTableCompanion(')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedDate: $lastModifiedDate, ')
          ..write('enabled: $enabled, ')
          ..write('serverId: $serverId, ')
          ..write('visitId: $visitId, ')
          ..write('routeStopId: $routeStopId, ')
          ..write('customerId: $customerId, ')
          ..write('visitType: $visitType, ')
          ..write('outcomeId: $outcomeId, ')
          ..write('arrived_at: $arrived_at, ')
          ..write('observations: $observations, ')
          ..write('amountCollected: $amountCollected, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SaleTableTable extends SaleTable
    with TableInfo<$SaleTableTable, SaleTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SaleTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastModifiedDateMeta = const VerificationMeta(
    'lastModifiedDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastModifiedDate =
      GeneratedColumn<DateTime>(
        'last_modified_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _saleIdMeta = const VerificationMeta('saleId');
  @override
  late final GeneratedColumn<String> saleId = GeneratedColumn<String>(
    'sale_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => uuid.v4(),
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES customers (customer_id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saleDateMeta = const VerificationMeta(
    'saleDate',
  );
  @override
  late final GeneratedColumn<DateTime> saleDate = GeneratedColumn<DateTime>(
    'sale_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shipping_amountMeta = const VerificationMeta(
    'shipping_amount',
  );
  @override
  late final GeneratedColumn<double> shipping_amount = GeneratedColumn<double>(
    'shipping_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visitIdMeta = const VerificationMeta(
    'visitId',
  );
  @override
  late final GeneratedColumn<String> visitId = GeneratedColumn<String>(
    'visit_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cashAmountMeta = const VerificationMeta(
    'cashAmount',
  );
  @override
  late final GeneratedColumn<double> cashAmount = GeneratedColumn<double>(
    'cash_amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transferAmountMeta = const VerificationMeta(
    'transferAmount',
  );
  @override
  late final GeneratedColumn<double> transferAmount = GeneratedColumn<double>(
    'transfer_amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    createdAt,
    lastModifiedDate,
    enabled,
    serverId,
    saleId,
    customerId,
    totalAmount,
    paymentMethod,
    saleDate,
    quantity,
    shipping_amount,
    visitId,
    cashAmount,
    transferAmount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sales';
  @override
  VerificationContext validateIntegrity(
    Insertable<SaleTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('last_modified_date')) {
      context.handle(
        _lastModifiedDateMeta,
        lastModifiedDate.isAcceptableOrUnknown(
          data['last_modified_date']!,
          _lastModifiedDateMeta,
        ),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('sale_id')) {
      context.handle(
        _saleIdMeta,
        saleId.isAcceptableOrUnknown(data['sale_id']!, _saleIdMeta),
      );
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalAmountMeta);
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentMethodMeta);
    }
    if (data.containsKey('sale_date')) {
      context.handle(
        _saleDateMeta,
        saleDate.isAcceptableOrUnknown(data['sale_date']!, _saleDateMeta),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('shipping_amount')) {
      context.handle(
        _shipping_amountMeta,
        shipping_amount.isAcceptableOrUnknown(
          data['shipping_amount']!,
          _shipping_amountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_shipping_amountMeta);
    }
    if (data.containsKey('visit_id')) {
      context.handle(
        _visitIdMeta,
        visitId.isAcceptableOrUnknown(data['visit_id']!, _visitIdMeta),
      );
    }
    if (data.containsKey('cash_amount')) {
      context.handle(
        _cashAmountMeta,
        cashAmount.isAcceptableOrUnknown(data['cash_amount']!, _cashAmountMeta),
      );
    }
    if (data.containsKey('transfer_amount')) {
      context.handle(
        _transferAmountMeta,
        transferAmount.isAcceptableOrUnknown(
          data['transfer_amount']!,
          _transferAmountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {saleId};
  @override
  SaleTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SaleTableData(
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastModifiedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified_date'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      saleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      )!,
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount'],
      )!,
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      )!,
      saleDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sale_date'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      shipping_amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}shipping_amount'],
      )!,
      visitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visit_id'],
      ),
      cashAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cash_amount'],
      ),
      transferAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}transfer_amount'],
      ),
    );
  }

  @override
  $SaleTableTable createAlias(String alias) {
    return $SaleTableTable(attachedDatabase, alias);
  }
}

class SaleTableData extends DataClass implements Insertable<SaleTableData> {
  final DateTime createdAt;
  final DateTime lastModifiedDate;
  final bool enabled;
  final int? serverId;
  final String saleId;
  final String customerId;
  final double totalAmount;
  final String paymentMethod;
  final DateTime saleDate;
  final int quantity;
  final double shipping_amount;
  final String? visitId;
  final double? cashAmount;
  final double? transferAmount;
  const SaleTableData({
    required this.createdAt,
    required this.lastModifiedDate,
    required this.enabled,
    this.serverId,
    required this.saleId,
    required this.customerId,
    required this.totalAmount,
    required this.paymentMethod,
    required this.saleDate,
    required this.quantity,
    required this.shipping_amount,
    this.visitId,
    this.cashAmount,
    this.transferAmount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_modified_date'] = Variable<DateTime>(lastModifiedDate);
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['sale_id'] = Variable<String>(saleId);
    map['customer_id'] = Variable<String>(customerId);
    map['total_amount'] = Variable<double>(totalAmount);
    map['payment_method'] = Variable<String>(paymentMethod);
    map['sale_date'] = Variable<DateTime>(saleDate);
    map['quantity'] = Variable<int>(quantity);
    map['shipping_amount'] = Variable<double>(shipping_amount);
    if (!nullToAbsent || visitId != null) {
      map['visit_id'] = Variable<String>(visitId);
    }
    if (!nullToAbsent || cashAmount != null) {
      map['cash_amount'] = Variable<double>(cashAmount);
    }
    if (!nullToAbsent || transferAmount != null) {
      map['transfer_amount'] = Variable<double>(transferAmount);
    }
    return map;
  }

  SaleTableCompanion toCompanion(bool nullToAbsent) {
    return SaleTableCompanion(
      createdAt: Value(createdAt),
      lastModifiedDate: Value(lastModifiedDate),
      enabled: Value(enabled),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      saleId: Value(saleId),
      customerId: Value(customerId),
      totalAmount: Value(totalAmount),
      paymentMethod: Value(paymentMethod),
      saleDate: Value(saleDate),
      quantity: Value(quantity),
      shipping_amount: Value(shipping_amount),
      visitId: visitId == null && nullToAbsent
          ? const Value.absent()
          : Value(visitId),
      cashAmount: cashAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(cashAmount),
      transferAmount: transferAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(transferAmount),
    );
  }

  factory SaleTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SaleTableData(
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastModifiedDate: serializer.fromJson<DateTime>(json['lastModifiedDate']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      saleId: serializer.fromJson<String>(json['saleId']),
      customerId: serializer.fromJson<String>(json['customerId']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      saleDate: serializer.fromJson<DateTime>(json['saleDate']),
      quantity: serializer.fromJson<int>(json['quantity']),
      shipping_amount: serializer.fromJson<double>(json['shipping_amount']),
      visitId: serializer.fromJson<String?>(json['visitId']),
      cashAmount: serializer.fromJson<double?>(json['cashAmount']),
      transferAmount: serializer.fromJson<double?>(json['transferAmount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastModifiedDate': serializer.toJson<DateTime>(lastModifiedDate),
      'enabled': serializer.toJson<bool>(enabled),
      'serverId': serializer.toJson<int?>(serverId),
      'saleId': serializer.toJson<String>(saleId),
      'customerId': serializer.toJson<String>(customerId),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'saleDate': serializer.toJson<DateTime>(saleDate),
      'quantity': serializer.toJson<int>(quantity),
      'shipping_amount': serializer.toJson<double>(shipping_amount),
      'visitId': serializer.toJson<String?>(visitId),
      'cashAmount': serializer.toJson<double?>(cashAmount),
      'transferAmount': serializer.toJson<double?>(transferAmount),
    };
  }

  SaleTableData copyWith({
    DateTime? createdAt,
    DateTime? lastModifiedDate,
    bool? enabled,
    Value<int?> serverId = const Value.absent(),
    String? saleId,
    String? customerId,
    double? totalAmount,
    String? paymentMethod,
    DateTime? saleDate,
    int? quantity,
    double? shipping_amount,
    Value<String?> visitId = const Value.absent(),
    Value<double?> cashAmount = const Value.absent(),
    Value<double?> transferAmount = const Value.absent(),
  }) => SaleTableData(
    createdAt: createdAt ?? this.createdAt,
    lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
    enabled: enabled ?? this.enabled,
    serverId: serverId.present ? serverId.value : this.serverId,
    saleId: saleId ?? this.saleId,
    customerId: customerId ?? this.customerId,
    totalAmount: totalAmount ?? this.totalAmount,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    saleDate: saleDate ?? this.saleDate,
    quantity: quantity ?? this.quantity,
    shipping_amount: shipping_amount ?? this.shipping_amount,
    visitId: visitId.present ? visitId.value : this.visitId,
    cashAmount: cashAmount.present ? cashAmount.value : this.cashAmount,
    transferAmount: transferAmount.present
        ? transferAmount.value
        : this.transferAmount,
  );
  SaleTableData copyWithCompanion(SaleTableCompanion data) {
    return SaleTableData(
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastModifiedDate: data.lastModifiedDate.present
          ? data.lastModifiedDate.value
          : this.lastModifiedDate,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      saleId: data.saleId.present ? data.saleId.value : this.saleId,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      saleDate: data.saleDate.present ? data.saleDate.value : this.saleDate,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      shipping_amount: data.shipping_amount.present
          ? data.shipping_amount.value
          : this.shipping_amount,
      visitId: data.visitId.present ? data.visitId.value : this.visitId,
      cashAmount: data.cashAmount.present
          ? data.cashAmount.value
          : this.cashAmount,
      transferAmount: data.transferAmount.present
          ? data.transferAmount.value
          : this.transferAmount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SaleTableData(')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedDate: $lastModifiedDate, ')
          ..write('enabled: $enabled, ')
          ..write('serverId: $serverId, ')
          ..write('saleId: $saleId, ')
          ..write('customerId: $customerId, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('saleDate: $saleDate, ')
          ..write('quantity: $quantity, ')
          ..write('shipping_amount: $shipping_amount, ')
          ..write('visitId: $visitId, ')
          ..write('cashAmount: $cashAmount, ')
          ..write('transferAmount: $transferAmount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    createdAt,
    lastModifiedDate,
    enabled,
    serverId,
    saleId,
    customerId,
    totalAmount,
    paymentMethod,
    saleDate,
    quantity,
    shipping_amount,
    visitId,
    cashAmount,
    transferAmount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SaleTableData &&
          other.createdAt == this.createdAt &&
          other.lastModifiedDate == this.lastModifiedDate &&
          other.enabled == this.enabled &&
          other.serverId == this.serverId &&
          other.saleId == this.saleId &&
          other.customerId == this.customerId &&
          other.totalAmount == this.totalAmount &&
          other.paymentMethod == this.paymentMethod &&
          other.saleDate == this.saleDate &&
          other.quantity == this.quantity &&
          other.shipping_amount == this.shipping_amount &&
          other.visitId == this.visitId &&
          other.cashAmount == this.cashAmount &&
          other.transferAmount == this.transferAmount);
}

class SaleTableCompanion extends UpdateCompanion<SaleTableData> {
  final Value<DateTime> createdAt;
  final Value<DateTime> lastModifiedDate;
  final Value<bool> enabled;
  final Value<int?> serverId;
  final Value<String> saleId;
  final Value<String> customerId;
  final Value<double> totalAmount;
  final Value<String> paymentMethod;
  final Value<DateTime> saleDate;
  final Value<int> quantity;
  final Value<double> shipping_amount;
  final Value<String?> visitId;
  final Value<double?> cashAmount;
  final Value<double?> transferAmount;
  final Value<int> rowid;
  const SaleTableCompanion({
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.serverId = const Value.absent(),
    this.saleId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.saleDate = const Value.absent(),
    this.quantity = const Value.absent(),
    this.shipping_amount = const Value.absent(),
    this.visitId = const Value.absent(),
    this.cashAmount = const Value.absent(),
    this.transferAmount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SaleTableCompanion.insert({
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.serverId = const Value.absent(),
    this.saleId = const Value.absent(),
    required String customerId,
    required double totalAmount,
    required String paymentMethod,
    this.saleDate = const Value.absent(),
    required int quantity,
    required double shipping_amount,
    this.visitId = const Value.absent(),
    this.cashAmount = const Value.absent(),
    this.transferAmount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : customerId = Value(customerId),
       totalAmount = Value(totalAmount),
       paymentMethod = Value(paymentMethod),
       quantity = Value(quantity),
       shipping_amount = Value(shipping_amount);
  static Insertable<SaleTableData> custom({
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastModifiedDate,
    Expression<bool>? enabled,
    Expression<int>? serverId,
    Expression<String>? saleId,
    Expression<String>? customerId,
    Expression<double>? totalAmount,
    Expression<String>? paymentMethod,
    Expression<DateTime>? saleDate,
    Expression<int>? quantity,
    Expression<double>? shipping_amount,
    Expression<String>? visitId,
    Expression<double>? cashAmount,
    Expression<double>? transferAmount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (lastModifiedDate != null) 'last_modified_date': lastModifiedDate,
      if (enabled != null) 'enabled': enabled,
      if (serverId != null) 'server_id': serverId,
      if (saleId != null) 'sale_id': saleId,
      if (customerId != null) 'customer_id': customerId,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (saleDate != null) 'sale_date': saleDate,
      if (quantity != null) 'quantity': quantity,
      if (shipping_amount != null) 'shipping_amount': shipping_amount,
      if (visitId != null) 'visit_id': visitId,
      if (cashAmount != null) 'cash_amount': cashAmount,
      if (transferAmount != null) 'transfer_amount': transferAmount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SaleTableCompanion copyWith({
    Value<DateTime>? createdAt,
    Value<DateTime>? lastModifiedDate,
    Value<bool>? enabled,
    Value<int?>? serverId,
    Value<String>? saleId,
    Value<String>? customerId,
    Value<double>? totalAmount,
    Value<String>? paymentMethod,
    Value<DateTime>? saleDate,
    Value<int>? quantity,
    Value<double>? shipping_amount,
    Value<String?>? visitId,
    Value<double?>? cashAmount,
    Value<double?>? transferAmount,
    Value<int>? rowid,
  }) {
    return SaleTableCompanion(
      createdAt: createdAt ?? this.createdAt,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      enabled: enabled ?? this.enabled,
      serverId: serverId ?? this.serverId,
      saleId: saleId ?? this.saleId,
      customerId: customerId ?? this.customerId,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      saleDate: saleDate ?? this.saleDate,
      quantity: quantity ?? this.quantity,
      shipping_amount: shipping_amount ?? this.shipping_amount,
      visitId: visitId ?? this.visitId,
      cashAmount: cashAmount ?? this.cashAmount,
      transferAmount: transferAmount ?? this.transferAmount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastModifiedDate.present) {
      map['last_modified_date'] = Variable<DateTime>(lastModifiedDate.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (saleId.present) {
      map['sale_id'] = Variable<String>(saleId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (saleDate.present) {
      map['sale_date'] = Variable<DateTime>(saleDate.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (shipping_amount.present) {
      map['shipping_amount'] = Variable<double>(shipping_amount.value);
    }
    if (visitId.present) {
      map['visit_id'] = Variable<String>(visitId.value);
    }
    if (cashAmount.present) {
      map['cash_amount'] = Variable<double>(cashAmount.value);
    }
    if (transferAmount.present) {
      map['transfer_amount'] = Variable<double>(transferAmount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SaleTableCompanion(')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedDate: $lastModifiedDate, ')
          ..write('enabled: $enabled, ')
          ..write('serverId: $serverId, ')
          ..write('saleId: $saleId, ')
          ..write('customerId: $customerId, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('saleDate: $saleDate, ')
          ..write('quantity: $quantity, ')
          ..write('shipping_amount: $shipping_amount, ')
          ..write('visitId: $visitId, ')
          ..write('cashAmount: $cashAmount, ')
          ..write('transferAmount: $transferAmount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SaleItemTableTable extends SaleItemTable
    with TableInfo<$SaleItemTableTable, SaleItemTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SaleItemTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastModifiedDateMeta = const VerificationMeta(
    'lastModifiedDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastModifiedDate =
      GeneratedColumn<DateTime>(
        'last_modified_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _saleItemIdMeta = const VerificationMeta(
    'saleItemId',
  );
  @override
  late final GeneratedColumn<String> saleItemId = GeneratedColumn<String>(
    'sale_item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => uuid.v4(),
  );
  static const VerificationMeta _saleIdMeta = const VerificationMeta('saleId');
  @override
  late final GeneratedColumn<String> saleId = GeneratedColumn<String>(
    'sale_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sales (sale_id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (product_id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<double> unitPrice = GeneratedColumn<double>(
    'unit_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subtotalMeta = const VerificationMeta(
    'subtotal',
  );
  @override
  late final GeneratedColumn<double> subtotal = GeneratedColumn<double>(
    'subtotal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _agreementServerIdMeta = const VerificationMeta(
    'agreementServerId',
  );
  @override
  late final GeneratedColumn<int> agreementServerId = GeneratedColumn<int>(
    'agreement_server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _agreementUuidMeta = const VerificationMeta(
    'agreementUuid',
  );
  @override
  late final GeneratedColumn<String> agreementUuid = GeneratedColumn<String>(
    'agreement_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    createdAt,
    lastModifiedDate,
    enabled,
    serverId,
    saleItemId,
    saleId,
    productId,
    quantity,
    unitPrice,
    subtotal,
    agreementServerId,
    agreementUuid,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sale_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<SaleItemTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('last_modified_date')) {
      context.handle(
        _lastModifiedDateMeta,
        lastModifiedDate.isAcceptableOrUnknown(
          data['last_modified_date']!,
          _lastModifiedDateMeta,
        ),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('sale_item_id')) {
      context.handle(
        _saleItemIdMeta,
        saleItemId.isAcceptableOrUnknown(
          data['sale_item_id']!,
          _saleItemIdMeta,
        ),
      );
    }
    if (data.containsKey('sale_id')) {
      context.handle(
        _saleIdMeta,
        saleId.isAcceptableOrUnknown(data['sale_id']!, _saleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_saleIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_unitPriceMeta);
    }
    if (data.containsKey('subtotal')) {
      context.handle(
        _subtotalMeta,
        subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta),
      );
    } else if (isInserting) {
      context.missing(_subtotalMeta);
    }
    if (data.containsKey('agreement_server_id')) {
      context.handle(
        _agreementServerIdMeta,
        agreementServerId.isAcceptableOrUnknown(
          data['agreement_server_id']!,
          _agreementServerIdMeta,
        ),
      );
    }
    if (data.containsKey('agreement_uuid')) {
      context.handle(
        _agreementUuidMeta,
        agreementUuid.isAcceptableOrUnknown(
          data['agreement_uuid']!,
          _agreementUuidMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {saleItemId};
  @override
  SaleItemTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SaleItemTableData(
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastModifiedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified_date'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      saleItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_item_id'],
      )!,
      saleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      unitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_price'],
      )!,
      subtotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}subtotal'],
      )!,
      agreementServerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}agreement_server_id'],
      ),
      agreementUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agreement_uuid'],
      ),
    );
  }

  @override
  $SaleItemTableTable createAlias(String alias) {
    return $SaleItemTableTable(attachedDatabase, alias);
  }
}

class SaleItemTableData extends DataClass
    implements Insertable<SaleItemTableData> {
  final DateTime createdAt;
  final DateTime lastModifiedDate;
  final bool enabled;
  final int? serverId;
  final String saleItemId;
  final String saleId;
  final String productId;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  /// Server id of the customer agreement that set [unitPrice]; null for
  /// the list price.
  final int? agreementServerId;

  /// Local uuid of that agreement, for agreements the server did not know
  /// yet when the sale was made.
  final String? agreementUuid;
  const SaleItemTableData({
    required this.createdAt,
    required this.lastModifiedDate,
    required this.enabled,
    this.serverId,
    required this.saleItemId,
    required this.saleId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.agreementServerId,
    this.agreementUuid,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_modified_date'] = Variable<DateTime>(lastModifiedDate);
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['sale_item_id'] = Variable<String>(saleItemId);
    map['sale_id'] = Variable<String>(saleId);
    map['product_id'] = Variable<String>(productId);
    map['quantity'] = Variable<int>(quantity);
    map['unit_price'] = Variable<double>(unitPrice);
    map['subtotal'] = Variable<double>(subtotal);
    if (!nullToAbsent || agreementServerId != null) {
      map['agreement_server_id'] = Variable<int>(agreementServerId);
    }
    if (!nullToAbsent || agreementUuid != null) {
      map['agreement_uuid'] = Variable<String>(agreementUuid);
    }
    return map;
  }

  SaleItemTableCompanion toCompanion(bool nullToAbsent) {
    return SaleItemTableCompanion(
      createdAt: Value(createdAt),
      lastModifiedDate: Value(lastModifiedDate),
      enabled: Value(enabled),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      saleItemId: Value(saleItemId),
      saleId: Value(saleId),
      productId: Value(productId),
      quantity: Value(quantity),
      unitPrice: Value(unitPrice),
      subtotal: Value(subtotal),
      agreementServerId: agreementServerId == null && nullToAbsent
          ? const Value.absent()
          : Value(agreementServerId),
      agreementUuid: agreementUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(agreementUuid),
    );
  }

  factory SaleItemTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SaleItemTableData(
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastModifiedDate: serializer.fromJson<DateTime>(json['lastModifiedDate']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      saleItemId: serializer.fromJson<String>(json['saleItemId']),
      saleId: serializer.fromJson<String>(json['saleId']),
      productId: serializer.fromJson<String>(json['productId']),
      quantity: serializer.fromJson<int>(json['quantity']),
      unitPrice: serializer.fromJson<double>(json['unitPrice']),
      subtotal: serializer.fromJson<double>(json['subtotal']),
      agreementServerId: serializer.fromJson<int?>(json['agreementServerId']),
      agreementUuid: serializer.fromJson<String?>(json['agreementUuid']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastModifiedDate': serializer.toJson<DateTime>(lastModifiedDate),
      'enabled': serializer.toJson<bool>(enabled),
      'serverId': serializer.toJson<int?>(serverId),
      'saleItemId': serializer.toJson<String>(saleItemId),
      'saleId': serializer.toJson<String>(saleId),
      'productId': serializer.toJson<String>(productId),
      'quantity': serializer.toJson<int>(quantity),
      'unitPrice': serializer.toJson<double>(unitPrice),
      'subtotal': serializer.toJson<double>(subtotal),
      'agreementServerId': serializer.toJson<int?>(agreementServerId),
      'agreementUuid': serializer.toJson<String?>(agreementUuid),
    };
  }

  SaleItemTableData copyWith({
    DateTime? createdAt,
    DateTime? lastModifiedDate,
    bool? enabled,
    Value<int?> serverId = const Value.absent(),
    String? saleItemId,
    String? saleId,
    String? productId,
    int? quantity,
    double? unitPrice,
    double? subtotal,
    Value<int?> agreementServerId = const Value.absent(),
    Value<String?> agreementUuid = const Value.absent(),
  }) => SaleItemTableData(
    createdAt: createdAt ?? this.createdAt,
    lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
    enabled: enabled ?? this.enabled,
    serverId: serverId.present ? serverId.value : this.serverId,
    saleItemId: saleItemId ?? this.saleItemId,
    saleId: saleId ?? this.saleId,
    productId: productId ?? this.productId,
    quantity: quantity ?? this.quantity,
    unitPrice: unitPrice ?? this.unitPrice,
    subtotal: subtotal ?? this.subtotal,
    agreementServerId: agreementServerId.present
        ? agreementServerId.value
        : this.agreementServerId,
    agreementUuid: agreementUuid.present
        ? agreementUuid.value
        : this.agreementUuid,
  );
  SaleItemTableData copyWithCompanion(SaleItemTableCompanion data) {
    return SaleItemTableData(
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastModifiedDate: data.lastModifiedDate.present
          ? data.lastModifiedDate.value
          : this.lastModifiedDate,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      saleItemId: data.saleItemId.present
          ? data.saleItemId.value
          : this.saleItemId,
      saleId: data.saleId.present ? data.saleId.value : this.saleId,
      productId: data.productId.present ? data.productId.value : this.productId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      agreementServerId: data.agreementServerId.present
          ? data.agreementServerId.value
          : this.agreementServerId,
      agreementUuid: data.agreementUuid.present
          ? data.agreementUuid.value
          : this.agreementUuid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SaleItemTableData(')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedDate: $lastModifiedDate, ')
          ..write('enabled: $enabled, ')
          ..write('serverId: $serverId, ')
          ..write('saleItemId: $saleItemId, ')
          ..write('saleId: $saleId, ')
          ..write('productId: $productId, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('subtotal: $subtotal, ')
          ..write('agreementServerId: $agreementServerId, ')
          ..write('agreementUuid: $agreementUuid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    createdAt,
    lastModifiedDate,
    enabled,
    serverId,
    saleItemId,
    saleId,
    productId,
    quantity,
    unitPrice,
    subtotal,
    agreementServerId,
    agreementUuid,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SaleItemTableData &&
          other.createdAt == this.createdAt &&
          other.lastModifiedDate == this.lastModifiedDate &&
          other.enabled == this.enabled &&
          other.serverId == this.serverId &&
          other.saleItemId == this.saleItemId &&
          other.saleId == this.saleId &&
          other.productId == this.productId &&
          other.quantity == this.quantity &&
          other.unitPrice == this.unitPrice &&
          other.subtotal == this.subtotal &&
          other.agreementServerId == this.agreementServerId &&
          other.agreementUuid == this.agreementUuid);
}

class SaleItemTableCompanion extends UpdateCompanion<SaleItemTableData> {
  final Value<DateTime> createdAt;
  final Value<DateTime> lastModifiedDate;
  final Value<bool> enabled;
  final Value<int?> serverId;
  final Value<String> saleItemId;
  final Value<String> saleId;
  final Value<String> productId;
  final Value<int> quantity;
  final Value<double> unitPrice;
  final Value<double> subtotal;
  final Value<int?> agreementServerId;
  final Value<String?> agreementUuid;
  final Value<int> rowid;
  const SaleItemTableCompanion({
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.serverId = const Value.absent(),
    this.saleItemId = const Value.absent(),
    this.saleId = const Value.absent(),
    this.productId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.agreementServerId = const Value.absent(),
    this.agreementUuid = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SaleItemTableCompanion.insert({
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.serverId = const Value.absent(),
    this.saleItemId = const Value.absent(),
    required String saleId,
    required String productId,
    required int quantity,
    required double unitPrice,
    required double subtotal,
    this.agreementServerId = const Value.absent(),
    this.agreementUuid = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : saleId = Value(saleId),
       productId = Value(productId),
       quantity = Value(quantity),
       unitPrice = Value(unitPrice),
       subtotal = Value(subtotal);
  static Insertable<SaleItemTableData> custom({
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastModifiedDate,
    Expression<bool>? enabled,
    Expression<int>? serverId,
    Expression<String>? saleItemId,
    Expression<String>? saleId,
    Expression<String>? productId,
    Expression<int>? quantity,
    Expression<double>? unitPrice,
    Expression<double>? subtotal,
    Expression<int>? agreementServerId,
    Expression<String>? agreementUuid,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (lastModifiedDate != null) 'last_modified_date': lastModifiedDate,
      if (enabled != null) 'enabled': enabled,
      if (serverId != null) 'server_id': serverId,
      if (saleItemId != null) 'sale_item_id': saleItemId,
      if (saleId != null) 'sale_id': saleId,
      if (productId != null) 'product_id': productId,
      if (quantity != null) 'quantity': quantity,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (subtotal != null) 'subtotal': subtotal,
      if (agreementServerId != null) 'agreement_server_id': agreementServerId,
      if (agreementUuid != null) 'agreement_uuid': agreementUuid,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SaleItemTableCompanion copyWith({
    Value<DateTime>? createdAt,
    Value<DateTime>? lastModifiedDate,
    Value<bool>? enabled,
    Value<int?>? serverId,
    Value<String>? saleItemId,
    Value<String>? saleId,
    Value<String>? productId,
    Value<int>? quantity,
    Value<double>? unitPrice,
    Value<double>? subtotal,
    Value<int?>? agreementServerId,
    Value<String?>? agreementUuid,
    Value<int>? rowid,
  }) {
    return SaleItemTableCompanion(
      createdAt: createdAt ?? this.createdAt,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      enabled: enabled ?? this.enabled,
      serverId: serverId ?? this.serverId,
      saleItemId: saleItemId ?? this.saleItemId,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      subtotal: subtotal ?? this.subtotal,
      agreementServerId: agreementServerId ?? this.agreementServerId,
      agreementUuid: agreementUuid ?? this.agreementUuid,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastModifiedDate.present) {
      map['last_modified_date'] = Variable<DateTime>(lastModifiedDate.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (saleItemId.present) {
      map['sale_item_id'] = Variable<String>(saleItemId.value);
    }
    if (saleId.present) {
      map['sale_id'] = Variable<String>(saleId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<double>(unitPrice.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<double>(subtotal.value);
    }
    if (agreementServerId.present) {
      map['agreement_server_id'] = Variable<int>(agreementServerId.value);
    }
    if (agreementUuid.present) {
      map['agreement_uuid'] = Variable<String>(agreementUuid.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SaleItemTableCompanion(')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedDate: $lastModifiedDate, ')
          ..write('enabled: $enabled, ')
          ..write('serverId: $serverId, ')
          ..write('saleItemId: $saleItemId, ')
          ..write('saleId: $saleId, ')
          ..write('productId: $productId, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('subtotal: $subtotal, ')
          ..write('agreementServerId: $agreementServerId, ')
          ..write('agreementUuid: $agreementUuid, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PaymentTableTable extends PaymentTable
    with TableInfo<$PaymentTableTable, PaymentTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastModifiedDateMeta = const VerificationMeta(
    'lastModifiedDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastModifiedDate =
      GeneratedColumn<DateTime>(
        'last_modified_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paymentIdMeta = const VerificationMeta(
    'paymentId',
  );
  @override
  late final GeneratedColumn<String> paymentId = GeneratedColumn<String>(
    'payment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => uuid.v4(),
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES customers (customer_id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visitIdMeta = const VerificationMeta(
    'visitId',
  );
  @override
  late final GeneratedColumn<String> visitId = GeneratedColumn<String>(
    'visit_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES visits (visit_id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _saleIdMeta = const VerificationMeta('saleId');
  @override
  late final GeneratedColumn<String> saleId = GeneratedColumn<String>(
    'sale_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sales (sale_id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('CONFIRMED'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    createdAt,
    lastModifiedDate,
    enabled,
    serverId,
    paymentId,
    customerId,
    amount,
    paymentMethod,
    visitId,
    saleId,
    notes,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<PaymentTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('last_modified_date')) {
      context.handle(
        _lastModifiedDateMeta,
        lastModifiedDate.isAcceptableOrUnknown(
          data['last_modified_date']!,
          _lastModifiedDateMeta,
        ),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('payment_id')) {
      context.handle(
        _paymentIdMeta,
        paymentId.isAcceptableOrUnknown(data['payment_id']!, _paymentIdMeta),
      );
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentMethodMeta);
    }
    if (data.containsKey('visit_id')) {
      context.handle(
        _visitIdMeta,
        visitId.isAcceptableOrUnknown(data['visit_id']!, _visitIdMeta),
      );
    }
    if (data.containsKey('sale_id')) {
      context.handle(
        _saleIdMeta,
        saleId.isAcceptableOrUnknown(data['sale_id']!, _saleIdMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {paymentId};
  @override
  PaymentTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PaymentTableData(
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastModifiedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified_date'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      paymentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      )!,
      visitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visit_id'],
      ),
      saleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_id'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $PaymentTableTable createAlias(String alias) {
    return $PaymentTableTable(attachedDatabase, alias);
  }
}

class PaymentTableData extends DataClass
    implements Insertable<PaymentTableData> {
  final DateTime createdAt;
  final DateTime lastModifiedDate;
  final bool enabled;
  final int? serverId;
  final String paymentId;
  final String customerId;
  final double amount;
  final String paymentMethod;
  final String? visitId;
  final String? saleId;
  final String? notes;
  final String status;
  const PaymentTableData({
    required this.createdAt,
    required this.lastModifiedDate,
    required this.enabled,
    this.serverId,
    required this.paymentId,
    required this.customerId,
    required this.amount,
    required this.paymentMethod,
    this.visitId,
    this.saleId,
    this.notes,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_modified_date'] = Variable<DateTime>(lastModifiedDate);
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['payment_id'] = Variable<String>(paymentId);
    map['customer_id'] = Variable<String>(customerId);
    map['amount'] = Variable<double>(amount);
    map['payment_method'] = Variable<String>(paymentMethod);
    if (!nullToAbsent || visitId != null) {
      map['visit_id'] = Variable<String>(visitId);
    }
    if (!nullToAbsent || saleId != null) {
      map['sale_id'] = Variable<String>(saleId);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['status'] = Variable<String>(status);
    return map;
  }

  PaymentTableCompanion toCompanion(bool nullToAbsent) {
    return PaymentTableCompanion(
      createdAt: Value(createdAt),
      lastModifiedDate: Value(lastModifiedDate),
      enabled: Value(enabled),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      paymentId: Value(paymentId),
      customerId: Value(customerId),
      amount: Value(amount),
      paymentMethod: Value(paymentMethod),
      visitId: visitId == null && nullToAbsent
          ? const Value.absent()
          : Value(visitId),
      saleId: saleId == null && nullToAbsent
          ? const Value.absent()
          : Value(saleId),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      status: Value(status),
    );
  }

  factory PaymentTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PaymentTableData(
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastModifiedDate: serializer.fromJson<DateTime>(json['lastModifiedDate']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      paymentId: serializer.fromJson<String>(json['paymentId']),
      customerId: serializer.fromJson<String>(json['customerId']),
      amount: serializer.fromJson<double>(json['amount']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      visitId: serializer.fromJson<String?>(json['visitId']),
      saleId: serializer.fromJson<String?>(json['saleId']),
      notes: serializer.fromJson<String?>(json['notes']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastModifiedDate': serializer.toJson<DateTime>(lastModifiedDate),
      'enabled': serializer.toJson<bool>(enabled),
      'serverId': serializer.toJson<int?>(serverId),
      'paymentId': serializer.toJson<String>(paymentId),
      'customerId': serializer.toJson<String>(customerId),
      'amount': serializer.toJson<double>(amount),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'visitId': serializer.toJson<String?>(visitId),
      'saleId': serializer.toJson<String?>(saleId),
      'notes': serializer.toJson<String?>(notes),
      'status': serializer.toJson<String>(status),
    };
  }

  PaymentTableData copyWith({
    DateTime? createdAt,
    DateTime? lastModifiedDate,
    bool? enabled,
    Value<int?> serverId = const Value.absent(),
    String? paymentId,
    String? customerId,
    double? amount,
    String? paymentMethod,
    Value<String?> visitId = const Value.absent(),
    Value<String?> saleId = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    String? status,
  }) => PaymentTableData(
    createdAt: createdAt ?? this.createdAt,
    lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
    enabled: enabled ?? this.enabled,
    serverId: serverId.present ? serverId.value : this.serverId,
    paymentId: paymentId ?? this.paymentId,
    customerId: customerId ?? this.customerId,
    amount: amount ?? this.amount,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    visitId: visitId.present ? visitId.value : this.visitId,
    saleId: saleId.present ? saleId.value : this.saleId,
    notes: notes.present ? notes.value : this.notes,
    status: status ?? this.status,
  );
  PaymentTableData copyWithCompanion(PaymentTableCompanion data) {
    return PaymentTableData(
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastModifiedDate: data.lastModifiedDate.present
          ? data.lastModifiedDate.value
          : this.lastModifiedDate,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      paymentId: data.paymentId.present ? data.paymentId.value : this.paymentId,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      amount: data.amount.present ? data.amount.value : this.amount,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      visitId: data.visitId.present ? data.visitId.value : this.visitId,
      saleId: data.saleId.present ? data.saleId.value : this.saleId,
      notes: data.notes.present ? data.notes.value : this.notes,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PaymentTableData(')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedDate: $lastModifiedDate, ')
          ..write('enabled: $enabled, ')
          ..write('serverId: $serverId, ')
          ..write('paymentId: $paymentId, ')
          ..write('customerId: $customerId, ')
          ..write('amount: $amount, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('visitId: $visitId, ')
          ..write('saleId: $saleId, ')
          ..write('notes: $notes, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    createdAt,
    lastModifiedDate,
    enabled,
    serverId,
    paymentId,
    customerId,
    amount,
    paymentMethod,
    visitId,
    saleId,
    notes,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaymentTableData &&
          other.createdAt == this.createdAt &&
          other.lastModifiedDate == this.lastModifiedDate &&
          other.enabled == this.enabled &&
          other.serverId == this.serverId &&
          other.paymentId == this.paymentId &&
          other.customerId == this.customerId &&
          other.amount == this.amount &&
          other.paymentMethod == this.paymentMethod &&
          other.visitId == this.visitId &&
          other.saleId == this.saleId &&
          other.notes == this.notes &&
          other.status == this.status);
}

class PaymentTableCompanion extends UpdateCompanion<PaymentTableData> {
  final Value<DateTime> createdAt;
  final Value<DateTime> lastModifiedDate;
  final Value<bool> enabled;
  final Value<int?> serverId;
  final Value<String> paymentId;
  final Value<String> customerId;
  final Value<double> amount;
  final Value<String> paymentMethod;
  final Value<String?> visitId;
  final Value<String?> saleId;
  final Value<String?> notes;
  final Value<String> status;
  final Value<int> rowid;
  const PaymentTableCompanion({
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.serverId = const Value.absent(),
    this.paymentId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.amount = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.visitId = const Value.absent(),
    this.saleId = const Value.absent(),
    this.notes = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PaymentTableCompanion.insert({
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.serverId = const Value.absent(),
    this.paymentId = const Value.absent(),
    required String customerId,
    required double amount,
    required String paymentMethod,
    this.visitId = const Value.absent(),
    this.saleId = const Value.absent(),
    this.notes = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : customerId = Value(customerId),
       amount = Value(amount),
       paymentMethod = Value(paymentMethod);
  static Insertable<PaymentTableData> custom({
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastModifiedDate,
    Expression<bool>? enabled,
    Expression<int>? serverId,
    Expression<String>? paymentId,
    Expression<String>? customerId,
    Expression<double>? amount,
    Expression<String>? paymentMethod,
    Expression<String>? visitId,
    Expression<String>? saleId,
    Expression<String>? notes,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (lastModifiedDate != null) 'last_modified_date': lastModifiedDate,
      if (enabled != null) 'enabled': enabled,
      if (serverId != null) 'server_id': serverId,
      if (paymentId != null) 'payment_id': paymentId,
      if (customerId != null) 'customer_id': customerId,
      if (amount != null) 'amount': amount,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (visitId != null) 'visit_id': visitId,
      if (saleId != null) 'sale_id': saleId,
      if (notes != null) 'notes': notes,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PaymentTableCompanion copyWith({
    Value<DateTime>? createdAt,
    Value<DateTime>? lastModifiedDate,
    Value<bool>? enabled,
    Value<int?>? serverId,
    Value<String>? paymentId,
    Value<String>? customerId,
    Value<double>? amount,
    Value<String>? paymentMethod,
    Value<String?>? visitId,
    Value<String?>? saleId,
    Value<String?>? notes,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return PaymentTableCompanion(
      createdAt: createdAt ?? this.createdAt,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      enabled: enabled ?? this.enabled,
      serverId: serverId ?? this.serverId,
      paymentId: paymentId ?? this.paymentId,
      customerId: customerId ?? this.customerId,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      visitId: visitId ?? this.visitId,
      saleId: saleId ?? this.saleId,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastModifiedDate.present) {
      map['last_modified_date'] = Variable<DateTime>(lastModifiedDate.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (paymentId.present) {
      map['payment_id'] = Variable<String>(paymentId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (visitId.present) {
      map['visit_id'] = Variable<String>(visitId.value);
    }
    if (saleId.present) {
      map['sale_id'] = Variable<String>(saleId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentTableCompanion(')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedDate: $lastModifiedDate, ')
          ..write('enabled: $enabled, ')
          ..write('serverId: $serverId, ')
          ..write('paymentId: $paymentId, ')
          ..write('customerId: $customerId, ')
          ..write('amount: $amount, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('visitId: $visitId, ')
          ..write('saleId: $saleId, ')
          ..write('notes: $notes, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomerAccountEntryTableTable extends CustomerAccountEntryTable
    with
        TableInfo<
          $CustomerAccountEntryTableTable,
          CustomerAccountEntryTableData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomerAccountEntryTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastModifiedDateMeta = const VerificationMeta(
    'lastModifiedDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastModifiedDate =
      GeneratedColumn<DateTime>(
        'last_modified_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerAccountEntryIdMeta =
      const VerificationMeta('customerAccountEntryId');
  @override
  late final GeneratedColumn<String> customerAccountEntryId =
      GeneratedColumn<String>(
        'customer_account_entry_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        clientDefault: () => uuid.v4(),
      );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES customers (customer_id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _saleIdMeta = const VerificationMeta('saleId');
  @override
  late final GeneratedColumn<String> saleId = GeneratedColumn<String>(
    'sale_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sales (sale_id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _paymentIdMeta = const VerificationMeta(
    'paymentId',
  );
  @override
  late final GeneratedColumn<String> paymentId = GeneratedColumn<String>(
    'payment_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES payments (payment_id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _entryTypeMeta = const VerificationMeta(
    'entryType',
  );
  @override
  late final GeneratedColumn<String> entryType = GeneratedColumn<String>(
    'entry_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<int> direction = GeneratedColumn<int>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    createdAt,
    lastModifiedDate,
    enabled,
    serverId,
    customerAccountEntryId,
    customerId,
    saleId,
    paymentId,
    createdBy,
    entryType,
    amount,
    direction,
    description,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customer_account_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomerAccountEntryTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('last_modified_date')) {
      context.handle(
        _lastModifiedDateMeta,
        lastModifiedDate.isAcceptableOrUnknown(
          data['last_modified_date']!,
          _lastModifiedDateMeta,
        ),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('customer_account_entry_id')) {
      context.handle(
        _customerAccountEntryIdMeta,
        customerAccountEntryId.isAcceptableOrUnknown(
          data['customer_account_entry_id']!,
          _customerAccountEntryIdMeta,
        ),
      );
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('sale_id')) {
      context.handle(
        _saleIdMeta,
        saleId.isAcceptableOrUnknown(data['sale_id']!, _saleIdMeta),
      );
    }
    if (data.containsKey('payment_id')) {
      context.handle(
        _paymentIdMeta,
        paymentId.isAcceptableOrUnknown(data['payment_id']!, _paymentIdMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('entry_type')) {
      context.handle(
        _entryTypeMeta,
        entryType.isAcceptableOrUnknown(data['entry_type']!, _entryTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entryTypeMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {customerAccountEntryId};
  @override
  CustomerAccountEntryTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomerAccountEntryTableData(
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastModifiedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified_date'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      customerAccountEntryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_account_entry_id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      )!,
      saleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_id'],
      ),
      paymentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_id'],
      ),
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
      entryType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_type'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}direction'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
    );
  }

  @override
  $CustomerAccountEntryTableTable createAlias(String alias) {
    return $CustomerAccountEntryTableTable(attachedDatabase, alias);
  }
}

class CustomerAccountEntryTableData extends DataClass
    implements Insertable<CustomerAccountEntryTableData> {
  final DateTime createdAt;
  final DateTime lastModifiedDate;
  final bool enabled;
  final int? serverId;
  final String customerAccountEntryId;
  final String customerId;
  final String? saleId;
  final String? paymentId;
  final String? createdBy;
  final String entryType;
  final double amount;
  final int direction;
  final String? description;
  const CustomerAccountEntryTableData({
    required this.createdAt,
    required this.lastModifiedDate,
    required this.enabled,
    this.serverId,
    required this.customerAccountEntryId,
    required this.customerId,
    this.saleId,
    this.paymentId,
    this.createdBy,
    required this.entryType,
    required this.amount,
    required this.direction,
    this.description,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_modified_date'] = Variable<DateTime>(lastModifiedDate);
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['customer_account_entry_id'] = Variable<String>(customerAccountEntryId);
    map['customer_id'] = Variable<String>(customerId);
    if (!nullToAbsent || saleId != null) {
      map['sale_id'] = Variable<String>(saleId);
    }
    if (!nullToAbsent || paymentId != null) {
      map['payment_id'] = Variable<String>(paymentId);
    }
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    map['entry_type'] = Variable<String>(entryType);
    map['amount'] = Variable<double>(amount);
    map['direction'] = Variable<int>(direction);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    return map;
  }

  CustomerAccountEntryTableCompanion toCompanion(bool nullToAbsent) {
    return CustomerAccountEntryTableCompanion(
      createdAt: Value(createdAt),
      lastModifiedDate: Value(lastModifiedDate),
      enabled: Value(enabled),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      customerAccountEntryId: Value(customerAccountEntryId),
      customerId: Value(customerId),
      saleId: saleId == null && nullToAbsent
          ? const Value.absent()
          : Value(saleId),
      paymentId: paymentId == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentId),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      entryType: Value(entryType),
      amount: Value(amount),
      direction: Value(direction),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
    );
  }

  factory CustomerAccountEntryTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomerAccountEntryTableData(
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastModifiedDate: serializer.fromJson<DateTime>(json['lastModifiedDate']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      customerAccountEntryId: serializer.fromJson<String>(
        json['customerAccountEntryId'],
      ),
      customerId: serializer.fromJson<String>(json['customerId']),
      saleId: serializer.fromJson<String?>(json['saleId']),
      paymentId: serializer.fromJson<String?>(json['paymentId']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      entryType: serializer.fromJson<String>(json['entryType']),
      amount: serializer.fromJson<double>(json['amount']),
      direction: serializer.fromJson<int>(json['direction']),
      description: serializer.fromJson<String?>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastModifiedDate': serializer.toJson<DateTime>(lastModifiedDate),
      'enabled': serializer.toJson<bool>(enabled),
      'serverId': serializer.toJson<int?>(serverId),
      'customerAccountEntryId': serializer.toJson<String>(
        customerAccountEntryId,
      ),
      'customerId': serializer.toJson<String>(customerId),
      'saleId': serializer.toJson<String?>(saleId),
      'paymentId': serializer.toJson<String?>(paymentId),
      'createdBy': serializer.toJson<String?>(createdBy),
      'entryType': serializer.toJson<String>(entryType),
      'amount': serializer.toJson<double>(amount),
      'direction': serializer.toJson<int>(direction),
      'description': serializer.toJson<String?>(description),
    };
  }

  CustomerAccountEntryTableData copyWith({
    DateTime? createdAt,
    DateTime? lastModifiedDate,
    bool? enabled,
    Value<int?> serverId = const Value.absent(),
    String? customerAccountEntryId,
    String? customerId,
    Value<String?> saleId = const Value.absent(),
    Value<String?> paymentId = const Value.absent(),
    Value<String?> createdBy = const Value.absent(),
    String? entryType,
    double? amount,
    int? direction,
    Value<String?> description = const Value.absent(),
  }) => CustomerAccountEntryTableData(
    createdAt: createdAt ?? this.createdAt,
    lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
    enabled: enabled ?? this.enabled,
    serverId: serverId.present ? serverId.value : this.serverId,
    customerAccountEntryId:
        customerAccountEntryId ?? this.customerAccountEntryId,
    customerId: customerId ?? this.customerId,
    saleId: saleId.present ? saleId.value : this.saleId,
    paymentId: paymentId.present ? paymentId.value : this.paymentId,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    entryType: entryType ?? this.entryType,
    amount: amount ?? this.amount,
    direction: direction ?? this.direction,
    description: description.present ? description.value : this.description,
  );
  CustomerAccountEntryTableData copyWithCompanion(
    CustomerAccountEntryTableCompanion data,
  ) {
    return CustomerAccountEntryTableData(
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastModifiedDate: data.lastModifiedDate.present
          ? data.lastModifiedDate.value
          : this.lastModifiedDate,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      customerAccountEntryId: data.customerAccountEntryId.present
          ? data.customerAccountEntryId.value
          : this.customerAccountEntryId,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      saleId: data.saleId.present ? data.saleId.value : this.saleId,
      paymentId: data.paymentId.present ? data.paymentId.value : this.paymentId,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      entryType: data.entryType.present ? data.entryType.value : this.entryType,
      amount: data.amount.present ? data.amount.value : this.amount,
      direction: data.direction.present ? data.direction.value : this.direction,
      description: data.description.present
          ? data.description.value
          : this.description,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomerAccountEntryTableData(')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedDate: $lastModifiedDate, ')
          ..write('enabled: $enabled, ')
          ..write('serverId: $serverId, ')
          ..write('customerAccountEntryId: $customerAccountEntryId, ')
          ..write('customerId: $customerId, ')
          ..write('saleId: $saleId, ')
          ..write('paymentId: $paymentId, ')
          ..write('createdBy: $createdBy, ')
          ..write('entryType: $entryType, ')
          ..write('amount: $amount, ')
          ..write('direction: $direction, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    createdAt,
    lastModifiedDate,
    enabled,
    serverId,
    customerAccountEntryId,
    customerId,
    saleId,
    paymentId,
    createdBy,
    entryType,
    amount,
    direction,
    description,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerAccountEntryTableData &&
          other.createdAt == this.createdAt &&
          other.lastModifiedDate == this.lastModifiedDate &&
          other.enabled == this.enabled &&
          other.serverId == this.serverId &&
          other.customerAccountEntryId == this.customerAccountEntryId &&
          other.customerId == this.customerId &&
          other.saleId == this.saleId &&
          other.paymentId == this.paymentId &&
          other.createdBy == this.createdBy &&
          other.entryType == this.entryType &&
          other.amount == this.amount &&
          other.direction == this.direction &&
          other.description == this.description);
}

class CustomerAccountEntryTableCompanion
    extends UpdateCompanion<CustomerAccountEntryTableData> {
  final Value<DateTime> createdAt;
  final Value<DateTime> lastModifiedDate;
  final Value<bool> enabled;
  final Value<int?> serverId;
  final Value<String> customerAccountEntryId;
  final Value<String> customerId;
  final Value<String?> saleId;
  final Value<String?> paymentId;
  final Value<String?> createdBy;
  final Value<String> entryType;
  final Value<double> amount;
  final Value<int> direction;
  final Value<String?> description;
  final Value<int> rowid;
  const CustomerAccountEntryTableCompanion({
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.serverId = const Value.absent(),
    this.customerAccountEntryId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.saleId = const Value.absent(),
    this.paymentId = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.entryType = const Value.absent(),
    this.amount = const Value.absent(),
    this.direction = const Value.absent(),
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomerAccountEntryTableCompanion.insert({
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.serverId = const Value.absent(),
    this.customerAccountEntryId = const Value.absent(),
    required String customerId,
    this.saleId = const Value.absent(),
    this.paymentId = const Value.absent(),
    this.createdBy = const Value.absent(),
    required String entryType,
    required double amount,
    required int direction,
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : customerId = Value(customerId),
       entryType = Value(entryType),
       amount = Value(amount),
       direction = Value(direction);
  static Insertable<CustomerAccountEntryTableData> custom({
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastModifiedDate,
    Expression<bool>? enabled,
    Expression<int>? serverId,
    Expression<String>? customerAccountEntryId,
    Expression<String>? customerId,
    Expression<String>? saleId,
    Expression<String>? paymentId,
    Expression<String>? createdBy,
    Expression<String>? entryType,
    Expression<double>? amount,
    Expression<int>? direction,
    Expression<String>? description,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (lastModifiedDate != null) 'last_modified_date': lastModifiedDate,
      if (enabled != null) 'enabled': enabled,
      if (serverId != null) 'server_id': serverId,
      if (customerAccountEntryId != null)
        'customer_account_entry_id': customerAccountEntryId,
      if (customerId != null) 'customer_id': customerId,
      if (saleId != null) 'sale_id': saleId,
      if (paymentId != null) 'payment_id': paymentId,
      if (createdBy != null) 'created_by': createdBy,
      if (entryType != null) 'entry_type': entryType,
      if (amount != null) 'amount': amount,
      if (direction != null) 'direction': direction,
      if (description != null) 'description': description,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomerAccountEntryTableCompanion copyWith({
    Value<DateTime>? createdAt,
    Value<DateTime>? lastModifiedDate,
    Value<bool>? enabled,
    Value<int?>? serverId,
    Value<String>? customerAccountEntryId,
    Value<String>? customerId,
    Value<String?>? saleId,
    Value<String?>? paymentId,
    Value<String?>? createdBy,
    Value<String>? entryType,
    Value<double>? amount,
    Value<int>? direction,
    Value<String?>? description,
    Value<int>? rowid,
  }) {
    return CustomerAccountEntryTableCompanion(
      createdAt: createdAt ?? this.createdAt,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      enabled: enabled ?? this.enabled,
      serverId: serverId ?? this.serverId,
      customerAccountEntryId:
          customerAccountEntryId ?? this.customerAccountEntryId,
      customerId: customerId ?? this.customerId,
      saleId: saleId ?? this.saleId,
      paymentId: paymentId ?? this.paymentId,
      createdBy: createdBy ?? this.createdBy,
      entryType: entryType ?? this.entryType,
      amount: amount ?? this.amount,
      direction: direction ?? this.direction,
      description: description ?? this.description,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastModifiedDate.present) {
      map['last_modified_date'] = Variable<DateTime>(lastModifiedDate.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (customerAccountEntryId.present) {
      map['customer_account_entry_id'] = Variable<String>(
        customerAccountEntryId.value,
      );
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (saleId.present) {
      map['sale_id'] = Variable<String>(saleId.value);
    }
    if (paymentId.present) {
      map['payment_id'] = Variable<String>(paymentId.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (entryType.present) {
      map['entry_type'] = Variable<String>(entryType.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (direction.present) {
      map['direction'] = Variable<int>(direction.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomerAccountEntryTableCompanion(')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedDate: $lastModifiedDate, ')
          ..write('enabled: $enabled, ')
          ..write('serverId: $serverId, ')
          ..write('customerAccountEntryId: $customerAccountEntryId, ')
          ..write('customerId: $customerId, ')
          ..write('saleId: $saleId, ')
          ..write('paymentId: $paymentId, ')
          ..write('createdBy: $createdBy, ')
          ..write('entryType: $entryType, ')
          ..write('amount: $amount, ')
          ..write('direction: $direction, ')
          ..write('description: $description, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomerBalanceTableTable extends CustomerBalanceTable
    with TableInfo<$CustomerBalanceTableTable, CustomerBalanceTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomerBalanceTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastModifiedDateMeta = const VerificationMeta(
    'lastModifiedDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastModifiedDate =
      GeneratedColumn<DateTime>(
        'last_modified_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES customers (customer_id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _currentBalanceMeta = const VerificationMeta(
    'currentBalance',
  );
  @override
  late final GeneratedColumn<double> currentBalance = GeneratedColumn<double>(
    'current_balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _lastEntryIdMeta = const VerificationMeta(
    'lastEntryId',
  );
  @override
  late final GeneratedColumn<String> lastEntryId = GeneratedColumn<String>(
    'last_entry_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES customer_account_entries (customer_account_entry_id) ON DELETE SET NULL',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    createdAt,
    lastModifiedDate,
    enabled,
    serverId,
    customerId,
    currentBalance,
    lastEntryId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customer_balances';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomerBalanceTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('last_modified_date')) {
      context.handle(
        _lastModifiedDateMeta,
        lastModifiedDate.isAcceptableOrUnknown(
          data['last_modified_date']!,
          _lastModifiedDateMeta,
        ),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('current_balance')) {
      context.handle(
        _currentBalanceMeta,
        currentBalance.isAcceptableOrUnknown(
          data['current_balance']!,
          _currentBalanceMeta,
        ),
      );
    }
    if (data.containsKey('last_entry_id')) {
      context.handle(
        _lastEntryIdMeta,
        lastEntryId.isAcceptableOrUnknown(
          data['last_entry_id']!,
          _lastEntryIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {customerId};
  @override
  CustomerBalanceTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomerBalanceTableData(
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastModifiedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified_date'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      )!,
      currentBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_balance'],
      )!,
      lastEntryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_entry_id'],
      ),
    );
  }

  @override
  $CustomerBalanceTableTable createAlias(String alias) {
    return $CustomerBalanceTableTable(attachedDatabase, alias);
  }
}

class CustomerBalanceTableData extends DataClass
    implements Insertable<CustomerBalanceTableData> {
  final DateTime createdAt;
  final DateTime lastModifiedDate;
  final bool enabled;
  final int? serverId;
  final String customerId;
  final double currentBalance;
  final String? lastEntryId;
  const CustomerBalanceTableData({
    required this.createdAt,
    required this.lastModifiedDate,
    required this.enabled,
    this.serverId,
    required this.customerId,
    required this.currentBalance,
    this.lastEntryId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_modified_date'] = Variable<DateTime>(lastModifiedDate);
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['customer_id'] = Variable<String>(customerId);
    map['current_balance'] = Variable<double>(currentBalance);
    if (!nullToAbsent || lastEntryId != null) {
      map['last_entry_id'] = Variable<String>(lastEntryId);
    }
    return map;
  }

  CustomerBalanceTableCompanion toCompanion(bool nullToAbsent) {
    return CustomerBalanceTableCompanion(
      createdAt: Value(createdAt),
      lastModifiedDate: Value(lastModifiedDate),
      enabled: Value(enabled),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      customerId: Value(customerId),
      currentBalance: Value(currentBalance),
      lastEntryId: lastEntryId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastEntryId),
    );
  }

  factory CustomerBalanceTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomerBalanceTableData(
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastModifiedDate: serializer.fromJson<DateTime>(json['lastModifiedDate']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      customerId: serializer.fromJson<String>(json['customerId']),
      currentBalance: serializer.fromJson<double>(json['currentBalance']),
      lastEntryId: serializer.fromJson<String?>(json['lastEntryId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastModifiedDate': serializer.toJson<DateTime>(lastModifiedDate),
      'enabled': serializer.toJson<bool>(enabled),
      'serverId': serializer.toJson<int?>(serverId),
      'customerId': serializer.toJson<String>(customerId),
      'currentBalance': serializer.toJson<double>(currentBalance),
      'lastEntryId': serializer.toJson<String?>(lastEntryId),
    };
  }

  CustomerBalanceTableData copyWith({
    DateTime? createdAt,
    DateTime? lastModifiedDate,
    bool? enabled,
    Value<int?> serverId = const Value.absent(),
    String? customerId,
    double? currentBalance,
    Value<String?> lastEntryId = const Value.absent(),
  }) => CustomerBalanceTableData(
    createdAt: createdAt ?? this.createdAt,
    lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
    enabled: enabled ?? this.enabled,
    serverId: serverId.present ? serverId.value : this.serverId,
    customerId: customerId ?? this.customerId,
    currentBalance: currentBalance ?? this.currentBalance,
    lastEntryId: lastEntryId.present ? lastEntryId.value : this.lastEntryId,
  );
  CustomerBalanceTableData copyWithCompanion(
    CustomerBalanceTableCompanion data,
  ) {
    return CustomerBalanceTableData(
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastModifiedDate: data.lastModifiedDate.present
          ? data.lastModifiedDate.value
          : this.lastModifiedDate,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      currentBalance: data.currentBalance.present
          ? data.currentBalance.value
          : this.currentBalance,
      lastEntryId: data.lastEntryId.present
          ? data.lastEntryId.value
          : this.lastEntryId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomerBalanceTableData(')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedDate: $lastModifiedDate, ')
          ..write('enabled: $enabled, ')
          ..write('serverId: $serverId, ')
          ..write('customerId: $customerId, ')
          ..write('currentBalance: $currentBalance, ')
          ..write('lastEntryId: $lastEntryId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    createdAt,
    lastModifiedDate,
    enabled,
    serverId,
    customerId,
    currentBalance,
    lastEntryId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerBalanceTableData &&
          other.createdAt == this.createdAt &&
          other.lastModifiedDate == this.lastModifiedDate &&
          other.enabled == this.enabled &&
          other.serverId == this.serverId &&
          other.customerId == this.customerId &&
          other.currentBalance == this.currentBalance &&
          other.lastEntryId == this.lastEntryId);
}

class CustomerBalanceTableCompanion
    extends UpdateCompanion<CustomerBalanceTableData> {
  final Value<DateTime> createdAt;
  final Value<DateTime> lastModifiedDate;
  final Value<bool> enabled;
  final Value<int?> serverId;
  final Value<String> customerId;
  final Value<double> currentBalance;
  final Value<String?> lastEntryId;
  final Value<int> rowid;
  const CustomerBalanceTableCompanion({
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.serverId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.currentBalance = const Value.absent(),
    this.lastEntryId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomerBalanceTableCompanion.insert({
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.serverId = const Value.absent(),
    required String customerId,
    this.currentBalance = const Value.absent(),
    this.lastEntryId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : customerId = Value(customerId);
  static Insertable<CustomerBalanceTableData> custom({
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastModifiedDate,
    Expression<bool>? enabled,
    Expression<int>? serverId,
    Expression<String>? customerId,
    Expression<double>? currentBalance,
    Expression<String>? lastEntryId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (lastModifiedDate != null) 'last_modified_date': lastModifiedDate,
      if (enabled != null) 'enabled': enabled,
      if (serverId != null) 'server_id': serverId,
      if (customerId != null) 'customer_id': customerId,
      if (currentBalance != null) 'current_balance': currentBalance,
      if (lastEntryId != null) 'last_entry_id': lastEntryId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomerBalanceTableCompanion copyWith({
    Value<DateTime>? createdAt,
    Value<DateTime>? lastModifiedDate,
    Value<bool>? enabled,
    Value<int?>? serverId,
    Value<String>? customerId,
    Value<double>? currentBalance,
    Value<String?>? lastEntryId,
    Value<int>? rowid,
  }) {
    return CustomerBalanceTableCompanion(
      createdAt: createdAt ?? this.createdAt,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      enabled: enabled ?? this.enabled,
      serverId: serverId ?? this.serverId,
      customerId: customerId ?? this.customerId,
      currentBalance: currentBalance ?? this.currentBalance,
      lastEntryId: lastEntryId ?? this.lastEntryId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastModifiedDate.present) {
      map['last_modified_date'] = Variable<DateTime>(lastModifiedDate.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (currentBalance.present) {
      map['current_balance'] = Variable<double>(currentBalance.value);
    }
    if (lastEntryId.present) {
      map['last_entry_id'] = Variable<String>(lastEntryId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomerBalanceTableCompanion(')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedDate: $lastModifiedDate, ')
          ..write('enabled: $enabled, ')
          ..write('serverId: $serverId, ')
          ..write('customerId: $customerId, ')
          ..write('currentBalance: $currentBalance, ')
          ..write('lastEntryId: $lastEntryId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContainerMovementTableTable extends ContainerMovementTable
    with TableInfo<$ContainerMovementTableTable, ContainerMovementTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContainerMovementTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastModifiedDateMeta = const VerificationMeta(
    'lastModifiedDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastModifiedDate =
      GeneratedColumn<DateTime>(
        'last_modified_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _containerMovementIdMeta =
      const VerificationMeta('containerMovementId');
  @override
  late final GeneratedColumn<String> containerMovementId =
      GeneratedColumn<String>(
        'container_movement_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        clientDefault: () => uuid.v4(),
      );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES customers (customer_id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _containerTypeMeta = const VerificationMeta(
    'containerType',
  );
  @override
  late final GeneratedColumn<String> containerType = GeneratedColumn<String>(
    'container_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deliveredQuantityMeta = const VerificationMeta(
    'deliveredQuantity',
  );
  @override
  late final GeneratedColumn<int> deliveredQuantity = GeneratedColumn<int>(
    'delivered_quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _returnedQuantityMeta = const VerificationMeta(
    'returnedQuantity',
  );
  @override
  late final GeneratedColumn<int> returnedQuantity = GeneratedColumn<int>(
    'returned_quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visitIdMeta = const VerificationMeta(
    'visitId',
  );
  @override
  late final GeneratedColumn<String> visitId = GeneratedColumn<String>(
    'visit_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES visits (visit_id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _routeIdMeta = const VerificationMeta(
    'routeId',
  );
  @override
  late final GeneratedColumn<String> routeId = GeneratedColumn<String>(
    'route_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES routes (route_id) ON DELETE SET NULL',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    createdAt,
    lastModifiedDate,
    enabled,
    serverId,
    containerMovementId,
    customerId,
    containerType,
    deliveredQuantity,
    returnedQuantity,
    visitId,
    routeId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'container_movements';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContainerMovementTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('last_modified_date')) {
      context.handle(
        _lastModifiedDateMeta,
        lastModifiedDate.isAcceptableOrUnknown(
          data['last_modified_date']!,
          _lastModifiedDateMeta,
        ),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('container_movement_id')) {
      context.handle(
        _containerMovementIdMeta,
        containerMovementId.isAcceptableOrUnknown(
          data['container_movement_id']!,
          _containerMovementIdMeta,
        ),
      );
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('container_type')) {
      context.handle(
        _containerTypeMeta,
        containerType.isAcceptableOrUnknown(
          data['container_type']!,
          _containerTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_containerTypeMeta);
    }
    if (data.containsKey('delivered_quantity')) {
      context.handle(
        _deliveredQuantityMeta,
        deliveredQuantity.isAcceptableOrUnknown(
          data['delivered_quantity']!,
          _deliveredQuantityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deliveredQuantityMeta);
    }
    if (data.containsKey('returned_quantity')) {
      context.handle(
        _returnedQuantityMeta,
        returnedQuantity.isAcceptableOrUnknown(
          data['returned_quantity']!,
          _returnedQuantityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_returnedQuantityMeta);
    }
    if (data.containsKey('visit_id')) {
      context.handle(
        _visitIdMeta,
        visitId.isAcceptableOrUnknown(data['visit_id']!, _visitIdMeta),
      );
    }
    if (data.containsKey('route_id')) {
      context.handle(
        _routeIdMeta,
        routeId.isAcceptableOrUnknown(data['route_id']!, _routeIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {containerMovementId};
  @override
  ContainerMovementTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContainerMovementTableData(
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastModifiedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified_date'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      containerMovementId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}container_movement_id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      )!,
      containerType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}container_type'],
      )!,
      deliveredQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}delivered_quantity'],
      )!,
      returnedQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}returned_quantity'],
      )!,
      visitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visit_id'],
      ),
      routeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route_id'],
      ),
    );
  }

  @override
  $ContainerMovementTableTable createAlias(String alias) {
    return $ContainerMovementTableTable(attachedDatabase, alias);
  }
}

class ContainerMovementTableData extends DataClass
    implements Insertable<ContainerMovementTableData> {
  final DateTime createdAt;
  final DateTime lastModifiedDate;
  final bool enabled;
  final int? serverId;
  final String containerMovementId;
  final String customerId;
  final String containerType;
  final int deliveredQuantity;
  final int returnedQuantity;
  final String? visitId;
  final String? routeId;
  const ContainerMovementTableData({
    required this.createdAt,
    required this.lastModifiedDate,
    required this.enabled,
    this.serverId,
    required this.containerMovementId,
    required this.customerId,
    required this.containerType,
    required this.deliveredQuantity,
    required this.returnedQuantity,
    this.visitId,
    this.routeId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_modified_date'] = Variable<DateTime>(lastModifiedDate);
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['container_movement_id'] = Variable<String>(containerMovementId);
    map['customer_id'] = Variable<String>(customerId);
    map['container_type'] = Variable<String>(containerType);
    map['delivered_quantity'] = Variable<int>(deliveredQuantity);
    map['returned_quantity'] = Variable<int>(returnedQuantity);
    if (!nullToAbsent || visitId != null) {
      map['visit_id'] = Variable<String>(visitId);
    }
    if (!nullToAbsent || routeId != null) {
      map['route_id'] = Variable<String>(routeId);
    }
    return map;
  }

  ContainerMovementTableCompanion toCompanion(bool nullToAbsent) {
    return ContainerMovementTableCompanion(
      createdAt: Value(createdAt),
      lastModifiedDate: Value(lastModifiedDate),
      enabled: Value(enabled),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      containerMovementId: Value(containerMovementId),
      customerId: Value(customerId),
      containerType: Value(containerType),
      deliveredQuantity: Value(deliveredQuantity),
      returnedQuantity: Value(returnedQuantity),
      visitId: visitId == null && nullToAbsent
          ? const Value.absent()
          : Value(visitId),
      routeId: routeId == null && nullToAbsent
          ? const Value.absent()
          : Value(routeId),
    );
  }

  factory ContainerMovementTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContainerMovementTableData(
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastModifiedDate: serializer.fromJson<DateTime>(json['lastModifiedDate']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      containerMovementId: serializer.fromJson<String>(
        json['containerMovementId'],
      ),
      customerId: serializer.fromJson<String>(json['customerId']),
      containerType: serializer.fromJson<String>(json['containerType']),
      deliveredQuantity: serializer.fromJson<int>(json['deliveredQuantity']),
      returnedQuantity: serializer.fromJson<int>(json['returnedQuantity']),
      visitId: serializer.fromJson<String?>(json['visitId']),
      routeId: serializer.fromJson<String?>(json['routeId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastModifiedDate': serializer.toJson<DateTime>(lastModifiedDate),
      'enabled': serializer.toJson<bool>(enabled),
      'serverId': serializer.toJson<int?>(serverId),
      'containerMovementId': serializer.toJson<String>(containerMovementId),
      'customerId': serializer.toJson<String>(customerId),
      'containerType': serializer.toJson<String>(containerType),
      'deliveredQuantity': serializer.toJson<int>(deliveredQuantity),
      'returnedQuantity': serializer.toJson<int>(returnedQuantity),
      'visitId': serializer.toJson<String?>(visitId),
      'routeId': serializer.toJson<String?>(routeId),
    };
  }

  ContainerMovementTableData copyWith({
    DateTime? createdAt,
    DateTime? lastModifiedDate,
    bool? enabled,
    Value<int?> serverId = const Value.absent(),
    String? containerMovementId,
    String? customerId,
    String? containerType,
    int? deliveredQuantity,
    int? returnedQuantity,
    Value<String?> visitId = const Value.absent(),
    Value<String?> routeId = const Value.absent(),
  }) => ContainerMovementTableData(
    createdAt: createdAt ?? this.createdAt,
    lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
    enabled: enabled ?? this.enabled,
    serverId: serverId.present ? serverId.value : this.serverId,
    containerMovementId: containerMovementId ?? this.containerMovementId,
    customerId: customerId ?? this.customerId,
    containerType: containerType ?? this.containerType,
    deliveredQuantity: deliveredQuantity ?? this.deliveredQuantity,
    returnedQuantity: returnedQuantity ?? this.returnedQuantity,
    visitId: visitId.present ? visitId.value : this.visitId,
    routeId: routeId.present ? routeId.value : this.routeId,
  );
  ContainerMovementTableData copyWithCompanion(
    ContainerMovementTableCompanion data,
  ) {
    return ContainerMovementTableData(
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastModifiedDate: data.lastModifiedDate.present
          ? data.lastModifiedDate.value
          : this.lastModifiedDate,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      containerMovementId: data.containerMovementId.present
          ? data.containerMovementId.value
          : this.containerMovementId,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      containerType: data.containerType.present
          ? data.containerType.value
          : this.containerType,
      deliveredQuantity: data.deliveredQuantity.present
          ? data.deliveredQuantity.value
          : this.deliveredQuantity,
      returnedQuantity: data.returnedQuantity.present
          ? data.returnedQuantity.value
          : this.returnedQuantity,
      visitId: data.visitId.present ? data.visitId.value : this.visitId,
      routeId: data.routeId.present ? data.routeId.value : this.routeId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContainerMovementTableData(')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedDate: $lastModifiedDate, ')
          ..write('enabled: $enabled, ')
          ..write('serverId: $serverId, ')
          ..write('containerMovementId: $containerMovementId, ')
          ..write('customerId: $customerId, ')
          ..write('containerType: $containerType, ')
          ..write('deliveredQuantity: $deliveredQuantity, ')
          ..write('returnedQuantity: $returnedQuantity, ')
          ..write('visitId: $visitId, ')
          ..write('routeId: $routeId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    createdAt,
    lastModifiedDate,
    enabled,
    serverId,
    containerMovementId,
    customerId,
    containerType,
    deliveredQuantity,
    returnedQuantity,
    visitId,
    routeId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContainerMovementTableData &&
          other.createdAt == this.createdAt &&
          other.lastModifiedDate == this.lastModifiedDate &&
          other.enabled == this.enabled &&
          other.serverId == this.serverId &&
          other.containerMovementId == this.containerMovementId &&
          other.customerId == this.customerId &&
          other.containerType == this.containerType &&
          other.deliveredQuantity == this.deliveredQuantity &&
          other.returnedQuantity == this.returnedQuantity &&
          other.visitId == this.visitId &&
          other.routeId == this.routeId);
}

class ContainerMovementTableCompanion
    extends UpdateCompanion<ContainerMovementTableData> {
  final Value<DateTime> createdAt;
  final Value<DateTime> lastModifiedDate;
  final Value<bool> enabled;
  final Value<int?> serverId;
  final Value<String> containerMovementId;
  final Value<String> customerId;
  final Value<String> containerType;
  final Value<int> deliveredQuantity;
  final Value<int> returnedQuantity;
  final Value<String?> visitId;
  final Value<String?> routeId;
  final Value<int> rowid;
  const ContainerMovementTableCompanion({
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.serverId = const Value.absent(),
    this.containerMovementId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.containerType = const Value.absent(),
    this.deliveredQuantity = const Value.absent(),
    this.returnedQuantity = const Value.absent(),
    this.visitId = const Value.absent(),
    this.routeId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContainerMovementTableCompanion.insert({
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.serverId = const Value.absent(),
    this.containerMovementId = const Value.absent(),
    required String customerId,
    required String containerType,
    required int deliveredQuantity,
    required int returnedQuantity,
    this.visitId = const Value.absent(),
    this.routeId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : customerId = Value(customerId),
       containerType = Value(containerType),
       deliveredQuantity = Value(deliveredQuantity),
       returnedQuantity = Value(returnedQuantity);
  static Insertable<ContainerMovementTableData> custom({
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastModifiedDate,
    Expression<bool>? enabled,
    Expression<int>? serverId,
    Expression<String>? containerMovementId,
    Expression<String>? customerId,
    Expression<String>? containerType,
    Expression<int>? deliveredQuantity,
    Expression<int>? returnedQuantity,
    Expression<String>? visitId,
    Expression<String>? routeId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (lastModifiedDate != null) 'last_modified_date': lastModifiedDate,
      if (enabled != null) 'enabled': enabled,
      if (serverId != null) 'server_id': serverId,
      if (containerMovementId != null)
        'container_movement_id': containerMovementId,
      if (customerId != null) 'customer_id': customerId,
      if (containerType != null) 'container_type': containerType,
      if (deliveredQuantity != null) 'delivered_quantity': deliveredQuantity,
      if (returnedQuantity != null) 'returned_quantity': returnedQuantity,
      if (visitId != null) 'visit_id': visitId,
      if (routeId != null) 'route_id': routeId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContainerMovementTableCompanion copyWith({
    Value<DateTime>? createdAt,
    Value<DateTime>? lastModifiedDate,
    Value<bool>? enabled,
    Value<int?>? serverId,
    Value<String>? containerMovementId,
    Value<String>? customerId,
    Value<String>? containerType,
    Value<int>? deliveredQuantity,
    Value<int>? returnedQuantity,
    Value<String?>? visitId,
    Value<String?>? routeId,
    Value<int>? rowid,
  }) {
    return ContainerMovementTableCompanion(
      createdAt: createdAt ?? this.createdAt,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      enabled: enabled ?? this.enabled,
      serverId: serverId ?? this.serverId,
      containerMovementId: containerMovementId ?? this.containerMovementId,
      customerId: customerId ?? this.customerId,
      containerType: containerType ?? this.containerType,
      deliveredQuantity: deliveredQuantity ?? this.deliveredQuantity,
      returnedQuantity: returnedQuantity ?? this.returnedQuantity,
      visitId: visitId ?? this.visitId,
      routeId: routeId ?? this.routeId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastModifiedDate.present) {
      map['last_modified_date'] = Variable<DateTime>(lastModifiedDate.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (containerMovementId.present) {
      map['container_movement_id'] = Variable<String>(
        containerMovementId.value,
      );
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (containerType.present) {
      map['container_type'] = Variable<String>(containerType.value);
    }
    if (deliveredQuantity.present) {
      map['delivered_quantity'] = Variable<int>(deliveredQuantity.value);
    }
    if (returnedQuantity.present) {
      map['returned_quantity'] = Variable<int>(returnedQuantity.value);
    }
    if (visitId.present) {
      map['visit_id'] = Variable<String>(visitId.value);
    }
    if (routeId.present) {
      map['route_id'] = Variable<String>(routeId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContainerMovementTableCompanion(')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedDate: $lastModifiedDate, ')
          ..write('enabled: $enabled, ')
          ..write('serverId: $serverId, ')
          ..write('containerMovementId: $containerMovementId, ')
          ..write('customerId: $customerId, ')
          ..write('containerType: $containerType, ')
          ..write('deliveredQuantity: $deliveredQuantity, ')
          ..write('returnedQuantity: $returnedQuantity, ')
          ..write('visitId: $visitId, ')
          ..write('routeId: $routeId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomerContainerBalanceTableTable extends CustomerContainerBalanceTable
    with
        TableInfo<
          $CustomerContainerBalanceTableTable,
          CustomerContainerBalanceTableData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomerContainerBalanceTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastModifiedDateMeta = const VerificationMeta(
    'lastModifiedDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastModifiedDate =
      GeneratedColumn<DateTime>(
        'last_modified_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES customers (customer_id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _containerTypeMeta = const VerificationMeta(
    'containerType',
  );
  @override
  late final GeneratedColumn<String> containerType = GeneratedColumn<String>(
    'container_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    createdAt,
    lastModifiedDate,
    enabled,
    serverId,
    customerId,
    containerType,
    quantity,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customer_container_balances';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomerContainerBalanceTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('last_modified_date')) {
      context.handle(
        _lastModifiedDateMeta,
        lastModifiedDate.isAcceptableOrUnknown(
          data['last_modified_date']!,
          _lastModifiedDateMeta,
        ),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('container_type')) {
      context.handle(
        _containerTypeMeta,
        containerType.isAcceptableOrUnknown(
          data['container_type']!,
          _containerTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_containerTypeMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {customerId, containerType};
  @override
  CustomerContainerBalanceTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomerContainerBalanceTableData(
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastModifiedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified_date'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      )!,
      containerType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}container_type'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
    );
  }

  @override
  $CustomerContainerBalanceTableTable createAlias(String alias) {
    return $CustomerContainerBalanceTableTable(attachedDatabase, alias);
  }
}

class CustomerContainerBalanceTableData extends DataClass
    implements Insertable<CustomerContainerBalanceTableData> {
  final DateTime createdAt;
  final DateTime lastModifiedDate;
  final bool enabled;
  final int? serverId;
  final String customerId;
  final String containerType;
  final int quantity;
  const CustomerContainerBalanceTableData({
    required this.createdAt,
    required this.lastModifiedDate,
    required this.enabled,
    this.serverId,
    required this.customerId,
    required this.containerType,
    required this.quantity,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_modified_date'] = Variable<DateTime>(lastModifiedDate);
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['customer_id'] = Variable<String>(customerId);
    map['container_type'] = Variable<String>(containerType);
    map['quantity'] = Variable<int>(quantity);
    return map;
  }

  CustomerContainerBalanceTableCompanion toCompanion(bool nullToAbsent) {
    return CustomerContainerBalanceTableCompanion(
      createdAt: Value(createdAt),
      lastModifiedDate: Value(lastModifiedDate),
      enabled: Value(enabled),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      customerId: Value(customerId),
      containerType: Value(containerType),
      quantity: Value(quantity),
    );
  }

  factory CustomerContainerBalanceTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomerContainerBalanceTableData(
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastModifiedDate: serializer.fromJson<DateTime>(json['lastModifiedDate']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      customerId: serializer.fromJson<String>(json['customerId']),
      containerType: serializer.fromJson<String>(json['containerType']),
      quantity: serializer.fromJson<int>(json['quantity']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastModifiedDate': serializer.toJson<DateTime>(lastModifiedDate),
      'enabled': serializer.toJson<bool>(enabled),
      'serverId': serializer.toJson<int?>(serverId),
      'customerId': serializer.toJson<String>(customerId),
      'containerType': serializer.toJson<String>(containerType),
      'quantity': serializer.toJson<int>(quantity),
    };
  }

  CustomerContainerBalanceTableData copyWith({
    DateTime? createdAt,
    DateTime? lastModifiedDate,
    bool? enabled,
    Value<int?> serverId = const Value.absent(),
    String? customerId,
    String? containerType,
    int? quantity,
  }) => CustomerContainerBalanceTableData(
    createdAt: createdAt ?? this.createdAt,
    lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
    enabled: enabled ?? this.enabled,
    serverId: serverId.present ? serverId.value : this.serverId,
    customerId: customerId ?? this.customerId,
    containerType: containerType ?? this.containerType,
    quantity: quantity ?? this.quantity,
  );
  CustomerContainerBalanceTableData copyWithCompanion(
    CustomerContainerBalanceTableCompanion data,
  ) {
    return CustomerContainerBalanceTableData(
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastModifiedDate: data.lastModifiedDate.present
          ? data.lastModifiedDate.value
          : this.lastModifiedDate,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      containerType: data.containerType.present
          ? data.containerType.value
          : this.containerType,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomerContainerBalanceTableData(')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedDate: $lastModifiedDate, ')
          ..write('enabled: $enabled, ')
          ..write('serverId: $serverId, ')
          ..write('customerId: $customerId, ')
          ..write('containerType: $containerType, ')
          ..write('quantity: $quantity')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    createdAt,
    lastModifiedDate,
    enabled,
    serverId,
    customerId,
    containerType,
    quantity,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerContainerBalanceTableData &&
          other.createdAt == this.createdAt &&
          other.lastModifiedDate == this.lastModifiedDate &&
          other.enabled == this.enabled &&
          other.serverId == this.serverId &&
          other.customerId == this.customerId &&
          other.containerType == this.containerType &&
          other.quantity == this.quantity);
}

class CustomerContainerBalanceTableCompanion
    extends UpdateCompanion<CustomerContainerBalanceTableData> {
  final Value<DateTime> createdAt;
  final Value<DateTime> lastModifiedDate;
  final Value<bool> enabled;
  final Value<int?> serverId;
  final Value<String> customerId;
  final Value<String> containerType;
  final Value<int> quantity;
  final Value<int> rowid;
  const CustomerContainerBalanceTableCompanion({
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.serverId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.containerType = const Value.absent(),
    this.quantity = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomerContainerBalanceTableCompanion.insert({
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.serverId = const Value.absent(),
    required String customerId,
    required String containerType,
    this.quantity = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : customerId = Value(customerId),
       containerType = Value(containerType);
  static Insertable<CustomerContainerBalanceTableData> custom({
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastModifiedDate,
    Expression<bool>? enabled,
    Expression<int>? serverId,
    Expression<String>? customerId,
    Expression<String>? containerType,
    Expression<int>? quantity,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (lastModifiedDate != null) 'last_modified_date': lastModifiedDate,
      if (enabled != null) 'enabled': enabled,
      if (serverId != null) 'server_id': serverId,
      if (customerId != null) 'customer_id': customerId,
      if (containerType != null) 'container_type': containerType,
      if (quantity != null) 'quantity': quantity,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomerContainerBalanceTableCompanion copyWith({
    Value<DateTime>? createdAt,
    Value<DateTime>? lastModifiedDate,
    Value<bool>? enabled,
    Value<int?>? serverId,
    Value<String>? customerId,
    Value<String>? containerType,
    Value<int>? quantity,
    Value<int>? rowid,
  }) {
    return CustomerContainerBalanceTableCompanion(
      createdAt: createdAt ?? this.createdAt,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      enabled: enabled ?? this.enabled,
      serverId: serverId ?? this.serverId,
      customerId: customerId ?? this.customerId,
      containerType: containerType ?? this.containerType,
      quantity: quantity ?? this.quantity,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastModifiedDate.present) {
      map['last_modified_date'] = Variable<DateTime>(lastModifiedDate.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (containerType.present) {
      map['container_type'] = Variable<String>(containerType.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomerContainerBalanceTableCompanion(')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedDate: $lastModifiedDate, ')
          ..write('enabled: $enabled, ')
          ..write('serverId: $serverId, ')
          ..write('customerId: $customerId, ')
          ..write('containerType: $containerType, ')
          ..write('quantity: $quantity, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RouteInventoryLoadTableTable extends RouteInventoryLoadTable
    with TableInfo<$RouteInventoryLoadTableTable, RouteInventoryLoadTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RouteInventoryLoadTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastModifiedDateMeta = const VerificationMeta(
    'lastModifiedDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastModifiedDate =
      GeneratedColumn<DateTime>(
        'last_modified_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _routeInventoryLoadIdMeta =
      const VerificationMeta('routeInventoryLoadId');
  @override
  late final GeneratedColumn<String> routeInventoryLoadId =
      GeneratedColumn<String>(
        'route_inventory_load_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        clientDefault: () => uuid.v4(),
      );
  static const VerificationMeta _routeIdMeta = const VerificationMeta(
    'routeId',
  );
  @override
  late final GeneratedColumn<String> routeId = GeneratedColumn<String>(
    'route_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES routes (route_id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (product_id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _loadedAtMeta = const VerificationMeta(
    'loadedAt',
  );
  @override
  late final GeneratedColumn<DateTime> loadedAt = GeneratedColumn<DateTime>(
    'loaded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    createdAt,
    lastModifiedDate,
    enabled,
    serverId,
    routeInventoryLoadId,
    routeId,
    productId,
    quantity,
    loadedAt,
    createdBy,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'route_inventory_loads';
  @override
  VerificationContext validateIntegrity(
    Insertable<RouteInventoryLoadTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('last_modified_date')) {
      context.handle(
        _lastModifiedDateMeta,
        lastModifiedDate.isAcceptableOrUnknown(
          data['last_modified_date']!,
          _lastModifiedDateMeta,
        ),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('route_inventory_load_id')) {
      context.handle(
        _routeInventoryLoadIdMeta,
        routeInventoryLoadId.isAcceptableOrUnknown(
          data['route_inventory_load_id']!,
          _routeInventoryLoadIdMeta,
        ),
      );
    }
    if (data.containsKey('route_id')) {
      context.handle(
        _routeIdMeta,
        routeId.isAcceptableOrUnknown(data['route_id']!, _routeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_routeIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('loaded_at')) {
      context.handle(
        _loadedAtMeta,
        loadedAt.isAcceptableOrUnknown(data['loaded_at']!, _loadedAtMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {routeInventoryLoadId};
  @override
  RouteInventoryLoadTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RouteInventoryLoadTableData(
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastModifiedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified_date'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      routeInventoryLoadId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route_inventory_load_id'],
      )!,
      routeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      loadedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}loaded_at'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
    );
  }

  @override
  $RouteInventoryLoadTableTable createAlias(String alias) {
    return $RouteInventoryLoadTableTable(attachedDatabase, alias);
  }
}

class RouteInventoryLoadTableData extends DataClass
    implements Insertable<RouteInventoryLoadTableData> {
  final DateTime createdAt;
  final DateTime lastModifiedDate;
  final bool enabled;
  final int? serverId;
  final String routeInventoryLoadId;
  final String routeId;
  final String productId;
  final int quantity;
  final DateTime loadedAt;
  final String? createdBy;
  const RouteInventoryLoadTableData({
    required this.createdAt,
    required this.lastModifiedDate,
    required this.enabled,
    this.serverId,
    required this.routeInventoryLoadId,
    required this.routeId,
    required this.productId,
    required this.quantity,
    required this.loadedAt,
    this.createdBy,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_modified_date'] = Variable<DateTime>(lastModifiedDate);
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['route_inventory_load_id'] = Variable<String>(routeInventoryLoadId);
    map['route_id'] = Variable<String>(routeId);
    map['product_id'] = Variable<String>(productId);
    map['quantity'] = Variable<int>(quantity);
    map['loaded_at'] = Variable<DateTime>(loadedAt);
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    return map;
  }

  RouteInventoryLoadTableCompanion toCompanion(bool nullToAbsent) {
    return RouteInventoryLoadTableCompanion(
      createdAt: Value(createdAt),
      lastModifiedDate: Value(lastModifiedDate),
      enabled: Value(enabled),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      routeInventoryLoadId: Value(routeInventoryLoadId),
      routeId: Value(routeId),
      productId: Value(productId),
      quantity: Value(quantity),
      loadedAt: Value(loadedAt),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
    );
  }

  factory RouteInventoryLoadTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RouteInventoryLoadTableData(
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastModifiedDate: serializer.fromJson<DateTime>(json['lastModifiedDate']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      routeInventoryLoadId: serializer.fromJson<String>(
        json['routeInventoryLoadId'],
      ),
      routeId: serializer.fromJson<String>(json['routeId']),
      productId: serializer.fromJson<String>(json['productId']),
      quantity: serializer.fromJson<int>(json['quantity']),
      loadedAt: serializer.fromJson<DateTime>(json['loadedAt']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastModifiedDate': serializer.toJson<DateTime>(lastModifiedDate),
      'enabled': serializer.toJson<bool>(enabled),
      'serverId': serializer.toJson<int?>(serverId),
      'routeInventoryLoadId': serializer.toJson<String>(routeInventoryLoadId),
      'routeId': serializer.toJson<String>(routeId),
      'productId': serializer.toJson<String>(productId),
      'quantity': serializer.toJson<int>(quantity),
      'loadedAt': serializer.toJson<DateTime>(loadedAt),
      'createdBy': serializer.toJson<String?>(createdBy),
    };
  }

  RouteInventoryLoadTableData copyWith({
    DateTime? createdAt,
    DateTime? lastModifiedDate,
    bool? enabled,
    Value<int?> serverId = const Value.absent(),
    String? routeInventoryLoadId,
    String? routeId,
    String? productId,
    int? quantity,
    DateTime? loadedAt,
    Value<String?> createdBy = const Value.absent(),
  }) => RouteInventoryLoadTableData(
    createdAt: createdAt ?? this.createdAt,
    lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
    enabled: enabled ?? this.enabled,
    serverId: serverId.present ? serverId.value : this.serverId,
    routeInventoryLoadId: routeInventoryLoadId ?? this.routeInventoryLoadId,
    routeId: routeId ?? this.routeId,
    productId: productId ?? this.productId,
    quantity: quantity ?? this.quantity,
    loadedAt: loadedAt ?? this.loadedAt,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
  );
  RouteInventoryLoadTableData copyWithCompanion(
    RouteInventoryLoadTableCompanion data,
  ) {
    return RouteInventoryLoadTableData(
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastModifiedDate: data.lastModifiedDate.present
          ? data.lastModifiedDate.value
          : this.lastModifiedDate,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      routeInventoryLoadId: data.routeInventoryLoadId.present
          ? data.routeInventoryLoadId.value
          : this.routeInventoryLoadId,
      routeId: data.routeId.present ? data.routeId.value : this.routeId,
      productId: data.productId.present ? data.productId.value : this.productId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      loadedAt: data.loadedAt.present ? data.loadedAt.value : this.loadedAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RouteInventoryLoadTableData(')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedDate: $lastModifiedDate, ')
          ..write('enabled: $enabled, ')
          ..write('serverId: $serverId, ')
          ..write('routeInventoryLoadId: $routeInventoryLoadId, ')
          ..write('routeId: $routeId, ')
          ..write('productId: $productId, ')
          ..write('quantity: $quantity, ')
          ..write('loadedAt: $loadedAt, ')
          ..write('createdBy: $createdBy')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    createdAt,
    lastModifiedDate,
    enabled,
    serverId,
    routeInventoryLoadId,
    routeId,
    productId,
    quantity,
    loadedAt,
    createdBy,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RouteInventoryLoadTableData &&
          other.createdAt == this.createdAt &&
          other.lastModifiedDate == this.lastModifiedDate &&
          other.enabled == this.enabled &&
          other.serverId == this.serverId &&
          other.routeInventoryLoadId == this.routeInventoryLoadId &&
          other.routeId == this.routeId &&
          other.productId == this.productId &&
          other.quantity == this.quantity &&
          other.loadedAt == this.loadedAt &&
          other.createdBy == this.createdBy);
}

class RouteInventoryLoadTableCompanion
    extends UpdateCompanion<RouteInventoryLoadTableData> {
  final Value<DateTime> createdAt;
  final Value<DateTime> lastModifiedDate;
  final Value<bool> enabled;
  final Value<int?> serverId;
  final Value<String> routeInventoryLoadId;
  final Value<String> routeId;
  final Value<String> productId;
  final Value<int> quantity;
  final Value<DateTime> loadedAt;
  final Value<String?> createdBy;
  final Value<int> rowid;
  const RouteInventoryLoadTableCompanion({
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.serverId = const Value.absent(),
    this.routeInventoryLoadId = const Value.absent(),
    this.routeId = const Value.absent(),
    this.productId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.loadedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RouteInventoryLoadTableCompanion.insert({
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.serverId = const Value.absent(),
    this.routeInventoryLoadId = const Value.absent(),
    required String routeId,
    required String productId,
    required int quantity,
    this.loadedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : routeId = Value(routeId),
       productId = Value(productId),
       quantity = Value(quantity);
  static Insertable<RouteInventoryLoadTableData> custom({
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastModifiedDate,
    Expression<bool>? enabled,
    Expression<int>? serverId,
    Expression<String>? routeInventoryLoadId,
    Expression<String>? routeId,
    Expression<String>? productId,
    Expression<int>? quantity,
    Expression<DateTime>? loadedAt,
    Expression<String>? createdBy,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (lastModifiedDate != null) 'last_modified_date': lastModifiedDate,
      if (enabled != null) 'enabled': enabled,
      if (serverId != null) 'server_id': serverId,
      if (routeInventoryLoadId != null)
        'route_inventory_load_id': routeInventoryLoadId,
      if (routeId != null) 'route_id': routeId,
      if (productId != null) 'product_id': productId,
      if (quantity != null) 'quantity': quantity,
      if (loadedAt != null) 'loaded_at': loadedAt,
      if (createdBy != null) 'created_by': createdBy,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RouteInventoryLoadTableCompanion copyWith({
    Value<DateTime>? createdAt,
    Value<DateTime>? lastModifiedDate,
    Value<bool>? enabled,
    Value<int?>? serverId,
    Value<String>? routeInventoryLoadId,
    Value<String>? routeId,
    Value<String>? productId,
    Value<int>? quantity,
    Value<DateTime>? loadedAt,
    Value<String?>? createdBy,
    Value<int>? rowid,
  }) {
    return RouteInventoryLoadTableCompanion(
      createdAt: createdAt ?? this.createdAt,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      enabled: enabled ?? this.enabled,
      serverId: serverId ?? this.serverId,
      routeInventoryLoadId: routeInventoryLoadId ?? this.routeInventoryLoadId,
      routeId: routeId ?? this.routeId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      loadedAt: loadedAt ?? this.loadedAt,
      createdBy: createdBy ?? this.createdBy,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastModifiedDate.present) {
      map['last_modified_date'] = Variable<DateTime>(lastModifiedDate.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (routeInventoryLoadId.present) {
      map['route_inventory_load_id'] = Variable<String>(
        routeInventoryLoadId.value,
      );
    }
    if (routeId.present) {
      map['route_id'] = Variable<String>(routeId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (loadedAt.present) {
      map['loaded_at'] = Variable<DateTime>(loadedAt.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RouteInventoryLoadTableCompanion(')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedDate: $lastModifiedDate, ')
          ..write('enabled: $enabled, ')
          ..write('serverId: $serverId, ')
          ..write('routeInventoryLoadId: $routeInventoryLoadId, ')
          ..write('routeId: $routeId, ')
          ..write('productId: $productId, ')
          ..write('quantity: $quantity, ')
          ..write('loadedAt: $loadedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingChangeTableTable extends PendingChangeTable
    with TableInfo<$PendingChangeTableTable, PendingChangeTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingChangeTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pendingChangeIdMeta = const VerificationMeta(
    'pendingChangeId',
  );
  @override
  late final GeneratedColumn<int> pendingChangeId = GeneratedColumn<int>(
    'pending_change_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _rejectionReasonMeta = const VerificationMeta(
    'rejectionReason',
  );
  @override
  late final GeneratedColumn<String> rejectionReason = GeneratedColumn<String>(
    'rejection_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastModifiedDateMeta = const VerificationMeta(
    'lastModifiedDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastModifiedDate =
      GeneratedColumn<DateTime>(
        'last_modified_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  @override
  List<GeneratedColumn> get $columns => [
    pendingChangeId,
    entity,
    entityId,
    action,
    payload,
    status,
    rejectionReason,
    createdAt,
    lastModifiedDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_changes';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingChangeTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('pending_change_id')) {
      context.handle(
        _pendingChangeIdMeta,
        pendingChangeId.isAcceptableOrUnknown(
          data['pending_change_id']!,
          _pendingChangeIdMeta,
        ),
      );
    }
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('rejection_reason')) {
      context.handle(
        _rejectionReasonMeta,
        rejectionReason.isAcceptableOrUnknown(
          data['rejection_reason']!,
          _rejectionReasonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('last_modified_date')) {
      context.handle(
        _lastModifiedDateMeta,
        lastModifiedDate.isAcceptableOrUnknown(
          data['last_modified_date']!,
          _lastModifiedDateMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {pendingChangeId};
  @override
  PendingChangeTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingChangeTableData(
      pendingChangeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pending_change_id'],
      )!,
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      rejectionReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rejection_reason'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastModifiedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified_date'],
      )!,
    );
  }

  @override
  $PendingChangeTableTable createAlias(String alias) {
    return $PendingChangeTableTable(attachedDatabase, alias);
  }
}

class PendingChangeTableData extends DataClass
    implements Insertable<PendingChangeTableData> {
  final int pendingChangeId;
  final String entity;
  final String entityId;
  final String action;
  final String? payload;
  final String status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime lastModifiedDate;
  const PendingChangeTableData({
    required this.pendingChangeId,
    required this.entity,
    required this.entityId,
    required this.action,
    this.payload,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    required this.lastModifiedDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['pending_change_id'] = Variable<int>(pendingChangeId);
    map['entity'] = Variable<String>(entity);
    map['entity_id'] = Variable<String>(entityId);
    map['action'] = Variable<String>(action);
    if (!nullToAbsent || payload != null) {
      map['payload'] = Variable<String>(payload);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || rejectionReason != null) {
      map['rejection_reason'] = Variable<String>(rejectionReason);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_modified_date'] = Variable<DateTime>(lastModifiedDate);
    return map;
  }

  PendingChangeTableCompanion toCompanion(bool nullToAbsent) {
    return PendingChangeTableCompanion(
      pendingChangeId: Value(pendingChangeId),
      entity: Value(entity),
      entityId: Value(entityId),
      action: Value(action),
      payload: payload == null && nullToAbsent
          ? const Value.absent()
          : Value(payload),
      status: Value(status),
      rejectionReason: rejectionReason == null && nullToAbsent
          ? const Value.absent()
          : Value(rejectionReason),
      createdAt: Value(createdAt),
      lastModifiedDate: Value(lastModifiedDate),
    );
  }

  factory PendingChangeTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingChangeTableData(
      pendingChangeId: serializer.fromJson<int>(json['pendingChangeId']),
      entity: serializer.fromJson<String>(json['entity']),
      entityId: serializer.fromJson<String>(json['entityId']),
      action: serializer.fromJson<String>(json['action']),
      payload: serializer.fromJson<String?>(json['payload']),
      status: serializer.fromJson<String>(json['status']),
      rejectionReason: serializer.fromJson<String?>(json['rejectionReason']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastModifiedDate: serializer.fromJson<DateTime>(json['lastModifiedDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'pendingChangeId': serializer.toJson<int>(pendingChangeId),
      'entity': serializer.toJson<String>(entity),
      'entityId': serializer.toJson<String>(entityId),
      'action': serializer.toJson<String>(action),
      'payload': serializer.toJson<String?>(payload),
      'status': serializer.toJson<String>(status),
      'rejectionReason': serializer.toJson<String?>(rejectionReason),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastModifiedDate': serializer.toJson<DateTime>(lastModifiedDate),
    };
  }

  PendingChangeTableData copyWith({
    int? pendingChangeId,
    String? entity,
    String? entityId,
    String? action,
    Value<String?> payload = const Value.absent(),
    String? status,
    Value<String?> rejectionReason = const Value.absent(),
    DateTime? createdAt,
    DateTime? lastModifiedDate,
  }) => PendingChangeTableData(
    pendingChangeId: pendingChangeId ?? this.pendingChangeId,
    entity: entity ?? this.entity,
    entityId: entityId ?? this.entityId,
    action: action ?? this.action,
    payload: payload.present ? payload.value : this.payload,
    status: status ?? this.status,
    rejectionReason: rejectionReason.present
        ? rejectionReason.value
        : this.rejectionReason,
    createdAt: createdAt ?? this.createdAt,
    lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
  );
  PendingChangeTableData copyWithCompanion(PendingChangeTableCompanion data) {
    return PendingChangeTableData(
      pendingChangeId: data.pendingChangeId.present
          ? data.pendingChangeId.value
          : this.pendingChangeId,
      entity: data.entity.present ? data.entity.value : this.entity,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      action: data.action.present ? data.action.value : this.action,
      payload: data.payload.present ? data.payload.value : this.payload,
      status: data.status.present ? data.status.value : this.status,
      rejectionReason: data.rejectionReason.present
          ? data.rejectionReason.value
          : this.rejectionReason,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastModifiedDate: data.lastModifiedDate.present
          ? data.lastModifiedDate.value
          : this.lastModifiedDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingChangeTableData(')
          ..write('pendingChangeId: $pendingChangeId, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('action: $action, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('rejectionReason: $rejectionReason, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedDate: $lastModifiedDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    pendingChangeId,
    entity,
    entityId,
    action,
    payload,
    status,
    rejectionReason,
    createdAt,
    lastModifiedDate,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingChangeTableData &&
          other.pendingChangeId == this.pendingChangeId &&
          other.entity == this.entity &&
          other.entityId == this.entityId &&
          other.action == this.action &&
          other.payload == this.payload &&
          other.status == this.status &&
          other.rejectionReason == this.rejectionReason &&
          other.createdAt == this.createdAt &&
          other.lastModifiedDate == this.lastModifiedDate);
}

class PendingChangeTableCompanion
    extends UpdateCompanion<PendingChangeTableData> {
  final Value<int> pendingChangeId;
  final Value<String> entity;
  final Value<String> entityId;
  final Value<String> action;
  final Value<String?> payload;
  final Value<String> status;
  final Value<String?> rejectionReason;
  final Value<DateTime> createdAt;
  final Value<DateTime> lastModifiedDate;
  const PendingChangeTableCompanion({
    this.pendingChangeId = const Value.absent(),
    this.entity = const Value.absent(),
    this.entityId = const Value.absent(),
    this.action = const Value.absent(),
    this.payload = const Value.absent(),
    this.status = const Value.absent(),
    this.rejectionReason = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
  });
  PendingChangeTableCompanion.insert({
    this.pendingChangeId = const Value.absent(),
    required String entity,
    required String entityId,
    required String action,
    this.payload = const Value.absent(),
    this.status = const Value.absent(),
    this.rejectionReason = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
  }) : entity = Value(entity),
       entityId = Value(entityId),
       action = Value(action);
  static Insertable<PendingChangeTableData> custom({
    Expression<int>? pendingChangeId,
    Expression<String>? entity,
    Expression<String>? entityId,
    Expression<String>? action,
    Expression<String>? payload,
    Expression<String>? status,
    Expression<String>? rejectionReason,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastModifiedDate,
  }) {
    return RawValuesInsertable({
      if (pendingChangeId != null) 'pending_change_id': pendingChangeId,
      if (entity != null) 'entity': entity,
      if (entityId != null) 'entity_id': entityId,
      if (action != null) 'action': action,
      if (payload != null) 'payload': payload,
      if (status != null) 'status': status,
      if (rejectionReason != null) 'rejection_reason': rejectionReason,
      if (createdAt != null) 'created_at': createdAt,
      if (lastModifiedDate != null) 'last_modified_date': lastModifiedDate,
    });
  }

  PendingChangeTableCompanion copyWith({
    Value<int>? pendingChangeId,
    Value<String>? entity,
    Value<String>? entityId,
    Value<String>? action,
    Value<String?>? payload,
    Value<String>? status,
    Value<String?>? rejectionReason,
    Value<DateTime>? createdAt,
    Value<DateTime>? lastModifiedDate,
  }) {
    return PendingChangeTableCompanion(
      pendingChangeId: pendingChangeId ?? this.pendingChangeId,
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      action: action ?? this.action,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (pendingChangeId.present) {
      map['pending_change_id'] = Variable<int>(pendingChangeId.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rejectionReason.present) {
      map['rejection_reason'] = Variable<String>(rejectionReason.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastModifiedDate.present) {
      map['last_modified_date'] = Variable<DateTime>(lastModifiedDate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingChangeTableCompanion(')
          ..write('pendingChangeId: $pendingChangeId, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('action: $action, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('rejectionReason: $rejectionReason, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedDate: $lastModifiedDate')
          ..write(')'))
        .toString();
  }
}

class $ContainerTypeTableTable extends ContainerTypeTable
    with TableInfo<$ContainerTypeTableTable, ContainerTypeTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContainerTypeTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [id, code, description, enabled];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'container_types';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContainerTypeTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ContainerTypeTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContainerTypeTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
    );
  }

  @override
  $ContainerTypeTableTable createAlias(String alias) {
    return $ContainerTypeTableTable(attachedDatabase, alias);
  }
}

class ContainerTypeTableData extends DataClass
    implements Insertable<ContainerTypeTableData> {
  final int id;
  final String code;
  final String? description;
  final bool enabled;
  const ContainerTypeTableData({
    required this.id,
    required this.code,
    this.description,
    required this.enabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['code'] = Variable<String>(code);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['enabled'] = Variable<bool>(enabled);
    return map;
  }

  ContainerTypeTableCompanion toCompanion(bool nullToAbsent) {
    return ContainerTypeTableCompanion(
      id: Value(id),
      code: Value(code),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      enabled: Value(enabled),
    );
  }

  factory ContainerTypeTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContainerTypeTableData(
      id: serializer.fromJson<int>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      description: serializer.fromJson<String?>(json['description']),
      enabled: serializer.fromJson<bool>(json['enabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'code': serializer.toJson<String>(code),
      'description': serializer.toJson<String?>(description),
      'enabled': serializer.toJson<bool>(enabled),
    };
  }

  ContainerTypeTableData copyWith({
    int? id,
    String? code,
    Value<String?> description = const Value.absent(),
    bool? enabled,
  }) => ContainerTypeTableData(
    id: id ?? this.id,
    code: code ?? this.code,
    description: description.present ? description.value : this.description,
    enabled: enabled ?? this.enabled,
  );
  ContainerTypeTableData copyWithCompanion(ContainerTypeTableCompanion data) {
    return ContainerTypeTableData(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      description: data.description.present
          ? data.description.value
          : this.description,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContainerTypeTableData(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('description: $description, ')
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, code, description, enabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContainerTypeTableData &&
          other.id == this.id &&
          other.code == this.code &&
          other.description == this.description &&
          other.enabled == this.enabled);
}

class ContainerTypeTableCompanion
    extends UpdateCompanion<ContainerTypeTableData> {
  final Value<int> id;
  final Value<String> code;
  final Value<String?> description;
  final Value<bool> enabled;
  const ContainerTypeTableCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.description = const Value.absent(),
    this.enabled = const Value.absent(),
  });
  ContainerTypeTableCompanion.insert({
    this.id = const Value.absent(),
    required String code,
    this.description = const Value.absent(),
    this.enabled = const Value.absent(),
  }) : code = Value(code);
  static Insertable<ContainerTypeTableData> custom({
    Expression<int>? id,
    Expression<String>? code,
    Expression<String>? description,
    Expression<bool>? enabled,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (description != null) 'description': description,
      if (enabled != null) 'enabled': enabled,
    });
  }

  ContainerTypeTableCompanion copyWith({
    Value<int>? id,
    Value<String>? code,
    Value<String?>? description,
    Value<bool>? enabled,
  }) {
    return ContainerTypeTableCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      description: description ?? this.description,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContainerTypeTableCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('description: $description, ')
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }
}

class $PaymentMethodTableTable extends PaymentMethodTable
    with TableInfo<$PaymentMethodTableTable, PaymentMethodTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentMethodTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [id, code, name, enabled];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payment_methods';
  @override
  VerificationContext validateIntegrity(
    Insertable<PaymentMethodTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PaymentMethodTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PaymentMethodTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
    );
  }

  @override
  $PaymentMethodTableTable createAlias(String alias) {
    return $PaymentMethodTableTable(attachedDatabase, alias);
  }
}

class PaymentMethodTableData extends DataClass
    implements Insertable<PaymentMethodTableData> {
  final int id;
  final String code;
  final String name;
  final bool enabled;
  const PaymentMethodTableData({
    required this.id,
    required this.code,
    required this.name,
    required this.enabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    map['enabled'] = Variable<bool>(enabled);
    return map;
  }

  PaymentMethodTableCompanion toCompanion(bool nullToAbsent) {
    return PaymentMethodTableCompanion(
      id: Value(id),
      code: Value(code),
      name: Value(name),
      enabled: Value(enabled),
    );
  }

  factory PaymentMethodTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PaymentMethodTableData(
      id: serializer.fromJson<int>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      enabled: serializer.fromJson<bool>(json['enabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'enabled': serializer.toJson<bool>(enabled),
    };
  }

  PaymentMethodTableData copyWith({
    int? id,
    String? code,
    String? name,
    bool? enabled,
  }) => PaymentMethodTableData(
    id: id ?? this.id,
    code: code ?? this.code,
    name: name ?? this.name,
    enabled: enabled ?? this.enabled,
  );
  PaymentMethodTableData copyWithCompanion(PaymentMethodTableCompanion data) {
    return PaymentMethodTableData(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PaymentMethodTableData(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, code, name, enabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaymentMethodTableData &&
          other.id == this.id &&
          other.code == this.code &&
          other.name == this.name &&
          other.enabled == this.enabled);
}

class PaymentMethodTableCompanion
    extends UpdateCompanion<PaymentMethodTableData> {
  final Value<int> id;
  final Value<String> code;
  final Value<String> name;
  final Value<bool> enabled;
  const PaymentMethodTableCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.enabled = const Value.absent(),
  });
  PaymentMethodTableCompanion.insert({
    this.id = const Value.absent(),
    required String code,
    required String name,
    this.enabled = const Value.absent(),
  }) : code = Value(code),
       name = Value(name);
  static Insertable<PaymentMethodTableData> custom({
    Expression<int>? id,
    Expression<String>? code,
    Expression<String>? name,
    Expression<bool>? enabled,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (enabled != null) 'enabled': enabled,
    });
  }

  PaymentMethodTableCompanion copyWith({
    Value<int>? id,
    Value<String>? code,
    Value<String>? name,
    Value<bool>? enabled,
  }) {
    return PaymentMethodTableCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentMethodTableCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }
}

class $CustomerAgreementTableTable extends CustomerAgreementTable
    with TableInfo<$CustomerAgreementTableTable, CustomerAgreementTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomerAgreementTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastModifiedDateMeta = const VerificationMeta(
    'lastModifiedDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastModifiedDate =
      GeneratedColumn<DateTime>(
        'last_modified_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _agreementIdMeta = const VerificationMeta(
    'agreementId',
  );
  @override
  late final GeneratedColumn<String> agreementId = GeneratedColumn<String>(
    'agreement_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => uuid.v4(),
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES customers (customer_id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (product_id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<double> unitPrice = GeneratedColumn<double>(
    'unit_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _validFromMeta = const VerificationMeta(
    'validFrom',
  );
  @override
  late final GeneratedColumn<String> validFrom = GeneratedColumn<String>(
    'valid_from',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _validToMeta = const VerificationMeta(
    'validTo',
  );
  @override
  late final GeneratedColumn<String> validTo = GeneratedColumn<String>(
    'valid_to',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    createdAt,
    lastModifiedDate,
    enabled,
    serverId,
    agreementId,
    customerId,
    productId,
    unitPrice,
    validFrom,
    validTo,
    reason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customer_agreements';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomerAgreementTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('last_modified_date')) {
      context.handle(
        _lastModifiedDateMeta,
        lastModifiedDate.isAcceptableOrUnknown(
          data['last_modified_date']!,
          _lastModifiedDateMeta,
        ),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('agreement_id')) {
      context.handle(
        _agreementIdMeta,
        agreementId.isAcceptableOrUnknown(
          data['agreement_id']!,
          _agreementIdMeta,
        ),
      );
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_unitPriceMeta);
    }
    if (data.containsKey('valid_from')) {
      context.handle(
        _validFromMeta,
        validFrom.isAcceptableOrUnknown(data['valid_from']!, _validFromMeta),
      );
    } else if (isInserting) {
      context.missing(_validFromMeta);
    }
    if (data.containsKey('valid_to')) {
      context.handle(
        _validToMeta,
        validTo.isAcceptableOrUnknown(data['valid_to']!, _validToMeta),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {agreementId};
  @override
  CustomerAgreementTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomerAgreementTableData(
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastModifiedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified_date'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      agreementId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agreement_id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      unitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_price'],
      )!,
      validFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valid_from'],
      )!,
      validTo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valid_to'],
      ),
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      ),
    );
  }

  @override
  $CustomerAgreementTableTable createAlias(String alias) {
    return $CustomerAgreementTableTable(attachedDatabase, alias);
  }
}

class CustomerAgreementTableData extends DataClass
    implements Insertable<CustomerAgreementTableData> {
  final DateTime createdAt;
  final DateTime lastModifiedDate;
  final bool enabled;
  final int? serverId;
  final String agreementId;
  final String customerId;
  final String productId;
  final double unitPrice;
  final String validFrom;
  final String? validTo;
  final String? reason;
  const CustomerAgreementTableData({
    required this.createdAt,
    required this.lastModifiedDate,
    required this.enabled,
    this.serverId,
    required this.agreementId,
    required this.customerId,
    required this.productId,
    required this.unitPrice,
    required this.validFrom,
    this.validTo,
    this.reason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_modified_date'] = Variable<DateTime>(lastModifiedDate);
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['agreement_id'] = Variable<String>(agreementId);
    map['customer_id'] = Variable<String>(customerId);
    map['product_id'] = Variable<String>(productId);
    map['unit_price'] = Variable<double>(unitPrice);
    map['valid_from'] = Variable<String>(validFrom);
    if (!nullToAbsent || validTo != null) {
      map['valid_to'] = Variable<String>(validTo);
    }
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    return map;
  }

  CustomerAgreementTableCompanion toCompanion(bool nullToAbsent) {
    return CustomerAgreementTableCompanion(
      createdAt: Value(createdAt),
      lastModifiedDate: Value(lastModifiedDate),
      enabled: Value(enabled),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      agreementId: Value(agreementId),
      customerId: Value(customerId),
      productId: Value(productId),
      unitPrice: Value(unitPrice),
      validFrom: Value(validFrom),
      validTo: validTo == null && nullToAbsent
          ? const Value.absent()
          : Value(validTo),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
    );
  }

  factory CustomerAgreementTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomerAgreementTableData(
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastModifiedDate: serializer.fromJson<DateTime>(json['lastModifiedDate']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      agreementId: serializer.fromJson<String>(json['agreementId']),
      customerId: serializer.fromJson<String>(json['customerId']),
      productId: serializer.fromJson<String>(json['productId']),
      unitPrice: serializer.fromJson<double>(json['unitPrice']),
      validFrom: serializer.fromJson<String>(json['validFrom']),
      validTo: serializer.fromJson<String?>(json['validTo']),
      reason: serializer.fromJson<String?>(json['reason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastModifiedDate': serializer.toJson<DateTime>(lastModifiedDate),
      'enabled': serializer.toJson<bool>(enabled),
      'serverId': serializer.toJson<int?>(serverId),
      'agreementId': serializer.toJson<String>(agreementId),
      'customerId': serializer.toJson<String>(customerId),
      'productId': serializer.toJson<String>(productId),
      'unitPrice': serializer.toJson<double>(unitPrice),
      'validFrom': serializer.toJson<String>(validFrom),
      'validTo': serializer.toJson<String?>(validTo),
      'reason': serializer.toJson<String?>(reason),
    };
  }

  CustomerAgreementTableData copyWith({
    DateTime? createdAt,
    DateTime? lastModifiedDate,
    bool? enabled,
    Value<int?> serverId = const Value.absent(),
    String? agreementId,
    String? customerId,
    String? productId,
    double? unitPrice,
    String? validFrom,
    Value<String?> validTo = const Value.absent(),
    Value<String?> reason = const Value.absent(),
  }) => CustomerAgreementTableData(
    createdAt: createdAt ?? this.createdAt,
    lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
    enabled: enabled ?? this.enabled,
    serverId: serverId.present ? serverId.value : this.serverId,
    agreementId: agreementId ?? this.agreementId,
    customerId: customerId ?? this.customerId,
    productId: productId ?? this.productId,
    unitPrice: unitPrice ?? this.unitPrice,
    validFrom: validFrom ?? this.validFrom,
    validTo: validTo.present ? validTo.value : this.validTo,
    reason: reason.present ? reason.value : this.reason,
  );
  CustomerAgreementTableData copyWithCompanion(
    CustomerAgreementTableCompanion data,
  ) {
    return CustomerAgreementTableData(
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastModifiedDate: data.lastModifiedDate.present
          ? data.lastModifiedDate.value
          : this.lastModifiedDate,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      agreementId: data.agreementId.present
          ? data.agreementId.value
          : this.agreementId,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      productId: data.productId.present ? data.productId.value : this.productId,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      validFrom: data.validFrom.present ? data.validFrom.value : this.validFrom,
      validTo: data.validTo.present ? data.validTo.value : this.validTo,
      reason: data.reason.present ? data.reason.value : this.reason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomerAgreementTableData(')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedDate: $lastModifiedDate, ')
          ..write('enabled: $enabled, ')
          ..write('serverId: $serverId, ')
          ..write('agreementId: $agreementId, ')
          ..write('customerId: $customerId, ')
          ..write('productId: $productId, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('validFrom: $validFrom, ')
          ..write('validTo: $validTo, ')
          ..write('reason: $reason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    createdAt,
    lastModifiedDate,
    enabled,
    serverId,
    agreementId,
    customerId,
    productId,
    unitPrice,
    validFrom,
    validTo,
    reason,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerAgreementTableData &&
          other.createdAt == this.createdAt &&
          other.lastModifiedDate == this.lastModifiedDate &&
          other.enabled == this.enabled &&
          other.serverId == this.serverId &&
          other.agreementId == this.agreementId &&
          other.customerId == this.customerId &&
          other.productId == this.productId &&
          other.unitPrice == this.unitPrice &&
          other.validFrom == this.validFrom &&
          other.validTo == this.validTo &&
          other.reason == this.reason);
}

class CustomerAgreementTableCompanion
    extends UpdateCompanion<CustomerAgreementTableData> {
  final Value<DateTime> createdAt;
  final Value<DateTime> lastModifiedDate;
  final Value<bool> enabled;
  final Value<int?> serverId;
  final Value<String> agreementId;
  final Value<String> customerId;
  final Value<String> productId;
  final Value<double> unitPrice;
  final Value<String> validFrom;
  final Value<String?> validTo;
  final Value<String?> reason;
  final Value<int> rowid;
  const CustomerAgreementTableCompanion({
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.serverId = const Value.absent(),
    this.agreementId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.productId = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.validFrom = const Value.absent(),
    this.validTo = const Value.absent(),
    this.reason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomerAgreementTableCompanion.insert({
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.serverId = const Value.absent(),
    this.agreementId = const Value.absent(),
    required String customerId,
    required String productId,
    required double unitPrice,
    required String validFrom,
    this.validTo = const Value.absent(),
    this.reason = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : customerId = Value(customerId),
       productId = Value(productId),
       unitPrice = Value(unitPrice),
       validFrom = Value(validFrom);
  static Insertable<CustomerAgreementTableData> custom({
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastModifiedDate,
    Expression<bool>? enabled,
    Expression<int>? serverId,
    Expression<String>? agreementId,
    Expression<String>? customerId,
    Expression<String>? productId,
    Expression<double>? unitPrice,
    Expression<String>? validFrom,
    Expression<String>? validTo,
    Expression<String>? reason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (lastModifiedDate != null) 'last_modified_date': lastModifiedDate,
      if (enabled != null) 'enabled': enabled,
      if (serverId != null) 'server_id': serverId,
      if (agreementId != null) 'agreement_id': agreementId,
      if (customerId != null) 'customer_id': customerId,
      if (productId != null) 'product_id': productId,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (validFrom != null) 'valid_from': validFrom,
      if (validTo != null) 'valid_to': validTo,
      if (reason != null) 'reason': reason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomerAgreementTableCompanion copyWith({
    Value<DateTime>? createdAt,
    Value<DateTime>? lastModifiedDate,
    Value<bool>? enabled,
    Value<int?>? serverId,
    Value<String>? agreementId,
    Value<String>? customerId,
    Value<String>? productId,
    Value<double>? unitPrice,
    Value<String>? validFrom,
    Value<String?>? validTo,
    Value<String?>? reason,
    Value<int>? rowid,
  }) {
    return CustomerAgreementTableCompanion(
      createdAt: createdAt ?? this.createdAt,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      enabled: enabled ?? this.enabled,
      serverId: serverId ?? this.serverId,
      agreementId: agreementId ?? this.agreementId,
      customerId: customerId ?? this.customerId,
      productId: productId ?? this.productId,
      unitPrice: unitPrice ?? this.unitPrice,
      validFrom: validFrom ?? this.validFrom,
      validTo: validTo ?? this.validTo,
      reason: reason ?? this.reason,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastModifiedDate.present) {
      map['last_modified_date'] = Variable<DateTime>(lastModifiedDate.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (agreementId.present) {
      map['agreement_id'] = Variable<String>(agreementId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<double>(unitPrice.value);
    }
    if (validFrom.present) {
      map['valid_from'] = Variable<String>(validFrom.value);
    }
    if (validTo.present) {
      map['valid_to'] = Variable<String>(validTo.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomerAgreementTableCompanion(')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedDate: $lastModifiedDate, ')
          ..write('enabled: $enabled, ')
          ..write('serverId: $serverId, ')
          ..write('agreementId: $agreementId, ')
          ..write('customerId: $customerId, ')
          ..write('productId: $productId, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('validFrom: $validFrom, ')
          ..write('validTo: $validTo, ')
          ..write('reason: $reason, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTableTable extends SyncStateTable
    with TableInfo<$SyncStateTableTable, SyncStateTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncStateTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateTableData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SyncStateTableTable createAlias(String alias) {
    return $SyncStateTableTable(attachedDatabase, alias);
  }
}

class SyncStateTableData extends DataClass
    implements Insertable<SyncStateTableData> {
  final String key;
  final String value;
  const SyncStateTableData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SyncStateTableCompanion toCompanion(bool nullToAbsent) {
    return SyncStateTableCompanion(key: Value(key), value: Value(value));
  }

  factory SyncStateTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateTableData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SyncStateTableData copyWith({String? key, String? value}) =>
      SyncStateTableData(key: key ?? this.key, value: value ?? this.value);
  SyncStateTableData copyWithCompanion(SyncStateTableCompanion data) {
    return SyncStateTableData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateTableData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateTableData &&
          other.key == this.key &&
          other.value == this.value);
}

class SyncStateTableCompanion extends UpdateCompanion<SyncStateTableData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SyncStateTableCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateTableCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SyncStateTableData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateTableCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SyncStateTableCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateTableCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CustomerTableTable customerTable = $CustomerTableTable(this);
  late final $CustomerAddressTableTable customerAddressTable =
      $CustomerAddressTableTable(this);
  late final $CustomerPreferenceTableTable customerPreferenceTable =
      $CustomerPreferenceTableTable(this);
  late final $RouteTableTable routeTable = $RouteTableTable(this);
  late final $RouteStopTableTable routeStopTable = $RouteStopTableTable(this);
  late final $ProductTableTable productTable = $ProductTableTable(this);
  late final $RouteInventoryTableTable routeInventoryTable =
      $RouteInventoryTableTable(this);
  late final $VisitOutcomeTableTable visitOutcomeTable =
      $VisitOutcomeTableTable(this);
  late final $VisitTableTable visitTable = $VisitTableTable(this);
  late final $SaleTableTable saleTable = $SaleTableTable(this);
  late final $SaleItemTableTable saleItemTable = $SaleItemTableTable(this);
  late final $PaymentTableTable paymentTable = $PaymentTableTable(this);
  late final $CustomerAccountEntryTableTable customerAccountEntryTable =
      $CustomerAccountEntryTableTable(this);
  late final $CustomerBalanceTableTable customerBalanceTable =
      $CustomerBalanceTableTable(this);
  late final $ContainerMovementTableTable containerMovementTable =
      $ContainerMovementTableTable(this);
  late final $CustomerContainerBalanceTableTable customerContainerBalanceTable =
      $CustomerContainerBalanceTableTable(this);
  late final $RouteInventoryLoadTableTable routeInventoryLoadTable =
      $RouteInventoryLoadTableTable(this);
  late final $PendingChangeTableTable pendingChangeTable =
      $PendingChangeTableTable(this);
  late final $ContainerTypeTableTable containerTypeTable =
      $ContainerTypeTableTable(this);
  late final $PaymentMethodTableTable paymentMethodTable =
      $PaymentMethodTableTable(this);
  late final $CustomerAgreementTableTable customerAgreementTable =
      $CustomerAgreementTableTable(this);
  late final $SyncStateTableTable syncStateTable = $SyncStateTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    customerTable,
    customerAddressTable,
    customerPreferenceTable,
    routeTable,
    routeStopTable,
    productTable,
    routeInventoryTable,
    visitOutcomeTable,
    visitTable,
    saleTable,
    saleItemTable,
    paymentTable,
    customerAccountEntryTable,
    customerBalanceTable,
    containerMovementTable,
    customerContainerBalanceTable,
    routeInventoryLoadTable,
    pendingChangeTable,
    containerTypeTable,
    paymentMethodTable,
    customerAgreementTable,
    syncStateTable,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'routes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('route_stops', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'customer_addresses',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('route_stops', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'route_stops',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('visits', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'visit_outcomes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('visits', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sales',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sale_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'visits',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('payments', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sales',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('payments', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sales',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('customer_account_entries', kind: UpdateKind.update),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'payments',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('customer_account_entries', kind: UpdateKind.update),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'customer_account_entries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('customer_balances', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'visits',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('container_movements', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'routes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('container_movements', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'customers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('customer_agreements', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'products',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('customer_agreements', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$CustomerTableTableCreateCompanionBuilder =
    CustomerTableCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
      Value<bool> enabled,
      Value<int?> serverId,
      Value<String> customerId,
      required String name,
      Value<String?> phone,
      Value<int> rowid,
    });
typedef $$CustomerTableTableUpdateCompanionBuilder =
    CustomerTableCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
      Value<bool> enabled,
      Value<int?> serverId,
      Value<String> customerId,
      Value<String> name,
      Value<String?> phone,
      Value<int> rowid,
    });

final class $$CustomerTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $CustomerTableTable, CustomerTableData> {
  $$CustomerTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$RouteStopTableTable, List<RouteStopTableData>>
  _routeStopTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.routeStopTable,
    aliasName: $_aliasNameGenerator(
      db.customerTable.customerId,
      db.routeStopTable.customerId,
    ),
  );

  $$RouteStopTableTableProcessedTableManager get routeStopTableRefs {
    final manager = $$RouteStopTableTableTableManager($_db, $_db.routeStopTable)
        .filter(
          (f) => f.customerId.customerId.sqlEquals(
            $_itemColumn<String>('customer_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_routeStopTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$VisitTableTable, List<VisitTableData>>
  _visitTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.visitTable,
    aliasName: $_aliasNameGenerator(
      db.customerTable.customerId,
      db.visitTable.customerId,
    ),
  );

  $$VisitTableTableProcessedTableManager get visitTableRefs {
    final manager = $$VisitTableTableTableManager($_db, $_db.visitTable).filter(
      (f) => f.customerId.customerId.sqlEquals(
        $_itemColumn<String>('customer_id')!,
      ),
    );

    final cache = $_typedResult.readTableOrNull(_visitTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SaleTableTable, List<SaleTableData>>
  _saleTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.saleTable,
    aliasName: $_aliasNameGenerator(
      db.customerTable.customerId,
      db.saleTable.customerId,
    ),
  );

  $$SaleTableTableProcessedTableManager get saleTableRefs {
    final manager = $$SaleTableTableTableManager($_db, $_db.saleTable).filter(
      (f) => f.customerId.customerId.sqlEquals(
        $_itemColumn<String>('customer_id')!,
      ),
    );

    final cache = $_typedResult.readTableOrNull(_saleTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PaymentTableTable, List<PaymentTableData>>
  _paymentTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.paymentTable,
    aliasName: $_aliasNameGenerator(
      db.customerTable.customerId,
      db.paymentTable.customerId,
    ),
  );

  $$PaymentTableTableProcessedTableManager get paymentTableRefs {
    final manager = $$PaymentTableTableTableManager($_db, $_db.paymentTable)
        .filter(
          (f) => f.customerId.customerId.sqlEquals(
            $_itemColumn<String>('customer_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_paymentTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $CustomerAccountEntryTableTable,
    List<CustomerAccountEntryTableData>
  >
  _customerAccountEntryTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.customerAccountEntryTable,
        aliasName: $_aliasNameGenerator(
          db.customerTable.customerId,
          db.customerAccountEntryTable.customerId,
        ),
      );

  $$CustomerAccountEntryTableTableProcessedTableManager
  get customerAccountEntryTableRefs {
    final manager =
        $$CustomerAccountEntryTableTableTableManager(
          $_db,
          $_db.customerAccountEntryTable,
        ).filter(
          (f) => f.customerId.customerId.sqlEquals(
            $_itemColumn<String>('customer_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _customerAccountEntryTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $CustomerBalanceTableTable,
    List<CustomerBalanceTableData>
  >
  _customerBalanceTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.customerBalanceTable,
        aliasName: $_aliasNameGenerator(
          db.customerTable.customerId,
          db.customerBalanceTable.customerId,
        ),
      );

  $$CustomerBalanceTableTableProcessedTableManager
  get customerBalanceTableRefs {
    final manager =
        $$CustomerBalanceTableTableTableManager(
          $_db,
          $_db.customerBalanceTable,
        ).filter(
          (f) => f.customerId.customerId.sqlEquals(
            $_itemColumn<String>('customer_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _customerBalanceTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ContainerMovementTableTable,
    List<ContainerMovementTableData>
  >
  _containerMovementTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.containerMovementTable,
        aliasName: $_aliasNameGenerator(
          db.customerTable.customerId,
          db.containerMovementTable.customerId,
        ),
      );

  $$ContainerMovementTableTableProcessedTableManager
  get containerMovementTableRefs {
    final manager =
        $$ContainerMovementTableTableTableManager(
          $_db,
          $_db.containerMovementTable,
        ).filter(
          (f) => f.customerId.customerId.sqlEquals(
            $_itemColumn<String>('customer_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _containerMovementTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $CustomerContainerBalanceTableTable,
    List<CustomerContainerBalanceTableData>
  >
  _customerContainerBalanceTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.customerContainerBalanceTable,
        aliasName: $_aliasNameGenerator(
          db.customerTable.customerId,
          db.customerContainerBalanceTable.customerId,
        ),
      );

  $$CustomerContainerBalanceTableTableProcessedTableManager
  get customerContainerBalanceTableRefs {
    final manager =
        $$CustomerContainerBalanceTableTableTableManager(
          $_db,
          $_db.customerContainerBalanceTable,
        ).filter(
          (f) => f.customerId.customerId.sqlEquals(
            $_itemColumn<String>('customer_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _customerContainerBalanceTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $CustomerAgreementTableTable,
    List<CustomerAgreementTableData>
  >
  _customerAgreementTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.customerAgreementTable,
        aliasName: $_aliasNameGenerator(
          db.customerTable.customerId,
          db.customerAgreementTable.customerId,
        ),
      );

  $$CustomerAgreementTableTableProcessedTableManager
  get customerAgreementTableRefs {
    final manager =
        $$CustomerAgreementTableTableTableManager(
          $_db,
          $_db.customerAgreementTable,
        ).filter(
          (f) => f.customerId.customerId.sqlEquals(
            $_itemColumn<String>('customer_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _customerAgreementTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CustomerTableTableFilterComposer
    extends Composer<_$AppDatabase, $CustomerTableTable> {
  $$CustomerTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> routeStopTableRefs(
    Expression<bool> Function($$RouteStopTableTableFilterComposer f) f,
  ) {
    final $$RouteStopTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.routeStopTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RouteStopTableTableFilterComposer(
            $db: $db,
            $table: $db.routeStopTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> visitTableRefs(
    Expression<bool> Function($$VisitTableTableFilterComposer f) f,
  ) {
    final $$VisitTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.visitTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitTableTableFilterComposer(
            $db: $db,
            $table: $db.visitTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> saleTableRefs(
    Expression<bool> Function($$SaleTableTableFilterComposer f) f,
  ) {
    final $$SaleTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.saleTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleTableTableFilterComposer(
            $db: $db,
            $table: $db.saleTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> paymentTableRefs(
    Expression<bool> Function($$PaymentTableTableFilterComposer f) f,
  ) {
    final $$PaymentTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.paymentTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentTableTableFilterComposer(
            $db: $db,
            $table: $db.paymentTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> customerAccountEntryTableRefs(
    Expression<bool> Function($$CustomerAccountEntryTableTableFilterComposer f)
    f,
  ) {
    final $$CustomerAccountEntryTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.customerId,
          referencedTable: $db.customerAccountEntryTable,
          getReferencedColumn: (t) => t.customerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CustomerAccountEntryTableTableFilterComposer(
                $db: $db,
                $table: $db.customerAccountEntryTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> customerBalanceTableRefs(
    Expression<bool> Function($$CustomerBalanceTableTableFilterComposer f) f,
  ) {
    final $$CustomerBalanceTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customerBalanceTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomerBalanceTableTableFilterComposer(
            $db: $db,
            $table: $db.customerBalanceTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> containerMovementTableRefs(
    Expression<bool> Function($$ContainerMovementTableTableFilterComposer f) f,
  ) {
    final $$ContainerMovementTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.customerId,
          referencedTable: $db.containerMovementTable,
          getReferencedColumn: (t) => t.customerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContainerMovementTableTableFilterComposer(
                $db: $db,
                $table: $db.containerMovementTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> customerContainerBalanceTableRefs(
    Expression<bool> Function(
      $$CustomerContainerBalanceTableTableFilterComposer f,
    )
    f,
  ) {
    final $$CustomerContainerBalanceTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.customerId,
          referencedTable: $db.customerContainerBalanceTable,
          getReferencedColumn: (t) => t.customerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CustomerContainerBalanceTableTableFilterComposer(
                $db: $db,
                $table: $db.customerContainerBalanceTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> customerAgreementTableRefs(
    Expression<bool> Function($$CustomerAgreementTableTableFilterComposer f) f,
  ) {
    final $$CustomerAgreementTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.customerId,
          referencedTable: $db.customerAgreementTable,
          getReferencedColumn: (t) => t.customerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CustomerAgreementTableTableFilterComposer(
                $db: $db,
                $table: $db.customerAgreementTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CustomerTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomerTableTable> {
  $$CustomerTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomerTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomerTableTable> {
  $$CustomerTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  Expression<T> routeStopTableRefs<T extends Object>(
    Expression<T> Function($$RouteStopTableTableAnnotationComposer a) f,
  ) {
    final $$RouteStopTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.routeStopTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RouteStopTableTableAnnotationComposer(
            $db: $db,
            $table: $db.routeStopTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> visitTableRefs<T extends Object>(
    Expression<T> Function($$VisitTableTableAnnotationComposer a) f,
  ) {
    final $$VisitTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.visitTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitTableTableAnnotationComposer(
            $db: $db,
            $table: $db.visitTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> saleTableRefs<T extends Object>(
    Expression<T> Function($$SaleTableTableAnnotationComposer a) f,
  ) {
    final $$SaleTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.saleTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleTableTableAnnotationComposer(
            $db: $db,
            $table: $db.saleTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> paymentTableRefs<T extends Object>(
    Expression<T> Function($$PaymentTableTableAnnotationComposer a) f,
  ) {
    final $$PaymentTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.paymentTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentTableTableAnnotationComposer(
            $db: $db,
            $table: $db.paymentTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> customerAccountEntryTableRefs<T extends Object>(
    Expression<T> Function($$CustomerAccountEntryTableTableAnnotationComposer a)
    f,
  ) {
    final $$CustomerAccountEntryTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.customerId,
          referencedTable: $db.customerAccountEntryTable,
          getReferencedColumn: (t) => t.customerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CustomerAccountEntryTableTableAnnotationComposer(
                $db: $db,
                $table: $db.customerAccountEntryTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> customerBalanceTableRefs<T extends Object>(
    Expression<T> Function($$CustomerBalanceTableTableAnnotationComposer a) f,
  ) {
    final $$CustomerBalanceTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.customerId,
          referencedTable: $db.customerBalanceTable,
          getReferencedColumn: (t) => t.customerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CustomerBalanceTableTableAnnotationComposer(
                $db: $db,
                $table: $db.customerBalanceTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> containerMovementTableRefs<T extends Object>(
    Expression<T> Function($$ContainerMovementTableTableAnnotationComposer a) f,
  ) {
    final $$ContainerMovementTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.customerId,
          referencedTable: $db.containerMovementTable,
          getReferencedColumn: (t) => t.customerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContainerMovementTableTableAnnotationComposer(
                $db: $db,
                $table: $db.containerMovementTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> customerContainerBalanceTableRefs<T extends Object>(
    Expression<T> Function(
      $$CustomerContainerBalanceTableTableAnnotationComposer a,
    )
    f,
  ) {
    final $$CustomerContainerBalanceTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.customerId,
          referencedTable: $db.customerContainerBalanceTable,
          getReferencedColumn: (t) => t.customerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CustomerContainerBalanceTableTableAnnotationComposer(
                $db: $db,
                $table: $db.customerContainerBalanceTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> customerAgreementTableRefs<T extends Object>(
    Expression<T> Function($$CustomerAgreementTableTableAnnotationComposer a) f,
  ) {
    final $$CustomerAgreementTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.customerId,
          referencedTable: $db.customerAgreementTable,
          getReferencedColumn: (t) => t.customerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CustomerAgreementTableTableAnnotationComposer(
                $db: $db,
                $table: $db.customerAgreementTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CustomerTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomerTableTable,
          CustomerTableData,
          $$CustomerTableTableFilterComposer,
          $$CustomerTableTableOrderingComposer,
          $$CustomerTableTableAnnotationComposer,
          $$CustomerTableTableCreateCompanionBuilder,
          $$CustomerTableTableUpdateCompanionBuilder,
          (CustomerTableData, $$CustomerTableTableReferences),
          CustomerTableData,
          PrefetchHooks Function({
            bool routeStopTableRefs,
            bool visitTableRefs,
            bool saleTableRefs,
            bool paymentTableRefs,
            bool customerAccountEntryTableRefs,
            bool customerBalanceTableRefs,
            bool containerMovementTableRefs,
            bool customerContainerBalanceTableRefs,
            bool customerAgreementTableRefs,
          })
        > {
  $$CustomerTableTableTableManager(_$AppDatabase db, $CustomerTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomerTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomerTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomerTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModifiedDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomerTableCompanion(
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
                enabled: enabled,
                serverId: serverId,
                customerId: customerId,
                name: name,
                phone: phone,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModifiedDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                required String name,
                Value<String?> phone = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomerTableCompanion.insert(
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
                enabled: enabled,
                serverId: serverId,
                customerId: customerId,
                name: name,
                phone: phone,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CustomerTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                routeStopTableRefs = false,
                visitTableRefs = false,
                saleTableRefs = false,
                paymentTableRefs = false,
                customerAccountEntryTableRefs = false,
                customerBalanceTableRefs = false,
                containerMovementTableRefs = false,
                customerContainerBalanceTableRefs = false,
                customerAgreementTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (routeStopTableRefs) db.routeStopTable,
                    if (visitTableRefs) db.visitTable,
                    if (saleTableRefs) db.saleTable,
                    if (paymentTableRefs) db.paymentTable,
                    if (customerAccountEntryTableRefs)
                      db.customerAccountEntryTable,
                    if (customerBalanceTableRefs) db.customerBalanceTable,
                    if (containerMovementTableRefs) db.containerMovementTable,
                    if (customerContainerBalanceTableRefs)
                      db.customerContainerBalanceTable,
                    if (customerAgreementTableRefs) db.customerAgreementTable,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (routeStopTableRefs)
                        await $_getPrefetchedData<
                          CustomerTableData,
                          $CustomerTableTable,
                          RouteStopTableData
                        >(
                          currentTable: table,
                          referencedTable: $$CustomerTableTableReferences
                              ._routeStopTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CustomerTableTableReferences(
                                db,
                                table,
                                p0,
                              ).routeStopTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.customerId == item.customerId,
                              ),
                          typedResults: items,
                        ),
                      if (visitTableRefs)
                        await $_getPrefetchedData<
                          CustomerTableData,
                          $CustomerTableTable,
                          VisitTableData
                        >(
                          currentTable: table,
                          referencedTable: $$CustomerTableTableReferences
                              ._visitTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CustomerTableTableReferences(
                                db,
                                table,
                                p0,
                              ).visitTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.customerId == item.customerId,
                              ),
                          typedResults: items,
                        ),
                      if (saleTableRefs)
                        await $_getPrefetchedData<
                          CustomerTableData,
                          $CustomerTableTable,
                          SaleTableData
                        >(
                          currentTable: table,
                          referencedTable: $$CustomerTableTableReferences
                              ._saleTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CustomerTableTableReferences(
                                db,
                                table,
                                p0,
                              ).saleTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.customerId == item.customerId,
                              ),
                          typedResults: items,
                        ),
                      if (paymentTableRefs)
                        await $_getPrefetchedData<
                          CustomerTableData,
                          $CustomerTableTable,
                          PaymentTableData
                        >(
                          currentTable: table,
                          referencedTable: $$CustomerTableTableReferences
                              ._paymentTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CustomerTableTableReferences(
                                db,
                                table,
                                p0,
                              ).paymentTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.customerId == item.customerId,
                              ),
                          typedResults: items,
                        ),
                      if (customerAccountEntryTableRefs)
                        await $_getPrefetchedData<
                          CustomerTableData,
                          $CustomerTableTable,
                          CustomerAccountEntryTableData
                        >(
                          currentTable: table,
                          referencedTable: $$CustomerTableTableReferences
                              ._customerAccountEntryTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CustomerTableTableReferences(
                                db,
                                table,
                                p0,
                              ).customerAccountEntryTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.customerId == item.customerId,
                              ),
                          typedResults: items,
                        ),
                      if (customerBalanceTableRefs)
                        await $_getPrefetchedData<
                          CustomerTableData,
                          $CustomerTableTable,
                          CustomerBalanceTableData
                        >(
                          currentTable: table,
                          referencedTable: $$CustomerTableTableReferences
                              ._customerBalanceTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CustomerTableTableReferences(
                                db,
                                table,
                                p0,
                              ).customerBalanceTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.customerId == item.customerId,
                              ),
                          typedResults: items,
                        ),
                      if (containerMovementTableRefs)
                        await $_getPrefetchedData<
                          CustomerTableData,
                          $CustomerTableTable,
                          ContainerMovementTableData
                        >(
                          currentTable: table,
                          referencedTable: $$CustomerTableTableReferences
                              ._containerMovementTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CustomerTableTableReferences(
                                db,
                                table,
                                p0,
                              ).containerMovementTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.customerId == item.customerId,
                              ),
                          typedResults: items,
                        ),
                      if (customerContainerBalanceTableRefs)
                        await $_getPrefetchedData<
                          CustomerTableData,
                          $CustomerTableTable,
                          CustomerContainerBalanceTableData
                        >(
                          currentTable: table,
                          referencedTable: $$CustomerTableTableReferences
                              ._customerContainerBalanceTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CustomerTableTableReferences(
                                db,
                                table,
                                p0,
                              ).customerContainerBalanceTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.customerId == item.customerId,
                              ),
                          typedResults: items,
                        ),
                      if (customerAgreementTableRefs)
                        await $_getPrefetchedData<
                          CustomerTableData,
                          $CustomerTableTable,
                          CustomerAgreementTableData
                        >(
                          currentTable: table,
                          referencedTable: $$CustomerTableTableReferences
                              ._customerAgreementTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CustomerTableTableReferences(
                                db,
                                table,
                                p0,
                              ).customerAgreementTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.customerId == item.customerId,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CustomerTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomerTableTable,
      CustomerTableData,
      $$CustomerTableTableFilterComposer,
      $$CustomerTableTableOrderingComposer,
      $$CustomerTableTableAnnotationComposer,
      $$CustomerTableTableCreateCompanionBuilder,
      $$CustomerTableTableUpdateCompanionBuilder,
      (CustomerTableData, $$CustomerTableTableReferences),
      CustomerTableData,
      PrefetchHooks Function({
        bool routeStopTableRefs,
        bool visitTableRefs,
        bool saleTableRefs,
        bool paymentTableRefs,
        bool customerAccountEntryTableRefs,
        bool customerBalanceTableRefs,
        bool containerMovementTableRefs,
        bool customerContainerBalanceTableRefs,
        bool customerAgreementTableRefs,
      })
    >;
typedef $$CustomerAddressTableTableCreateCompanionBuilder =
    CustomerAddressTableCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
      Value<bool> enabled,
      Value<int?> serverId,
      Value<String> addressId,
      Value<String?> street,
      Value<String?> apartment,
      Value<String?> floor,
      Value<String?> visualReference,
      Value<bool> isPrimary,
      Value<String> customerId,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<String?> neighborhood,
      Value<int> rowid,
    });
typedef $$CustomerAddressTableTableUpdateCompanionBuilder =
    CustomerAddressTableCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
      Value<bool> enabled,
      Value<int?> serverId,
      Value<String> addressId,
      Value<String?> street,
      Value<String?> apartment,
      Value<String?> floor,
      Value<String?> visualReference,
      Value<bool> isPrimary,
      Value<String> customerId,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<String?> neighborhood,
      Value<int> rowid,
    });

final class $$CustomerAddressTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CustomerAddressTableTable,
          CustomerAddressTableData
        > {
  $$CustomerAddressTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$RouteStopTableTable, List<RouteStopTableData>>
  _routeStopTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.routeStopTable,
    aliasName: $_aliasNameGenerator(
      db.customerAddressTable.addressId,
      db.routeStopTable.customerAddressId,
    ),
  );

  $$RouteStopTableTableProcessedTableManager get routeStopTableRefs {
    final manager = $$RouteStopTableTableTableManager($_db, $_db.routeStopTable)
        .filter(
          (f) => f.customerAddressId.addressId.sqlEquals(
            $_itemColumn<String>('address_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_routeStopTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CustomerAddressTableTableFilterComposer
    extends Composer<_$AppDatabase, $CustomerAddressTableTable> {
  $$CustomerAddressTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get addressId => $composableBuilder(
    column: $table.addressId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get street => $composableBuilder(
    column: $table.street,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get apartment => $composableBuilder(
    column: $table.apartment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get floor => $composableBuilder(
    column: $table.floor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visualReference => $composableBuilder(
    column: $table.visualReference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get neighborhood => $composableBuilder(
    column: $table.neighborhood,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> routeStopTableRefs(
    Expression<bool> Function($$RouteStopTableTableFilterComposer f) f,
  ) {
    final $$RouteStopTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.addressId,
      referencedTable: $db.routeStopTable,
      getReferencedColumn: (t) => t.customerAddressId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RouteStopTableTableFilterComposer(
            $db: $db,
            $table: $db.routeStopTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CustomerAddressTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomerAddressTableTable> {
  $$CustomerAddressTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get addressId => $composableBuilder(
    column: $table.addressId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get street => $composableBuilder(
    column: $table.street,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get apartment => $composableBuilder(
    column: $table.apartment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get floor => $composableBuilder(
    column: $table.floor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visualReference => $composableBuilder(
    column: $table.visualReference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get neighborhood => $composableBuilder(
    column: $table.neighborhood,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomerAddressTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomerAddressTableTable> {
  $$CustomerAddressTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get addressId =>
      $composableBuilder(column: $table.addressId, builder: (column) => column);

  GeneratedColumn<String> get street =>
      $composableBuilder(column: $table.street, builder: (column) => column);

  GeneratedColumn<String> get apartment =>
      $composableBuilder(column: $table.apartment, builder: (column) => column);

  GeneratedColumn<String> get floor =>
      $composableBuilder(column: $table.floor, builder: (column) => column);

  GeneratedColumn<String> get visualReference => $composableBuilder(
    column: $table.visualReference,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPrimary =>
      $composableBuilder(column: $table.isPrimary, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get neighborhood => $composableBuilder(
    column: $table.neighborhood,
    builder: (column) => column,
  );

  Expression<T> routeStopTableRefs<T extends Object>(
    Expression<T> Function($$RouteStopTableTableAnnotationComposer a) f,
  ) {
    final $$RouteStopTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.addressId,
      referencedTable: $db.routeStopTable,
      getReferencedColumn: (t) => t.customerAddressId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RouteStopTableTableAnnotationComposer(
            $db: $db,
            $table: $db.routeStopTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CustomerAddressTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomerAddressTableTable,
          CustomerAddressTableData,
          $$CustomerAddressTableTableFilterComposer,
          $$CustomerAddressTableTableOrderingComposer,
          $$CustomerAddressTableTableAnnotationComposer,
          $$CustomerAddressTableTableCreateCompanionBuilder,
          $$CustomerAddressTableTableUpdateCompanionBuilder,
          (CustomerAddressTableData, $$CustomerAddressTableTableReferences),
          CustomerAddressTableData,
          PrefetchHooks Function({bool routeStopTableRefs})
        > {
  $$CustomerAddressTableTableTableManager(
    _$AppDatabase db,
    $CustomerAddressTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomerAddressTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomerAddressTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CustomerAddressTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModifiedDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> addressId = const Value.absent(),
                Value<String?> street = const Value.absent(),
                Value<String?> apartment = const Value.absent(),
                Value<String?> floor = const Value.absent(),
                Value<String?> visualReference = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<String?> neighborhood = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomerAddressTableCompanion(
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
                enabled: enabled,
                serverId: serverId,
                addressId: addressId,
                street: street,
                apartment: apartment,
                floor: floor,
                visualReference: visualReference,
                isPrimary: isPrimary,
                customerId: customerId,
                latitude: latitude,
                longitude: longitude,
                neighborhood: neighborhood,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModifiedDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> addressId = const Value.absent(),
                Value<String?> street = const Value.absent(),
                Value<String?> apartment = const Value.absent(),
                Value<String?> floor = const Value.absent(),
                Value<String?> visualReference = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<String?> neighborhood = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomerAddressTableCompanion.insert(
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
                enabled: enabled,
                serverId: serverId,
                addressId: addressId,
                street: street,
                apartment: apartment,
                floor: floor,
                visualReference: visualReference,
                isPrimary: isPrimary,
                customerId: customerId,
                latitude: latitude,
                longitude: longitude,
                neighborhood: neighborhood,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CustomerAddressTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({routeStopTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (routeStopTableRefs) db.routeStopTable,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (routeStopTableRefs)
                    await $_getPrefetchedData<
                      CustomerAddressTableData,
                      $CustomerAddressTableTable,
                      RouteStopTableData
                    >(
                      currentTable: table,
                      referencedTable: $$CustomerAddressTableTableReferences
                          ._routeStopTableRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CustomerAddressTableTableReferences(
                            db,
                            table,
                            p0,
                          ).routeStopTableRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.customerAddressId == item.addressId,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CustomerAddressTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomerAddressTableTable,
      CustomerAddressTableData,
      $$CustomerAddressTableTableFilterComposer,
      $$CustomerAddressTableTableOrderingComposer,
      $$CustomerAddressTableTableAnnotationComposer,
      $$CustomerAddressTableTableCreateCompanionBuilder,
      $$CustomerAddressTableTableUpdateCompanionBuilder,
      (CustomerAddressTableData, $$CustomerAddressTableTableReferences),
      CustomerAddressTableData,
      PrefetchHooks Function({bool routeStopTableRefs})
    >;
typedef $$CustomerPreferenceTableTableCreateCompanionBuilder =
    CustomerPreferenceTableCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
      Value<bool> enabled,
      Value<int?> serverId,
      Value<String> customerPreferenceId,
      Value<String> customerId,
      Value<int> dayOfWeek,
      required String timeWindowStart,
      Value<String?> timeWindowEnd,
      Value<int> rowid,
    });
typedef $$CustomerPreferenceTableTableUpdateCompanionBuilder =
    CustomerPreferenceTableCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
      Value<bool> enabled,
      Value<int?> serverId,
      Value<String> customerPreferenceId,
      Value<String> customerId,
      Value<int> dayOfWeek,
      Value<String> timeWindowStart,
      Value<String?> timeWindowEnd,
      Value<int> rowid,
    });

class $$CustomerPreferenceTableTableFilterComposer
    extends Composer<_$AppDatabase, $CustomerPreferenceTableTable> {
  $$CustomerPreferenceTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerPreferenceId => $composableBuilder(
    column: $table.customerPreferenceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayOfWeek => $composableBuilder(
    column: $table.dayOfWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeWindowStart => $composableBuilder(
    column: $table.timeWindowStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeWindowEnd => $composableBuilder(
    column: $table.timeWindowEnd,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomerPreferenceTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomerPreferenceTableTable> {
  $$CustomerPreferenceTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerPreferenceId => $composableBuilder(
    column: $table.customerPreferenceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayOfWeek => $composableBuilder(
    column: $table.dayOfWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeWindowStart => $composableBuilder(
    column: $table.timeWindowStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeWindowEnd => $composableBuilder(
    column: $table.timeWindowEnd,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomerPreferenceTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomerPreferenceTableTable> {
  $$CustomerPreferenceTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get customerPreferenceId => $composableBuilder(
    column: $table.customerPreferenceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dayOfWeek =>
      $composableBuilder(column: $table.dayOfWeek, builder: (column) => column);

  GeneratedColumn<String> get timeWindowStart => $composableBuilder(
    column: $table.timeWindowStart,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timeWindowEnd => $composableBuilder(
    column: $table.timeWindowEnd,
    builder: (column) => column,
  );
}

class $$CustomerPreferenceTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomerPreferenceTableTable,
          CustomerPreferenceTableData,
          $$CustomerPreferenceTableTableFilterComposer,
          $$CustomerPreferenceTableTableOrderingComposer,
          $$CustomerPreferenceTableTableAnnotationComposer,
          $$CustomerPreferenceTableTableCreateCompanionBuilder,
          $$CustomerPreferenceTableTableUpdateCompanionBuilder,
          (
            CustomerPreferenceTableData,
            BaseReferences<
              _$AppDatabase,
              $CustomerPreferenceTableTable,
              CustomerPreferenceTableData
            >,
          ),
          CustomerPreferenceTableData,
          PrefetchHooks Function()
        > {
  $$CustomerPreferenceTableTableTableManager(
    _$AppDatabase db,
    $CustomerPreferenceTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomerPreferenceTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CustomerPreferenceTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CustomerPreferenceTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModifiedDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> customerPreferenceId = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<int> dayOfWeek = const Value.absent(),
                Value<String> timeWindowStart = const Value.absent(),
                Value<String?> timeWindowEnd = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomerPreferenceTableCompanion(
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
                enabled: enabled,
                serverId: serverId,
                customerPreferenceId: customerPreferenceId,
                customerId: customerId,
                dayOfWeek: dayOfWeek,
                timeWindowStart: timeWindowStart,
                timeWindowEnd: timeWindowEnd,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModifiedDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> customerPreferenceId = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<int> dayOfWeek = const Value.absent(),
                required String timeWindowStart,
                Value<String?> timeWindowEnd = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomerPreferenceTableCompanion.insert(
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
                enabled: enabled,
                serverId: serverId,
                customerPreferenceId: customerPreferenceId,
                customerId: customerId,
                dayOfWeek: dayOfWeek,
                timeWindowStart: timeWindowStart,
                timeWindowEnd: timeWindowEnd,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomerPreferenceTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomerPreferenceTableTable,
      CustomerPreferenceTableData,
      $$CustomerPreferenceTableTableFilterComposer,
      $$CustomerPreferenceTableTableOrderingComposer,
      $$CustomerPreferenceTableTableAnnotationComposer,
      $$CustomerPreferenceTableTableCreateCompanionBuilder,
      $$CustomerPreferenceTableTableUpdateCompanionBuilder,
      (
        CustomerPreferenceTableData,
        BaseReferences<
          _$AppDatabase,
          $CustomerPreferenceTableTable,
          CustomerPreferenceTableData
        >,
      ),
      CustomerPreferenceTableData,
      PrefetchHooks Function()
    >;
typedef $$RouteTableTableCreateCompanionBuilder =
    RouteTableCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
      Value<bool> enabled,
      Value<int?> serverId,
      Value<String> routeId,
      Value<String?> driverName,
      required String route_date,
      Value<int> started_at,
      Value<String?> completed_at,
      Value<String?> last_modified,
      Value<String?> available,
      Value<String?> status,
      Value<int> rowid,
    });
typedef $$RouteTableTableUpdateCompanionBuilder =
    RouteTableCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
      Value<bool> enabled,
      Value<int?> serverId,
      Value<String> routeId,
      Value<String?> driverName,
      Value<String> route_date,
      Value<int> started_at,
      Value<String?> completed_at,
      Value<String?> last_modified,
      Value<String?> available,
      Value<String?> status,
      Value<int> rowid,
    });

final class $$RouteTableTableReferences
    extends BaseReferences<_$AppDatabase, $RouteTableTable, RouteTableData> {
  $$RouteTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RouteStopTableTable, List<RouteStopTableData>>
  _routeStopTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.routeStopTable,
    aliasName: $_aliasNameGenerator(
      db.routeTable.routeId,
      db.routeStopTable.routeId,
    ),
  );

  $$RouteStopTableTableProcessedTableManager get routeStopTableRefs {
    final manager = $$RouteStopTableTableTableManager($_db, $_db.routeStopTable)
        .filter(
          (f) => f.routeId.routeId.sqlEquals($_itemColumn<String>('route_id')!),
        );

    final cache = $_typedResult.readTableOrNull(_routeStopTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ContainerMovementTableTable,
    List<ContainerMovementTableData>
  >
  _containerMovementTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.containerMovementTable,
        aliasName: $_aliasNameGenerator(
          db.routeTable.routeId,
          db.containerMovementTable.routeId,
        ),
      );

  $$ContainerMovementTableTableProcessedTableManager
  get containerMovementTableRefs {
    final manager =
        $$ContainerMovementTableTableTableManager(
          $_db,
          $_db.containerMovementTable,
        ).filter(
          (f) => f.routeId.routeId.sqlEquals($_itemColumn<String>('route_id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _containerMovementTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $RouteInventoryLoadTableTable,
    List<RouteInventoryLoadTableData>
  >
  _routeInventoryLoadTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.routeInventoryLoadTable,
        aliasName: $_aliasNameGenerator(
          db.routeTable.routeId,
          db.routeInventoryLoadTable.routeId,
        ),
      );

  $$RouteInventoryLoadTableTableProcessedTableManager
  get routeInventoryLoadTableRefs {
    final manager =
        $$RouteInventoryLoadTableTableTableManager(
          $_db,
          $_db.routeInventoryLoadTable,
        ).filter(
          (f) => f.routeId.routeId.sqlEquals($_itemColumn<String>('route_id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _routeInventoryLoadTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RouteTableTableFilterComposer
    extends Composer<_$AppDatabase, $RouteTableTable> {
  $$RouteTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routeId => $composableBuilder(
    column: $table.routeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get driverName => $composableBuilder(
    column: $table.driverName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get route_date => $composableBuilder(
    column: $table.route_date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get started_at => $composableBuilder(
    column: $table.started_at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get completed_at => $composableBuilder(
    column: $table.completed_at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get last_modified => $composableBuilder(
    column: $table.last_modified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get available => $composableBuilder(
    column: $table.available,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> routeStopTableRefs(
    Expression<bool> Function($$RouteStopTableTableFilterComposer f) f,
  ) {
    final $$RouteStopTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routeId,
      referencedTable: $db.routeStopTable,
      getReferencedColumn: (t) => t.routeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RouteStopTableTableFilterComposer(
            $db: $db,
            $table: $db.routeStopTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> containerMovementTableRefs(
    Expression<bool> Function($$ContainerMovementTableTableFilterComposer f) f,
  ) {
    final $$ContainerMovementTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.routeId,
          referencedTable: $db.containerMovementTable,
          getReferencedColumn: (t) => t.routeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContainerMovementTableTableFilterComposer(
                $db: $db,
                $table: $db.containerMovementTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> routeInventoryLoadTableRefs(
    Expression<bool> Function($$RouteInventoryLoadTableTableFilterComposer f) f,
  ) {
    final $$RouteInventoryLoadTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.routeId,
          referencedTable: $db.routeInventoryLoadTable,
          getReferencedColumn: (t) => t.routeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RouteInventoryLoadTableTableFilterComposer(
                $db: $db,
                $table: $db.routeInventoryLoadTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$RouteTableTableOrderingComposer
    extends Composer<_$AppDatabase, $RouteTableTable> {
  $$RouteTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routeId => $composableBuilder(
    column: $table.routeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get driverName => $composableBuilder(
    column: $table.driverName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get route_date => $composableBuilder(
    column: $table.route_date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get started_at => $composableBuilder(
    column: $table.started_at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get completed_at => $composableBuilder(
    column: $table.completed_at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get last_modified => $composableBuilder(
    column: $table.last_modified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get available => $composableBuilder(
    column: $table.available,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RouteTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $RouteTableTable> {
  $$RouteTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get routeId =>
      $composableBuilder(column: $table.routeId, builder: (column) => column);

  GeneratedColumn<String> get driverName => $composableBuilder(
    column: $table.driverName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get route_date => $composableBuilder(
    column: $table.route_date,
    builder: (column) => column,
  );

  GeneratedColumn<int> get started_at => $composableBuilder(
    column: $table.started_at,
    builder: (column) => column,
  );

  GeneratedColumn<String> get completed_at => $composableBuilder(
    column: $table.completed_at,
    builder: (column) => column,
  );

  GeneratedColumn<String> get last_modified => $composableBuilder(
    column: $table.last_modified,
    builder: (column) => column,
  );

  GeneratedColumn<String> get available =>
      $composableBuilder(column: $table.available, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  Expression<T> routeStopTableRefs<T extends Object>(
    Expression<T> Function($$RouteStopTableTableAnnotationComposer a) f,
  ) {
    final $$RouteStopTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routeId,
      referencedTable: $db.routeStopTable,
      getReferencedColumn: (t) => t.routeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RouteStopTableTableAnnotationComposer(
            $db: $db,
            $table: $db.routeStopTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> containerMovementTableRefs<T extends Object>(
    Expression<T> Function($$ContainerMovementTableTableAnnotationComposer a) f,
  ) {
    final $$ContainerMovementTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.routeId,
          referencedTable: $db.containerMovementTable,
          getReferencedColumn: (t) => t.routeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContainerMovementTableTableAnnotationComposer(
                $db: $db,
                $table: $db.containerMovementTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> routeInventoryLoadTableRefs<T extends Object>(
    Expression<T> Function($$RouteInventoryLoadTableTableAnnotationComposer a)
    f,
  ) {
    final $$RouteInventoryLoadTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.routeId,
          referencedTable: $db.routeInventoryLoadTable,
          getReferencedColumn: (t) => t.routeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RouteInventoryLoadTableTableAnnotationComposer(
                $db: $db,
                $table: $db.routeInventoryLoadTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$RouteTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RouteTableTable,
          RouteTableData,
          $$RouteTableTableFilterComposer,
          $$RouteTableTableOrderingComposer,
          $$RouteTableTableAnnotationComposer,
          $$RouteTableTableCreateCompanionBuilder,
          $$RouteTableTableUpdateCompanionBuilder,
          (RouteTableData, $$RouteTableTableReferences),
          RouteTableData,
          PrefetchHooks Function({
            bool routeStopTableRefs,
            bool containerMovementTableRefs,
            bool routeInventoryLoadTableRefs,
          })
        > {
  $$RouteTableTableTableManager(_$AppDatabase db, $RouteTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RouteTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RouteTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RouteTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModifiedDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> routeId = const Value.absent(),
                Value<String?> driverName = const Value.absent(),
                Value<String> route_date = const Value.absent(),
                Value<int> started_at = const Value.absent(),
                Value<String?> completed_at = const Value.absent(),
                Value<String?> last_modified = const Value.absent(),
                Value<String?> available = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RouteTableCompanion(
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
                enabled: enabled,
                serverId: serverId,
                routeId: routeId,
                driverName: driverName,
                route_date: route_date,
                started_at: started_at,
                completed_at: completed_at,
                last_modified: last_modified,
                available: available,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModifiedDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> routeId = const Value.absent(),
                Value<String?> driverName = const Value.absent(),
                required String route_date,
                Value<int> started_at = const Value.absent(),
                Value<String?> completed_at = const Value.absent(),
                Value<String?> last_modified = const Value.absent(),
                Value<String?> available = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RouteTableCompanion.insert(
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
                enabled: enabled,
                serverId: serverId,
                routeId: routeId,
                driverName: driverName,
                route_date: route_date,
                started_at: started_at,
                completed_at: completed_at,
                last_modified: last_modified,
                available: available,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RouteTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                routeStopTableRefs = false,
                containerMovementTableRefs = false,
                routeInventoryLoadTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (routeStopTableRefs) db.routeStopTable,
                    if (containerMovementTableRefs) db.containerMovementTable,
                    if (routeInventoryLoadTableRefs) db.routeInventoryLoadTable,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (routeStopTableRefs)
                        await $_getPrefetchedData<
                          RouteTableData,
                          $RouteTableTable,
                          RouteStopTableData
                        >(
                          currentTable: table,
                          referencedTable: $$RouteTableTableReferences
                              ._routeStopTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RouteTableTableReferences(
                                db,
                                table,
                                p0,
                              ).routeStopTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.routeId == item.routeId,
                              ),
                          typedResults: items,
                        ),
                      if (containerMovementTableRefs)
                        await $_getPrefetchedData<
                          RouteTableData,
                          $RouteTableTable,
                          ContainerMovementTableData
                        >(
                          currentTable: table,
                          referencedTable: $$RouteTableTableReferences
                              ._containerMovementTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RouteTableTableReferences(
                                db,
                                table,
                                p0,
                              ).containerMovementTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.routeId == item.routeId,
                              ),
                          typedResults: items,
                        ),
                      if (routeInventoryLoadTableRefs)
                        await $_getPrefetchedData<
                          RouteTableData,
                          $RouteTableTable,
                          RouteInventoryLoadTableData
                        >(
                          currentTable: table,
                          referencedTable: $$RouteTableTableReferences
                              ._routeInventoryLoadTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RouteTableTableReferences(
                                db,
                                table,
                                p0,
                              ).routeInventoryLoadTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.routeId == item.routeId,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$RouteTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RouteTableTable,
      RouteTableData,
      $$RouteTableTableFilterComposer,
      $$RouteTableTableOrderingComposer,
      $$RouteTableTableAnnotationComposer,
      $$RouteTableTableCreateCompanionBuilder,
      $$RouteTableTableUpdateCompanionBuilder,
      (RouteTableData, $$RouteTableTableReferences),
      RouteTableData,
      PrefetchHooks Function({
        bool routeStopTableRefs,
        bool containerMovementTableRefs,
        bool routeInventoryLoadTableRefs,
      })
    >;
typedef $$RouteStopTableTableCreateCompanionBuilder =
    RouteStopTableCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
      Value<bool> enabled,
      Value<int?> serverId,
      Value<String> routeStopId,
      required String routeId,
      required String customerId,
      Value<String?> customerAddressId,
      required int sequence,
      Value<String> status,
      required DateTime scheduledAt,
      Value<DateTime?> visitedAt,
      Value<String?> notes,
      Value<String?> scheduledTime,
      Value<String?> rescheduledFromStopId,
      Value<int> rowid,
    });
typedef $$RouteStopTableTableUpdateCompanionBuilder =
    RouteStopTableCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
      Value<bool> enabled,
      Value<int?> serverId,
      Value<String> routeStopId,
      Value<String> routeId,
      Value<String> customerId,
      Value<String?> customerAddressId,
      Value<int> sequence,
      Value<String> status,
      Value<DateTime> scheduledAt,
      Value<DateTime?> visitedAt,
      Value<String?> notes,
      Value<String?> scheduledTime,
      Value<String?> rescheduledFromStopId,
      Value<int> rowid,
    });

final class $$RouteStopTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $RouteStopTableTable,
          RouteStopTableData
        > {
  $$RouteStopTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RouteTableTable _routeIdTable(_$AppDatabase db) =>
      db.routeTable.createAlias(
        $_aliasNameGenerator(db.routeStopTable.routeId, db.routeTable.routeId),
      );

  $$RouteTableTableProcessedTableManager get routeId {
    final $_column = $_itemColumn<String>('route_id')!;

    final manager = $$RouteTableTableTableManager(
      $_db,
      $_db.routeTable,
    ).filter((f) => f.routeId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_routeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CustomerTableTable _customerIdTable(_$AppDatabase db) =>
      db.customerTable.createAlias(
        $_aliasNameGenerator(
          db.routeStopTable.customerId,
          db.customerTable.customerId,
        ),
      );

  $$CustomerTableTableProcessedTableManager get customerId {
    final $_column = $_itemColumn<String>('customer_id')!;

    final manager = $$CustomerTableTableTableManager(
      $_db,
      $_db.customerTable,
    ).filter((f) => f.customerId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_customerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CustomerAddressTableTable _customerAddressIdTable(_$AppDatabase db) =>
      db.customerAddressTable.createAlias(
        $_aliasNameGenerator(
          db.routeStopTable.customerAddressId,
          db.customerAddressTable.addressId,
        ),
      );

  $$CustomerAddressTableTableProcessedTableManager? get customerAddressId {
    final $_column = $_itemColumn<String>('customer_address_id');
    if ($_column == null) return null;
    final manager = $$CustomerAddressTableTableTableManager(
      $_db,
      $_db.customerAddressTable,
    ).filter((f) => f.addressId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_customerAddressIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$VisitTableTable, List<VisitTableData>>
  _visitTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.visitTable,
    aliasName: $_aliasNameGenerator(
      db.routeStopTable.routeStopId,
      db.visitTable.routeStopId,
    ),
  );

  $$VisitTableTableProcessedTableManager get visitTableRefs {
    final manager = $$VisitTableTableTableManager($_db, $_db.visitTable).filter(
      (f) => f.routeStopId.routeStopId.sqlEquals(
        $_itemColumn<String>('route_stop_id')!,
      ),
    );

    final cache = $_typedResult.readTableOrNull(_visitTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RouteStopTableTableFilterComposer
    extends Composer<_$AppDatabase, $RouteStopTableTable> {
  $$RouteStopTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routeStopId => $composableBuilder(
    column: $table.routeStopId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get visitedAt => $composableBuilder(
    column: $table.visitedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scheduledTime => $composableBuilder(
    column: $table.scheduledTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rescheduledFromStopId => $composableBuilder(
    column: $table.rescheduledFromStopId,
    builder: (column) => ColumnFilters(column),
  );

  $$RouteTableTableFilterComposer get routeId {
    final $$RouteTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routeId,
      referencedTable: $db.routeTable,
      getReferencedColumn: (t) => t.routeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RouteTableTableFilterComposer(
            $db: $db,
            $table: $db.routeTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CustomerTableTableFilterComposer get customerId {
    final $$CustomerTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customerTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomerTableTableFilterComposer(
            $db: $db,
            $table: $db.customerTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CustomerAddressTableTableFilterComposer get customerAddressId {
    final $$CustomerAddressTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerAddressId,
      referencedTable: $db.customerAddressTable,
      getReferencedColumn: (t) => t.addressId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomerAddressTableTableFilterComposer(
            $db: $db,
            $table: $db.customerAddressTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> visitTableRefs(
    Expression<bool> Function($$VisitTableTableFilterComposer f) f,
  ) {
    final $$VisitTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routeStopId,
      referencedTable: $db.visitTable,
      getReferencedColumn: (t) => t.routeStopId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitTableTableFilterComposer(
            $db: $db,
            $table: $db.visitTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RouteStopTableTableOrderingComposer
    extends Composer<_$AppDatabase, $RouteStopTableTable> {
  $$RouteStopTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routeStopId => $composableBuilder(
    column: $table.routeStopId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get visitedAt => $composableBuilder(
    column: $table.visitedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scheduledTime => $composableBuilder(
    column: $table.scheduledTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rescheduledFromStopId => $composableBuilder(
    column: $table.rescheduledFromStopId,
    builder: (column) => ColumnOrderings(column),
  );

  $$RouteTableTableOrderingComposer get routeId {
    final $$RouteTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routeId,
      referencedTable: $db.routeTable,
      getReferencedColumn: (t) => t.routeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RouteTableTableOrderingComposer(
            $db: $db,
            $table: $db.routeTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CustomerTableTableOrderingComposer get customerId {
    final $$CustomerTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customerTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomerTableTableOrderingComposer(
            $db: $db,
            $table: $db.customerTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CustomerAddressTableTableOrderingComposer get customerAddressId {
    final $$CustomerAddressTableTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.customerAddressId,
          referencedTable: $db.customerAddressTable,
          getReferencedColumn: (t) => t.addressId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CustomerAddressTableTableOrderingComposer(
                $db: $db,
                $table: $db.customerAddressTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$RouteStopTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $RouteStopTableTable> {
  $$RouteStopTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get routeStopId => $composableBuilder(
    column: $table.routeStopId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get visitedAt =>
      $composableBuilder(column: $table.visitedAt, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get scheduledTime => $composableBuilder(
    column: $table.scheduledTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rescheduledFromStopId => $composableBuilder(
    column: $table.rescheduledFromStopId,
    builder: (column) => column,
  );

  $$RouteTableTableAnnotationComposer get routeId {
    final $$RouteTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routeId,
      referencedTable: $db.routeTable,
      getReferencedColumn: (t) => t.routeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RouteTableTableAnnotationComposer(
            $db: $db,
            $table: $db.routeTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CustomerTableTableAnnotationComposer get customerId {
    final $$CustomerTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customerTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomerTableTableAnnotationComposer(
            $db: $db,
            $table: $db.customerTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CustomerAddressTableTableAnnotationComposer get customerAddressId {
    final $$CustomerAddressTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.customerAddressId,
          referencedTable: $db.customerAddressTable,
          getReferencedColumn: (t) => t.addressId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CustomerAddressTableTableAnnotationComposer(
                $db: $db,
                $table: $db.customerAddressTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> visitTableRefs<T extends Object>(
    Expression<T> Function($$VisitTableTableAnnotationComposer a) f,
  ) {
    final $$VisitTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routeStopId,
      referencedTable: $db.visitTable,
      getReferencedColumn: (t) => t.routeStopId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitTableTableAnnotationComposer(
            $db: $db,
            $table: $db.visitTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RouteStopTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RouteStopTableTable,
          RouteStopTableData,
          $$RouteStopTableTableFilterComposer,
          $$RouteStopTableTableOrderingComposer,
          $$RouteStopTableTableAnnotationComposer,
          $$RouteStopTableTableCreateCompanionBuilder,
          $$RouteStopTableTableUpdateCompanionBuilder,
          (RouteStopTableData, $$RouteStopTableTableReferences),
          RouteStopTableData,
          PrefetchHooks Function({
            bool routeId,
            bool customerId,
            bool customerAddressId,
            bool visitTableRefs,
          })
        > {
  $$RouteStopTableTableTableManager(
    _$AppDatabase db,
    $RouteStopTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RouteStopTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RouteStopTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RouteStopTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModifiedDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> routeStopId = const Value.absent(),
                Value<String> routeId = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<String?> customerAddressId = const Value.absent(),
                Value<int> sequence = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> scheduledAt = const Value.absent(),
                Value<DateTime?> visitedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> scheduledTime = const Value.absent(),
                Value<String?> rescheduledFromStopId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RouteStopTableCompanion(
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
                enabled: enabled,
                serverId: serverId,
                routeStopId: routeStopId,
                routeId: routeId,
                customerId: customerId,
                customerAddressId: customerAddressId,
                sequence: sequence,
                status: status,
                scheduledAt: scheduledAt,
                visitedAt: visitedAt,
                notes: notes,
                scheduledTime: scheduledTime,
                rescheduledFromStopId: rescheduledFromStopId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModifiedDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> routeStopId = const Value.absent(),
                required String routeId,
                required String customerId,
                Value<String?> customerAddressId = const Value.absent(),
                required int sequence,
                Value<String> status = const Value.absent(),
                required DateTime scheduledAt,
                Value<DateTime?> visitedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> scheduledTime = const Value.absent(),
                Value<String?> rescheduledFromStopId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RouteStopTableCompanion.insert(
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
                enabled: enabled,
                serverId: serverId,
                routeStopId: routeStopId,
                routeId: routeId,
                customerId: customerId,
                customerAddressId: customerAddressId,
                sequence: sequence,
                status: status,
                scheduledAt: scheduledAt,
                visitedAt: visitedAt,
                notes: notes,
                scheduledTime: scheduledTime,
                rescheduledFromStopId: rescheduledFromStopId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RouteStopTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                routeId = false,
                customerId = false,
                customerAddressId = false,
                visitTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (visitTableRefs) db.visitTable],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (routeId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.routeId,
                                    referencedTable:
                                        $$RouteStopTableTableReferences
                                            ._routeIdTable(db),
                                    referencedColumn:
                                        $$RouteStopTableTableReferences
                                            ._routeIdTable(db)
                                            .routeId,
                                  )
                                  as T;
                        }
                        if (customerId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.customerId,
                                    referencedTable:
                                        $$RouteStopTableTableReferences
                                            ._customerIdTable(db),
                                    referencedColumn:
                                        $$RouteStopTableTableReferences
                                            ._customerIdTable(db)
                                            .customerId,
                                  )
                                  as T;
                        }
                        if (customerAddressId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.customerAddressId,
                                    referencedTable:
                                        $$RouteStopTableTableReferences
                                            ._customerAddressIdTable(db),
                                    referencedColumn:
                                        $$RouteStopTableTableReferences
                                            ._customerAddressIdTable(db)
                                            .addressId,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (visitTableRefs)
                        await $_getPrefetchedData<
                          RouteStopTableData,
                          $RouteStopTableTable,
                          VisitTableData
                        >(
                          currentTable: table,
                          referencedTable: $$RouteStopTableTableReferences
                              ._visitTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RouteStopTableTableReferences(
                                db,
                                table,
                                p0,
                              ).visitTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.routeStopId == item.routeStopId,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$RouteStopTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RouteStopTableTable,
      RouteStopTableData,
      $$RouteStopTableTableFilterComposer,
      $$RouteStopTableTableOrderingComposer,
      $$RouteStopTableTableAnnotationComposer,
      $$RouteStopTableTableCreateCompanionBuilder,
      $$RouteStopTableTableUpdateCompanionBuilder,
      (RouteStopTableData, $$RouteStopTableTableReferences),
      RouteStopTableData,
      PrefetchHooks Function({
        bool routeId,
        bool customerId,
        bool customerAddressId,
        bool visitTableRefs,
      })
    >;
typedef $$ProductTableTableCreateCompanionBuilder =
    ProductTableCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
      Value<bool> enabled,
      Value<int?> serverId,
      Value<String> productId,
      required String name,
      Value<String?> description,
      required double price,
      Value<int> stock,
      Value<int> rowid,
    });
typedef $$ProductTableTableUpdateCompanionBuilder =
    ProductTableCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
      Value<bool> enabled,
      Value<int?> serverId,
      Value<String> productId,
      Value<String> name,
      Value<String?> description,
      Value<double> price,
      Value<int> stock,
      Value<int> rowid,
    });

final class $$ProductTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $ProductTableTable, ProductTableData> {
  $$ProductTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $RouteInventoryTableTable,
    List<RouteInventoryTableData>
  >
  _routeInventoryTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.routeInventoryTable,
        aliasName: $_aliasNameGenerator(
          db.productTable.productId,
          db.routeInventoryTable.productId,
        ),
      );

  $$RouteInventoryTableTableProcessedTableManager get routeInventoryTableRefs {
    final manager =
        $$RouteInventoryTableTableTableManager(
          $_db,
          $_db.routeInventoryTable,
        ).filter(
          (f) => f.productId.productId.sqlEquals(
            $_itemColumn<String>('product_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _routeInventoryTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SaleItemTableTable, List<SaleItemTableData>>
  _saleItemTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.saleItemTable,
    aliasName: $_aliasNameGenerator(
      db.productTable.productId,
      db.saleItemTable.productId,
    ),
  );

  $$SaleItemTableTableProcessedTableManager get saleItemTableRefs {
    final manager = $$SaleItemTableTableTableManager($_db, $_db.saleItemTable)
        .filter(
          (f) => f.productId.productId.sqlEquals(
            $_itemColumn<String>('product_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_saleItemTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $RouteInventoryLoadTableTable,
    List<RouteInventoryLoadTableData>
  >
  _routeInventoryLoadTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.routeInventoryLoadTable,
        aliasName: $_aliasNameGenerator(
          db.productTable.productId,
          db.routeInventoryLoadTable.productId,
        ),
      );

  $$RouteInventoryLoadTableTableProcessedTableManager
  get routeInventoryLoadTableRefs {
    final manager =
        $$RouteInventoryLoadTableTableTableManager(
          $_db,
          $_db.routeInventoryLoadTable,
        ).filter(
          (f) => f.productId.productId.sqlEquals(
            $_itemColumn<String>('product_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _routeInventoryLoadTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $CustomerAgreementTableTable,
    List<CustomerAgreementTableData>
  >
  _customerAgreementTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.customerAgreementTable,
        aliasName: $_aliasNameGenerator(
          db.productTable.productId,
          db.customerAgreementTable.productId,
        ),
      );

  $$CustomerAgreementTableTableProcessedTableManager
  get customerAgreementTableRefs {
    final manager =
        $$CustomerAgreementTableTableTableManager(
          $_db,
          $_db.customerAgreementTable,
        ).filter(
          (f) => f.productId.productId.sqlEquals(
            $_itemColumn<String>('product_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _customerAgreementTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProductTableTableFilterComposer
    extends Composer<_$AppDatabase, $ProductTableTable> {
  $$ProductTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stock => $composableBuilder(
    column: $table.stock,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> routeInventoryTableRefs(
    Expression<bool> Function($$RouteInventoryTableTableFilterComposer f) f,
  ) {
    final $$RouteInventoryTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.routeInventoryTable,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RouteInventoryTableTableFilterComposer(
            $db: $db,
            $table: $db.routeInventoryTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> saleItemTableRefs(
    Expression<bool> Function($$SaleItemTableTableFilterComposer f) f,
  ) {
    final $$SaleItemTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.saleItemTable,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleItemTableTableFilterComposer(
            $db: $db,
            $table: $db.saleItemTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> routeInventoryLoadTableRefs(
    Expression<bool> Function($$RouteInventoryLoadTableTableFilterComposer f) f,
  ) {
    final $$RouteInventoryLoadTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.productId,
          referencedTable: $db.routeInventoryLoadTable,
          getReferencedColumn: (t) => t.productId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RouteInventoryLoadTableTableFilterComposer(
                $db: $db,
                $table: $db.routeInventoryLoadTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> customerAgreementTableRefs(
    Expression<bool> Function($$CustomerAgreementTableTableFilterComposer f) f,
  ) {
    final $$CustomerAgreementTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.productId,
          referencedTable: $db.customerAgreementTable,
          getReferencedColumn: (t) => t.productId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CustomerAgreementTableTableFilterComposer(
                $db: $db,
                $table: $db.customerAgreementTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ProductTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductTableTable> {
  $$ProductTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stock => $composableBuilder(
    column: $table.stock,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductTableTable> {
  $$ProductTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<int> get stock =>
      $composableBuilder(column: $table.stock, builder: (column) => column);

  Expression<T> routeInventoryTableRefs<T extends Object>(
    Expression<T> Function($$RouteInventoryTableTableAnnotationComposer a) f,
  ) {
    final $$RouteInventoryTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.productId,
          referencedTable: $db.routeInventoryTable,
          getReferencedColumn: (t) => t.productId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RouteInventoryTableTableAnnotationComposer(
                $db: $db,
                $table: $db.routeInventoryTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> saleItemTableRefs<T extends Object>(
    Expression<T> Function($$SaleItemTableTableAnnotationComposer a) f,
  ) {
    final $$SaleItemTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.saleItemTable,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleItemTableTableAnnotationComposer(
            $db: $db,
            $table: $db.saleItemTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> routeInventoryLoadTableRefs<T extends Object>(
    Expression<T> Function($$RouteInventoryLoadTableTableAnnotationComposer a)
    f,
  ) {
    final $$RouteInventoryLoadTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.productId,
          referencedTable: $db.routeInventoryLoadTable,
          getReferencedColumn: (t) => t.productId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RouteInventoryLoadTableTableAnnotationComposer(
                $db: $db,
                $table: $db.routeInventoryLoadTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> customerAgreementTableRefs<T extends Object>(
    Expression<T> Function($$CustomerAgreementTableTableAnnotationComposer a) f,
  ) {
    final $$CustomerAgreementTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.productId,
          referencedTable: $db.customerAgreementTable,
          getReferencedColumn: (t) => t.productId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CustomerAgreementTableTableAnnotationComposer(
                $db: $db,
                $table: $db.customerAgreementTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ProductTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductTableTable,
          ProductTableData,
          $$ProductTableTableFilterComposer,
          $$ProductTableTableOrderingComposer,
          $$ProductTableTableAnnotationComposer,
          $$ProductTableTableCreateCompanionBuilder,
          $$ProductTableTableUpdateCompanionBuilder,
          (ProductTableData, $$ProductTableTableReferences),
          ProductTableData,
          PrefetchHooks Function({
            bool routeInventoryTableRefs,
            bool saleItemTableRefs,
            bool routeInventoryLoadTableRefs,
            bool customerAgreementTableRefs,
          })
        > {
  $$ProductTableTableTableManager(_$AppDatabase db, $ProductTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModifiedDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<double> price = const Value.absent(),
                Value<int> stock = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductTableCompanion(
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
                enabled: enabled,
                serverId: serverId,
                productId: productId,
                name: name,
                description: description,
                price: price,
                stock: stock,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModifiedDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                required String name,
                Value<String?> description = const Value.absent(),
                required double price,
                Value<int> stock = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductTableCompanion.insert(
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
                enabled: enabled,
                serverId: serverId,
                productId: productId,
                name: name,
                description: description,
                price: price,
                stock: stock,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProductTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                routeInventoryTableRefs = false,
                saleItemTableRefs = false,
                routeInventoryLoadTableRefs = false,
                customerAgreementTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (routeInventoryTableRefs) db.routeInventoryTable,
                    if (saleItemTableRefs) db.saleItemTable,
                    if (routeInventoryLoadTableRefs) db.routeInventoryLoadTable,
                    if (customerAgreementTableRefs) db.customerAgreementTable,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (routeInventoryTableRefs)
                        await $_getPrefetchedData<
                          ProductTableData,
                          $ProductTableTable,
                          RouteInventoryTableData
                        >(
                          currentTable: table,
                          referencedTable: $$ProductTableTableReferences
                              ._routeInventoryTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductTableTableReferences(
                                db,
                                table,
                                p0,
                              ).routeInventoryTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.productId == item.productId,
                              ),
                          typedResults: items,
                        ),
                      if (saleItemTableRefs)
                        await $_getPrefetchedData<
                          ProductTableData,
                          $ProductTableTable,
                          SaleItemTableData
                        >(
                          currentTable: table,
                          referencedTable: $$ProductTableTableReferences
                              ._saleItemTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductTableTableReferences(
                                db,
                                table,
                                p0,
                              ).saleItemTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.productId == item.productId,
                              ),
                          typedResults: items,
                        ),
                      if (routeInventoryLoadTableRefs)
                        await $_getPrefetchedData<
                          ProductTableData,
                          $ProductTableTable,
                          RouteInventoryLoadTableData
                        >(
                          currentTable: table,
                          referencedTable: $$ProductTableTableReferences
                              ._routeInventoryLoadTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductTableTableReferences(
                                db,
                                table,
                                p0,
                              ).routeInventoryLoadTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.productId == item.productId,
                              ),
                          typedResults: items,
                        ),
                      if (customerAgreementTableRefs)
                        await $_getPrefetchedData<
                          ProductTableData,
                          $ProductTableTable,
                          CustomerAgreementTableData
                        >(
                          currentTable: table,
                          referencedTable: $$ProductTableTableReferences
                              ._customerAgreementTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductTableTableReferences(
                                db,
                                table,
                                p0,
                              ).customerAgreementTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.productId == item.productId,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ProductTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductTableTable,
      ProductTableData,
      $$ProductTableTableFilterComposer,
      $$ProductTableTableOrderingComposer,
      $$ProductTableTableAnnotationComposer,
      $$ProductTableTableCreateCompanionBuilder,
      $$ProductTableTableUpdateCompanionBuilder,
      (ProductTableData, $$ProductTableTableReferences),
      ProductTableData,
      PrefetchHooks Function({
        bool routeInventoryTableRefs,
        bool saleItemTableRefs,
        bool routeInventoryLoadTableRefs,
        bool customerAgreementTableRefs,
      })
    >;
typedef $$RouteInventoryTableTableCreateCompanionBuilder =
    RouteInventoryTableCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
      Value<bool> enabled,
      Value<int?> serverId,
      Value<String> inventoryMovementId,
      required String productId,
      required String movementType,
      required int quantity,
      required String reason,
      Value<DateTime> movementDate,
      Value<String?> notes,
      Value<int> rowid,
    });
typedef $$RouteInventoryTableTableUpdateCompanionBuilder =
    RouteInventoryTableCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
      Value<bool> enabled,
      Value<int?> serverId,
      Value<String> inventoryMovementId,
      Value<String> productId,
      Value<String> movementType,
      Value<int> quantity,
      Value<String> reason,
      Value<DateTime> movementDate,
      Value<String?> notes,
      Value<int> rowid,
    });

final class $$RouteInventoryTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $RouteInventoryTableTable,
          RouteInventoryTableData
        > {
  $$RouteInventoryTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProductTableTable _productIdTable(_$AppDatabase db) =>
      db.productTable.createAlias(
        $_aliasNameGenerator(
          db.routeInventoryTable.productId,
          db.productTable.productId,
        ),
      );

  $$ProductTableTableProcessedTableManager get productId {
    final $_column = $_itemColumn<String>('product_id')!;

    final manager = $$ProductTableTableTableManager(
      $_db,
      $_db.productTable,
    ).filter((f) => f.productId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RouteInventoryTableTableFilterComposer
    extends Composer<_$AppDatabase, $RouteInventoryTableTable> {
  $$RouteInventoryTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inventoryMovementId => $composableBuilder(
    column: $table.inventoryMovementId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get movementType => $composableBuilder(
    column: $table.movementType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get movementDate => $composableBuilder(
    column: $table.movementDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  $$ProductTableTableFilterComposer get productId {
    final $$ProductTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.productTable,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductTableTableFilterComposer(
            $db: $db,
            $table: $db.productTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RouteInventoryTableTableOrderingComposer
    extends Composer<_$AppDatabase, $RouteInventoryTableTable> {
  $$RouteInventoryTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inventoryMovementId => $composableBuilder(
    column: $table.inventoryMovementId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get movementType => $composableBuilder(
    column: $table.movementType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get movementDate => $composableBuilder(
    column: $table.movementDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProductTableTableOrderingComposer get productId {
    final $$ProductTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.productTable,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductTableTableOrderingComposer(
            $db: $db,
            $table: $db.productTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RouteInventoryTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $RouteInventoryTableTable> {
  $$RouteInventoryTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get inventoryMovementId => $composableBuilder(
    column: $table.inventoryMovementId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get movementType => $composableBuilder(
    column: $table.movementType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<DateTime> get movementDate => $composableBuilder(
    column: $table.movementDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $$ProductTableTableAnnotationComposer get productId {
    final $$ProductTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.productTable,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductTableTableAnnotationComposer(
            $db: $db,
            $table: $db.productTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RouteInventoryTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RouteInventoryTableTable,
          RouteInventoryTableData,
          $$RouteInventoryTableTableFilterComposer,
          $$RouteInventoryTableTableOrderingComposer,
          $$RouteInventoryTableTableAnnotationComposer,
          $$RouteInventoryTableTableCreateCompanionBuilder,
          $$RouteInventoryTableTableUpdateCompanionBuilder,
          (RouteInventoryTableData, $$RouteInventoryTableTableReferences),
          RouteInventoryTableData,
          PrefetchHooks Function({bool productId})
        > {
  $$RouteInventoryTableTableTableManager(
    _$AppDatabase db,
    $RouteInventoryTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RouteInventoryTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RouteInventoryTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RouteInventoryTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModifiedDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> inventoryMovementId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> movementType = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<DateTime> movementDate = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RouteInventoryTableCompanion(
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
                enabled: enabled,
                serverId: serverId,
                inventoryMovementId: inventoryMovementId,
                productId: productId,
                movementType: movementType,
                quantity: quantity,
                reason: reason,
                movementDate: movementDate,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModifiedDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> inventoryMovementId = const Value.absent(),
                required String productId,
                required String movementType,
                required int quantity,
                required String reason,
                Value<DateTime> movementDate = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RouteInventoryTableCompanion.insert(
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
                enabled: enabled,
                serverId: serverId,
                inventoryMovementId: inventoryMovementId,
                productId: productId,
                movementType: movementType,
                quantity: quantity,
                reason: reason,
                movementDate: movementDate,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RouteInventoryTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({productId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (productId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.productId,
                                referencedTable:
                                    $$RouteInventoryTableTableReferences
                                        ._productIdTable(db),
                                referencedColumn:
                                    $$RouteInventoryTableTableReferences
                                        ._productIdTable(db)
                                        .productId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RouteInventoryTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RouteInventoryTableTable,
      RouteInventoryTableData,
      $$RouteInventoryTableTableFilterComposer,
      $$RouteInventoryTableTableOrderingComposer,
      $$RouteInventoryTableTableAnnotationComposer,
      $$RouteInventoryTableTableCreateCompanionBuilder,
      $$RouteInventoryTableTableUpdateCompanionBuilder,
      (RouteInventoryTableData, $$RouteInventoryTableTableReferences),
      RouteInventoryTableData,
      PrefetchHooks Function({bool productId})
    >;
typedef $$VisitOutcomeTableTableCreateCompanionBuilder =
    VisitOutcomeTableCompanion Function({
      Value<int> id,
      Value<String?> code,
      required String name,
      Value<bool> triggersReschedule,
      Value<bool> enabled,
    });
typedef $$VisitOutcomeTableTableUpdateCompanionBuilder =
    VisitOutcomeTableCompanion Function({
      Value<int> id,
      Value<String?> code,
      Value<String> name,
      Value<bool> triggersReschedule,
      Value<bool> enabled,
    });

final class $$VisitOutcomeTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $VisitOutcomeTableTable,
          VisitOutcomeTableData
        > {
  $$VisitOutcomeTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$VisitTableTable, List<VisitTableData>>
  _visitTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.visitTable,
    aliasName: $_aliasNameGenerator(
      db.visitOutcomeTable.id,
      db.visitTable.outcomeId,
    ),
  );

  $$VisitTableTableProcessedTableManager get visitTableRefs {
    final manager = $$VisitTableTableTableManager(
      $_db,
      $_db.visitTable,
    ).filter((f) => f.outcomeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_visitTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$VisitOutcomeTableTableFilterComposer
    extends Composer<_$AppDatabase, $VisitOutcomeTableTable> {
  $$VisitOutcomeTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get triggersReschedule => $composableBuilder(
    column: $table.triggersReschedule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> visitTableRefs(
    Expression<bool> Function($$VisitTableTableFilterComposer f) f,
  ) {
    final $$VisitTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.visitTable,
      getReferencedColumn: (t) => t.outcomeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitTableTableFilterComposer(
            $db: $db,
            $table: $db.visitTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VisitOutcomeTableTableOrderingComposer
    extends Composer<_$AppDatabase, $VisitOutcomeTableTable> {
  $$VisitOutcomeTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get triggersReschedule => $composableBuilder(
    column: $table.triggersReschedule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VisitOutcomeTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $VisitOutcomeTableTable> {
  $$VisitOutcomeTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get triggersReschedule => $composableBuilder(
    column: $table.triggersReschedule,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  Expression<T> visitTableRefs<T extends Object>(
    Expression<T> Function($$VisitTableTableAnnotationComposer a) f,
  ) {
    final $$VisitTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.visitTable,
      getReferencedColumn: (t) => t.outcomeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitTableTableAnnotationComposer(
            $db: $db,
            $table: $db.visitTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VisitOutcomeTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VisitOutcomeTableTable,
          VisitOutcomeTableData,
          $$VisitOutcomeTableTableFilterComposer,
          $$VisitOutcomeTableTableOrderingComposer,
          $$VisitOutcomeTableTableAnnotationComposer,
          $$VisitOutcomeTableTableCreateCompanionBuilder,
          $$VisitOutcomeTableTableUpdateCompanionBuilder,
          (VisitOutcomeTableData, $$VisitOutcomeTableTableReferences),
          VisitOutcomeTableData,
          PrefetchHooks Function({bool visitTableRefs})
        > {
  $$VisitOutcomeTableTableTableManager(
    _$AppDatabase db,
    $VisitOutcomeTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VisitOutcomeTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VisitOutcomeTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VisitOutcomeTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> triggersReschedule = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
              }) => VisitOutcomeTableCompanion(
                id: id,
                code: code,
                name: name,
                triggersReschedule: triggersReschedule,
                enabled: enabled,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> code = const Value.absent(),
                required String name,
                Value<bool> triggersReschedule = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
              }) => VisitOutcomeTableCompanion.insert(
                id: id,
                code: code,
                name: name,
                triggersReschedule: triggersReschedule,
                enabled: enabled,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$VisitOutcomeTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({visitTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (visitTableRefs) db.visitTable],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (visitTableRefs)
                    await $_getPrefetchedData<
                      VisitOutcomeTableData,
                      $VisitOutcomeTableTable,
                      VisitTableData
                    >(
                      currentTable: table,
                      referencedTable: $$VisitOutcomeTableTableReferences
                          ._visitTableRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$VisitOutcomeTableTableReferences(
                            db,
                            table,
                            p0,
                          ).visitTableRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.outcomeId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$VisitOutcomeTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VisitOutcomeTableTable,
      VisitOutcomeTableData,
      $$VisitOutcomeTableTableFilterComposer,
      $$VisitOutcomeTableTableOrderingComposer,
      $$VisitOutcomeTableTableAnnotationComposer,
      $$VisitOutcomeTableTableCreateCompanionBuilder,
      $$VisitOutcomeTableTableUpdateCompanionBuilder,
      (VisitOutcomeTableData, $$VisitOutcomeTableTableReferences),
      VisitOutcomeTableData,
      PrefetchHooks Function({bool visitTableRefs})
    >;
typedef $$VisitTableTableCreateCompanionBuilder =
    VisitTableCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
      Value<bool> enabled,
      Value<int?> serverId,
      Value<String> visitId,
      required String routeStopId,
      required String customerId,
      required String visitType,
      Value<int?> outcomeId,
      required DateTime arrived_at,
      Value<String?> observations,
      Value<double> amountCollected,
      Value<int> rowid,
    });
typedef $$VisitTableTableUpdateCompanionBuilder =
    VisitTableCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
      Value<bool> enabled,
      Value<int?> serverId,
      Value<String> visitId,
      Value<String> routeStopId,
      Value<String> customerId,
      Value<String> visitType,
      Value<int?> outcomeId,
      Value<DateTime> arrived_at,
      Value<String?> observations,
      Value<double> amountCollected,
      Value<int> rowid,
    });

final class $$VisitTableTableReferences
    extends BaseReferences<_$AppDatabase, $VisitTableTable, VisitTableData> {
  $$VisitTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RouteStopTableTable _routeStopIdTable(_$AppDatabase db) =>
      db.routeStopTable.createAlias(
        $_aliasNameGenerator(
          db.visitTable.routeStopId,
          db.routeStopTable.routeStopId,
        ),
      );

  $$RouteStopTableTableProcessedTableManager get routeStopId {
    final $_column = $_itemColumn<String>('route_stop_id')!;

    final manager = $$RouteStopTableTableTableManager(
      $_db,
      $_db.routeStopTable,
    ).filter((f) => f.routeStopId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_routeStopIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CustomerTableTable _customerIdTable(_$AppDatabase db) =>
      db.customerTable.createAlias(
        $_aliasNameGenerator(
          db.visitTable.customerId,
          db.customerTable.customerId,
        ),
      );

  $$CustomerTableTableProcessedTableManager get customerId {
    final $_column = $_itemColumn<String>('customer_id')!;

    final manager = $$CustomerTableTableTableManager(
      $_db,
      $_db.customerTable,
    ).filter((f) => f.customerId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_customerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $VisitOutcomeTableTable _outcomeIdTable(_$AppDatabase db) =>
      db.visitOutcomeTable.createAlias(
        $_aliasNameGenerator(db.visitTable.outcomeId, db.visitOutcomeTable.id),
      );

  $$VisitOutcomeTableTableProcessedTableManager? get outcomeId {
    final $_column = $_itemColumn<int>('outcome_id');
    if ($_column == null) return null;
    final manager = $$VisitOutcomeTableTableTableManager(
      $_db,
      $_db.visitOutcomeTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_outcomeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PaymentTableTable, List<PaymentTableData>>
  _paymentTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.paymentTable,
    aliasName: $_aliasNameGenerator(
      db.visitTable.visitId,
      db.paymentTable.visitId,
    ),
  );

  $$PaymentTableTableProcessedTableManager get paymentTableRefs {
    final manager = $$PaymentTableTableTableManager($_db, $_db.paymentTable)
        .filter(
          (f) => f.visitId.visitId.sqlEquals($_itemColumn<String>('visit_id')!),
        );

    final cache = $_typedResult.readTableOrNull(_paymentTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ContainerMovementTableTable,
    List<ContainerMovementTableData>
  >
  _containerMovementTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.containerMovementTable,
        aliasName: $_aliasNameGenerator(
          db.visitTable.visitId,
          db.containerMovementTable.visitId,
        ),
      );

  $$ContainerMovementTableTableProcessedTableManager
  get containerMovementTableRefs {
    final manager =
        $$ContainerMovementTableTableTableManager(
          $_db,
          $_db.containerMovementTable,
        ).filter(
          (f) => f.visitId.visitId.sqlEquals($_itemColumn<String>('visit_id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _containerMovementTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$VisitTableTableFilterComposer
    extends Composer<_$AppDatabase, $VisitTableTable> {
  $$VisitTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visitId => $composableBuilder(
    column: $table.visitId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visitType => $composableBuilder(
    column: $table.visitType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get arrived_at => $composableBuilder(
    column: $table.arrived_at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get observations => $composableBuilder(
    column: $table.observations,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amountCollected => $composableBuilder(
    column: $table.amountCollected,
    builder: (column) => ColumnFilters(column),
  );

  $$RouteStopTableTableFilterComposer get routeStopId {
    final $$RouteStopTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routeStopId,
      referencedTable: $db.routeStopTable,
      getReferencedColumn: (t) => t.routeStopId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RouteStopTableTableFilterComposer(
            $db: $db,
            $table: $db.routeStopTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CustomerTableTableFilterComposer get customerId {
    final $$CustomerTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customerTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomerTableTableFilterComposer(
            $db: $db,
            $table: $db.customerTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VisitOutcomeTableTableFilterComposer get outcomeId {
    final $$VisitOutcomeTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.outcomeId,
      referencedTable: $db.visitOutcomeTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitOutcomeTableTableFilterComposer(
            $db: $db,
            $table: $db.visitOutcomeTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> paymentTableRefs(
    Expression<bool> Function($$PaymentTableTableFilterComposer f) f,
  ) {
    final $$PaymentTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.paymentTable,
      getReferencedColumn: (t) => t.visitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentTableTableFilterComposer(
            $db: $db,
            $table: $db.paymentTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> containerMovementTableRefs(
    Expression<bool> Function($$ContainerMovementTableTableFilterComposer f) f,
  ) {
    final $$ContainerMovementTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.visitId,
          referencedTable: $db.containerMovementTable,
          getReferencedColumn: (t) => t.visitId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContainerMovementTableTableFilterComposer(
                $db: $db,
                $table: $db.containerMovementTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$VisitTableTableOrderingComposer
    extends Composer<_$AppDatabase, $VisitTableTable> {
  $$VisitTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visitId => $composableBuilder(
    column: $table.visitId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visitType => $composableBuilder(
    column: $table.visitType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get arrived_at => $composableBuilder(
    column: $table.arrived_at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get observations => $composableBuilder(
    column: $table.observations,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amountCollected => $composableBuilder(
    column: $table.amountCollected,
    builder: (column) => ColumnOrderings(column),
  );

  $$RouteStopTableTableOrderingComposer get routeStopId {
    final $$RouteStopTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routeStopId,
      referencedTable: $db.routeStopTable,
      getReferencedColumn: (t) => t.routeStopId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RouteStopTableTableOrderingComposer(
            $db: $db,
            $table: $db.routeStopTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CustomerTableTableOrderingComposer get customerId {
    final $$CustomerTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customerTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomerTableTableOrderingComposer(
            $db: $db,
            $table: $db.customerTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VisitOutcomeTableTableOrderingComposer get outcomeId {
    final $$VisitOutcomeTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.outcomeId,
      referencedTable: $db.visitOutcomeTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitOutcomeTableTableOrderingComposer(
            $db: $db,
            $table: $db.visitOutcomeTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VisitTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $VisitTableTable> {
  $$VisitTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get visitId =>
      $composableBuilder(column: $table.visitId, builder: (column) => column);

  GeneratedColumn<String> get visitType =>
      $composableBuilder(column: $table.visitType, builder: (column) => column);

  GeneratedColumn<DateTime> get arrived_at => $composableBuilder(
    column: $table.arrived_at,
    builder: (column) => column,
  );

  GeneratedColumn<String> get observations => $composableBuilder(
    column: $table.observations,
    builder: (column) => column,
  );

  GeneratedColumn<double> get amountCollected => $composableBuilder(
    column: $table.amountCollected,
    builder: (column) => column,
  );

  $$RouteStopTableTableAnnotationComposer get routeStopId {
    final $$RouteStopTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routeStopId,
      referencedTable: $db.routeStopTable,
      getReferencedColumn: (t) => t.routeStopId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RouteStopTableTableAnnotationComposer(
            $db: $db,
            $table: $db.routeStopTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CustomerTableTableAnnotationComposer get customerId {
    final $$CustomerTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customerTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomerTableTableAnnotationComposer(
            $db: $db,
            $table: $db.customerTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VisitOutcomeTableTableAnnotationComposer get outcomeId {
    final $$VisitOutcomeTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.outcomeId,
          referencedTable: $db.visitOutcomeTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$VisitOutcomeTableTableAnnotationComposer(
                $db: $db,
                $table: $db.visitOutcomeTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> paymentTableRefs<T extends Object>(
    Expression<T> Function($$PaymentTableTableAnnotationComposer a) f,
  ) {
    final $$PaymentTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.paymentTable,
      getReferencedColumn: (t) => t.visitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentTableTableAnnotationComposer(
            $db: $db,
            $table: $db.paymentTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> containerMovementTableRefs<T extends Object>(
    Expression<T> Function($$ContainerMovementTableTableAnnotationComposer a) f,
  ) {
    final $$ContainerMovementTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.visitId,
          referencedTable: $db.containerMovementTable,
          getReferencedColumn: (t) => t.visitId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContainerMovementTableTableAnnotationComposer(
                $db: $db,
                $table: $db.containerMovementTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$VisitTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VisitTableTable,
          VisitTableData,
          $$VisitTableTableFilterComposer,
          $$VisitTableTableOrderingComposer,
          $$VisitTableTableAnnotationComposer,
          $$VisitTableTableCreateCompanionBuilder,
          $$VisitTableTableUpdateCompanionBuilder,
          (VisitTableData, $$VisitTableTableReferences),
          VisitTableData,
          PrefetchHooks Function({
            bool routeStopId,
            bool customerId,
            bool outcomeId,
            bool paymentTableRefs,
            bool containerMovementTableRefs,
          })
        > {
  $$VisitTableTableTableManager(_$AppDatabase db, $VisitTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VisitTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VisitTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VisitTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModifiedDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> visitId = const Value.absent(),
                Value<String> routeStopId = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<String> visitType = const Value.absent(),
                Value<int?> outcomeId = const Value.absent(),
                Value<DateTime> arrived_at = const Value.absent(),
                Value<String?> observations = const Value.absent(),
                Value<double> amountCollected = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VisitTableCompanion(
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
                enabled: enabled,
                serverId: serverId,
                visitId: visitId,
                routeStopId: routeStopId,
                customerId: customerId,
                visitType: visitType,
                outcomeId: outcomeId,
                arrived_at: arrived_at,
                observations: observations,
                amountCollected: amountCollected,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModifiedDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> visitId = const Value.absent(),
                required String routeStopId,
                required String customerId,
                required String visitType,
                Value<int?> outcomeId = const Value.absent(),
                required DateTime arrived_at,
                Value<String?> observations = const Value.absent(),
                Value<double> amountCollected = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VisitTableCompanion.insert(
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
                enabled: enabled,
                serverId: serverId,
                visitId: visitId,
                routeStopId: routeStopId,
                customerId: customerId,
                visitType: visitType,
                outcomeId: outcomeId,
                arrived_at: arrived_at,
                observations: observations,
                amountCollected: amountCollected,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$VisitTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                routeStopId = false,
                customerId = false,
                outcomeId = false,
                paymentTableRefs = false,
                containerMovementTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (paymentTableRefs) db.paymentTable,
                    if (containerMovementTableRefs) db.containerMovementTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (routeStopId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.routeStopId,
                                    referencedTable: $$VisitTableTableReferences
                                        ._routeStopIdTable(db),
                                    referencedColumn:
                                        $$VisitTableTableReferences
                                            ._routeStopIdTable(db)
                                            .routeStopId,
                                  )
                                  as T;
                        }
                        if (customerId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.customerId,
                                    referencedTable: $$VisitTableTableReferences
                                        ._customerIdTable(db),
                                    referencedColumn:
                                        $$VisitTableTableReferences
                                            ._customerIdTable(db)
                                            .customerId,
                                  )
                                  as T;
                        }
                        if (outcomeId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.outcomeId,
                                    referencedTable: $$VisitTableTableReferences
                                        ._outcomeIdTable(db),
                                    referencedColumn:
                                        $$VisitTableTableReferences
                                            ._outcomeIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (paymentTableRefs)
                        await $_getPrefetchedData<
                          VisitTableData,
                          $VisitTableTable,
                          PaymentTableData
                        >(
                          currentTable: table,
                          referencedTable: $$VisitTableTableReferences
                              ._paymentTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VisitTableTableReferences(
                                db,
                                table,
                                p0,
                              ).paymentTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.visitId == item.visitId,
                              ),
                          typedResults: items,
                        ),
                      if (containerMovementTableRefs)
                        await $_getPrefetchedData<
                          VisitTableData,
                          $VisitTableTable,
                          ContainerMovementTableData
                        >(
                          currentTable: table,
                          referencedTable: $$VisitTableTableReferences
                              ._containerMovementTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VisitTableTableReferences(
                                db,
                                table,
                                p0,
                              ).containerMovementTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.visitId == item.visitId,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$VisitTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VisitTableTable,
      VisitTableData,
      $$VisitTableTableFilterComposer,
      $$VisitTableTableOrderingComposer,
      $$VisitTableTableAnnotationComposer,
      $$VisitTableTableCreateCompanionBuilder,
      $$VisitTableTableUpdateCompanionBuilder,
      (VisitTableData, $$VisitTableTableReferences),
      VisitTableData,
      PrefetchHooks Function({
        bool routeStopId,
        bool customerId,
        bool outcomeId,
        bool paymentTableRefs,
        bool containerMovementTableRefs,
      })
    >;
typedef $$SaleTableTableCreateCompanionBuilder =
    SaleTableCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
      Value<bool> enabled,
      Value<int?> serverId,
      Value<String> saleId,
      required String customerId,
      required double totalAmount,
      required String paymentMethod,
      Value<DateTime> saleDate,
      required int quantity,
      required double shipping_amount,
      Value<String?> visitId,
      Value<double?> cashAmount,
      Value<double?> transferAmount,
      Value<int> rowid,
    });
typedef $$SaleTableTableUpdateCompanionBuilder =
    SaleTableCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
      Value<bool> enabled,
      Value<int?> serverId,
      Value<String> saleId,
      Value<String> customerId,
      Value<double> totalAmount,
      Value<String> paymentMethod,
      Value<DateTime> saleDate,
      Value<int> quantity,
      Value<double> shipping_amount,
      Value<String?> visitId,
      Value<double?> cashAmount,
      Value<double?> transferAmount,
      Value<int> rowid,
    });

final class $$SaleTableTableReferences
    extends BaseReferences<_$AppDatabase, $SaleTableTable, SaleTableData> {
  $$SaleTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CustomerTableTable _customerIdTable(_$AppDatabase db) =>
      db.customerTable.createAlias(
        $_aliasNameGenerator(
          db.saleTable.customerId,
          db.customerTable.customerId,
        ),
      );

  $$CustomerTableTableProcessedTableManager get customerId {
    final $_column = $_itemColumn<String>('customer_id')!;

    final manager = $$CustomerTableTableTableManager(
      $_db,
      $_db.customerTable,
    ).filter((f) => f.customerId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_customerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SaleItemTableTable, List<SaleItemTableData>>
  _saleItemTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.saleItemTable,
    aliasName: $_aliasNameGenerator(
      db.saleTable.saleId,
      db.saleItemTable.saleId,
    ),
  );

  $$SaleItemTableTableProcessedTableManager get saleItemTableRefs {
    final manager = $$SaleItemTableTableTableManager($_db, $_db.saleItemTable)
        .filter(
          (f) => f.saleId.saleId.sqlEquals($_itemColumn<String>('sale_id')!),
        );

    final cache = $_typedResult.readTableOrNull(_saleItemTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PaymentTableTable, List<PaymentTableData>>
  _paymentTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.paymentTable,
    aliasName: $_aliasNameGenerator(
      db.saleTable.saleId,
      db.paymentTable.saleId,
    ),
  );

  $$PaymentTableTableProcessedTableManager get paymentTableRefs {
    final manager = $$PaymentTableTableTableManager($_db, $_db.paymentTable)
        .filter(
          (f) => f.saleId.saleId.sqlEquals($_itemColumn<String>('sale_id')!),
        );

    final cache = $_typedResult.readTableOrNull(_paymentTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $CustomerAccountEntryTableTable,
    List<CustomerAccountEntryTableData>
  >
  _customerAccountEntryTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.customerAccountEntryTable,
        aliasName: $_aliasNameGenerator(
          db.saleTable.saleId,
          db.customerAccountEntryTable.saleId,
        ),
      );

  $$CustomerAccountEntryTableTableProcessedTableManager
  get customerAccountEntryTableRefs {
    final manager =
        $$CustomerAccountEntryTableTableTableManager(
          $_db,
          $_db.customerAccountEntryTable,
        ).filter(
          (f) => f.saleId.saleId.sqlEquals($_itemColumn<String>('sale_id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _customerAccountEntryTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SaleTableTableFilterComposer
    extends Composer<_$AppDatabase, $SaleTableTable> {
  $$SaleTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get saleId => $composableBuilder(
    column: $table.saleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get saleDate => $composableBuilder(
    column: $table.saleDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get shipping_amount => $composableBuilder(
    column: $table.shipping_amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visitId => $composableBuilder(
    column: $table.visitId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cashAmount => $composableBuilder(
    column: $table.cashAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get transferAmount => $composableBuilder(
    column: $table.transferAmount,
    builder: (column) => ColumnFilters(column),
  );

  $$CustomerTableTableFilterComposer get customerId {
    final $$CustomerTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customerTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomerTableTableFilterComposer(
            $db: $db,
            $table: $db.customerTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> saleItemTableRefs(
    Expression<bool> Function($$SaleItemTableTableFilterComposer f) f,
  ) {
    final $$SaleItemTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.saleItemTable,
      getReferencedColumn: (t) => t.saleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleItemTableTableFilterComposer(
            $db: $db,
            $table: $db.saleItemTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> paymentTableRefs(
    Expression<bool> Function($$PaymentTableTableFilterComposer f) f,
  ) {
    final $$PaymentTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.paymentTable,
      getReferencedColumn: (t) => t.saleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentTableTableFilterComposer(
            $db: $db,
            $table: $db.paymentTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> customerAccountEntryTableRefs(
    Expression<bool> Function($$CustomerAccountEntryTableTableFilterComposer f)
    f,
  ) {
    final $$CustomerAccountEntryTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.saleId,
          referencedTable: $db.customerAccountEntryTable,
          getReferencedColumn: (t) => t.saleId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CustomerAccountEntryTableTableFilterComposer(
                $db: $db,
                $table: $db.customerAccountEntryTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$SaleTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SaleTableTable> {
  $$SaleTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get saleId => $composableBuilder(
    column: $table.saleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get saleDate => $composableBuilder(
    column: $table.saleDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get shipping_amount => $composableBuilder(
    column: $table.shipping_amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visitId => $composableBuilder(
    column: $table.visitId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cashAmount => $composableBuilder(
    column: $table.cashAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get transferAmount => $composableBuilder(
    column: $table.transferAmount,
    builder: (column) => ColumnOrderings(column),
  );

  $$CustomerTableTableOrderingComposer get customerId {
    final $$CustomerTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customerTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomerTableTableOrderingComposer(
            $db: $db,
            $table: $db.customerTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SaleTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SaleTableTable> {
  $$SaleTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get saleId =>
      $composableBuilder(column: $table.saleId, builder: (column) => column);

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get saleDate =>
      $composableBuilder(column: $table.saleDate, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get shipping_amount => $composableBuilder(
    column: $table.shipping_amount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get visitId =>
      $composableBuilder(column: $table.visitId, builder: (column) => column);

  GeneratedColumn<double> get cashAmount => $composableBuilder(
    column: $table.cashAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get transferAmount => $composableBuilder(
    column: $table.transferAmount,
    builder: (column) => column,
  );

  $$CustomerTableTableAnnotationComposer get customerId {
    final $$CustomerTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customerTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomerTableTableAnnotationComposer(
            $db: $db,
            $table: $db.customerTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> saleItemTableRefs<T extends Object>(
    Expression<T> Function($$SaleItemTableTableAnnotationComposer a) f,
  ) {
    final $$SaleItemTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.saleItemTable,
      getReferencedColumn: (t) => t.saleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleItemTableTableAnnotationComposer(
            $db: $db,
            $table: $db.saleItemTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> paymentTableRefs<T extends Object>(
    Expression<T> Function($$PaymentTableTableAnnotationComposer a) f,
  ) {
    final $$PaymentTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.paymentTable,
      getReferencedColumn: (t) => t.saleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentTableTableAnnotationComposer(
            $db: $db,
            $table: $db.paymentTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> customerAccountEntryTableRefs<T extends Object>(
    Expression<T> Function($$CustomerAccountEntryTableTableAnnotationComposer a)
    f,
  ) {
    final $$CustomerAccountEntryTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.saleId,
          referencedTable: $db.customerAccountEntryTable,
          getReferencedColumn: (t) => t.saleId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CustomerAccountEntryTableTableAnnotationComposer(
                $db: $db,
                $table: $db.customerAccountEntryTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$SaleTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SaleTableTable,
          SaleTableData,
          $$SaleTableTableFilterComposer,
          $$SaleTableTableOrderingComposer,
          $$SaleTableTableAnnotationComposer,
          $$SaleTableTableCreateCompanionBuilder,
          $$SaleTableTableUpdateCompanionBuilder,
          (SaleTableData, $$SaleTableTableReferences),
          SaleTableData,
          PrefetchHooks Function({
            bool customerId,
            bool saleItemTableRefs,
            bool paymentTableRefs,
            bool customerAccountEntryTableRefs,
          })
        > {
  $$SaleTableTableTableManager(_$AppDatabase db, $SaleTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SaleTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SaleTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SaleTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModifiedDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> saleId = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<DateTime> saleDate = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<double> shipping_amount = const Value.absent(),
                Value<String?> visitId = const Value.absent(),
                Value<double?> cashAmount = const Value.absent(),
                Value<double?> transferAmount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SaleTableCompanion(
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
                enabled: enabled,
                serverId: serverId,
                saleId: saleId,
                customerId: customerId,
                totalAmount: totalAmount,
                paymentMethod: paymentMethod,
                saleDate: saleDate,
                quantity: quantity,
                shipping_amount: shipping_amount,
                visitId: visitId,
                cashAmount: cashAmount,
                transferAmount: transferAmount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModifiedDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> saleId = const Value.absent(),
                required String customerId,
                required double totalAmount,
                required String paymentMethod,
                Value<DateTime> saleDate = const Value.absent(),
                required int quantity,
                required double shipping_amount,
                Value<String?> visitId = const Value.absent(),
                Value<double?> cashAmount = const Value.absent(),
                Value<double?> transferAmount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SaleTableCompanion.insert(
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
                enabled: enabled,
                serverId: serverId,
                saleId: saleId,
                customerId: customerId,
                totalAmount: totalAmount,
                paymentMethod: paymentMethod,
                saleDate: saleDate,
                quantity: quantity,
                shipping_amount: shipping_amount,
                visitId: visitId,
                cashAmount: cashAmount,
                transferAmount: transferAmount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SaleTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                customerId = false,
                saleItemTableRefs = false,
                paymentTableRefs = false,
                customerAccountEntryTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (saleItemTableRefs) db.saleItemTable,
                    if (paymentTableRefs) db.paymentTable,
                    if (customerAccountEntryTableRefs)
                      db.customerAccountEntryTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (customerId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.customerId,
                                    referencedTable: $$SaleTableTableReferences
                                        ._customerIdTable(db),
                                    referencedColumn: $$SaleTableTableReferences
                                        ._customerIdTable(db)
                                        .customerId,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (saleItemTableRefs)
                        await $_getPrefetchedData<
                          SaleTableData,
                          $SaleTableTable,
                          SaleItemTableData
                        >(
                          currentTable: table,
                          referencedTable: $$SaleTableTableReferences
                              ._saleItemTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SaleTableTableReferences(
                                db,
                                table,
                                p0,
                              ).saleItemTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.saleId == item.saleId,
                              ),
                          typedResults: items,
                        ),
                      if (paymentTableRefs)
                        await $_getPrefetchedData<
                          SaleTableData,
                          $SaleTableTable,
                          PaymentTableData
                        >(
                          currentTable: table,
                          referencedTable: $$SaleTableTableReferences
                              ._paymentTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SaleTableTableReferences(
                                db,
                                table,
                                p0,
                              ).paymentTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.saleId == item.saleId,
                              ),
                          typedResults: items,
                        ),
                      if (customerAccountEntryTableRefs)
                        await $_getPrefetchedData<
                          SaleTableData,
                          $SaleTableTable,
                          CustomerAccountEntryTableData
                        >(
                          currentTable: table,
                          referencedTable: $$SaleTableTableReferences
                              ._customerAccountEntryTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SaleTableTableReferences(
                                db,
                                table,
                                p0,
                              ).customerAccountEntryTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.saleId == item.saleId,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SaleTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SaleTableTable,
      SaleTableData,
      $$SaleTableTableFilterComposer,
      $$SaleTableTableOrderingComposer,
      $$SaleTableTableAnnotationComposer,
      $$SaleTableTableCreateCompanionBuilder,
      $$SaleTableTableUpdateCompanionBuilder,
      (SaleTableData, $$SaleTableTableReferences),
      SaleTableData,
      PrefetchHooks Function({
        bool customerId,
        bool saleItemTableRefs,
        bool paymentTableRefs,
        bool customerAccountEntryTableRefs,
      })
    >;
typedef $$SaleItemTableTableCreateCompanionBuilder =
    SaleItemTableCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
      Value<bool> enabled,
      Value<int?> serverId,
      Value<String> saleItemId,
      required String saleId,
      required String productId,
      required int quantity,
      required double unitPrice,
      required double subtotal,
      Value<int?> agreementServerId,
      Value<String?> agreementUuid,
      Value<int> rowid,
    });
typedef $$SaleItemTableTableUpdateCompanionBuilder =
    SaleItemTableCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
      Value<bool> enabled,
      Value<int?> serverId,
      Value<String> saleItemId,
      Value<String> saleId,
      Value<String> productId,
      Value<int> quantity,
      Value<double> unitPrice,
      Value<double> subtotal,
      Value<int?> agreementServerId,
      Value<String?> agreementUuid,
      Value<int> rowid,
    });

final class $$SaleItemTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $SaleItemTableTable, SaleItemTableData> {
  $$SaleItemTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SaleTableTable _saleIdTable(_$AppDatabase db) =>
      db.saleTable.createAlias(
        $_aliasNameGenerator(db.saleItemTable.saleId, db.saleTable.saleId),
      );

  $$SaleTableTableProcessedTableManager get saleId {
    final $_column = $_itemColumn<String>('sale_id')!;

    final manager = $$SaleTableTableTableManager(
      $_db,
      $_db.saleTable,
    ).filter((f) => f.saleId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_saleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ProductTableTable _productIdTable(_$AppDatabase db) =>
      db.productTable.createAlias(
        $_aliasNameGenerator(
          db.saleItemTable.productId,
          db.productTable.productId,
        ),
      );

  $$ProductTableTableProcessedTableManager get productId {
    final $_column = $_itemColumn<String>('product_id')!;

    final manager = $$ProductTableTableTableManager(
      $_db,
      $_db.productTable,
    ).filter((f) => f.productId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SaleItemTableTableFilterComposer
    extends Composer<_$AppDatabase, $SaleItemTableTable> {
  $$SaleItemTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get saleItemId => $composableBuilder(
    column: $table.saleItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get agreementServerId => $composableBuilder(
    column: $table.agreementServerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get agreementUuid => $composableBuilder(
    column: $table.agreementUuid,
    builder: (column) => ColumnFilters(column),
  );

  $$SaleTableTableFilterComposer get saleId {
    final $$SaleTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.saleTable,
      getReferencedColumn: (t) => t.saleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleTableTableFilterComposer(
            $db: $db,
            $table: $db.saleTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductTableTableFilterComposer get productId {
    final $$ProductTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.productTable,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductTableTableFilterComposer(
            $db: $db,
            $table: $db.productTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SaleItemTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SaleItemTableTable> {
  $$SaleItemTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get saleItemId => $composableBuilder(
    column: $table.saleItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get agreementServerId => $composableBuilder(
    column: $table.agreementServerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get agreementUuid => $composableBuilder(
    column: $table.agreementUuid,
    builder: (column) => ColumnOrderings(column),
  );

  $$SaleTableTableOrderingComposer get saleId {
    final $$SaleTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.saleTable,
      getReferencedColumn: (t) => t.saleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleTableTableOrderingComposer(
            $db: $db,
            $table: $db.saleTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductTableTableOrderingComposer get productId {
    final $$ProductTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.productTable,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductTableTableOrderingComposer(
            $db: $db,
            $table: $db.productTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SaleItemTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SaleItemTableTable> {
  $$SaleItemTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get saleItemId => $composableBuilder(
    column: $table.saleItemId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<double> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<int> get agreementServerId => $composableBuilder(
    column: $table.agreementServerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get agreementUuid => $composableBuilder(
    column: $table.agreementUuid,
    builder: (column) => column,
  );

  $$SaleTableTableAnnotationComposer get saleId {
    final $$SaleTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.saleTable,
      getReferencedColumn: (t) => t.saleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleTableTableAnnotationComposer(
            $db: $db,
            $table: $db.saleTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductTableTableAnnotationComposer get productId {
    final $$ProductTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.productTable,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductTableTableAnnotationComposer(
            $db: $db,
            $table: $db.productTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SaleItemTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SaleItemTableTable,
          SaleItemTableData,
          $$SaleItemTableTableFilterComposer,
          $$SaleItemTableTableOrderingComposer,
          $$SaleItemTableTableAnnotationComposer,
          $$SaleItemTableTableCreateCompanionBuilder,
          $$SaleItemTableTableUpdateCompanionBuilder,
          (SaleItemTableData, $$SaleItemTableTableReferences),
          SaleItemTableData,
          PrefetchHooks Function({bool saleId, bool productId})
        > {
  $$SaleItemTableTableTableManager(_$AppDatabase db, $SaleItemTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SaleItemTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SaleItemTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SaleItemTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModifiedDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> saleItemId = const Value.absent(),
                Value<String> saleId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<double> unitPrice = const Value.absent(),
                Value<double> subtotal = const Value.absent(),
                Value<int?> agreementServerId = const Value.absent(),
                Value<String?> agreementUuid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SaleItemTableCompanion(
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
                enabled: enabled,
                serverId: serverId,
                saleItemId: saleItemId,
                saleId: saleId,
                productId: productId,
                quantity: quantity,
                unitPrice: unitPrice,
                subtotal: subtotal,
                agreementServerId: agreementServerId,
                agreementUuid: agreementUuid,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModifiedDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> saleItemId = const Value.absent(),
                required String saleId,
                required String productId,
                required int quantity,
                required double unitPrice,
                required double subtotal,
                Value<int?> agreementServerId = const Value.absent(),
                Value<String?> agreementUuid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SaleItemTableCompanion.insert(
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
                enabled: enabled,
                serverId: serverId,
                saleItemId: saleItemId,
                saleId: saleId,
                productId: productId,
                quantity: quantity,
                unitPrice: unitPrice,
                subtotal: subtotal,
                agreementServerId: agreementServerId,
                agreementUuid: agreementUuid,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SaleItemTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({saleId = false, productId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (saleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.saleId,
                                referencedTable: $$SaleItemTableTableReferences
                                    ._saleIdTable(db),
                                referencedColumn: $$SaleItemTableTableReferences
                                    ._saleIdTable(db)
                                    .saleId,
                              )
                              as T;
                    }
                    if (productId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.productId,
                                referencedTable: $$SaleItemTableTableReferences
                                    ._productIdTable(db),
                                referencedColumn: $$SaleItemTableTableReferences
                                    ._productIdTable(db)
                                    .productId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SaleItemTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SaleItemTableTable,
      SaleItemTableData,
      $$SaleItemTableTableFilterComposer,
      $$SaleItemTableTableOrderingComposer,
      $$SaleItemTableTableAnnotationComposer,
      $$SaleItemTableTableCreateCompanionBuilder,
      $$SaleItemTableTableUpdateCompanionBuilder,
      (SaleItemTableData, $$SaleItemTableTableReferences),
      SaleItemTableData,
      PrefetchHooks Function({bool saleId, bool productId})
    >;
typedef $$PaymentTableTableCreateCompanionBuilder =
    PaymentTableCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
      Value<bool> enabled,
      Value<int?> serverId,
      Value<String> paymentId,
      required String customerId,
      required double amount,
      required String paymentMethod,
      Value<String?> visitId,
      Value<String?> saleId,
      Value<String?> notes,
      Value<String> status,
      Value<int> rowid,
    });
typedef $$PaymentTableTableUpdateCompanionBuilder =
    PaymentTableCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
      Value<bool> enabled,
      Value<int?> serverId,
      Value<String> paymentId,
      Value<String> customerId,
      Value<double> amount,
      Value<String> paymentMethod,
      Value<String?> visitId,
      Value<String?> saleId,
      Value<String?> notes,
      Value<String> status,
      Value<int> rowid,
    });

final class $$PaymentTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $PaymentTableTable, PaymentTableData> {
  $$PaymentTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CustomerTableTable _customerIdTable(_$AppDatabase db) =>
      db.customerTable.createAlias(
        $_aliasNameGenerator(
          db.paymentTable.customerId,
          db.customerTable.customerId,
        ),
      );

  $$CustomerTableTableProcessedTableManager get customerId {
    final $_column = $_itemColumn<String>('customer_id')!;

    final manager = $$CustomerTableTableTableManager(
      $_db,
      $_db.customerTable,
    ).filter((f) => f.customerId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_customerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $VisitTableTable _visitIdTable(_$AppDatabase db) =>
      db.visitTable.createAlias(
        $_aliasNameGenerator(db.paymentTable.visitId, db.visitTable.visitId),
      );

  $$VisitTableTableProcessedTableManager? get visitId {
    final $_column = $_itemColumn<String>('visit_id');
    if ($_column == null) return null;
    final manager = $$VisitTableTableTableManager(
      $_db,
      $_db.visitTable,
    ).filter((f) => f.visitId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_visitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SaleTableTable _saleIdTable(_$AppDatabase db) =>
      db.saleTable.createAlias(
        $_aliasNameGenerator(db.paymentTable.saleId, db.saleTable.saleId),
      );

  $$SaleTableTableProcessedTableManager? get saleId {
    final $_column = $_itemColumn<String>('sale_id');
    if ($_column == null) return null;
    final manager = $$SaleTableTableTableManager(
      $_db,
      $_db.saleTable,
    ).filter((f) => f.saleId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_saleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $CustomerAccountEntryTableTable,
    List<CustomerAccountEntryTableData>
  >
  _customerAccountEntryTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.customerAccountEntryTable,
        aliasName: $_aliasNameGenerator(
          db.paymentTable.paymentId,
          db.customerAccountEntryTable.paymentId,
        ),
      );

  $$CustomerAccountEntryTableTableProcessedTableManager
  get customerAccountEntryTableRefs {
    final manager =
        $$CustomerAccountEntryTableTableTableManager(
          $_db,
          $_db.customerAccountEntryTable,
        ).filter(
          (f) => f.paymentId.paymentId.sqlEquals(
            $_itemColumn<String>('payment_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _customerAccountEntryTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PaymentTableTableFilterComposer
    extends Composer<_$AppDatabase, $PaymentTableTable> {
  $$PaymentTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentId => $composableBuilder(
    column: $table.paymentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  $$CustomerTableTableFilterComposer get customerId {
    final $$CustomerTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customerTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomerTableTableFilterComposer(
            $db: $db,
            $table: $db.customerTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VisitTableTableFilterComposer get visitId {
    final $$VisitTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visitTable,
      getReferencedColumn: (t) => t.visitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitTableTableFilterComposer(
            $db: $db,
            $table: $db.visitTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SaleTableTableFilterComposer get saleId {
    final $$SaleTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.saleTable,
      getReferencedColumn: (t) => t.saleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleTableTableFilterComposer(
            $db: $db,
            $table: $db.saleTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> customerAccountEntryTableRefs(
    Expression<bool> Function($$CustomerAccountEntryTableTableFilterComposer f)
    f,
  ) {
    final $$CustomerAccountEntryTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.paymentId,
          referencedTable: $db.customerAccountEntryTable,
          getReferencedColumn: (t) => t.paymentId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CustomerAccountEntryTableTableFilterComposer(
                $db: $db,
                $table: $db.customerAccountEntryTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$PaymentTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PaymentTableTable> {
  $$PaymentTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentId => $composableBuilder(
    column: $table.paymentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  $$CustomerTableTableOrderingComposer get customerId {
    final $$CustomerTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customerTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomerTableTableOrderingComposer(
            $db: $db,
            $table: $db.customerTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VisitTableTableOrderingComposer get visitId {
    final $$VisitTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visitTable,
      getReferencedColumn: (t) => t.visitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitTableTableOrderingComposer(
            $db: $db,
            $table: $db.visitTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SaleTableTableOrderingComposer get saleId {
    final $$SaleTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.saleTable,
      getReferencedColumn: (t) => t.saleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleTableTableOrderingComposer(
            $db: $db,
            $table: $db.saleTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PaymentTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PaymentTableTable> {
  $$PaymentTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get paymentId =>
      $composableBuilder(column: $table.paymentId, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  $$CustomerTableTableAnnotationComposer get customerId {
    final $$CustomerTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customerTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomerTableTableAnnotationComposer(
            $db: $db,
            $table: $db.customerTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VisitTableTableAnnotationComposer get visitId {
    final $$VisitTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visitTable,
      getReferencedColumn: (t) => t.visitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitTableTableAnnotationComposer(
            $db: $db,
            $table: $db.visitTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SaleTableTableAnnotationComposer get saleId {
    final $$SaleTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.saleTable,
      getReferencedColumn: (t) => t.saleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleTableTableAnnotationComposer(
            $db: $db,
            $table: $db.saleTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> customerAccountEntryTableRefs<T extends Object>(
    Expression<T> Function($$CustomerAccountEntryTableTableAnnotationComposer a)
    f,
  ) {
    final $$CustomerAccountEntryTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.paymentId,
          referencedTable: $db.customerAccountEntryTable,
          getReferencedColumn: (t) => t.paymentId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CustomerAccountEntryTableTableAnnotationComposer(
                $db: $db,
                $table: $db.customerAccountEntryTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$PaymentTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PaymentTableTable,
          PaymentTableData,
          $$PaymentTableTableFilterComposer,
          $$PaymentTableTableOrderingComposer,
          $$PaymentTableTableAnnotationComposer,
          $$PaymentTableTableCreateCompanionBuilder,
          $$PaymentTableTableUpdateCompanionBuilder,
          (PaymentTableData, $$PaymentTableTableReferences),
          PaymentTableData,
          PrefetchHooks Function({
            bool customerId,
            bool visitId,
            bool saleId,
            bool customerAccountEntryTableRefs,
          })
        > {
  $$PaymentTableTableTableManager(_$AppDatabase db, $PaymentTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaymentTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaymentTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PaymentTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModifiedDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> paymentId = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<String?> visitId = const Value.absent(),
                Value<String?> saleId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaymentTableCompanion(
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
                enabled: enabled,
                serverId: serverId,
                paymentId: paymentId,
                customerId: customerId,
                amount: amount,
                paymentMethod: paymentMethod,
                visitId: visitId,
                saleId: saleId,
                notes: notes,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModifiedDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> paymentId = const Value.absent(),
                required String customerId,
                required double amount,
                required String paymentMethod,
                Value<String?> visitId = const Value.absent(),
                Value<String?> saleId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaymentTableCompanion.insert(
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
                enabled: enabled,
                serverId: serverId,
                paymentId: paymentId,
                customerId: customerId,
                amount: amount,
                paymentMethod: paymentMethod,
                visitId: visitId,
                saleId: saleId,
                notes: notes,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PaymentTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                customerId = false,
                visitId = false,
                saleId = false,
                customerAccountEntryTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (customerAccountEntryTableRefs)
                      db.customerAccountEntryTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (customerId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.customerId,
                                    referencedTable:
                                        $$PaymentTableTableReferences
                                            ._customerIdTable(db),
                                    referencedColumn:
                                        $$PaymentTableTableReferences
                                            ._customerIdTable(db)
                                            .customerId,
                                  )
                                  as T;
                        }
                        if (visitId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.visitId,
                                    referencedTable:
                                        $$PaymentTableTableReferences
                                            ._visitIdTable(db),
                                    referencedColumn:
                                        $$PaymentTableTableReferences
                                            ._visitIdTable(db)
                                            .visitId,
                                  )
                                  as T;
                        }
                        if (saleId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.saleId,
                                    referencedTable:
                                        $$PaymentTableTableReferences
                                            ._saleIdTable(db),
                                    referencedColumn:
                                        $$PaymentTableTableReferences
                                            ._saleIdTable(db)
                                            .saleId,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (customerAccountEntryTableRefs)
                        await $_getPrefetchedData<
                          PaymentTableData,
                          $PaymentTableTable,
                          CustomerAccountEntryTableData
                        >(
                          currentTable: table,
                          referencedTable: $$PaymentTableTableReferences
                              ._customerAccountEntryTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PaymentTableTableReferences(
                                db,
                                table,
                                p0,
                              ).customerAccountEntryTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.paymentId == item.paymentId,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PaymentTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PaymentTableTable,
      PaymentTableData,
      $$PaymentTableTableFilterComposer,
      $$PaymentTableTableOrderingComposer,
      $$PaymentTableTableAnnotationComposer,
      $$PaymentTableTableCreateCompanionBuilder,
      $$PaymentTableTableUpdateCompanionBuilder,
      (PaymentTableData, $$PaymentTableTableReferences),
      PaymentTableData,
      PrefetchHooks Function({
        bool customerId,
        bool visitId,
        bool saleId,
        bool customerAccountEntryTableRefs,
      })
    >;
typedef $$CustomerAccountEntryTableTableCreateCompanionBuilder =
    CustomerAccountEntryTableCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
      Value<bool> enabled,
      Value<int?> serverId,
      Value<String> customerAccountEntryId,
      required String customerId,
      Value<String?> saleId,
      Value<String?> paymentId,
      Value<String?> createdBy,
      required String entryType,
      required double amount,
      required int direction,
      Value<String?> description,
      Value<int> rowid,
    });
typedef $$CustomerAccountEntryTableTableUpdateCompanionBuilder =
    CustomerAccountEntryTableCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
      Value<bool> enabled,
      Value<int?> serverId,
      Value<String> customerAccountEntryId,
      Value<String> customerId,
      Value<String?> saleId,
      Value<String?> paymentId,
      Value<String?> createdBy,
      Value<String> entryType,
      Value<double> amount,
      Value<int> direction,
      Value<String?> description,
      Value<int> rowid,
    });

final class $$CustomerAccountEntryTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CustomerAccountEntryTableTable,
          CustomerAccountEntryTableData
        > {
  $$CustomerAccountEntryTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CustomerTableTable _customerIdTable(_$AppDatabase db) =>
      db.customerTable.createAlias(
        $_aliasNameGenerator(
          db.customerAccountEntryTable.customerId,
          db.customerTable.customerId,
        ),
      );

  $$CustomerTableTableProcessedTableManager get customerId {
    final $_column = $_itemColumn<String>('customer_id')!;

    final manager = $$CustomerTableTableTableManager(
      $_db,
      $_db.customerTable,
    ).filter((f) => f.customerId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_customerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SaleTableTable _saleIdTable(_$AppDatabase db) =>
      db.saleTable.createAlias(
        $_aliasNameGenerator(
          db.customerAccountEntryTable.saleId,
          db.saleTable.saleId,
        ),
      );

  $$SaleTableTableProcessedTableManager? get saleId {
    final $_column = $_itemColumn<String>('sale_id');
    if ($_column == null) return null;
    final manager = $$SaleTableTableTableManager(
      $_db,
      $_db.saleTable,
    ).filter((f) => f.saleId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_saleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PaymentTableTable _paymentIdTable(_$AppDatabase db) =>
      db.paymentTable.createAlias(
        $_aliasNameGenerator(
          db.customerAccountEntryTable.paymentId,
          db.paymentTable.paymentId,
        ),
      );

  $$PaymentTableTableProcessedTableManager? get paymentId {
    final $_column = $_itemColumn<String>('payment_id');
    if ($_column == null) return null;
    final manager = $$PaymentTableTableTableManager(
      $_db,
      $_db.paymentTable,
    ).filter((f) => f.paymentId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_paymentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $CustomerBalanceTableTable,
    List<CustomerBalanceTableData>
  >
  _customerBalanceTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.customerBalanceTable,
        aliasName: $_aliasNameGenerator(
          db.customerAccountEntryTable.customerAccountEntryId,
          db.customerBalanceTable.lastEntryId,
        ),
      );

  $$CustomerBalanceTableTableProcessedTableManager
  get customerBalanceTableRefs {
    final manager =
        $$CustomerBalanceTableTableTableManager(
          $_db,
          $_db.customerBalanceTable,
        ).filter(
          (f) => f.lastEntryId.customerAccountEntryId.sqlEquals(
            $_itemColumn<String>('customer_account_entry_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _customerBalanceTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CustomerAccountEntryTableTableFilterComposer
    extends Composer<_$AppDatabase, $CustomerAccountEntryTableTable> {
  $$CustomerAccountEntryTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerAccountEntryId => $composableBuilder(
    column: $table.customerAccountEntryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entryType => $composableBuilder(
    column: $table.entryType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  $$CustomerTableTableFilterComposer get customerId {
    final $$CustomerTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customerTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomerTableTableFilterComposer(
            $db: $db,
            $table: $db.customerTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SaleTableTableFilterComposer get saleId {
    final $$SaleTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.saleTable,
      getReferencedColumn: (t) => t.saleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleTableTableFilterComposer(
            $db: $db,
            $table: $db.saleTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PaymentTableTableFilterComposer get paymentId {
    final $$PaymentTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.paymentId,
      referencedTable: $db.paymentTable,
      getReferencedColumn: (t) => t.paymentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentTableTableFilterComposer(
            $db: $db,
            $table: $db.paymentTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> customerBalanceTableRefs(
    Expression<bool> Function($$CustomerBalanceTableTableFilterComposer f) f,
  ) {
    final $$CustomerBalanceTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerAccountEntryId,
      referencedTable: $db.customerBalanceTable,
      getReferencedColumn: (t) => t.lastEntryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomerBalanceTableTableFilterComposer(
            $db: $db,
            $table: $db.customerBalanceTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CustomerAccountEntryTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomerAccountEntryTableTable> {
  $$CustomerAccountEntryTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerAccountEntryId => $composableBuilder(
    column: $table.customerAccountEntryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entryType => $composableBuilder(
    column: $table.entryType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  $$CustomerTableTableOrderingComposer get customerId {
    final $$CustomerTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customerTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomerTableTableOrderingComposer(
            $db: $db,
            $table: $db.customerTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SaleTableTableOrderingComposer get saleId {
    final $$SaleTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.saleTable,
      getReferencedColumn: (t) => t.saleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleTableTableOrderingComposer(
            $db: $db,
            $table: $db.saleTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PaymentTableTableOrderingComposer get paymentId {
    final $$PaymentTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.paymentId,
      referencedTable: $db.paymentTable,
      getReferencedColumn: (t) => t.paymentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentTableTableOrderingComposer(
            $db: $db,
            $table: $db.paymentTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CustomerAccountEntryTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomerAccountEntryTableTable> {
  $$CustomerAccountEntryTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get customerAccountEntryId => $composableBuilder(
    column: $table.customerAccountEntryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get entryType =>
      $composableBuilder(column: $table.entryType, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<int> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  $$CustomerTableTableAnnotationComposer get customerId {
    final $$CustomerTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customerTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomerTableTableAnnotationComposer(
            $db: $db,
            $table: $db.customerTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SaleTableTableAnnotationComposer get saleId {
    final $$SaleTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.saleTable,
      getReferencedColumn: (t) => t.saleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleTableTableAnnotationComposer(
            $db: $db,
            $table: $db.saleTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PaymentTableTableAnnotationComposer get paymentId {
    final $$PaymentTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.paymentId,
      referencedTable: $db.paymentTable,
      getReferencedColumn: (t) => t.paymentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentTableTableAnnotationComposer(
            $db: $db,
            $table: $db.paymentTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> customerBalanceTableRefs<T extends Object>(
    Expression<T> Function($$CustomerBalanceTableTableAnnotationComposer a) f,
  ) {
    final $$CustomerBalanceTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.customerAccountEntryId,
          referencedTable: $db.customerBalanceTable,
          getReferencedColumn: (t) => t.lastEntryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CustomerBalanceTableTableAnnotationComposer(
                $db: $db,
                $table: $db.customerBalanceTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CustomerAccountEntryTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomerAccountEntryTableTable,
          CustomerAccountEntryTableData,
          $$CustomerAccountEntryTableTableFilterComposer,
          $$CustomerAccountEntryTableTableOrderingComposer,
          $$CustomerAccountEntryTableTableAnnotationComposer,
          $$CustomerAccountEntryTableTableCreateCompanionBuilder,
          $$CustomerAccountEntryTableTableUpdateCompanionBuilder,
          (
            CustomerAccountEntryTableData,
            $$CustomerAccountEntryTableTableReferences,
          ),
          CustomerAccountEntryTableData,
          PrefetchHooks Function({
            bool customerId,
            bool saleId,
            bool paymentId,
            bool customerBalanceTableRefs,
          })
        > {
  $$CustomerAccountEntryTableTableTableManager(
    _$AppDatabase db,
    $CustomerAccountEntryTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomerAccountEntryTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CustomerAccountEntryTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CustomerAccountEntryTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModifiedDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> customerAccountEntryId = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<String?> saleId = const Value.absent(),
                Value<String?> paymentId = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<String> entryType = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<int> direction = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomerAccountEntryTableCompanion(
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
                enabled: enabled,
                serverId: serverId,
                customerAccountEntryId: customerAccountEntryId,
                customerId: customerId,
                saleId: saleId,
                paymentId: paymentId,
                createdBy: createdBy,
                entryType: entryType,
                amount: amount,
                direction: direction,
                description: description,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModifiedDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> customerAccountEntryId = const Value.absent(),
                required String customerId,
                Value<String?> saleId = const Value.absent(),
                Value<String?> paymentId = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                required String entryType,
                required double amount,
                required int direction,
                Value<String?> description = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomerAccountEntryTableCompanion.insert(
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
                enabled: enabled,
                serverId: serverId,
                customerAccountEntryId: customerAccountEntryId,
                customerId: customerId,
                saleId: saleId,
                paymentId: paymentId,
                createdBy: createdBy,
                entryType: entryType,
                amount: amount,
                direction: direction,
                description: description,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CustomerAccountEntryTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                customerId = false,
                saleId = false,
                paymentId = false,
                customerBalanceTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (customerBalanceTableRefs) db.customerBalanceTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (customerId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.customerId,
                                    referencedTable:
                                        $$CustomerAccountEntryTableTableReferences
                                            ._customerIdTable(db),
                                    referencedColumn:
                                        $$CustomerAccountEntryTableTableReferences
                                            ._customerIdTable(db)
                                            .customerId,
                                  )
                                  as T;
                        }
                        if (saleId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.saleId,
                                    referencedTable:
                                        $$CustomerAccountEntryTableTableReferences
                                            ._saleIdTable(db),
                                    referencedColumn:
                                        $$CustomerAccountEntryTableTableReferences
                                            ._saleIdTable(db)
                                            .saleId,
                                  )
                                  as T;
                        }
                        if (paymentId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.paymentId,
                                    referencedTable:
                                        $$CustomerAccountEntryTableTableReferences
                                            ._paymentIdTable(db),
                                    referencedColumn:
                                        $$CustomerAccountEntryTableTableReferences
                                            ._paymentIdTable(db)
                                            .paymentId,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (customerBalanceTableRefs)
                        await $_getPrefetchedData<
                          CustomerAccountEntryTableData,
                          $CustomerAccountEntryTableTable,
                          CustomerBalanceTableData
                        >(
                          currentTable: table,
                          referencedTable:
                              $$CustomerAccountEntryTableTableReferences
                                  ._customerBalanceTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CustomerAccountEntryTableTableReferences(
                                db,
                                table,
                                p0,
                              ).customerBalanceTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) =>
                                    e.lastEntryId ==
                                    item.customerAccountEntryId,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CustomerAccountEntryTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomerAccountEntryTableTable,
      CustomerAccountEntryTableData,
      $$CustomerAccountEntryTableTableFilterComposer,
      $$CustomerAccountEntryTableTableOrderingComposer,
      $$CustomerAccountEntryTableTableAnnotationComposer,
      $$CustomerAccountEntryTableTableCreateCompanionBuilder,
      $$CustomerAccountEntryTableTableUpdateCompanionBuilder,
      (
        CustomerAccountEntryTableData,
        $$CustomerAccountEntryTableTableReferences,
      ),
      CustomerAccountEntryTableData,
      PrefetchHooks Function({
        bool customerId,
        bool saleId,
        bool paymentId,
        bool customerBalanceTableRefs,
      })
    >;
typedef $$CustomerBalanceTableTableCreateCompanionBuilder =
    CustomerBalanceTableCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
      Value<bool> enabled,
      Value<int?> serverId,
      required String customerId,
      Value<double> currentBalance,
      Value<String?> lastEntryId,
      Value<int> rowid,
    });
typedef $$CustomerBalanceTableTableUpdateCompanionBuilder =
    CustomerBalanceTableCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
      Value<bool> enabled,
      Value<int?> serverId,
      Value<String> customerId,
      Value<double> currentBalance,
      Value<String?> lastEntryId,
      Value<int> rowid,
    });

final class $$CustomerBalanceTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CustomerBalanceTableTable,
          CustomerBalanceTableData
        > {
  $$CustomerBalanceTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CustomerTableTable _customerIdTable(_$AppDatabase db) =>
      db.customerTable.createAlias(
        $_aliasNameGenerator(
          db.customerBalanceTable.customerId,
          db.customerTable.customerId,
        ),
      );

  $$CustomerTableTableProcessedTableManager get customerId {
    final $_column = $_itemColumn<String>('customer_id')!;

    final manager = $$CustomerTableTableTableManager(
      $_db,
      $_db.customerTable,
    ).filter((f) => f.customerId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_customerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CustomerAccountEntryTableTable _lastEntryIdTable(_$AppDatabase db) =>
      db.customerAccountEntryTable.createAlias(
        $_aliasNameGenerator(
          db.customerBalanceTable.lastEntryId,
          db.customerAccountEntryTable.customerAccountEntryId,
        ),
      );

  $$CustomerAccountEntryTableTableProcessedTableManager? get lastEntryId {
    final $_column = $_itemColumn<String>('last_entry_id');
    if ($_column == null) return null;
    final manager = $$CustomerAccountEntryTableTableTableManager(
      $_db,
      $_db.customerAccountEntryTable,
    ).filter((f) => f.customerAccountEntryId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_lastEntryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CustomerBalanceTableTableFilterComposer
    extends Composer<_$AppDatabase, $CustomerBalanceTableTable> {
  $$CustomerBalanceTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => ColumnFilters(column),
  );

  $$CustomerTableTableFilterComposer get customerId {
    final $$CustomerTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customerTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomerTableTableFilterComposer(
            $db: $db,
            $table: $db.customerTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CustomerAccountEntryTableTableFilterComposer get lastEntryId {
    final $$CustomerAccountEntryTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.lastEntryId,
          referencedTable: $db.customerAccountEntryTable,
          getReferencedColumn: (t) => t.customerAccountEntryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CustomerAccountEntryTableTableFilterComposer(
                $db: $db,
                $table: $db.customerAccountEntryTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$CustomerBalanceTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomerBalanceTableTable> {
  $$CustomerBalanceTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => ColumnOrderings(column),
  );

  $$CustomerTableTableOrderingComposer get customerId {
    final $$CustomerTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customerTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomerTableTableOrderingComposer(
            $db: $db,
            $table: $db.customerTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CustomerAccountEntryTableTableOrderingComposer get lastEntryId {
    final $$CustomerAccountEntryTableTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.lastEntryId,
          referencedTable: $db.customerAccountEntryTable,
          getReferencedColumn: (t) => t.customerAccountEntryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CustomerAccountEntryTableTableOrderingComposer(
                $db: $db,
                $table: $db.customerAccountEntryTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$CustomerBalanceTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomerBalanceTableTable> {
  $$CustomerBalanceTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<double> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => column,
  );

  $$CustomerTableTableAnnotationComposer get customerId {
    final $$CustomerTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customerTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomerTableTableAnnotationComposer(
            $db: $db,
            $table: $db.customerTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CustomerAccountEntryTableTableAnnotationComposer get lastEntryId {
    final $$CustomerAccountEntryTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.lastEntryId,
          referencedTable: $db.customerAccountEntryTable,
          getReferencedColumn: (t) => t.customerAccountEntryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CustomerAccountEntryTableTableAnnotationComposer(
                $db: $db,
                $table: $db.customerAccountEntryTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$CustomerBalanceTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomerBalanceTableTable,
          CustomerBalanceTableData,
          $$CustomerBalanceTableTableFilterComposer,
          $$CustomerBalanceTableTableOrderingComposer,
          $$CustomerBalanceTableTableAnnotationComposer,
          $$CustomerBalanceTableTableCreateCompanionBuilder,
          $$CustomerBalanceTableTableUpdateCompanionBuilder,
          (CustomerBalanceTableData, $$CustomerBalanceTableTableReferences),
          CustomerBalanceTableData,
          PrefetchHooks Function({bool customerId, bool lastEntryId})
        > {
  $$CustomerBalanceTableTableTableManager(
    _$AppDatabase db,
    $CustomerBalanceTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomerBalanceTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomerBalanceTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CustomerBalanceTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModifiedDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<double> currentBalance = const Value.absent(),
                Value<String?> lastEntryId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomerBalanceTableCompanion(
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
                enabled: enabled,
                serverId: serverId,
                customerId: customerId,
                currentBalance: currentBalance,
                lastEntryId: lastEntryId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModifiedDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                required String customerId,
                Value<double> currentBalance = const Value.absent(),
                Value<String?> lastEntryId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomerBalanceTableCompanion.insert(
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
                enabled: enabled,
                serverId: serverId,
                customerId: customerId,
                currentBalance: currentBalance,
                lastEntryId: lastEntryId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CustomerBalanceTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({customerId = false, lastEntryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (customerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.customerId,
                                referencedTable:
                                    $$CustomerBalanceTableTableReferences
                                        ._customerIdTable(db),
                                referencedColumn:
                                    $$CustomerBalanceTableTableReferences
                                        ._customerIdTable(db)
                                        .customerId,
                              )
                              as T;
                    }
                    if (lastEntryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.lastEntryId,
                                referencedTable:
                                    $$CustomerBalanceTableTableReferences
                                        ._lastEntryIdTable(db),
                                referencedColumn:
                                    $$CustomerBalanceTableTableReferences
                                        ._lastEntryIdTable(db)
                                        .customerAccountEntryId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CustomerBalanceTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomerBalanceTableTable,
      CustomerBalanceTableData,
      $$CustomerBalanceTableTableFilterComposer,
      $$CustomerBalanceTableTableOrderingComposer,
      $$CustomerBalanceTableTableAnnotationComposer,
      $$CustomerBalanceTableTableCreateCompanionBuilder,
      $$CustomerBalanceTableTableUpdateCompanionBuilder,
      (CustomerBalanceTableData, $$CustomerBalanceTableTableReferences),
      CustomerBalanceTableData,
      PrefetchHooks Function({bool customerId, bool lastEntryId})
    >;
typedef $$ContainerMovementTableTableCreateCompanionBuilder =
    ContainerMovementTableCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
      Value<bool> enabled,
      Value<int?> serverId,
      Value<String> containerMovementId,
      required String customerId,
      required String containerType,
      required int deliveredQuantity,
      required int returnedQuantity,
      Value<String?> visitId,
      Value<String?> routeId,
      Value<int> rowid,
    });
typedef $$ContainerMovementTableTableUpdateCompanionBuilder =
    ContainerMovementTableCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
      Value<bool> enabled,
      Value<int?> serverId,
      Value<String> containerMovementId,
      Value<String> customerId,
      Value<String> containerType,
      Value<int> deliveredQuantity,
      Value<int> returnedQuantity,
      Value<String?> visitId,
      Value<String?> routeId,
      Value<int> rowid,
    });

final class $$ContainerMovementTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ContainerMovementTableTable,
          ContainerMovementTableData
        > {
  $$ContainerMovementTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CustomerTableTable _customerIdTable(_$AppDatabase db) =>
      db.customerTable.createAlias(
        $_aliasNameGenerator(
          db.containerMovementTable.customerId,
          db.customerTable.customerId,
        ),
      );

  $$CustomerTableTableProcessedTableManager get customerId {
    final $_column = $_itemColumn<String>('customer_id')!;

    final manager = $$CustomerTableTableTableManager(
      $_db,
      $_db.customerTable,
    ).filter((f) => f.customerId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_customerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $VisitTableTable _visitIdTable(_$AppDatabase db) =>
      db.visitTable.createAlias(
        $_aliasNameGenerator(
          db.containerMovementTable.visitId,
          db.visitTable.visitId,
        ),
      );

  $$VisitTableTableProcessedTableManager? get visitId {
    final $_column = $_itemColumn<String>('visit_id');
    if ($_column == null) return null;
    final manager = $$VisitTableTableTableManager(
      $_db,
      $_db.visitTable,
    ).filter((f) => f.visitId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_visitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $RouteTableTable _routeIdTable(_$AppDatabase db) =>
      db.routeTable.createAlias(
        $_aliasNameGenerator(
          db.containerMovementTable.routeId,
          db.routeTable.routeId,
        ),
      );

  $$RouteTableTableProcessedTableManager? get routeId {
    final $_column = $_itemColumn<String>('route_id');
    if ($_column == null) return null;
    final manager = $$RouteTableTableTableManager(
      $_db,
      $_db.routeTable,
    ).filter((f) => f.routeId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_routeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ContainerMovementTableTableFilterComposer
    extends Composer<_$AppDatabase, $ContainerMovementTableTable> {
  $$ContainerMovementTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get containerMovementId => $composableBuilder(
    column: $table.containerMovementId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get containerType => $composableBuilder(
    column: $table.containerType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deliveredQuantity => $composableBuilder(
    column: $table.deliveredQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get returnedQuantity => $composableBuilder(
    column: $table.returnedQuantity,
    builder: (column) => ColumnFilters(column),
  );

  $$CustomerTableTableFilterComposer get customerId {
    final $$CustomerTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customerTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomerTableTableFilterComposer(
            $db: $db,
            $table: $db.customerTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VisitTableTableFilterComposer get visitId {
    final $$VisitTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visitTable,
      getReferencedColumn: (t) => t.visitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitTableTableFilterComposer(
            $db: $db,
            $table: $db.visitTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RouteTableTableFilterComposer get routeId {
    final $$RouteTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routeId,
      referencedTable: $db.routeTable,
      getReferencedColumn: (t) => t.routeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RouteTableTableFilterComposer(
            $db: $db,
            $table: $db.routeTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContainerMovementTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ContainerMovementTableTable> {
  $$ContainerMovementTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get containerMovementId => $composableBuilder(
    column: $table.containerMovementId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get containerType => $composableBuilder(
    column: $table.containerType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deliveredQuantity => $composableBuilder(
    column: $table.deliveredQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get returnedQuantity => $composableBuilder(
    column: $table.returnedQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  $$CustomerTableTableOrderingComposer get customerId {
    final $$CustomerTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customerTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomerTableTableOrderingComposer(
            $db: $db,
            $table: $db.customerTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VisitTableTableOrderingComposer get visitId {
    final $$VisitTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visitTable,
      getReferencedColumn: (t) => t.visitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitTableTableOrderingComposer(
            $db: $db,
            $table: $db.visitTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RouteTableTableOrderingComposer get routeId {
    final $$RouteTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routeId,
      referencedTable: $db.routeTable,
      getReferencedColumn: (t) => t.routeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RouteTableTableOrderingComposer(
            $db: $db,
            $table: $db.routeTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContainerMovementTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContainerMovementTableTable> {
  $$ContainerMovementTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get containerMovementId => $composableBuilder(
    column: $table.containerMovementId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get containerType => $composableBuilder(
    column: $table.containerType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deliveredQuantity => $composableBuilder(
    column: $table.deliveredQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<int> get returnedQuantity => $composableBuilder(
    column: $table.returnedQuantity,
    builder: (column) => column,
  );

  $$CustomerTableTableAnnotationComposer get customerId {
    final $$CustomerTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customerTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomerTableTableAnnotationComposer(
            $db: $db,
            $table: $db.customerTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VisitTableTableAnnotationComposer get visitId {
    final $$VisitTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visitTable,
      getReferencedColumn: (t) => t.visitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitTableTableAnnotationComposer(
            $db: $db,
            $table: $db.visitTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RouteTableTableAnnotationComposer get routeId {
    final $$RouteTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routeId,
      referencedTable: $db.routeTable,
      getReferencedColumn: (t) => t.routeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RouteTableTableAnnotationComposer(
            $db: $db,
            $table: $db.routeTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContainerMovementTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContainerMovementTableTable,
          ContainerMovementTableData,
          $$ContainerMovementTableTableFilterComposer,
          $$ContainerMovementTableTableOrderingComposer,
          $$ContainerMovementTableTableAnnotationComposer,
          $$ContainerMovementTableTableCreateCompanionBuilder,
          $$ContainerMovementTableTableUpdateCompanionBuilder,
          (ContainerMovementTableData, $$ContainerMovementTableTableReferences),
          ContainerMovementTableData,
          PrefetchHooks Function({bool customerId, bool visitId, bool routeId})
        > {
  $$ContainerMovementTableTableTableManager(
    _$AppDatabase db,
    $ContainerMovementTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContainerMovementTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ContainerMovementTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ContainerMovementTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModifiedDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> containerMovementId = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<String> containerType = const Value.absent(),
                Value<int> deliveredQuantity = const Value.absent(),
                Value<int> returnedQuantity = const Value.absent(),
                Value<String?> visitId = const Value.absent(),
                Value<String?> routeId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContainerMovementTableCompanion(
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
                enabled: enabled,
                serverId: serverId,
                containerMovementId: containerMovementId,
                customerId: customerId,
                containerType: containerType,
                deliveredQuantity: deliveredQuantity,
                returnedQuantity: returnedQuantity,
                visitId: visitId,
                routeId: routeId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModifiedDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> containerMovementId = const Value.absent(),
                required String customerId,
                required String containerType,
                required int deliveredQuantity,
                required int returnedQuantity,
                Value<String?> visitId = const Value.absent(),
                Value<String?> routeId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContainerMovementTableCompanion.insert(
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
                enabled: enabled,
                serverId: serverId,
                containerMovementId: containerMovementId,
                customerId: customerId,
                containerType: containerType,
                deliveredQuantity: deliveredQuantity,
                returnedQuantity: returnedQuantity,
                visitId: visitId,
                routeId: routeId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ContainerMovementTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({customerId = false, visitId = false, routeId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (customerId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.customerId,
                                    referencedTable:
                                        $$ContainerMovementTableTableReferences
                                            ._customerIdTable(db),
                                    referencedColumn:
                                        $$ContainerMovementTableTableReferences
                                            ._customerIdTable(db)
                                            .customerId,
                                  )
                                  as T;
                        }
                        if (visitId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.visitId,
                                    referencedTable:
                                        $$ContainerMovementTableTableReferences
                                            ._visitIdTable(db),
                                    referencedColumn:
                                        $$ContainerMovementTableTableReferences
                                            ._visitIdTable(db)
                                            .visitId,
                                  )
                                  as T;
                        }
                        if (routeId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.routeId,
                                    referencedTable:
                                        $$ContainerMovementTableTableReferences
                                            ._routeIdTable(db),
                                    referencedColumn:
                                        $$ContainerMovementTableTableReferences
                                            ._routeIdTable(db)
                                            .routeId,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$ContainerMovementTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContainerMovementTableTable,
      ContainerMovementTableData,
      $$ContainerMovementTableTableFilterComposer,
      $$ContainerMovementTableTableOrderingComposer,
      $$ContainerMovementTableTableAnnotationComposer,
      $$ContainerMovementTableTableCreateCompanionBuilder,
      $$ContainerMovementTableTableUpdateCompanionBuilder,
      (ContainerMovementTableData, $$ContainerMovementTableTableReferences),
      ContainerMovementTableData,
      PrefetchHooks Function({bool customerId, bool visitId, bool routeId})
    >;
typedef $$CustomerContainerBalanceTableTableCreateCompanionBuilder =
    CustomerContainerBalanceTableCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
      Value<bool> enabled,
      Value<int?> serverId,
      required String customerId,
      required String containerType,
      Value<int> quantity,
      Value<int> rowid,
    });
typedef $$CustomerContainerBalanceTableTableUpdateCompanionBuilder =
    CustomerContainerBalanceTableCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
      Value<bool> enabled,
      Value<int?> serverId,
      Value<String> customerId,
      Value<String> containerType,
      Value<int> quantity,
      Value<int> rowid,
    });

final class $$CustomerContainerBalanceTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CustomerContainerBalanceTableTable,
          CustomerContainerBalanceTableData
        > {
  $$CustomerContainerBalanceTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CustomerTableTable _customerIdTable(_$AppDatabase db) =>
      db.customerTable.createAlias(
        $_aliasNameGenerator(
          db.customerContainerBalanceTable.customerId,
          db.customerTable.customerId,
        ),
      );

  $$CustomerTableTableProcessedTableManager get customerId {
    final $_column = $_itemColumn<String>('customer_id')!;

    final manager = $$CustomerTableTableTableManager(
      $_db,
      $_db.customerTable,
    ).filter((f) => f.customerId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_customerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CustomerContainerBalanceTableTableFilterComposer
    extends Composer<_$AppDatabase, $CustomerContainerBalanceTableTable> {
  $$CustomerContainerBalanceTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get containerType => $composableBuilder(
    column: $table.containerType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  $$CustomerTableTableFilterComposer get customerId {
    final $$CustomerTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customerTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomerTableTableFilterComposer(
            $db: $db,
            $table: $db.customerTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CustomerContainerBalanceTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomerContainerBalanceTableTable> {
  $$CustomerContainerBalanceTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get containerType => $composableBuilder(
    column: $table.containerType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  $$CustomerTableTableOrderingComposer get customerId {
    final $$CustomerTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customerTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomerTableTableOrderingComposer(
            $db: $db,
            $table: $db.customerTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CustomerContainerBalanceTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomerContainerBalanceTableTable> {
  $$CustomerContainerBalanceTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get containerType => $composableBuilder(
    column: $table.containerType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  $$CustomerTableTableAnnotationComposer get customerId {
    final $$CustomerTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customerTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomerTableTableAnnotationComposer(
            $db: $db,
            $table: $db.customerTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CustomerContainerBalanceTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomerContainerBalanceTableTable,
          CustomerContainerBalanceTableData,
          $$CustomerContainerBalanceTableTableFilterComposer,
          $$CustomerContainerBalanceTableTableOrderingComposer,
          $$CustomerContainerBalanceTableTableAnnotationComposer,
          $$CustomerContainerBalanceTableTableCreateCompanionBuilder,
          $$CustomerContainerBalanceTableTableUpdateCompanionBuilder,
          (
            CustomerContainerBalanceTableData,
            $$CustomerContainerBalanceTableTableReferences,
          ),
          CustomerContainerBalanceTableData,
          PrefetchHooks Function({bool customerId})
        > {
  $$CustomerContainerBalanceTableTableTableManager(
    _$AppDatabase db,
    $CustomerContainerBalanceTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomerContainerBalanceTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CustomerContainerBalanceTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CustomerContainerBalanceTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModifiedDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<String> containerType = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomerContainerBalanceTableCompanion(
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
                enabled: enabled,
                serverId: serverId,
                customerId: customerId,
                containerType: containerType,
                quantity: quantity,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModifiedDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                required String customerId,
                required String containerType,
                Value<int> quantity = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomerContainerBalanceTableCompanion.insert(
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
                enabled: enabled,
                serverId: serverId,
                customerId: customerId,
                containerType: containerType,
                quantity: quantity,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CustomerContainerBalanceTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({customerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (customerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.customerId,
                                referencedTable:
                                    $$CustomerContainerBalanceTableTableReferences
                                        ._customerIdTable(db),
                                referencedColumn:
                                    $$CustomerContainerBalanceTableTableReferences
                                        ._customerIdTable(db)
                                        .customerId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CustomerContainerBalanceTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomerContainerBalanceTableTable,
      CustomerContainerBalanceTableData,
      $$CustomerContainerBalanceTableTableFilterComposer,
      $$CustomerContainerBalanceTableTableOrderingComposer,
      $$CustomerContainerBalanceTableTableAnnotationComposer,
      $$CustomerContainerBalanceTableTableCreateCompanionBuilder,
      $$CustomerContainerBalanceTableTableUpdateCompanionBuilder,
      (
        CustomerContainerBalanceTableData,
        $$CustomerContainerBalanceTableTableReferences,
      ),
      CustomerContainerBalanceTableData,
      PrefetchHooks Function({bool customerId})
    >;
typedef $$RouteInventoryLoadTableTableCreateCompanionBuilder =
    RouteInventoryLoadTableCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
      Value<bool> enabled,
      Value<int?> serverId,
      Value<String> routeInventoryLoadId,
      required String routeId,
      required String productId,
      required int quantity,
      Value<DateTime> loadedAt,
      Value<String?> createdBy,
      Value<int> rowid,
    });
typedef $$RouteInventoryLoadTableTableUpdateCompanionBuilder =
    RouteInventoryLoadTableCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
      Value<bool> enabled,
      Value<int?> serverId,
      Value<String> routeInventoryLoadId,
      Value<String> routeId,
      Value<String> productId,
      Value<int> quantity,
      Value<DateTime> loadedAt,
      Value<String?> createdBy,
      Value<int> rowid,
    });

final class $$RouteInventoryLoadTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $RouteInventoryLoadTableTable,
          RouteInventoryLoadTableData
        > {
  $$RouteInventoryLoadTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RouteTableTable _routeIdTable(_$AppDatabase db) =>
      db.routeTable.createAlias(
        $_aliasNameGenerator(
          db.routeInventoryLoadTable.routeId,
          db.routeTable.routeId,
        ),
      );

  $$RouteTableTableProcessedTableManager get routeId {
    final $_column = $_itemColumn<String>('route_id')!;

    final manager = $$RouteTableTableTableManager(
      $_db,
      $_db.routeTable,
    ).filter((f) => f.routeId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_routeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ProductTableTable _productIdTable(_$AppDatabase db) =>
      db.productTable.createAlias(
        $_aliasNameGenerator(
          db.routeInventoryLoadTable.productId,
          db.productTable.productId,
        ),
      );

  $$ProductTableTableProcessedTableManager get productId {
    final $_column = $_itemColumn<String>('product_id')!;

    final manager = $$ProductTableTableTableManager(
      $_db,
      $_db.productTable,
    ).filter((f) => f.productId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RouteInventoryLoadTableTableFilterComposer
    extends Composer<_$AppDatabase, $RouteInventoryLoadTableTable> {
  $$RouteInventoryLoadTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routeInventoryLoadId => $composableBuilder(
    column: $table.routeInventoryLoadId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get loadedAt => $composableBuilder(
    column: $table.loadedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  $$RouteTableTableFilterComposer get routeId {
    final $$RouteTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routeId,
      referencedTable: $db.routeTable,
      getReferencedColumn: (t) => t.routeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RouteTableTableFilterComposer(
            $db: $db,
            $table: $db.routeTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductTableTableFilterComposer get productId {
    final $$ProductTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.productTable,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductTableTableFilterComposer(
            $db: $db,
            $table: $db.productTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RouteInventoryLoadTableTableOrderingComposer
    extends Composer<_$AppDatabase, $RouteInventoryLoadTableTable> {
  $$RouteInventoryLoadTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routeInventoryLoadId => $composableBuilder(
    column: $table.routeInventoryLoadId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get loadedAt => $composableBuilder(
    column: $table.loadedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  $$RouteTableTableOrderingComposer get routeId {
    final $$RouteTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routeId,
      referencedTable: $db.routeTable,
      getReferencedColumn: (t) => t.routeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RouteTableTableOrderingComposer(
            $db: $db,
            $table: $db.routeTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductTableTableOrderingComposer get productId {
    final $$ProductTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.productTable,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductTableTableOrderingComposer(
            $db: $db,
            $table: $db.productTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RouteInventoryLoadTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $RouteInventoryLoadTableTable> {
  $$RouteInventoryLoadTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get routeInventoryLoadId => $composableBuilder(
    column: $table.routeInventoryLoadId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<DateTime> get loadedAt =>
      $composableBuilder(column: $table.loadedAt, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  $$RouteTableTableAnnotationComposer get routeId {
    final $$RouteTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routeId,
      referencedTable: $db.routeTable,
      getReferencedColumn: (t) => t.routeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RouteTableTableAnnotationComposer(
            $db: $db,
            $table: $db.routeTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductTableTableAnnotationComposer get productId {
    final $$ProductTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.productTable,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductTableTableAnnotationComposer(
            $db: $db,
            $table: $db.productTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RouteInventoryLoadTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RouteInventoryLoadTableTable,
          RouteInventoryLoadTableData,
          $$RouteInventoryLoadTableTableFilterComposer,
          $$RouteInventoryLoadTableTableOrderingComposer,
          $$RouteInventoryLoadTableTableAnnotationComposer,
          $$RouteInventoryLoadTableTableCreateCompanionBuilder,
          $$RouteInventoryLoadTableTableUpdateCompanionBuilder,
          (
            RouteInventoryLoadTableData,
            $$RouteInventoryLoadTableTableReferences,
          ),
          RouteInventoryLoadTableData,
          PrefetchHooks Function({bool routeId, bool productId})
        > {
  $$RouteInventoryLoadTableTableTableManager(
    _$AppDatabase db,
    $RouteInventoryLoadTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RouteInventoryLoadTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$RouteInventoryLoadTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RouteInventoryLoadTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModifiedDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> routeInventoryLoadId = const Value.absent(),
                Value<String> routeId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<DateTime> loadedAt = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RouteInventoryLoadTableCompanion(
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
                enabled: enabled,
                serverId: serverId,
                routeInventoryLoadId: routeInventoryLoadId,
                routeId: routeId,
                productId: productId,
                quantity: quantity,
                loadedAt: loadedAt,
                createdBy: createdBy,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModifiedDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> routeInventoryLoadId = const Value.absent(),
                required String routeId,
                required String productId,
                required int quantity,
                Value<DateTime> loadedAt = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RouteInventoryLoadTableCompanion.insert(
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
                enabled: enabled,
                serverId: serverId,
                routeInventoryLoadId: routeInventoryLoadId,
                routeId: routeId,
                productId: productId,
                quantity: quantity,
                loadedAt: loadedAt,
                createdBy: createdBy,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RouteInventoryLoadTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({routeId = false, productId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (routeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.routeId,
                                referencedTable:
                                    $$RouteInventoryLoadTableTableReferences
                                        ._routeIdTable(db),
                                referencedColumn:
                                    $$RouteInventoryLoadTableTableReferences
                                        ._routeIdTable(db)
                                        .routeId,
                              )
                              as T;
                    }
                    if (productId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.productId,
                                referencedTable:
                                    $$RouteInventoryLoadTableTableReferences
                                        ._productIdTable(db),
                                referencedColumn:
                                    $$RouteInventoryLoadTableTableReferences
                                        ._productIdTable(db)
                                        .productId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RouteInventoryLoadTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RouteInventoryLoadTableTable,
      RouteInventoryLoadTableData,
      $$RouteInventoryLoadTableTableFilterComposer,
      $$RouteInventoryLoadTableTableOrderingComposer,
      $$RouteInventoryLoadTableTableAnnotationComposer,
      $$RouteInventoryLoadTableTableCreateCompanionBuilder,
      $$RouteInventoryLoadTableTableUpdateCompanionBuilder,
      (RouteInventoryLoadTableData, $$RouteInventoryLoadTableTableReferences),
      RouteInventoryLoadTableData,
      PrefetchHooks Function({bool routeId, bool productId})
    >;
typedef $$PendingChangeTableTableCreateCompanionBuilder =
    PendingChangeTableCompanion Function({
      Value<int> pendingChangeId,
      required String entity,
      required String entityId,
      required String action,
      Value<String?> payload,
      Value<String> status,
      Value<String?> rejectionReason,
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
    });
typedef $$PendingChangeTableTableUpdateCompanionBuilder =
    PendingChangeTableCompanion Function({
      Value<int> pendingChangeId,
      Value<String> entity,
      Value<String> entityId,
      Value<String> action,
      Value<String?> payload,
      Value<String> status,
      Value<String?> rejectionReason,
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
    });

class $$PendingChangeTableTableFilterComposer
    extends Composer<_$AppDatabase, $PendingChangeTableTable> {
  $$PendingChangeTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get pendingChangeId => $composableBuilder(
    column: $table.pendingChangeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rejectionReason => $composableBuilder(
    column: $table.rejectionReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingChangeTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingChangeTableTable> {
  $$PendingChangeTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get pendingChangeId => $composableBuilder(
    column: $table.pendingChangeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rejectionReason => $composableBuilder(
    column: $table.rejectionReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingChangeTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingChangeTableTable> {
  $$PendingChangeTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get pendingChangeId => $composableBuilder(
    column: $table.pendingChangeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get rejectionReason => $composableBuilder(
    column: $table.rejectionReason,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => column,
  );
}

class $$PendingChangeTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingChangeTableTable,
          PendingChangeTableData,
          $$PendingChangeTableTableFilterComposer,
          $$PendingChangeTableTableOrderingComposer,
          $$PendingChangeTableTableAnnotationComposer,
          $$PendingChangeTableTableCreateCompanionBuilder,
          $$PendingChangeTableTableUpdateCompanionBuilder,
          (
            PendingChangeTableData,
            BaseReferences<
              _$AppDatabase,
              $PendingChangeTableTable,
              PendingChangeTableData
            >,
          ),
          PendingChangeTableData,
          PrefetchHooks Function()
        > {
  $$PendingChangeTableTableTableManager(
    _$AppDatabase db,
    $PendingChangeTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingChangeTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingChangeTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingChangeTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> pendingChangeId = const Value.absent(),
                Value<String> entity = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String?> payload = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> rejectionReason = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModifiedDate = const Value.absent(),
              }) => PendingChangeTableCompanion(
                pendingChangeId: pendingChangeId,
                entity: entity,
                entityId: entityId,
                action: action,
                payload: payload,
                status: status,
                rejectionReason: rejectionReason,
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
              ),
          createCompanionCallback:
              ({
                Value<int> pendingChangeId = const Value.absent(),
                required String entity,
                required String entityId,
                required String action,
                Value<String?> payload = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> rejectionReason = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModifiedDate = const Value.absent(),
              }) => PendingChangeTableCompanion.insert(
                pendingChangeId: pendingChangeId,
                entity: entity,
                entityId: entityId,
                action: action,
                payload: payload,
                status: status,
                rejectionReason: rejectionReason,
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingChangeTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingChangeTableTable,
      PendingChangeTableData,
      $$PendingChangeTableTableFilterComposer,
      $$PendingChangeTableTableOrderingComposer,
      $$PendingChangeTableTableAnnotationComposer,
      $$PendingChangeTableTableCreateCompanionBuilder,
      $$PendingChangeTableTableUpdateCompanionBuilder,
      (
        PendingChangeTableData,
        BaseReferences<
          _$AppDatabase,
          $PendingChangeTableTable,
          PendingChangeTableData
        >,
      ),
      PendingChangeTableData,
      PrefetchHooks Function()
    >;
typedef $$ContainerTypeTableTableCreateCompanionBuilder =
    ContainerTypeTableCompanion Function({
      Value<int> id,
      required String code,
      Value<String?> description,
      Value<bool> enabled,
    });
typedef $$ContainerTypeTableTableUpdateCompanionBuilder =
    ContainerTypeTableCompanion Function({
      Value<int> id,
      Value<String> code,
      Value<String?> description,
      Value<bool> enabled,
    });

class $$ContainerTypeTableTableFilterComposer
    extends Composer<_$AppDatabase, $ContainerTypeTableTable> {
  $$ContainerTypeTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ContainerTypeTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ContainerTypeTableTable> {
  $$ContainerTypeTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContainerTypeTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContainerTypeTableTable> {
  $$ContainerTypeTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);
}

class $$ContainerTypeTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContainerTypeTableTable,
          ContainerTypeTableData,
          $$ContainerTypeTableTableFilterComposer,
          $$ContainerTypeTableTableOrderingComposer,
          $$ContainerTypeTableTableAnnotationComposer,
          $$ContainerTypeTableTableCreateCompanionBuilder,
          $$ContainerTypeTableTableUpdateCompanionBuilder,
          (
            ContainerTypeTableData,
            BaseReferences<
              _$AppDatabase,
              $ContainerTypeTableTable,
              ContainerTypeTableData
            >,
          ),
          ContainerTypeTableData,
          PrefetchHooks Function()
        > {
  $$ContainerTypeTableTableTableManager(
    _$AppDatabase db,
    $ContainerTypeTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContainerTypeTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContainerTypeTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContainerTypeTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
              }) => ContainerTypeTableCompanion(
                id: id,
                code: code,
                description: description,
                enabled: enabled,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String code,
                Value<String?> description = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
              }) => ContainerTypeTableCompanion.insert(
                id: id,
                code: code,
                description: description,
                enabled: enabled,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ContainerTypeTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContainerTypeTableTable,
      ContainerTypeTableData,
      $$ContainerTypeTableTableFilterComposer,
      $$ContainerTypeTableTableOrderingComposer,
      $$ContainerTypeTableTableAnnotationComposer,
      $$ContainerTypeTableTableCreateCompanionBuilder,
      $$ContainerTypeTableTableUpdateCompanionBuilder,
      (
        ContainerTypeTableData,
        BaseReferences<
          _$AppDatabase,
          $ContainerTypeTableTable,
          ContainerTypeTableData
        >,
      ),
      ContainerTypeTableData,
      PrefetchHooks Function()
    >;
typedef $$PaymentMethodTableTableCreateCompanionBuilder =
    PaymentMethodTableCompanion Function({
      Value<int> id,
      required String code,
      required String name,
      Value<bool> enabled,
    });
typedef $$PaymentMethodTableTableUpdateCompanionBuilder =
    PaymentMethodTableCompanion Function({
      Value<int> id,
      Value<String> code,
      Value<String> name,
      Value<bool> enabled,
    });

class $$PaymentMethodTableTableFilterComposer
    extends Composer<_$AppDatabase, $PaymentMethodTableTable> {
  $$PaymentMethodTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PaymentMethodTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PaymentMethodTableTable> {
  $$PaymentMethodTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PaymentMethodTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PaymentMethodTableTable> {
  $$PaymentMethodTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);
}

class $$PaymentMethodTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PaymentMethodTableTable,
          PaymentMethodTableData,
          $$PaymentMethodTableTableFilterComposer,
          $$PaymentMethodTableTableOrderingComposer,
          $$PaymentMethodTableTableAnnotationComposer,
          $$PaymentMethodTableTableCreateCompanionBuilder,
          $$PaymentMethodTableTableUpdateCompanionBuilder,
          (
            PaymentMethodTableData,
            BaseReferences<
              _$AppDatabase,
              $PaymentMethodTableTable,
              PaymentMethodTableData
            >,
          ),
          PaymentMethodTableData,
          PrefetchHooks Function()
        > {
  $$PaymentMethodTableTableTableManager(
    _$AppDatabase db,
    $PaymentMethodTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaymentMethodTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaymentMethodTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PaymentMethodTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
              }) => PaymentMethodTableCompanion(
                id: id,
                code: code,
                name: name,
                enabled: enabled,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String code,
                required String name,
                Value<bool> enabled = const Value.absent(),
              }) => PaymentMethodTableCompanion.insert(
                id: id,
                code: code,
                name: name,
                enabled: enabled,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PaymentMethodTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PaymentMethodTableTable,
      PaymentMethodTableData,
      $$PaymentMethodTableTableFilterComposer,
      $$PaymentMethodTableTableOrderingComposer,
      $$PaymentMethodTableTableAnnotationComposer,
      $$PaymentMethodTableTableCreateCompanionBuilder,
      $$PaymentMethodTableTableUpdateCompanionBuilder,
      (
        PaymentMethodTableData,
        BaseReferences<
          _$AppDatabase,
          $PaymentMethodTableTable,
          PaymentMethodTableData
        >,
      ),
      PaymentMethodTableData,
      PrefetchHooks Function()
    >;
typedef $$CustomerAgreementTableTableCreateCompanionBuilder =
    CustomerAgreementTableCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
      Value<bool> enabled,
      Value<int?> serverId,
      Value<String> agreementId,
      required String customerId,
      required String productId,
      required double unitPrice,
      required String validFrom,
      Value<String?> validTo,
      Value<String?> reason,
      Value<int> rowid,
    });
typedef $$CustomerAgreementTableTableUpdateCompanionBuilder =
    CustomerAgreementTableCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
      Value<bool> enabled,
      Value<int?> serverId,
      Value<String> agreementId,
      Value<String> customerId,
      Value<String> productId,
      Value<double> unitPrice,
      Value<String> validFrom,
      Value<String?> validTo,
      Value<String?> reason,
      Value<int> rowid,
    });

final class $$CustomerAgreementTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CustomerAgreementTableTable,
          CustomerAgreementTableData
        > {
  $$CustomerAgreementTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CustomerTableTable _customerIdTable(_$AppDatabase db) =>
      db.customerTable.createAlias(
        $_aliasNameGenerator(
          db.customerAgreementTable.customerId,
          db.customerTable.customerId,
        ),
      );

  $$CustomerTableTableProcessedTableManager get customerId {
    final $_column = $_itemColumn<String>('customer_id')!;

    final manager = $$CustomerTableTableTableManager(
      $_db,
      $_db.customerTable,
    ).filter((f) => f.customerId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_customerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ProductTableTable _productIdTable(_$AppDatabase db) =>
      db.productTable.createAlias(
        $_aliasNameGenerator(
          db.customerAgreementTable.productId,
          db.productTable.productId,
        ),
      );

  $$ProductTableTableProcessedTableManager get productId {
    final $_column = $_itemColumn<String>('product_id')!;

    final manager = $$ProductTableTableTableManager(
      $_db,
      $_db.productTable,
    ).filter((f) => f.productId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CustomerAgreementTableTableFilterComposer
    extends Composer<_$AppDatabase, $CustomerAgreementTableTable> {
  $$CustomerAgreementTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get agreementId => $composableBuilder(
    column: $table.agreementId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get validFrom => $composableBuilder(
    column: $table.validFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get validTo => $composableBuilder(
    column: $table.validTo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  $$CustomerTableTableFilterComposer get customerId {
    final $$CustomerTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customerTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomerTableTableFilterComposer(
            $db: $db,
            $table: $db.customerTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductTableTableFilterComposer get productId {
    final $$ProductTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.productTable,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductTableTableFilterComposer(
            $db: $db,
            $table: $db.productTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CustomerAgreementTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomerAgreementTableTable> {
  $$CustomerAgreementTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get agreementId => $composableBuilder(
    column: $table.agreementId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get validFrom => $composableBuilder(
    column: $table.validFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get validTo => $composableBuilder(
    column: $table.validTo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  $$CustomerTableTableOrderingComposer get customerId {
    final $$CustomerTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customerTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomerTableTableOrderingComposer(
            $db: $db,
            $table: $db.customerTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductTableTableOrderingComposer get productId {
    final $$ProductTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.productTable,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductTableTableOrderingComposer(
            $db: $db,
            $table: $db.productTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CustomerAgreementTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomerAgreementTableTable> {
  $$CustomerAgreementTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModifiedDate => $composableBuilder(
    column: $table.lastModifiedDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get agreementId => $composableBuilder(
    column: $table.agreementId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<String> get validFrom =>
      $composableBuilder(column: $table.validFrom, builder: (column) => column);

  GeneratedColumn<String> get validTo =>
      $composableBuilder(column: $table.validTo, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  $$CustomerTableTableAnnotationComposer get customerId {
    final $$CustomerTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customerTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomerTableTableAnnotationComposer(
            $db: $db,
            $table: $db.customerTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductTableTableAnnotationComposer get productId {
    final $$ProductTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.productTable,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductTableTableAnnotationComposer(
            $db: $db,
            $table: $db.productTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CustomerAgreementTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomerAgreementTableTable,
          CustomerAgreementTableData,
          $$CustomerAgreementTableTableFilterComposer,
          $$CustomerAgreementTableTableOrderingComposer,
          $$CustomerAgreementTableTableAnnotationComposer,
          $$CustomerAgreementTableTableCreateCompanionBuilder,
          $$CustomerAgreementTableTableUpdateCompanionBuilder,
          (CustomerAgreementTableData, $$CustomerAgreementTableTableReferences),
          CustomerAgreementTableData,
          PrefetchHooks Function({bool customerId, bool productId})
        > {
  $$CustomerAgreementTableTableTableManager(
    _$AppDatabase db,
    $CustomerAgreementTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomerAgreementTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CustomerAgreementTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CustomerAgreementTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModifiedDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> agreementId = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<double> unitPrice = const Value.absent(),
                Value<String> validFrom = const Value.absent(),
                Value<String?> validTo = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomerAgreementTableCompanion(
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
                enabled: enabled,
                serverId: serverId,
                agreementId: agreementId,
                customerId: customerId,
                productId: productId,
                unitPrice: unitPrice,
                validFrom: validFrom,
                validTo: validTo,
                reason: reason,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModifiedDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> agreementId = const Value.absent(),
                required String customerId,
                required String productId,
                required double unitPrice,
                required String validFrom,
                Value<String?> validTo = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomerAgreementTableCompanion.insert(
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
                enabled: enabled,
                serverId: serverId,
                agreementId: agreementId,
                customerId: customerId,
                productId: productId,
                unitPrice: unitPrice,
                validFrom: validFrom,
                validTo: validTo,
                reason: reason,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CustomerAgreementTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({customerId = false, productId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (customerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.customerId,
                                referencedTable:
                                    $$CustomerAgreementTableTableReferences
                                        ._customerIdTable(db),
                                referencedColumn:
                                    $$CustomerAgreementTableTableReferences
                                        ._customerIdTable(db)
                                        .customerId,
                              )
                              as T;
                    }
                    if (productId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.productId,
                                referencedTable:
                                    $$CustomerAgreementTableTableReferences
                                        ._productIdTable(db),
                                referencedColumn:
                                    $$CustomerAgreementTableTableReferences
                                        ._productIdTable(db)
                                        .productId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CustomerAgreementTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomerAgreementTableTable,
      CustomerAgreementTableData,
      $$CustomerAgreementTableTableFilterComposer,
      $$CustomerAgreementTableTableOrderingComposer,
      $$CustomerAgreementTableTableAnnotationComposer,
      $$CustomerAgreementTableTableCreateCompanionBuilder,
      $$CustomerAgreementTableTableUpdateCompanionBuilder,
      (CustomerAgreementTableData, $$CustomerAgreementTableTableReferences),
      CustomerAgreementTableData,
      PrefetchHooks Function({bool customerId, bool productId})
    >;
typedef $$SyncStateTableTableCreateCompanionBuilder =
    SyncStateTableCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SyncStateTableTableUpdateCompanionBuilder =
    SyncStateTableCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SyncStateTableTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStateTableTable> {
  $$SyncStateTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStateTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStateTableTable> {
  $$SyncStateTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStateTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStateTableTable> {
  $$SyncStateTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SyncStateTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStateTableTable,
          SyncStateTableData,
          $$SyncStateTableTableFilterComposer,
          $$SyncStateTableTableOrderingComposer,
          $$SyncStateTableTableAnnotationComposer,
          $$SyncStateTableTableCreateCompanionBuilder,
          $$SyncStateTableTableUpdateCompanionBuilder,
          (
            SyncStateTableData,
            BaseReferences<
              _$AppDatabase,
              $SyncStateTableTable,
              SyncStateTableData
            >,
          ),
          SyncStateTableData,
          PrefetchHooks Function()
        > {
  $$SyncStateTableTableTableManager(
    _$AppDatabase db,
    $SyncStateTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) =>
                  SyncStateTableCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SyncStateTableCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStateTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStateTableTable,
      SyncStateTableData,
      $$SyncStateTableTableFilterComposer,
      $$SyncStateTableTableOrderingComposer,
      $$SyncStateTableTableAnnotationComposer,
      $$SyncStateTableTableCreateCompanionBuilder,
      $$SyncStateTableTableUpdateCompanionBuilder,
      (
        SyncStateTableData,
        BaseReferences<_$AppDatabase, $SyncStateTableTable, SyncStateTableData>,
      ),
      SyncStateTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CustomerTableTableTableManager get customerTable =>
      $$CustomerTableTableTableManager(_db, _db.customerTable);
  $$CustomerAddressTableTableTableManager get customerAddressTable =>
      $$CustomerAddressTableTableTableManager(_db, _db.customerAddressTable);
  $$CustomerPreferenceTableTableTableManager get customerPreferenceTable =>
      $$CustomerPreferenceTableTableTableManager(
        _db,
        _db.customerPreferenceTable,
      );
  $$RouteTableTableTableManager get routeTable =>
      $$RouteTableTableTableManager(_db, _db.routeTable);
  $$RouteStopTableTableTableManager get routeStopTable =>
      $$RouteStopTableTableTableManager(_db, _db.routeStopTable);
  $$ProductTableTableTableManager get productTable =>
      $$ProductTableTableTableManager(_db, _db.productTable);
  $$RouteInventoryTableTableTableManager get routeInventoryTable =>
      $$RouteInventoryTableTableTableManager(_db, _db.routeInventoryTable);
  $$VisitOutcomeTableTableTableManager get visitOutcomeTable =>
      $$VisitOutcomeTableTableTableManager(_db, _db.visitOutcomeTable);
  $$VisitTableTableTableManager get visitTable =>
      $$VisitTableTableTableManager(_db, _db.visitTable);
  $$SaleTableTableTableManager get saleTable =>
      $$SaleTableTableTableManager(_db, _db.saleTable);
  $$SaleItemTableTableTableManager get saleItemTable =>
      $$SaleItemTableTableTableManager(_db, _db.saleItemTable);
  $$PaymentTableTableTableManager get paymentTable =>
      $$PaymentTableTableTableManager(_db, _db.paymentTable);
  $$CustomerAccountEntryTableTableTableManager get customerAccountEntryTable =>
      $$CustomerAccountEntryTableTableTableManager(
        _db,
        _db.customerAccountEntryTable,
      );
  $$CustomerBalanceTableTableTableManager get customerBalanceTable =>
      $$CustomerBalanceTableTableTableManager(_db, _db.customerBalanceTable);
  $$ContainerMovementTableTableTableManager get containerMovementTable =>
      $$ContainerMovementTableTableTableManager(
        _db,
        _db.containerMovementTable,
      );
  $$CustomerContainerBalanceTableTableTableManager
  get customerContainerBalanceTable =>
      $$CustomerContainerBalanceTableTableTableManager(
        _db,
        _db.customerContainerBalanceTable,
      );
  $$RouteInventoryLoadTableTableTableManager get routeInventoryLoadTable =>
      $$RouteInventoryLoadTableTableTableManager(
        _db,
        _db.routeInventoryLoadTable,
      );
  $$PendingChangeTableTableTableManager get pendingChangeTable =>
      $$PendingChangeTableTableTableManager(_db, _db.pendingChangeTable);
  $$ContainerTypeTableTableTableManager get containerTypeTable =>
      $$ContainerTypeTableTableTableManager(_db, _db.containerTypeTable);
  $$PaymentMethodTableTableTableManager get paymentMethodTable =>
      $$PaymentMethodTableTableTableManager(_db, _db.paymentMethodTable);
  $$CustomerAgreementTableTableTableManager get customerAgreementTable =>
      $$CustomerAgreementTableTableTableManager(
        _db,
        _db.customerAgreementTable,
      );
  $$SyncStateTableTableTableManager get syncStateTable =>
      $$SyncStateTableTableTableManager(_db, _db.syncStateTable);
}
