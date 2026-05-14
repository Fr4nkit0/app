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
  final String customerId;
  final String name;
  final String? phone;
  const CustomerTableData({
    required this.createdAt,
    required this.lastModifiedDate,
    required this.enabled,
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
      'customerId': serializer.toJson<String>(customerId),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String?>(phone),
    };
  }

  CustomerTableData copyWith({
    DateTime? createdAt,
    DateTime? lastModifiedDate,
    bool? enabled,
    String? customerId,
    String? name,
    Value<String?> phone = const Value.absent(),
  }) => CustomerTableData(
    createdAt: createdAt ?? this.createdAt,
    lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
    enabled: enabled ?? this.enabled,
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
          other.customerId == this.customerId &&
          other.name == this.name &&
          other.phone == this.phone);
}

class CustomerTableCompanion extends UpdateCompanion<CustomerTableData> {
  final Value<DateTime> createdAt;
  final Value<DateTime> lastModifiedDate;
  final Value<bool> enabled;
  final Value<String> customerId;
  final Value<String> name;
  final Value<String?> phone;
  final Value<int> rowid;
  const CustomerTableCompanion({
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.customerId = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomerTableCompanion.insert({
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.customerId = const Value.absent(),
    required String name,
    this.phone = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name);
  static Insertable<CustomerTableData> custom({
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastModifiedDate,
    Expression<bool>? enabled,
    Expression<String>? customerId,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (lastModifiedDate != null) 'last_modified_date': lastModifiedDate,
      if (enabled != null) 'enabled': enabled,
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
    Value<String>? customerId,
    Value<String>? name,
    Value<String?>? phone,
    Value<int>? rowid,
  }) {
    return CustomerTableCompanion(
      createdAt: createdAt ?? this.createdAt,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      enabled: enabled ?? this.enabled,
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
  @override
  List<GeneratedColumn> get $columns => [
    createdAt,
    lastModifiedDate,
    enabled,
    addressId,
    street,
    apartment,
    floor,
    visualReference,
    isPrimary,
    customerId,
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
  final String addressId;
  final String? street;
  final String? apartment;
  final String? floor;
  final String? visualReference;
  final bool isPrimary;
  final String customerId;
  const CustomerAddressTableData({
    required this.createdAt,
    required this.lastModifiedDate,
    required this.enabled,
    required this.addressId,
    this.street,
    this.apartment,
    this.floor,
    this.visualReference,
    required this.isPrimary,
    required this.customerId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_modified_date'] = Variable<DateTime>(lastModifiedDate);
    map['enabled'] = Variable<bool>(enabled);
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
    return map;
  }

  CustomerAddressTableCompanion toCompanion(bool nullToAbsent) {
    return CustomerAddressTableCompanion(
      createdAt: Value(createdAt),
      lastModifiedDate: Value(lastModifiedDate),
      enabled: Value(enabled),
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
      addressId: serializer.fromJson<String>(json['addressId']),
      street: serializer.fromJson<String?>(json['street']),
      apartment: serializer.fromJson<String?>(json['apartment']),
      floor: serializer.fromJson<String?>(json['floor']),
      visualReference: serializer.fromJson<String?>(json['visualReference']),
      isPrimary: serializer.fromJson<bool>(json['isPrimary']),
      customerId: serializer.fromJson<String>(json['customerId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastModifiedDate': serializer.toJson<DateTime>(lastModifiedDate),
      'enabled': serializer.toJson<bool>(enabled),
      'addressId': serializer.toJson<String>(addressId),
      'street': serializer.toJson<String?>(street),
      'apartment': serializer.toJson<String?>(apartment),
      'floor': serializer.toJson<String?>(floor),
      'visualReference': serializer.toJson<String?>(visualReference),
      'isPrimary': serializer.toJson<bool>(isPrimary),
      'customerId': serializer.toJson<String>(customerId),
    };
  }

  CustomerAddressTableData copyWith({
    DateTime? createdAt,
    DateTime? lastModifiedDate,
    bool? enabled,
    String? addressId,
    Value<String?> street = const Value.absent(),
    Value<String?> apartment = const Value.absent(),
    Value<String?> floor = const Value.absent(),
    Value<String?> visualReference = const Value.absent(),
    bool? isPrimary,
    String? customerId,
  }) => CustomerAddressTableData(
    createdAt: createdAt ?? this.createdAt,
    lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
    enabled: enabled ?? this.enabled,
    addressId: addressId ?? this.addressId,
    street: street.present ? street.value : this.street,
    apartment: apartment.present ? apartment.value : this.apartment,
    floor: floor.present ? floor.value : this.floor,
    visualReference: visualReference.present
        ? visualReference.value
        : this.visualReference,
    isPrimary: isPrimary ?? this.isPrimary,
    customerId: customerId ?? this.customerId,
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
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomerAddressTableData(')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedDate: $lastModifiedDate, ')
          ..write('enabled: $enabled, ')
          ..write('addressId: $addressId, ')
          ..write('street: $street, ')
          ..write('apartment: $apartment, ')
          ..write('floor: $floor, ')
          ..write('visualReference: $visualReference, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('customerId: $customerId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    createdAt,
    lastModifiedDate,
    enabled,
    addressId,
    street,
    apartment,
    floor,
    visualReference,
    isPrimary,
    customerId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerAddressTableData &&
          other.createdAt == this.createdAt &&
          other.lastModifiedDate == this.lastModifiedDate &&
          other.enabled == this.enabled &&
          other.addressId == this.addressId &&
          other.street == this.street &&
          other.apartment == this.apartment &&
          other.floor == this.floor &&
          other.visualReference == this.visualReference &&
          other.isPrimary == this.isPrimary &&
          other.customerId == this.customerId);
}

class CustomerAddressTableCompanion
    extends UpdateCompanion<CustomerAddressTableData> {
  final Value<DateTime> createdAt;
  final Value<DateTime> lastModifiedDate;
  final Value<bool> enabled;
  final Value<String> addressId;
  final Value<String?> street;
  final Value<String?> apartment;
  final Value<String?> floor;
  final Value<String?> visualReference;
  final Value<bool> isPrimary;
  final Value<String> customerId;
  final Value<int> rowid;
  const CustomerAddressTableCompanion({
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.addressId = const Value.absent(),
    this.street = const Value.absent(),
    this.apartment = const Value.absent(),
    this.floor = const Value.absent(),
    this.visualReference = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.customerId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomerAddressTableCompanion.insert({
    this.createdAt = const Value.absent(),
    this.lastModifiedDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.addressId = const Value.absent(),
    this.street = const Value.absent(),
    this.apartment = const Value.absent(),
    this.floor = const Value.absent(),
    this.visualReference = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.customerId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  static Insertable<CustomerAddressTableData> custom({
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastModifiedDate,
    Expression<bool>? enabled,
    Expression<String>? addressId,
    Expression<String>? street,
    Expression<String>? apartment,
    Expression<String>? floor,
    Expression<String>? visualReference,
    Expression<bool>? isPrimary,
    Expression<String>? customerId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (lastModifiedDate != null) 'last_modified_date': lastModifiedDate,
      if (enabled != null) 'enabled': enabled,
      if (addressId != null) 'address_id': addressId,
      if (street != null) 'street': street,
      if (apartment != null) 'apartment': apartment,
      if (floor != null) 'floor': floor,
      if (visualReference != null) 'visual_reference': visualReference,
      if (isPrimary != null) 'is_primary': isPrimary,
      if (customerId != null) 'customer_id': customerId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomerAddressTableCompanion copyWith({
    Value<DateTime>? createdAt,
    Value<DateTime>? lastModifiedDate,
    Value<bool>? enabled,
    Value<String>? addressId,
    Value<String?>? street,
    Value<String?>? apartment,
    Value<String?>? floor,
    Value<String?>? visualReference,
    Value<bool>? isPrimary,
    Value<String>? customerId,
    Value<int>? rowid,
  }) {
    return CustomerAddressTableCompanion(
      createdAt: createdAt ?? this.createdAt,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      enabled: enabled ?? this.enabled,
      addressId: addressId ?? this.addressId,
      street: street ?? this.street,
      apartment: apartment ?? this.apartment,
      floor: floor ?? this.floor,
      visualReference: visualReference ?? this.visualReference,
      isPrimary: isPrimary ?? this.isPrimary,
      customerId: customerId ?? this.customerId,
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
          ..write('addressId: $addressId, ')
          ..write('street: $street, ')
          ..write('apartment: $apartment, ')
          ..write('floor: $floor, ')
          ..write('visualReference: $visualReference, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('customerId: $customerId, ')
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
  final String customerPreferenceId;
  final String customerId;
  final int dayOfWeek;
  final String timeWindowStart;
  final String? timeWindowEnd;
  const CustomerPreferenceTableData({
    required this.createdAt,
    required this.lastModifiedDate,
    required this.enabled,
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
    String? customerPreferenceId,
    String? customerId,
    int? dayOfWeek,
    String? timeWindowStart,
    Value<String?> timeWindowEnd = const Value.absent(),
  }) => CustomerPreferenceTableData(
    createdAt: createdAt ?? this.createdAt,
    lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
    enabled: enabled ?? this.enabled,
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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CustomerTableTable customerTable = $CustomerTableTable(this);
  late final $CustomerAddressTableTable customerAddressTable =
      $CustomerAddressTableTable(this);
  late final $CustomerPreferenceTableTable customerPreferenceTable =
      $CustomerPreferenceTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    customerTable,
    customerAddressTable,
    customerPreferenceTable,
  ];
}

typedef $$CustomerTableTableCreateCompanionBuilder =
    CustomerTableCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
      Value<bool> enabled,
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
      Value<String> customerId,
      Value<String> name,
      Value<String?> phone,
      Value<int> rowid,
    });

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

  GeneratedColumn<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);
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
          (
            CustomerTableData,
            BaseReferences<
              _$AppDatabase,
              $CustomerTableTable,
              CustomerTableData
            >,
          ),
          CustomerTableData,
          PrefetchHooks Function()
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
                Value<String> customerId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomerTableCompanion(
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
                enabled: enabled,
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
                Value<String> customerId = const Value.absent(),
                required String name,
                Value<String?> phone = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomerTableCompanion.insert(
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
                enabled: enabled,
                customerId: customerId,
                name: name,
                phone: phone,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
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
      (
        CustomerTableData,
        BaseReferences<_$AppDatabase, $CustomerTableTable, CustomerTableData>,
      ),
      CustomerTableData,
      PrefetchHooks Function()
    >;
typedef $$CustomerAddressTableTableCreateCompanionBuilder =
    CustomerAddressTableCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
      Value<bool> enabled,
      Value<String> addressId,
      Value<String?> street,
      Value<String?> apartment,
      Value<String?> floor,
      Value<String?> visualReference,
      Value<bool> isPrimary,
      Value<String> customerId,
      Value<int> rowid,
    });
typedef $$CustomerAddressTableTableUpdateCompanionBuilder =
    CustomerAddressTableCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
      Value<bool> enabled,
      Value<String> addressId,
      Value<String?> street,
      Value<String?> apartment,
      Value<String?> floor,
      Value<String?> visualReference,
      Value<bool> isPrimary,
      Value<String> customerId,
      Value<int> rowid,
    });

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
          (
            CustomerAddressTableData,
            BaseReferences<
              _$AppDatabase,
              $CustomerAddressTableTable,
              CustomerAddressTableData
            >,
          ),
          CustomerAddressTableData,
          PrefetchHooks Function()
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
                Value<String> addressId = const Value.absent(),
                Value<String?> street = const Value.absent(),
                Value<String?> apartment = const Value.absent(),
                Value<String?> floor = const Value.absent(),
                Value<String?> visualReference = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomerAddressTableCompanion(
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
                enabled: enabled,
                addressId: addressId,
                street: street,
                apartment: apartment,
                floor: floor,
                visualReference: visualReference,
                isPrimary: isPrimary,
                customerId: customerId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastModifiedDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<String> addressId = const Value.absent(),
                Value<String?> street = const Value.absent(),
                Value<String?> apartment = const Value.absent(),
                Value<String?> floor = const Value.absent(),
                Value<String?> visualReference = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomerAddressTableCompanion.insert(
                createdAt: createdAt,
                lastModifiedDate: lastModifiedDate,
                enabled: enabled,
                addressId: addressId,
                street: street,
                apartment: apartment,
                floor: floor,
                visualReference: visualReference,
                isPrimary: isPrimary,
                customerId: customerId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
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
      (
        CustomerAddressTableData,
        BaseReferences<
          _$AppDatabase,
          $CustomerAddressTableTable,
          CustomerAddressTableData
        >,
      ),
      CustomerAddressTableData,
      PrefetchHooks Function()
    >;
typedef $$CustomerPreferenceTableTableCreateCompanionBuilder =
    CustomerPreferenceTableCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> lastModifiedDate,
      Value<bool> enabled,
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
}
