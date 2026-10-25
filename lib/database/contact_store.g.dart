// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_store.dart';

// ignore_for_file: type=lint
class $ContactsTable extends Contacts with TableInfo<$ContactsTable, Contact> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<Uint8List> data = GeneratedColumn<Uint8List>(
    'data',
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
    displayName,
    fingerprint,
    data,
    isRevoked,
    createdAt,
    expiresAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contacts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Contact> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
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
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
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
  Contact map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Contact(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      ),
      fingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}fingerprint'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}data'],
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
  $ContactsTable createAlias(String alias) {
    return $ContactsTable(attachedDatabase, alias);
  }
}

class Contact extends DataClass implements Insertable<Contact> {
  final int id;
  final String? displayName;
  final Uint8List fingerprint;
  final Uint8List data;
  final bool isRevoked;
  final DateTime createdAt;
  final DateTime? expiresAt;
  const Contact({
    required this.id,
    this.displayName,
    required this.fingerprint,
    required this.data,
    required this.isRevoked,
    required this.createdAt,
    this.expiresAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    map['fingerprint'] = Variable<Uint8List>(fingerprint);
    map['data'] = Variable<Uint8List>(data);
    map['is_revoked'] = Variable<bool>(isRevoked);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<DateTime>(expiresAt);
    }
    return map;
  }

  ContactsCompanion toCompanion(bool nullToAbsent) {
    return ContactsCompanion(
      id: Value(id),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      fingerprint: Value(fingerprint),
      data: Value(data),
      isRevoked: Value(isRevoked),
      createdAt: Value(createdAt),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
    );
  }

  factory Contact.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Contact(
      id: serializer.fromJson<int>(json['id']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      fingerprint: serializer.fromJson<Uint8List>(json['fingerprint']),
      data: serializer.fromJson<Uint8List>(json['data']),
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
      'displayName': serializer.toJson<String?>(displayName),
      'fingerprint': serializer.toJson<Uint8List>(fingerprint),
      'data': serializer.toJson<Uint8List>(data),
      'isRevoked': serializer.toJson<bool>(isRevoked),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'expiresAt': serializer.toJson<DateTime?>(expiresAt),
    };
  }

  Contact copyWith({
    int? id,
    Value<String?> displayName = const Value.absent(),
    Uint8List? fingerprint,
    Uint8List? data,
    bool? isRevoked,
    DateTime? createdAt,
    Value<DateTime?> expiresAt = const Value.absent(),
  }) => Contact(
    id: id ?? this.id,
    displayName: displayName.present ? displayName.value : this.displayName,
    fingerprint: fingerprint ?? this.fingerprint,
    data: data ?? this.data,
    isRevoked: isRevoked ?? this.isRevoked,
    createdAt: createdAt ?? this.createdAt,
    expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
  );
  Contact copyWithCompanion(ContactsCompanion data) {
    return Contact(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      fingerprint: data.fingerprint.present
          ? data.fingerprint.value
          : this.fingerprint,
      data: data.data.present ? data.data.value : this.data,
      isRevoked: data.isRevoked.present ? data.isRevoked.value : this.isRevoked,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Contact(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('data: $data, ')
          ..write('isRevoked: $isRevoked, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    displayName,
    $driftBlobEquality.hash(fingerprint),
    $driftBlobEquality.hash(data),
    isRevoked,
    createdAt,
    expiresAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Contact &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          $driftBlobEquality.equals(other.fingerprint, this.fingerprint) &&
          $driftBlobEquality.equals(other.data, this.data) &&
          other.isRevoked == this.isRevoked &&
          other.createdAt == this.createdAt &&
          other.expiresAt == this.expiresAt);
}

class ContactsCompanion extends UpdateCompanion<Contact> {
  final Value<int> id;
  final Value<String?> displayName;
  final Value<Uint8List> fingerprint;
  final Value<Uint8List> data;
  final Value<bool> isRevoked;
  final Value<DateTime> createdAt;
  final Value<DateTime?> expiresAt;
  const ContactsCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.fingerprint = const Value.absent(),
    this.data = const Value.absent(),
    this.isRevoked = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
  });
  ContactsCompanion.insert({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    required Uint8List fingerprint,
    required Uint8List data,
    required bool isRevoked,
    required DateTime createdAt,
    this.expiresAt = const Value.absent(),
  }) : fingerprint = Value(fingerprint),
       data = Value(data),
       isRevoked = Value(isRevoked),
       createdAt = Value(createdAt);
  static Insertable<Contact> custom({
    Expression<int>? id,
    Expression<String>? displayName,
    Expression<Uint8List>? fingerprint,
    Expression<Uint8List>? data,
    Expression<bool>? isRevoked,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? expiresAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (fingerprint != null) 'fingerprint': fingerprint,
      if (data != null) 'data': data,
      if (isRevoked != null) 'is_revoked': isRevoked,
      if (createdAt != null) 'created_at': createdAt,
      if (expiresAt != null) 'expires_at': expiresAt,
    });
  }

