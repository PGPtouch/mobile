import 'dart:async';

import 'package:material_helper/material_helper.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/components/identity_tile.dart';
import 'package:mobile/database/contact_store.dart';
import 'package:mobile/l10n/app_localizations.dart';

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
  bool _dataLoaded = false;

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
    _dataLoaded = true;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return MaterialLoadedWidgetBuilder(
      animationStyle: .all,
      builder: (context) {
        if (!_dataLoaded) return null;

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
                return IdentityTile(
                  key: ValueKey(contact.id),
                  keyData: .new(contact),
                  userIds: userIds.toInterchangeable(),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}
