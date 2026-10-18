import 'dart:convert';

import 'package:dart_pg/dart_pg.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_graphics/material_graphics.dart';
import 'package:material_helper/material_helper.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/components/snack_bar_manager.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:file_selector/file_selector.dart';
import 'package:mobile/main.dart';
import 'package:mobile/screens/screen_run.dart';
import 'package:mobile/states.dart';
import 'package:shared/shared.dart';
import 'package:shared/user_id.dart' as user_id;
import 'package:http/http.dart' as http;

String? _tryDecodeUtf8(Uint8List input) {
  try {
    return utf8.decode(input);
  } on FormatException {
    return null;
  }
}

final _armoredPublicKeyBlock = RegExp(
  r"-----BEGIN PGP PUBLIC KEY BLOCK-----[\s\S]*?-----END PGP PUBLIC KEY BLOCK-----",
);

String _keyStateDigest(PublicKey key) {
  final users =
      key.users
          .map((u) => "${u.userID}|${u.revocationSignatures.isNotEmpty}")
          .toList()
        ..sort();
  final subkeys =
      key.subkeys
          .map(
            (s) =>
                "${s.fingerprint.map((b) => b.toRadixString(16)).join()}"
                "|${s.expirationTime?.millisecondsSinceEpoch}"
                "|${s.revocationSignatures.isNotEmpty}",
          )
          .toList()
        ..sort();
  return [
    key.expirationTime?.millisecondsSinceEpoch,
    key.revocationSignatures.isNotEmpty,
    users.join(";"),
    subkeys.join(";"),
  ].join("#");
}

class _ContactSourceChooser extends StatefulWidget {
  const _ContactSourceChooser();

  @override
  State<_ContactSourceChooser> createState() => _ContactSourceChooserState();
}

class _ContactSourceChooserState extends State<_ContactSourceChooser> {
  bool _loadMode = false;
  bool _searchMode = false;

  final _searchController = TextEditingController();
  String? _searchControllerError;
  bool _isSearching = false;
  List<UserIdKeyFetchResult> _searchResults = [];