  ContactsCompanion copyWith({
    Value<int>? id,
    Value<String?>? displayName,
    Value<Uint8List>? fingerprint,
    Value<Uint8List>? data,
    Value<bool>? isRevoked,
    Value<DateTime>? createdAt,
    Value<DateTime?>? expiresAt,
  }) {
    return ContactsCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      fingerprint: fingerprint ?? this.fingerprint,
      data: data ?? this.data,
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
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (fingerprint.present) {
      map['fingerprint'] = Variable<Uint8List>(fingerprint.value);
    }
    if (data.present) {
      map['data'] = Variable<Uint8List>(data.value);
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
    return (StringBuffer('ContactsCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('data: $data, ')
          ..write('isRevoked: $isRevoked, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }
}

class $ContactUserIdsTable extends ContactUserIds
    with TableInfo<$ContactUserIdsTable, ContactUserId> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactUserIdsTable(this.attachedDatabase, [this._alias]);
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
      'REFERENCES contacts (id) ON UPDATE CASCADE ON DELETE CASCADE',
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
  static const String $name = 'contact_user_ids';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContactUserId> instance, {
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
  ContactUserId map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContactUserId(
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
  $ContactUserIdsTable createAlias(String alias) {
    return $ContactUserIdsTable(attachedDatabase, alias);
  }
}

class ContactUserId extends DataClass implements Insertable<ContactUserId> {
  final int id;
  final int parent;
  final String? name;
  final String? comment;
  final String email;
  const ContactUserId({
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

  ContactUserIdsCompanion toCompanion(bool nullToAbsent) {
    return ContactUserIdsCompanion(
      id: Value(id),
      parent: Value(parent),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      comment: comment == null && nullToAbsent
          ? const Value.absent()
          : Value(comment),
      email: Value(email),
    );
  }

  factory ContactUserId.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContactUserId(
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

  ContactUserId copyWith({
    int? id,
    int? parent,
    Value<String?> name = const Value.absent(),
    Value<String?> comment = const Value.absent(),
    String? email,
  }) => ContactUserId(
    id: id ?? this.id,
    parent: parent ?? this.parent,
    name: name.present ? name.value : this.name,
    comment: comment.present ? comment.value : this.comment,
    email: email ?? this.email,
  );
  ContactUserId copyWithCompanion(ContactUserIdsCompanion data) {
    return ContactUserId(
      id: data.id.present ? data.id.value : this.id,
      parent: data.parent.present ? data.parent.value : this.parent,
      name: data.name.present ? data.name.value : this.name,
      comment: data.comment.present ? data.comment.value : this.comment,
      email: data.email.present ? data.email.value : this.email,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContactUserId(')
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
      (other is ContactUserId &&
          other.id == this.id &&
          other.parent == this.parent &&
          other.name == this.name &&
          other.comment == this.comment &&
          other.email == this.email);
}

class ContactUserIdsCompanion extends UpdateCompanion<ContactUserId> {
  final Value<int> id;
  final Value<int> parent;
  final Value<String?> name;
  final Value<String?> comment;
  final Value<String> email;
  const ContactUserIdsCompanion({
    this.id = const Value.absent(),
    this.parent = const Value.absent(),
    this.name = const Value.absent(),
    this.comment = const Value.absent(),
    this.email = const Value.absent(),
  });
  ContactUserIdsCompanion.insert({
    this.id = const Value.absent(),
    required int parent,
    this.name = const Value.absent(),
    this.comment = const Value.absent(),
    required String email,
  }) : parent = Value(parent),
       email = Value(email);
  static Insertable<ContactUserId> custom({
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

  ContactUserIdsCompanion copyWith({
    Value<int>? id,
    Value<int>? parent,
    Value<String?>? name,
    Value<String?>? comment,
    Value<String>? email,
  }) {
    return ContactUserIdsCompanion(
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
    return (StringBuffer('ContactUserIdsCompanion(')
          ..write('id: $id, ')
          ..write('parent: $parent, ')
          ..write('name: $name, ')
          ..write('comment: $comment, ')
          ..write('email: $email')
          ..write(')'))
        .toString();
  }
}

abstract class _$ContactStore extends GeneratedDatabase {
  _$ContactStore(QueryExecutor e) : super(e);
  $ContactStoreManager get managers => $ContactStoreManager(this);
  late final $ContactsTable contacts = $ContactsTable(this);
  late final $ContactUserIdsTable contactUserIds = $ContactUserIdsTable(this);
  late final Index contactsFingerprint = Index(
    'contacts_fingerprint',
    'CREATE INDEX contacts_fingerprint ON contacts (fingerprint)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    contacts,
    contactUserIds,
    contactsFingerprint,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'contacts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('contact_user_ids', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'contacts',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('contact_user_ids', kind: UpdateKind.update)],
    ),
  ]);
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$ContactsTableCreateCompanionBuilder = ContactsCompanion Function({
  Value<int> id,
  Value<String?> displayName,
  required Uint8List fingerprint,
  required Uint8List data,
  required bool isRevoked,
  required DateTime createdAt,
  Value<DateTime?> expiresAt,
});
typedef $$ContactsTableUpdateCompanionBuilder = ContactsCompanion Function({
  Value<int> id,
  Value<String?> displayName,
  Value<Uint8List> fingerprint,
  Value<Uint8List> data,
  Value<bool> isRevoked,
  Value<DateTime> createdAt,
  Value<DateTime?> expiresAt,
});

final class $$ContactsTableReferences
    extends BaseReferences<_$ContactStore, $ContactsTable, Contact> {
  $$ContactsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ContactUserIdsTable, List<ContactUserId>>
  _contactUserIdsRefsTable(_$ContactStore db) => MultiTypedResultKey.fromTable(
    db.contactUserIds,
    aliasName: 'contacts__id__contact_user_ids__parent',
  );

  $$ContactUserIdsTableProcessedTableManager get contactUserIdsRefs {
    final manager = $$ContactUserIdsTableTableManager(
      $_db,
      $_db.contactUserIds,
    ).filter((f) => f.parent.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_contactUserIdsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ContactsTableFilterComposer
    extends Composer<_$ContactStore, $ContactsTable> {
  $$ContactsTableFilterComposer({
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

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get data => $composableBuilder(
    column: $table.data,
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

  Expression<bool> contactUserIdsRefs(
    Expression<bool> Function($$ContactUserIdsTableFilterComposer f) f,
  ) {
    final $$ContactUserIdsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.contactUserIds,
      getReferencedColumn: (t) => t.parent,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactUserIdsTableFilterComposer(
            $db: $db,
            $table: $db.contactUserIds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ContactsTableOrderingComposer
    extends Composer<_$ContactStore, $ContactsTable> {
  $$ContactsTableOrderingComposer({
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

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get data => $composableBuilder(
    column: $table.data,
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

class $$ContactsTableAnnotationComposer
    extends Composer<_$ContactStore, $ContactsTable> {
  $$ContactsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<bool> get isRevoked =>
      $composableBuilder(column: $table.isRevoked, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  Expression<T> contactUserIdsRefs<T extends Object>(
    Expression<T> Function($$ContactUserIdsTableAnnotationComposer a) f,
  ) {
    final $$ContactUserIdsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.contactUserIds,
      getReferencedColumn: (t) => t.parent,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactUserIdsTableAnnotationComposer(
            $db: $db,
            $table: $db.contactUserIds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ContactsTableTableManager
    extends
        RootTableManager<
          _$ContactStore,
          $ContactsTable,
          Contact,
          $$ContactsTableFilterComposer,
          $$ContactsTableOrderingComposer,
          $$ContactsTableAnnotationComposer,
          $$ContactsTableCreateCompanionBuilder,
          $$ContactsTableUpdateCompanionBuilder,
          (Contact, $$ContactsTableReferences),
          Contact,
          PrefetchHooks Function({bool contactUserIdsRefs})
        > {
  $$ContactsTableTableManager(_$ContactStore db, $ContactsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContactsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContactsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContactsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<Uint8List> fingerprint = const Value.absent(),
                Value<Uint8List> data = const Value.absent(),
                Value<bool> isRevoked = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> expiresAt = const Value.absent(),
              }) => ContactsCompanion(
                id: id,
                displayName: displayName,
                fingerprint: fingerprint,
                data: data,
                isRevoked: isRevoked,
                createdAt: createdAt,
                expiresAt: expiresAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                required Uint8List fingerprint,
                required Uint8List data,
                required bool isRevoked,
                required DateTime createdAt,
                Value<DateTime?> expiresAt = const Value.absent(),
              }) => ContactsCompanion.insert(
                id: id,
                displayName: displayName,
                fingerprint: fingerprint,
                data: data,
                isRevoked: isRevoked,
                createdAt: createdAt,
                expiresAt: expiresAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ContactsTable, Contact>(table),
                  $$ContactsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({contactUserIdsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (contactUserIdsRefs) db.contactUserIds,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (contactUserIdsRefs)
                    await $_getPrefetchedDataByColumns<
                      Contact,
                      $ContactsTable,
                      ContactUserId,
                      $ContactUserIdsTable
                    >(
                      currentTable: table,
                      referencedTable: $$ContactsTableReferences
                          ._contactUserIdsRefsTable(db),
                      managerFromTypedResult: (p0) => $$ContactsTableReferences(
                        db,
                        table,
                        p0,
                      ).contactUserIdsRefs,
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

typedef $$ContactsTableProcessedTableManager =
    ProcessedTableManager<
      _$ContactStore,
      $ContactsTable,
      Contact,
      $$ContactsTableFilterComposer,
      $$ContactsTableOrderingComposer,
      $$ContactsTableAnnotationComposer,
      $$ContactsTableCreateCompanionBuilder,
      $$ContactsTableUpdateCompanionBuilder,
      (Contact, $$ContactsTableReferences),
      Contact,
      PrefetchHooks Function({bool contactUserIdsRefs})
    >;
typedef $$ContactUserIdsTableCreateCompanionBuilder =
    ContactUserIdsCompanion Function({
      Value<int> id,
      required int parent,
      Value<String?> name,
      Value<String?> comment,
      required String email,
    });
typedef $$ContactUserIdsTableUpdateCompanionBuilder =
    ContactUserIdsCompanion Function({
      Value<int> id,
      Value<int> parent,
      Value<String?> name,
      Value<String?> comment,
      Value<String> email,
    });

final class $$ContactUserIdsTableReferences
    extends
        BaseReferences<_$ContactStore, $ContactUserIdsTable, ContactUserId> {
  $$ContactUserIdsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ContactsTable _parentTable(_$ContactStore db) =>
      db.contacts.createAlias('contact_user_ids__parent__contacts__id');

  $$ContactsTableProcessedTableManager get parent {
    final $_column = $_itemColumn<int>('parent')!;

    final manager = $$ContactsTableTableManager(
      $_db,
      $_db.contacts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ContactUserIdsTableFilterComposer
    extends Composer<_$ContactStore, $ContactUserIdsTable> {
  $$ContactUserIdsTableFilterComposer({
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

  $$ContactsTableFilterComposer get parent {
    final $$ContactsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parent,
      referencedTable: $db.contacts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactsTableFilterComposer(
            $db: $db,
            $table: $db.contacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContactUserIdsTableOrderingComposer
    extends Composer<_$ContactStore, $ContactUserIdsTable> {
  $$ContactUserIdsTableOrderingComposer({
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

  $$ContactsTableOrderingComposer get parent {
    final $$ContactsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parent,
      referencedTable: $db.contacts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactsTableOrderingComposer(
            $db: $db,
            $table: $db.contacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContactUserIdsTableAnnotationComposer
    extends Composer<_$ContactStore, $ContactUserIdsTable> {
  $$ContactUserIdsTableAnnotationComposer({
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

  $$ContactsTableAnnotationComposer get parent {
    final $$ContactsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parent,
      referencedTable: $db.contacts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactsTableAnnotationComposer(
            $db: $db,
            $table: $db.contacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContactUserIdsTableTableManager
    extends
        RootTableManager<
          _$ContactStore,
          $ContactUserIdsTable,
          ContactUserId,
          $$ContactUserIdsTableFilterComposer,
          $$ContactUserIdsTableOrderingComposer,
          $$ContactUserIdsTableAnnotationComposer,
          $$ContactUserIdsTableCreateCompanionBuilder,
          $$ContactUserIdsTableUpdateCompanionBuilder,
          (ContactUserId, $$ContactUserIdsTableReferences),
          ContactUserId,
          PrefetchHooks Function({bool parent})
        > {
  $$ContactUserIdsTableTableManager(
    _$ContactStore db,
    $ContactUserIdsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContactUserIdsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContactUserIdsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContactUserIdsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> parent = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> comment = const Value.absent(),
                Value<String> email = const Value.absent(),
              }) => ContactUserIdsCompanion(
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
              }) => ContactUserIdsCompanion.insert(
                id: id,
                parent: parent,
                name: name,
                comment: comment,
                email: email,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ContactUserIdsTable, ContactUserId>(table),
                  $$ContactUserIdsTableReferences(db, table, e),
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
                        referencedTable: $$ContactUserIdsTableReferences
                            ._parentTable(db),
                        referencedColumn: $$ContactUserIdsTableReferences
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

typedef $$ContactUserIdsTableProcessedTableManager =
    ProcessedTableManager<
      _$ContactStore,
      $ContactUserIdsTable,
      ContactUserId,
      $$ContactUserIdsTableFilterComposer,
      $$ContactUserIdsTableOrderingComposer,
      $$ContactUserIdsTableAnnotationComposer,
      $$ContactUserIdsTableCreateCompanionBuilder,
      $$ContactUserIdsTableUpdateCompanionBuilder,
      (ContactUserId, $$ContactUserIdsTableReferences),
      ContactUserId,
      PrefetchHooks Function({bool parent})
    >;

class $ContactStoreManager {
  final _$ContactStore _db;
  $ContactStoreManager(this._db);
  $$ContactsTableTableManager get contacts =>
      $$ContactsTableTableManager(_db, _db.contacts);
  $$ContactUserIdsTableTableManager get contactUserIds =>
      $$ContactUserIdsTableTableManager(_db, _db.contactUserIds);
}
