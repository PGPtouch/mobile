import 'dart:async';

import 'package:material_graphics/material_graphics.dart';
import 'package:material_helper/material_helper.dart';
import 'package:material_ui/material_ui.dart' hide Key;
import 'package:mobile/components/step_by_step_guide_dialog.dart';
import 'package:mobile/database/key_store.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/screens/screen_run.dart';

class ScreenIdentities extends StatefulWidget {
  const new({super.key});

  @override
  State<ScreenIdentities> createState() => _ScreenIdentitiesState();
}

class _ScreenIdentitiesState extends State<ScreenIdentities> {
  final _keys = <Key>{};
  final _keyUserIds = <KeyUserId>{};
  StreamSubscription<List<Key>>? _keySubscription;

  bool _loading = false;
  KeyStore? get _keyStore => KeyStoreHandler.instance.keyStore;

  @override
  void initState() {
    super.initState();
    KeyStoreHandler.instance.addListener(onData);
    _dataLoaderInit();
  }

  @override
  void dispose() {
    _keySubscription?.cancel();
    KeyStoreHandler.instance.removeListener(onData);
    super.dispose();
  }

  void onData() {
    _dataLoaderInit();
  }

  void _dataLoaderInit() {
    if (_keyStore == null) return;
    _keySubscription = _keyStore!
        .select(_keyStore!.keys)
        .watch()
        .listen(_loadData);
    _keyStore?.select(_keyStore!.keys).get().then(_loadData);
  }

  Future<void> _loadData(List<Key> newData) async {
    if (_keyStore == null) return;
    final newData = await _keyStore!.select(_keyStore!.keys).get();
    final newDataIds = newData.map((key) => key.id).toSet();
    final newKeyUserIds = await (_keyStore!.select(
      _keyStore!.keyUserIds,
    )..where((c) => c.parent.isIn(newDataIds))).get();
    _keys
      ..clear()
      ..addAll(newData);
    _keyUserIds
      ..clear()
      ..addAll(newKeyUserIds);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return MaterialLoadedWidgetBuilder(
      animationStyle: .all,
      builder: (context) {
        if (_keyStore == null) {
          // Returning null makes the widget show its loading indicator.
          if (!KeyStoreHandler.instance.isLocked || _loading) return null;
          return SizedBox.expand(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () async {
                _loading = true;
                if (mounted) setState(() {});
                final result = await KeyStoreHandler.instance.unlock(
                  appLocalizations,
                );
                _loading = false;
                if (!mounted) return;
                setState(() {});
                if (result == UnlockResult.deviceReauthRequired) {
                  showKeyStoreReauthRequiredDialog(context);
                }
              },
              child: Column(
                mainAxisSize: .min,
                mainAxisAlignment: .center,
                crossAxisAlignment: .center,
                children: [
                  DecoratedBox(
                    decoration: MaterialShapes.ghostish.toShapeDecoration(
                      color: colorScheme.primary,
                    ),
                    child: SizedBox.square(dimension: 128),
                  ),
                  Text(
                    appLocalizations.identitiesUnlock,
                    style: textTheme.headlineMedium!
                        .copyWith(color: colorScheme.primary, height: 0.8)
                        .bagelFatOne,
                  ),
                ],
              ),
            ),
          );
        }

        if (_keys.isEmpty) {
          return Center(
            child: Text(
              appLocalizations.identitiesEmpty,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium!.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        return ListView(
          children: [
            ...MaterialListTile.group(
              _keys.map((key) {
                final userIds = _keyUserIds
                    .where((c) => c.parent == key.id)
                    .toList();
                return MaterialListTile(
                  title: Text(
                    "${userIds.first.name ?? "–"} (${userIds.first.email})",
                  ),
                  subtitle: Builder(
                    builder: (context) => Text(
                      formatFingerprint(key.fingerprint),
                      style: DefaultTextStyle.of(context).style.googleSansCode,
                    ),
                  ),
                  isThreeLine: true,
                  onLongPress: () {
                    final keyStore = KeyStoreHandler.instance.keyStore!;
                    keyStore.transaction(() async {
                      await (keyStore.delete(
                        keyStore.keys,
                      )..where((c) => c.id.equals(key.id))).go();
                      await (keyStore.delete(
                        keyStore.keyUserIds,
                      )..where((c) => c.parent.equals(key.id))).go();
                      await KeyStoreHandler.instance.deleteKeyPassphrase(
                        key.fingerprint,
                      );
                    });
                  },
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}
