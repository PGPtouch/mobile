import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared/shared.dart';

part 'contact_store.g.dart';

@TableIndex(name: "contacts_fingerprint", columns: {#fingerprint})
class Contacts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get displayName => text().nullable()();

  BlobColumn get fingerprint => blob()();
  BlobColumn get data => blob().unique()();

  BoolColumn get isRevoked => boolean()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime().nullable()();
}

extension ContactExtension on Contact {
  List<ContactUserIdsCompanion> generateInsertsForUserIds(
    List<String> userIds,
  ) {
    if (userIds.isEmpty) return const [];
    final parsed = userIds.map(UserId.parse);
    return parsed
        .map(
          (u) => ContactUserIdsCompanion.insert(
            parent: id,
            name: .absentIfNull(u.name),
            comment: .absentIfNull(u.comment),
            email: u.email,
          ),
        )
        .toList();
  }

  Future<List<ContactUserId>> getUserIds(ContactStore db) =>
      (db.select(db.contactUserIds)..where((u) => u.parent.equals(id))).get();
}

class ContactUserIds extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get parent => integer().references(
    Contacts,
    #id,
    onUpdate: .cascade,
    onDelete: .cascade,
  )();

  TextColumn get name => text().nullable()();
  TextColumn get comment => text().nullable()();
  TextColumn get email => text()();
}

@DriftDatabase(tables: [Contacts, ContactUserIds])
class ContactStore extends _$ContactStore {
  ContactStore([QueryExecutor? executor])
    : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() => driftDatabase(
    name: "contactStore",
    native: const DriftNativeOptions(
      databaseDirectory: getApplicationDocumentsDirectory,
    ),
  );

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: _schemaUpgrade,
    beforeOpen: (details) async =>
        await customStatement("PRAGMA foreign_keys = ON"),
  );

  Future<void> insertContact(ContactsCompanion contact, List<String> userIds) =>
      transaction(() async {
        final id = await into(contacts).insert(contact);
        final insertedContact = await (select(
          contacts,
        )..where((c) => c.id.equals(id))).getSingleOrNull();
        if (insertedContact == null) {
          throw Exception("Failed to insert contact");
        }
        for (final insert in insertedContact.generateInsertsForUserIds(
          userIds,
        )) {
          await into(contactUserIds).insert(insert);
        }
      });

  Future<void> updateContact(
    ContactsCompanion contact,
    List<String> userIds,
  ) => transaction(() async {
    final existing =
        await (select(contacts)
              ..where((c) => c.fingerprint.equals(contact.fingerprint.value)))
            .getSingleOrNull();
    if (existing == null) {
      throw Exception("Failed to update contact: contact not found");
    }
    final id = existing.id;
    if (contact.id.present && contact.id.value != id) {
      throw ArgumentError("updateContact must not change the id of a contact");
    }
    await update(contacts).replace(contact.copyWith(id: Value(id)));
    final updatedContact = await (select(
      contacts,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
    if (updatedContact == null) {
      throw Exception("Failed to update contact");
    }
    await (delete(contactUserIds)..where((u) => u.parent.equals(id))).go();
    for (final insert in updatedContact.generateInsertsForUserIds(userIds)) {
      await into(contactUserIds).insert(insert);
    }
  });

  Future<Contact> getByFingerprint(Uint8List fingerprint) => (select(
    contacts,
  )..where((k) => k.fingerprint.equals(fingerprint))).getSingle();

  Future<List<Contact>> getByEmail(String email) async {
    final contactIds =
        (await (select(
              contactUserIds,
            )..where((u) => u.email.equals(email))).get())
            .map((u) => u.parent)
            .toList();
    return (select(contacts)..where((c) => c.id.isIn(contactIds))).get();
  }
}

extension Migrations on GeneratedDatabase {
  OnUpgrade get _schemaUpgrade {
    // return stepByStep(from1To2: (m, schema) async {});
    return (_, _, _) => Future.syncValue(null);
  }
}
