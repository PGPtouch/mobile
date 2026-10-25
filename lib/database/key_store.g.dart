// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'key_store.dart';

// ignore_for_file: type=lint
class $KeysTable extends Keys with TableInfo<$KeysTable, Key> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _fingerprintMeta = const VerificationMeta(
    'fingerprint',
  );
  @override
  late final GeneratedColumn<Uint8List> fingerprint =
      GeneratedColumn<Uint8List>(
        'fingerprint',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _publicDataMeta = const VerificationMeta(
    'publicData',
  );
  @override
  late final GeneratedColumn<Uint8List> publicData = GeneratedColumn<Uint8List>(
    'public_data',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _privateDataMeta = const VerificationMeta(
    'privateData',
  );
  @override
  late final GeneratedColumn<Uint8List> privateData =
      GeneratedColumn<Uint8List>(
        'private_data',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      );
  static const VerificationMeta _isRevokedMeta = const VerificationMeta(
    'isRevoked',
  );
  @override
  late final GeneratedColumn<bool> isRevoked = GeneratedColumn<bool>(
    'is_revoked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_revoked" IN (0, 1))',
    ),
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fingerprint,
    publicData,
    privateData,
    isRevoked,
    createdAt,
    expiresAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'keys';
  @override
  VerificationContext validateIntegrity(
    Insertable<Key> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('fingerprint')) {
      context.handle(
        _fingerprintMeta,
        fingerprint.isAcceptableOrUnknown(
          data['fingerprint']!,
          _fingerprintMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fingerprintMeta);
    }
    if (data.containsKey('public_data')) {
      context.handle(
        _publicDataMeta,
        publicData.isAcceptableOrUnknown(data['public_data']!, _publicDataMeta),
      );
    } else if (isInserting) {
      context.missing(_publicDataMeta);
    }
    if (data.containsKey('private_data')) {
      context.handle(
        _privateDataMeta,
        privateData.isAcceptableOrUnknown(
          data['private_data']!,
          _privateDataMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_privateDataMeta);
    }
    if (data.containsKey('is_revoked')) {
      context.handle(
        _isRevokedMeta,
        isRevoked.isAcceptableOrUnknown(data['is_revoked']!, _isRevokedMeta),
      );
    } else if (isInserting) {
      context.missing(_isRevokedMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Key map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Key(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      fingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}fingerprint'],
      )!,
      publicData: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}public_data'],
      )!,
      privateData: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}private_data'],
      )!,
      isRevoked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_revoked'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      ),
    );
  }

  @override
  $KeysTable createAlias(String alias) {
    return $KeysTable(attachedDatabase, alias);
  }
}

class Key extends DataClass implements Insertable<Key> {
  final int id;
  final Uint8List fingerprint;
  final Uint8List publicData;
  final Uint8List privateData;
  final bool isRevoked;
  final DateTime createdAt;
  final DateTime? expiresAt;
  const Key({
    required this.id,
    required this.fingerprint,
    required this.publicData,
    required this.privateData,
    required this.isRevoked,
    required this.createdAt,
    this.expiresAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['fingerprint'] = Variable<Uint8List>(fingerprint);
    map['public_data'] = Variable<Uint8List>(publicData);
    map['private_data'] = Variable<Uint8List>(privateData);
    map['is_revoked'] = Variable<bool>(isRevoked);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<DateTime>(expiresAt);
    }
    return map;
  }

  KeysCompanion toCompanion(bool nullToAbsent) {
    return KeysCompanion(
      id: Value(id),
      fingerprint: Value(fingerprint),
      publicData: Value(publicData),
      privateData: Value(privateData),
      isRevoked: Value(isRevoked),
      createdAt: Value(createdAt),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
    );
  }