  List<PublicKey> _primarySearchResult = const [];
  Map<Uint8List, PublicKey?> _parsedResultKeys = const {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _processSelection(String source) async {
    if (_loadMode) return;
    _loadMode = true;
    if (mounted) setState(() {});
    final result = await Future.wait([
      _processSelectionFuture(source),
      if (source != "search") Future.delayed(Durations.long1),
    ]);
    if (!mounted) return;

    if (result.first == null) {
      _loadMode = false;
      if (mounted) setState(() {});
      return;
    }

    Navigator.of(context).pop(result.first.$1);
    if (result.first.$2 != null) {
      SnackBarManager.showSnackBar(context, result.first.$2);
    }
  }

  Future<(List<Uint8List>?, String?)?> _processSelectionFuture(
    String source,
  ) async {
    final appLocalizations = AppLocalizations.of(context);

    Future<List<Uint8List>?> tryParseArbitraryInput(Uint8List input) async {
      try {
        final text = _tryDecodeUtf8(input);
        final List<Uint8List> keys;
        if (text != null && text.contains("-----BEGIN PGP")) {
          final normalized = text
              .replaceAll("\r\n", "\n")
              .replaceAll("\r", "\n")
              .trim();
          keys = [
            for (final match in _armoredPublicKeyBlock.allMatches(normalized))
              ...OpenPGP.readPublicKeys(match.group(0)!)
                  .map((key) => key.publicKey.packetList.encode()),
          ];
        } else {
          final packetList = PacketList.decode(input);
          final starts = packetList.indexOfTypes([
            PacketType.publicKey,
            PacketType.secretKey,
          ]);
          keys = [
            for (var i = 0; i < starts.length; i++)
              if (packetList.packets[starts[i]].type == PacketType.publicKey)
                PublicKey(
                  PacketList(
                    packetList.packets.sublist(
                      starts[i],
                      i + 1 < starts.length ? starts[i + 1] : packetList.length,
                    ),
                  ),
                ).packetList.encode(),
          ];
        }
        keys.removeWhere(
          (k) =>
              publicKeyFromBytes(k).users
                  .any((u) => UserId.tryParse(u.userID) == null),
        );
        return keys.isEmpty ? null : keys;
      } catch (_) {
        return null;
      }
    }

    switch (source) {
      case "search":
        _searchMode = true;
        return null;
      case "clipboard":
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        if (data?.text == null) {
          return (null, appLocalizations.addContactClipboardEmpty);
        }

        final value = await compute(
          (_) => tryParseArbitraryInput(utf8.encode(data!.text!)),
          null,
        );
        if (value == null) {
          return (null, appLocalizations.addContactClipboardReadFailed);
        }
        return (
          value,
          appLocalizations.addContactClipboardReadKeys(value.length),
        );
      case "file":
        final file = await openFile(
          confirmButtonText: appLocalizations.addContactFileImport,
        );
        if (file == null) return (null, null);
        Uint8List data;
        try {
          data = await file.readAsBytes();
        } catch (_) {
          return (null, appLocalizations.addContactFileFailed);
        }
        final value = await compute((_) => tryParseArbitraryInput(data), null);
        if (value == null) {
          return (null, appLocalizations.addContactFileReadFailed);
        }
        return (value, appLocalizations.addContactFileReadKeys(value.length));
    }
    return (null, null);
  }

  Future<void> _search() async {
    if (_isSearching) return;
    final appLocalizations = AppLocalizations.of(context);
    _isSearching = true;
    _searchControllerError = null;
    _searchResults = [];
    _primarySearchResult = const [];
    _parsedResultKeys = const {};
    if (mounted) setState(() {});

    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    if (query.length < 3) {
      _searchControllerError = appLocalizations.addContactSearchQueryTooShort;
      _isSearching = false;
      if (mounted) setState(() {});
      return;
    }
    if (!query.contains("@")) {
      _searchControllerError =
          appLocalizations.addContactSearchQueryInvalidEmail;
      _isSearching = false;
      if (mounted) setState(() {});
      return;
    }

    try {
      final hkpKeyServers =
          prefs
              ?.getStringList("hkp_key_servers")
              ?.map(
                (s) => UserId.commonHkpKeyServers.firstWhereOrNull(
                  (c) => c.host == s,
                ),
              )
              .whereType<HkpKeyServer>()
              .toList() ??
          UserId.defaultHkpKeyServers;
      _searchResults = await compute(
        (_) => UserId(email: query).fetchKeyFromPublicFull(
          _KeyFetchHttpClient(),
          hkpKeyServers: hkpKeyServers,
        ),
        null,
      );
      if (_searchResults.isEmpty) {
        _searchControllerError = appLocalizations.addContactSearchNoKeys;
      } else {
        final parsedKeys = <Uint8List, PublicKey?>{};
        for (final result in _searchResults) {
          for (final key in result.keys) {
            if (!key.isValid || parsedKeys.containsKey(key.bytes)) continue;
            try {
              parsedKeys[key.bytes] = publicKeyFromBytes(key.bytes);
            } catch (_) {
              parsedKeys[key.bytes] = null;
            }
          }
        }
        _parsedResultKeys = parsedKeys;
        _primarySearchResult =
            _searchResults
                .firstWhereOrNull((r) => r.keys.any((k) => k.isValid))
                ?.keys
                .map((k) => parsedKeys[k.bytes])
                .whereType<PublicKey>()
                .toList() ??
            const [];
      }
    } catch (e) {
      log("AddContactFlow", "(error) $e");
      _searchControllerError = appLocalizations.addContactSearchFailed;
    }
    _isSearching = false;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final appLocalizations = AppLocalizations.of(context);
    final size = MediaQuery.sizeOf(context);

    final primarySearchResult = _primarySearchResult;

    final modeSelection = Column(
      key: ValueKey("modeSelection"),
      mainAxisSize: .min,
      children: [
        SizedBox(height: 16),
        ...MaterialListTile.group([
          MaterialListTile(
            title: Text(appLocalizations.addContactSourceSearch),
            onTap: () => _processSelection("search"),
            trailing: Icon(Icons.search),
            backgroundStyle: .lightened,
          ),
          MaterialListTile(
            title: Text(appLocalizations.addContactSourceClipboard),
            onTap: () => _processSelection("clipboard"),
            trailing: Icon(Icons.content_paste),
            backgroundStyle: .lightened,
          ),
          MaterialListTile(
            title: Text(appLocalizations.addContactSourceFile),
            onTap: () => _processSelection("file"),
            trailing: Icon(Icons.file_open_outlined),
            backgroundStyle: .lightened,
          ),
        ]),
        MaterialListTileBottomSpacer(),
      ],
    );
    final modeSearching = () {
      final children = _searchResults
          .expand(
            (e) => e.keys.map(
              (k) => (key: k, origin: e.origin, originHost: e.originHost),
            ),
          )
          .map((result) {
            final isValid = result.key.isValid;
            final isExpired = result.key.isExpired;
            final isRevoked = result.key.isRevoked;

            var keyIdentitiesVerifies = false;

            var title = switch (result.origin) {
              .webKeyDirectoryAdvanced =>
                appLocalizations.keyFetchOriginWebKeyDirectoryAdvanced,
              .webKeyDirectoryDirect =>
                appLocalizations.keyFetchOriginWebKeyDirectoryDirect,
              .hkpKeyServer => appLocalizations.keyFetchOriginHkpKeyServer,
              null => result.originHost!,
            };
            if (result.originHost?.split("|").length == 3) {
              title = appLocalizations.keyFetchKeyserverTitle(
                result.originHost!.split("|")[1],
              );
              keyIdentitiesVerifies =
                  result.originHost!.split("|")[2] == "true";
            }
            final isPrimary =
                result.origin == _searchResults.first.origin &&
                _searchResults.first.keys.length == 1 &&
                isValid;

            final resultKey = _parsedResultKeys[result.key.bytes];
            bool matchesPrimary(PublicKey primary) {
              if (resultKey == null) return false;
              if (!const ListEquality<int>().equals(
                primary.fingerprint,
                resultKey.fingerprint,
              )) {
                return false;
              }
              final resultUserIds = resultKey.users
                  .map((u) => UserId.tryParse(u.userID))
                  .nonNulls
                  .toList();
              return primary.users
                  .map((u) => UserId.tryParse(u.userID))
                  .nonNulls
                  .any((a) => resultUserIds.any(a.isEmailEquivalent));
            }

            final matchingPrimaries = primarySearchResult
                .where(matchesPrimary)
                .toList();
            final isNotInPrimary =
                primarySearchResult.isNotEmpty && matchingPrimaries.isEmpty;
            final differsFromPrimary =
                !isPrimary &&
                resultKey != null &&
                matchingPrimaries.isNotEmpty &&
                !matchingPrimaries.any(
                  (p) => _keyStateDigest(p) == _keyStateDigest(resultKey),
                );

            return MaterialListTile(
              backgroundStyle: .lightened,
              leading: Icon(switch (result.origin!) {
                .webKeyDirectoryAdvanced ||
                .webKeyDirectoryDirect => Icons.public_outlined,
                .hkpKeyServer => Icons.dns_outlined,
              }),
              title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
              isThreeLine: true,
              subtitle: isValid && result.key.fingerprint != null
                  ? Builder(
                      builder: (context) => Text(
                        formatFingerprint(result.key.fingerprint!),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: DefaultTextStyle.of(context)
                            .style
                            .googleSansCode,
                      ),
                    )
                  : Text(
                      hyphenate(
                        "${appLocalizations.addContactSearchResultUnusable} ${isExpired
                            ? appLocalizations.addContactSearchResultExpired
                            : isRevoked
                            ? appLocalizations.addContactSearchResultRevoked
                            : appLocalizations.addContactSearchResultUnreadable}",
                      ),
                    ),
              trailing: isNotInPrimary
                  ? Tooltip(
                      message: hyphenate(
                        appLocalizations
                            .addContactSearchResultNotInPrimaryTooltip,
                      ),
                      child: Icon(
                        Icons.priority_high,
                        color: Colors.redAccent.harmonizeWith(
                          colorScheme.primary,
                        ),
                      ),
                    )
                  : differsFromPrimary
                  ? Tooltip(
                      message: hyphenate(
                        appLocalizations.addContactSearchResultDiffersTooltip,
                      ),
                      child: Icon(
                        Icons.warning_amber_outlined,
                        color: Colors.deepOrangeAccent.harmonizeWith(
                          colorScheme.primary,
                        ),
                      ),
                    )
                  : isPrimary
                  ? Tooltip(
                      message: hyphenate(
                        appLocalizations.addContactSearchResultPreferredTooltip,
                      ),
                      child: Icon(
                        Icons.star,
                        color: Colors.amber[400]!.harmonizeWith(
                          colorScheme.primary,
                        ),
                      ),
                    )
                  : keyIdentitiesVerifies
                  ? Tooltip(
                      message: hyphenate(
                        appLocalizations
                            .addContactSearchResultIdentityVerifiedTooltip,
                      ),
                      child: Icon(
                        Icons.how_to_reg_outlined,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    )
                  : null,
              enabled: isValid,
              onTap: isValid
                  ? () {
                      Navigator.of(context).pop([result.key.bytes]);
                      SnackBarManager.showSnackBar(
                        context,
                        appLocalizations.addContactSearchAdded,
                      );
                    }
                  : null,
            );
          })
          .toList();
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: size.height / 4 * 3),
        child: SingleChildScrollView(
          child: Padding(
            padding:
                MediaQuery.viewInsetsOf(context) +
                MediaQuery.paddingOf(context) +
                (MediaQuery.paddingOf(context).bottom == 0 &&
                        _searchResults.isNotEmpty
                    ? EdgeInsets.only(bottom: 16)
                    : EdgeInsets.zero),
            child: Column(
              key: ValueKey("modeSearching"),
              mainAxisSize: .min,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.all(16).copyWith(
                    top: 20,
                    bottom: _searchResults.isNotEmpty ? 0 : 12,
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: _searchResults.isEmpty,
                    onSubmitted: (_) => _search(),
                    textInputAction: .search,
                    keyboardType: .emailAddress,
                    autofillHints: [AutofillHints.email],
                    enabled: !_isSearching,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: appLocalizations.addContactSearchLabel,
                      hintText: appLocalizations.addContactSearchHint,
                      helperText: appLocalizations.addContactSearchHelper,
                      helperMaxLines: 3,
                      errorText: _searchControllerError,
                      errorMaxLines: 3,
                      suffixIcon: _isSearching
                          ? SizedBox.square(
                              dimension: 36,
                              child: Center(
                                child: SizedBox.square(
                                  dimension: 36,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                  ),
                                ),
                              ),
                            )
                          : IconButton(
                              onPressed: _search,
                              icon: Icon(Icons.send),
                            ),
                    ),
                  ),
                ),
                if (_searchResults.isNotEmpty) ...[
                  SizedBox(width: size.width / 3, child: Divider(height: 32)),
                  ...MaterialListTile.group(children),
                ],
              ],
            ),
          ),
        ),
      );
    }();
    final modeLoading = SafeArea(
      key: ValueKey("modeLoading"),
      child: SizedBox(
        height: size.height / 6,
        child: Center(
          child: MaterialLoadingIndicator(
            size: MaterialLoadingIndicatorSizes.large,
          ),
        ),
      ),
    );

    return SizedBox(
      width: double.infinity,
      child: AnimatedSize(
        curve: ExpressiveCurves.expressiveEffects.slow,
        duration: ExpressiveCurves.expressiveEffects.slowDuration,
        alignment: Alignment.topCenter,
        clipBehavior: Clip.antiAlias,
        child: AnimatedSwitcher(
          switchInCurve: ExpressiveCurves.expressiveEffects.slow,
          switchOutCurve: ExpressiveCurves.expressiveEffects.slow.flipped,
          duration: ExpressiveCurves.expressiveEffects.slowDuration,
          transitionBuilder: (child, animation) {
            var widget = child;
            if (!animation.isForwardOrCompleted) {
              widget = SlideTransition(
                position: Tween(
                  begin: Offset(0.0, 0.06),
                  end: Offset.zero,
                ).animate(animation),
                child: Material(color: Colors.transparent, child: widget),
              );
            }
            return FadeTransition(opacity: animation, child: widget);
          },
          layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
            return Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: <Widget>[
                ...previousChildren.map(
                  (child) =>
                      Positioned(left: 0, right: 0, top: 0, child: child),
                ),
                ?currentChild,
              ],
            );
          },
          child: _loadMode
              ? modeLoading
              : _searchMode
              ? modeSearching
              : modeSelection,
        ),
      ),
    );
  }
}

Future<List<Uint8List>?> startAddContactFlow(BuildContext context) async =>
    await showModalBottomSheet<List<Uint8List>>(
      context: context,
      isScrollControlled: true,
      clipBehavior: Clip.antiAlias,
      builder: (_) => _ContactSourceChooser(),
    );

class _KeyFetchHttpClient implements user_id.HttpClientProvider {
  @override
  Future<HttpResponse> send(HttpRequest request) async {
    if (request.url.scheme != "https") {
      throw Exception("Only HTTPS requests are allowed");
    }
    final response = await http.Response.fromStream(
      await (http.Request(request.method, request.url)
            ..headers.addAll(request.headers)
            ..bodyBytes = request.body)
          .send(),
    );
    return HttpResponse(
      statusCode: response.statusCode,
      headers: response.headers,
      body: response.bodyBytes,
    );
  }
}
