import 'dart:async';

import 'package:material_graphics/material_graphics.dart';
import 'package:material_helper/material_helper.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/database/contact_store.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/screens/screen_run.dart';

var contactStore = ContactStore();

class ScreenContacts extends StatefulWidget {
  const new({super.key});

  @override
  State<ScreenContacts> createState() => _ScreenContactsState();
}

class _ScreenContactsState extends State<ScreenContacts> {
  final _contacts = <Contact>{};
  final _contactUserIds = <ContactUserId>{};
  late final StreamSubscription<List<Contact>> _contactSubscription;

  @override
  void initState() {
    super.initState();
    _contactSubscription = contactStore
        .select(contactStore.contacts)
        .watch()
        .listen(_loadData);
    contactStore.select(contactStore.contacts).get().then(_loadData);
  }

  @override
  void dispose() {
    _contactSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadData(List<Contact> newData) async {
    final newData = await contactStore.select(contactStore.contacts).get();
    final newDataIds = newData.map((contact) => contact.id).toSet();
    final newContactUserIds = await (contactStore.select(
      contactStore.contactUserIds,
    )..where((c) => c.parent.isIn(newDataIds))).get();
    _contacts
      ..clear()
      ..addAll(newData);
    _contactUserIds
      ..clear()
      ..addAll(newContactUserIds);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (_contacts.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).contactsEmpty,
          style: textTheme.bodyMedium!.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return ListView(
      children: [
        ...MaterialListTile.group(
          _contacts.map((contact) {
            final userIds = _contactUserIds
                .where((c) => c.parent == contact.id)
                .toList();
            return MaterialListTile(
              title: Text(
                "${contact.displayName ?? ""}\n${userIds.first.name ?? "–"} (${userIds.first.email})"
                    .trim(),
              ),
              subtitle: Builder(
                builder: (context) => Text(
                  formatFingerprint(contact.fingerprint),
                  style: DefaultTextStyle.of(context).style.googleSansCode,
                ),
              ),
              isThreeLine: true,
              onLongPress: () => contactStore.transaction(() async {
                await (contactStore.delete(
                  contactStore.contacts,
                )..where((c) => c.id.equals(contact.id))).go();
                await (contactStore.delete(
                  contactStore.contactUserIds,
                )..where((c) => c.parent.equals(contact.id))).go();
              }),
            );
          }).toList(),
        ),
      ],
    );
  }
}