  factory Key.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Key(
      id: serializer.fromJson<int>(json['id']),
      fingerprint: serializer.fromJson<Uint8List>(json['fingerprint']),
      publicData: serializer.fromJson<Uint8List>(json['publicData']),
      privateData: serializer.fromJson<Uint8List>(json['privateData']),
      isRevoked: serializer.fromJson<bool>(json['isRevoked']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      expiresAt: serializer.fromJson<DateTime?>(json['expiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fingerprint': serializer.toJson<Uint8List>(fingerprint),
      'publicData': serializer.toJson<Uint8List>(publicData),
      'privateData': serializer.toJson<Uint8List>(privateData),
      'isRevoked': serializer.toJson<bool>(isRevoked),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'expiresAt': serializer.toJson<DateTime?>(expiresAt),
    };
  }

  Key copyWith({
    int? id,
    Uint8List? fingerprint,
    Uint8List? publicData,
    Uint8List? privateData,
    bool? isRevoked,
    DateTime? createdAt,
    Value<DateTime?> expiresAt = const Value.absent(),
  }) => Key(
    id: id ?? this.id,
    fingerprint: fingerprint ?? this.fingerprint,
    publicData: publicData ?? this.publicData,
    privateData: privateData ?? this.privateData,
    isRevoked: isRevoked ?? this.isRevoked,
    createdAt: createdAt ?? this.createdAt,
    expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
  );
  Key copyWithCompanion(KeysCompanion data) {
    return Key(
      id: data.id.present ? data.id.value : this.id,
      fingerprint: data.fingerprint.present
          ? data.fingerprint.value
          : this.fingerprint,
      publicData: data.publicData.present
          ? data.publicData.value
          : this.publicData,
      privateData: data.privateData.present
          ? data.privateData.value
          : this.privateData,
      isRevoked: data.isRevoked.present ? data.isRevoked.value : this.isRevoked,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Key(')
          ..write('id: $id, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('publicData: $publicData, ')
          ..write('privateData: $privateData, ')
          ..write('isRevoked: $isRevoked, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    $driftBlobEquality.hash(fingerprint),
    $driftBlobEquality.hash(publicData),
    $driftBlobEquality.hash(privateData),
    isRevoked,
    createdAt,
    expiresAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Key &&
          other.id == this.id &&
          $driftBlobEquality.equals(other.fingerprint, this.fingerprint) &&
          $driftBlobEquality.equals(other.publicData, this.publicData) &&
          $driftBlobEquality.equals(other.privateData, this.privateData) &&
          other.isRevoked == this.isRevoked &&
          other.createdAt == this.createdAt &&
          other.expiresAt == this.expiresAt);
}

class KeysCompanion extends UpdateCompanion<Key> {
  final Value<int> id;
  final Value<Uint8List> fingerprint;
  final Value<Uint8List> publicData;
  final Value<Uint8List> privateData;
  final Value<bool> isRevoked;
  final Value<DateTime> createdAt;
  final Value<DateTime?> expiresAt;
  const KeysCompanion({
    this.id = const Value.absent(),
    this.fingerprint = const Value.absent(),
    this.publicData = const Value.absent(),
    this.privateData = const Value.absent(),
    this.isRevoked = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
  });
  KeysCompanion.insert({
    this.id = const Value.absent(),
    required Uint8List fingerprint,
    required Uint8List publicData,
    required Uint8List privateData,
    required bool isRevoked,
    required DateTime createdAt,
    this.expiresAt = const Value.absent(),
  }) : fingerprint = Value(fingerprint),
       publicData = Value(publicData),
       privateData = Value(privateData),
       isRevoked = Value(isRevoked),
       createdAt = Value(createdAt);
  static Insertable<Key> custom({
    Expression<int>? id,
    Expression<Uint8List>? fingerprint,
    Expression<Uint8List>? publicData,
    Expression<Uint8List>? privateData,
    Expression<bool>? isRevoked,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? expiresAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fingerprint != null) 'fingerprint': fingerprint,
      if (publicData != null) 'public_data': publicData,
      if (privateData != null) 'private_data': privateData,
      if (isRevoked != null) 'is_revoked': isRevoked,
      if (createdAt != null) 'created_at': createdAt,
      if (expiresAt != null) 'expires_at': expiresAt,
    });
  }

  KeysCompanion copyWith({
    Value<int>? id,
    Value<Uint8List>? fingerprint,
    Value<Uint8List>? publicData,
    Value<Uint8List>? privateData,
    Value<bool>? isRevoked,
    Value<DateTime>? createdAt,
    Value<DateTime?>? expiresAt,
  }) {
    return KeysCompanion(
      id: id ?? this.id,
      fingerprint: fingerprint ?? this.fingerprint,
      publicData: publicData ?? this.publicData,
      privateData: privateData ?? this.privateData,
      isRevoked: isRevoked ?? this.isRevoked,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fingerprint.present) {
      map['fingerprint'] = Variable<Uint8List>(fingerprint.value);
    }
    if (publicData.present) {
      map['public_data'] = Variable<Uint8List>(publicData.value);
    }
    if (privateData.present) {
      map['private_data'] = Variable<Uint8List>(privateData.value);
    }
    if (isRevoked.present) {
      map['is_revoked'] = Variable<bool>(isRevoked.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KeysCompanion(')
          ..write('id: $id, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('publicData: $publicData, ')
          ..write('privateData: $privateData, ')
          ..write('isRevoked: $isRevoked, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }
}

class $KeyUserIdsTable extends KeyUserIds
    with TableInfo<$KeyUserIdsTable, KeyUserId> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeyUserIdsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _parentMeta = const VerificationMeta('parent');
  @override
  late final GeneratedColumn<int> parent = GeneratedColumn<int>(
    'parent',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES keys (id) ON UPDATE CASCADE ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _commentMeta = const VerificationMeta(
    'comment',
  );
  @override
  late final GeneratedColumn<String> comment = GeneratedColumn<String>(
    'comment',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, parent, name, comment, email];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'key_user_ids';
  @override
  VerificationContext validateIntegrity(
    Insertable<KeyUserId> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('parent')) {
      context.handle(
        _parentMeta,
        parent.isAcceptableOrUnknown(data['parent']!, _parentMeta),
      );
    } else if (isInserting) {
      context.missing(_parentMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('comment')) {
      context.handle(
        _commentMeta,
        comment.isAcceptableOrUnknown(data['comment']!, _commentMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KeyUserId map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KeyUserId(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      parent: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parent'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      comment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comment'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
    );
  }

  @override
  $KeyUserIdsTable createAlias(String alias) {
    return $KeyUserIdsTable(attachedDatabase, alias);
  }
}

class KeyUserId extends DataClass implements Insertable<KeyUserId> {
  final int id;
  final int parent;
  final String? name;
  final String? comment;
  final String email;
  const KeyUserId({
    required this.id,
    required this.parent,
    this.name,
    this.comment,
    required this.email,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['parent'] = Variable<int>(parent);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || comment != null) {
      map['comment'] = Variable<String>(comment);
    }
    map['email'] = Variable<String>(email);
    return map;
  }

  KeyUserIdsCompanion toCompanion(bool nullToAbsent) {
    return KeyUserIdsCompanion(
      id: Value(id),
      parent: Value(parent),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      comment: comment == null && nullToAbsent
          ? const Value.absent()
          : Value(comment),
      email: Value(email),
    );
  }

  factory KeyUserId.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KeyUserId(
      id: serializer.fromJson<int>(json['id']),
      parent: serializer.fromJson<int>(json['parent']),
      name: serializer.fromJson<String?>(json['name']),
      comment: serializer.fromJson<String?>(json['comment']),
      email: serializer.fromJson<String>(json['email']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'parent': serializer.toJson<int>(parent),
      'name': serializer.toJson<String?>(name),
      'comment': serializer.toJson<String?>(comment),
      'email': serializer.toJson<String>(email),
    };
  }

  KeyUserId copyWith({
    int? id,
    int? parent,
    Value<String?> name = const Value.absent(),
    Value<String?> comment = const Value.absent(),
    String? email,
  }) => KeyUserId(
    id: id ?? this.id,
    parent: parent ?? this.parent,
    name: name.present ? name.value : this.name,
    comment: comment.present ? comment.value : this.comment,
    email: email ?? this.email,
  );
  KeyUserId copyWithCompanion(KeyUserIdsCompanion data) {
    return KeyUserId(
      id: data.id.present ? data.id.value : this.id,
      parent: data.parent.present ? data.parent.value : this.parent,
      name: data.name.present ? data.name.value : this.name,
      comment: data.comment.present ? data.comment.value : this.comment,
      email: data.email.present ? data.email.value : this.email,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KeyUserId(')
          ..write('id: $id, ')
          ..write('parent: $parent, ')
          ..write('name: $name, ')
          ..write('comment: $comment, ')
          ..write('email: $email')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, parent, name, comment, email);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KeyUserId &&
          other.id == this.id &&
          other.parent == this.parent &&
          other.name == this.name &&
          other.comment == this.comment &&
          other.email == this.email);
}

class KeyUserIdsCompanion extends UpdateCompanion<KeyUserId> {
  final Value<int> id;
  final Value<int> parent;
  final Value<String?> name;
  final Value<String?> comment;
  final Value<String> email;
  const KeyUserIdsCompanion({
    this.id = const Value.absent(),
    this.parent = const Value.absent(),
    this.name = const Value.absent(),
    this.comment = const Value.absent(),
    this.email = const Value.absent(),
  });
  KeyUserIdsCompanion.insert({
    this.id = const Value.absent(),
    required int parent,
    this.name = const Value.absent(),
    this.comment = const Value.absent(),
    required String email,
  }) : parent = Value(parent),
       email = Value(email);
  static Insertable<KeyUserId> custom({
    Expression<int>? id,
    Expression<int>? parent,
    Expression<String>? name,
    Expression<String>? comment,
    Expression<String>? email,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (parent != null) 'parent': parent,
      if (name != null) 'name': name,
      if (comment != null) 'comment': comment,
      if (email != null) 'email': email,
    });
  }

  KeyUserIdsCompanion copyWith({
    Value<int>? id,
    Value<int>? parent,
    Value<String?>? name,
    Value<String?>? comment,
    Value<String>? email,
  }) {
    return KeyUserIdsCompanion(
      id: id ?? this.id,
      parent: parent ?? this.parent,
      name: name ?? this.name,
      comment: comment ?? this.comment,
      email: email ?? this.email,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (parent.present) {
      map['parent'] = Variable<int>(parent.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (comment.present) {
      map['comment'] = Variable<String>(comment.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KeyUserIdsCompanion(')
          ..write('id: $id, ')
          ..write('parent: $parent, ')
          ..write('name: $name, ')
          ..write('comment: $comment, ')
          ..write('email: $email')
          ..write(')'))
        .toString();
  }
}

abstract class _$KeyStore extends GeneratedDatabase {
  _$KeyStore(QueryExecutor e) : super(e);
  $KeyStoreManager get managers => $KeyStoreManager(this);
  late final $KeysTable keys = $KeysTable(this);
  late final $KeyUserIdsTable keyUserIds = $KeyUserIdsTable(this);
  late final Index keysFingerprint = Index(
    'keys_fingerprint',
    'CREATE INDEX keys_fingerprint ON keys (fingerprint)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    keys,
    keyUserIds,
    keysFingerprint,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'keys',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('key_user_ids', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'keys',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('key_user_ids', kind: UpdateKind.update)],
    ),
  ]);
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$KeysTableCreateCompanionBuilder = KeysCompanion Function({
  Value<int> id,
  required Uint8List fingerprint,
  required Uint8List publicData,
  required Uint8List privateData,
  required bool isRevoked,
  required DateTime createdAt,
  Value<DateTime?> expiresAt,
});
typedef $$KeysTableUpdateCompanionBuilder = KeysCompanion Function({
  Value<int> id,
  Value<Uint8List> fingerprint,
  Value<Uint8List> publicData,
  Value<Uint8List> privateData,
  Value<bool> isRevoked,
  Value<DateTime> createdAt,
  Value<DateTime?> expiresAt,
});

final class $$KeysTableReferences
    extends BaseReferences<_$KeyStore, $KeysTable, Key> {
  $$KeysTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$KeyUserIdsTable, List<KeyUserId>>
  _keyUserIdsRefsTable(_$KeyStore db) => MultiTypedResultKey.fromTable(
    db.keyUserIds,
    aliasName: 'keys__id__key_user_ids__parent',
  );

  $$KeyUserIdsTableProcessedTableManager get keyUserIdsRefs {
    final manager = $$KeyUserIdsTableTableManager(
      $_db,
      $_db.keyUserIds,
    ).filter((f) => f.parent.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_keyUserIdsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$KeysTableFilterComposer extends Composer<_$KeyStore, $KeysTable> {
  $$KeysTableFilterComposer({
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

  ColumnFilters<Uint8List> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get publicData => $composableBuilder(
    column: $table.publicData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get privateData => $composableBuilder(
    column: $table.privateData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRevoked => $composableBuilder(
    column: $table.isRevoked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> keyUserIdsRefs(
    Expression<bool> Function($$KeyUserIdsTableFilterComposer f) f,
  ) {
    final $$KeyUserIdsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.keyUserIds,
      getReferencedColumn: (t) => t.parent,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KeyUserIdsTableFilterComposer(
            $db: $db,
            $table: $db.keyUserIds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$KeysTableOrderingComposer extends Composer<_$KeyStore, $KeysTable> {
  $$KeysTableOrderingComposer({
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

  ColumnOrderings<Uint8List> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get publicData => $composableBuilder(
    column: $table.publicData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get privateData => $composableBuilder(
    column: $table.privateData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRevoked => $composableBuilder(
    column: $table.isRevoked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KeysTableAnnotationComposer extends Composer<_$KeyStore, $KeysTable> {
  $$KeysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<Uint8List> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get publicData => $composableBuilder(
    column: $table.publicData,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get privateData => $composableBuilder(
    column: $table.privateData,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isRevoked =>
      $composableBuilder(column: $table.isRevoked, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  Expression<T> keyUserIdsRefs<T extends Object>(
    Expression<T> Function($$KeyUserIdsTableAnnotationComposer a) f,
  ) {
    final $$KeyUserIdsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.keyUserIds,
      getReferencedColumn: (t) => t.parent,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KeyUserIdsTableAnnotationComposer(
            $db: $db,
            $table: $db.keyUserIds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$KeysTableTableManager
    extends
        RootTableManager<
          _$KeyStore,
          $KeysTable,
          Key,
          $$KeysTableFilterComposer,
          $$KeysTableOrderingComposer,
          $$KeysTableAnnotationComposer,
          $$KeysTableCreateCompanionBuilder,
          $$KeysTableUpdateCompanionBuilder,
          (Key, $$KeysTableReferences),
          Key,
          PrefetchHooks Function({bool keyUserIdsRefs})
        > {
  $$KeysTableTableManager(_$KeyStore db, $KeysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KeysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KeysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KeysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<Uint8List> fingerprint = const Value.absent(),
                Value<Uint8List> publicData = const Value.absent(),
                Value<Uint8List> privateData = const Value.absent(),
                Value<bool> isRevoked = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> expiresAt = const Value.absent(),
              }) => KeysCompanion(
                id: id,
                fingerprint: fingerprint,
                publicData: publicData,
                privateData: privateData,
                isRevoked: isRevoked,
                createdAt: createdAt,
                expiresAt: expiresAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required Uint8List fingerprint,
                required Uint8List publicData,
                required Uint8List privateData,
                required bool isRevoked,
                required DateTime createdAt,
                Value<DateTime?> expiresAt = const Value.absent(),
              }) => KeysCompanion.insert(
                id: id,
                fingerprint: fingerprint,
                publicData: publicData,
                privateData: privateData,
                isRevoked: isRevoked,
                createdAt: createdAt,
                expiresAt: expiresAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KeysTable, Key>(table),
                  $$KeysTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({keyUserIdsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (keyUserIdsRefs) db.keyUserIds],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (keyUserIdsRefs)
                    await $_getPrefetchedDataByColumns<
                      Key,
                      $KeysTable,
                      KeyUserId,
                      $KeyUserIdsTable
                    >(
                      currentTable: table,
                      referencedTable: $$KeysTableReferences
                          ._keyUserIdsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$KeysTableReferences(db, table, p0).keyUserIdsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'parent',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$KeysTableProcessedTableManager =
    ProcessedTableManager<
      _$KeyStore,
      $KeysTable,
      Key,
      $$KeysTableFilterComposer,
      $$KeysTableOrderingComposer,
      $$KeysTableAnnotationComposer,
      $$KeysTableCreateCompanionBuilder,
      $$KeysTableUpdateCompanionBuilder,
      (Key, $$KeysTableReferences),
      Key,
      PrefetchHooks Function({bool keyUserIdsRefs})
    >;
typedef $$KeyUserIdsTableCreateCompanionBuilder = KeyUserIdsCompanion Function({
  Value<int> id,
  required int parent,
  Value<String?> name,
  Value<String?> comment,
  required String email,
});
typedef $$KeyUserIdsTableUpdateCompanionBuilder = KeyUserIdsCompanion Function({
  Value<int> id,
  Value<int> parent,
  Value<String?> name,
  Value<String?> comment,
  Value<String> email,
});

final class $$KeyUserIdsTableReferences
    extends BaseReferences<_$KeyStore, $KeyUserIdsTable, KeyUserId> {
  $$KeyUserIdsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $KeysTable _parentTable(_$KeyStore db) =>
      db.keys.createAlias('key_user_ids__parent__keys__id');

  $$KeysTableProcessedTableManager get parent {
    final $_column = $_itemColumn<int>('parent')!;

    final manager = $$KeysTableTableManager(
      $_db,
      $_db.keys,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$KeyUserIdsTableFilterComposer
    extends Composer<_$KeyStore, $KeyUserIdsTable> {
  $$KeyUserIdsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  $$KeysTableFilterComposer get parent {
    final $$KeysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parent,
      referencedTable: $db.keys,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KeysTableFilterComposer(
            $db: $db,
            $table: $db.keys,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$KeyUserIdsTableOrderingComposer
    extends Composer<_$KeyStore, $KeyUserIdsTable> {
  $$KeyUserIdsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  $$KeysTableOrderingComposer get parent {
    final $$KeysTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parent,
      referencedTable: $db.keys,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KeysTableOrderingComposer(
            $db: $db,
            $table: $db.keys,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$KeyUserIdsTableAnnotationComposer
    extends Composer<_$KeyStore, $KeyUserIdsTable> {
  $$KeyUserIdsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get comment =>
      $composableBuilder(column: $table.comment, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  $$KeysTableAnnotationComposer get parent {
    final $$KeysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parent,
      referencedTable: $db.keys,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KeysTableAnnotationComposer(
            $db: $db,
            $table: $db.keys,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$KeyUserIdsTableTableManager
    extends
        RootTableManager<
          _$KeyStore,
          $KeyUserIdsTable,
          KeyUserId,
          $$KeyUserIdsTableFilterComposer,
          $$KeyUserIdsTableOrderingComposer,
          $$KeyUserIdsTableAnnotationComposer,
          $$KeyUserIdsTableCreateCompanionBuilder,
          $$KeyUserIdsTableUpdateCompanionBuilder,
          (KeyUserId, $$KeyUserIdsTableReferences),
          KeyUserId,
          PrefetchHooks Function({bool parent})
        > {
  $$KeyUserIdsTableTableManager(_$KeyStore db, $KeyUserIdsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KeyUserIdsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KeyUserIdsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KeyUserIdsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> parent = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> comment = const Value.absent(),
                Value<String> email = const Value.absent(),
              }) => KeyUserIdsCompanion(
                id: id,
                parent: parent,
                name: name,
                comment: comment,
                email: email,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int parent,
                Value<String?> name = const Value.absent(),
                Value<String?> comment = const Value.absent(),
                required String email,
              }) => KeyUserIdsCompanion.insert(
                id: id,
                parent: parent,
                name: name,
                comment: comment,
                email: email,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KeyUserIdsTable, KeyUserId>(table),
                  $$KeyUserIdsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({parent = false}) {
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
                    if (parent) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.parent,
                        referencedTable: $$KeyUserIdsTableReferences
                            ._parentTable(db),
                        referencedColumn: $$KeyUserIdsTableReferences
                            ._parentTable(db)
                            .id,
                      ) as T;
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

typedef $$KeyUserIdsTableProcessedTableManager =
    ProcessedTableManager<
      _$KeyStore,
      $KeyUserIdsTable,
      KeyUserId,
      $$KeyUserIdsTableFilterComposer,
      $$KeyUserIdsTableOrderingComposer,
      $$KeyUserIdsTableAnnotationComposer,
      $$KeyUserIdsTableCreateCompanionBuilder,
      $$KeyUserIdsTableUpdateCompanionBuilder,
      (KeyUserId, $$KeyUserIdsTableReferences),
      KeyUserId,
      PrefetchHooks Function({bool parent})
    >;

class $KeyStoreManager {
  final _$KeyStore _db;
  $KeyStoreManager(this._db);
  $$KeysTableTableManager get keys => $$KeysTableTableManager(_db, _db.keys);
  $$KeyUserIdsTableTableManager get keyUserIds =>
      $$KeyUserIdsTableTableManager(_db, _db.keyUserIds);
}
