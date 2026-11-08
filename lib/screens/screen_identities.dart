import 'dart:async';

import 'package:material_graphics/material_graphics.dart';
import 'package:material_helper/material_helper.dart';
import 'package:material_ui/material_ui.dart' hide Key;
import 'package:shared/shared.dart';

import '../components/identity_tile.dart';
import '../components/step_by_step_guide_dialog.dart';
import '../database/key_store.dart';
import '../l10n/app_localizations.dart';

class ScreenIdentities extends StatefulWidget {
  final void Function(int id, String display, DateTime? expiration)
  onIdentitySelected;
  final void Function(int id, String display, DateTime? expiration)
  onIdentityUpdated;
  final void Function(int id) onIdentityDeleted;

  const new({
    super.key,
    required this.onIdentitySelected,
    required this.onIdentityUpdated,
    required this.onIdentityDeleted,
  });

  @override
  State<ScreenIdentities> createState() => _ScreenIdentitiesState();
}

class _ScreenIdentitiesState extends State<ScreenIdentities> {
  final _keys = <Key>{};
  final _keyUserIds = <KeyUserId>{};
  StreamSubscription<List<Key>>? _keySubscription;

  bool _loading = false;
  bool _dataLoaded = false;
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
    if (_keyStore == null) {
      _keySubscription?.cancel();
      _keySubscription = null;
      _dataLoaded = false;
      if (mounted) setState(() {});
      return;
    }
    _keySubscription?.cancel();
    _keySubscription = _keyStore!
        .select(_keyStore!.keys)
        .watch()
        .listen(_loadData);
    _keyStore?.select(_keyStore!.keys).get().then(_loadData);
  }

  Future<void> _loadData(List<Key> newData) async {
    if (_keyStore == null) return;
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
    _dataLoaded = true;
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
                if (result == UnlockResult.deviceReauthRequired &&
                    context.mounted) {
                  showKeyStoreReauthRequiredDialog(context);
                }
              },
              child: Builder(
                builder: (context) {
                  final style = textTheme.headlineMedium!
                      .copyWith(color: colorScheme.onPrimary)
                      .bagelFatOne;
                  final textPainter = TextPainter(
                    text: TextSpan(
                      text: appLocalizations.identitiesUnlock,
                      style: style,
                    ),
                    textDirection: Directionality.of(context),
                    textScaler: MediaQuery.textScalerOf(context),
                  )..layout();
                  final height = textPainter.height + 16 + 24;
                  final width = textPainter.width + 16 + 16;
                  final side = width > height ? width : height;

                  return Column(
                    mainAxisSize: .min,
                    mainAxisAlignment: .center,
                    crossAxisAlignment: .center,
                    children: [
                      SizedBox.square(
                        dimension: side,
                        child: DecoratedBox(
                          decoration: ShapeDecoration(
                            color: colorScheme.primary,
                            shape: MaterialShapeBorder(
                              shape: MaterialShapes.ghostish,
                            ),
                          ),
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(16).copyWith(top: 24),
                              child: Text(
                                appLocalizations.identitiesUnlock,
                                style: style,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        }

        if (!_dataLoaded) return null;

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
                void onSelectedUpdated(
                  void Function(int, String, DateTime?) callback,
                ) => callback(
                  key.id,
                  userIds
                      .map(
                        (u) => UserId(
                          name: u.name,
                          comment: u.comment,
                          email: u.email,
                        ).toString(),
                      )
                      .join(","),
                  key.expiresAt,
                );
                return IdentityTile(
                  key: ValueKey(key.id),
                  keyData: .new(key),
                  userIds: userIds.toInterchangeable(),
                  onTap: () => onSelectedUpdated(widget.onIdentitySelected),
                  onUpdate: () => onSelectedUpdated(widget.onIdentityUpdated),
                  onDeleted: () => widget.onIdentityDeleted(key.id),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}
