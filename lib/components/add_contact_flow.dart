import 'dart:async';
import 'dart:convert';

import 'package:dart_pg/dart_pg.dart';
// not publicly exposed
// ignore: implementation_imports
import 'package:dart_pg/src/common/armor.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:material_graphics/material_graphics.dart';
import 'package:material_helper/material_helper.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared/shared.dart';
import 'package:shared/user_id.dart' as user_id;

import '../key_utils.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../screens/screen_run.dart';
import '../states.dart';
import 'backup_code_input.dart';
import 'bottom_sheet_multi_state.dart';
import 'research_point.dart';
import 'snack_bar_manager.dart';

String? _tryDecodeUtf8(Uint8List input) {
  try {
    return utf8.decode(input);
  } on FormatException {
    return null;
  }
}

final _armoredKeyBlock = RegExp(
  r"-----BEGIN PGP (PUBLIC|PRIVATE) KEY BLOCK-----[\s\S]*?-----END PGP \1 KEY BLOCK-----",
);

List<Uint8List>? _tryParseArbitraryInput(Uint8List input) {
  try {
    final text = _tryDecodeUtf8(input);
    final packetLists = <PacketList>[];
    if (text != null && text.contains("-----BEGIN PGP")) {
      final normalized = text
          .replaceAll("\r\n", "\n")
          .replaceAll("\r", "\n")
          .trim();
      for (final match in _armoredKeyBlock.allMatches(normalized)) {
        packetLists.add(PacketList.decode(Armor.decode(match.group(0)!).data));
      }
    } else {
      packetLists.add(PacketList.decode(input));
    }

    // dart_pg drops key revocation signatures while parsing, so the public
    // keys are re-encoded with the revocations from the raw packets.
    final keys = <Uint8List>[];
    for (final packetList in packetLists) {
      final starts = packetList.indexOfTypes([
        PacketType.publicKey,
        PacketType.secretKey,
      ]);
      for (var i = 0; i < starts.length; i++) {
        final packets = PacketList(
          packetList.packets.sublist(
            starts[i],
            i + 1 < starts.length ? starts[i + 1] : packetList.length,
          ),
        );
        final publicKey =
            packetList.packets[starts[i]].type == PacketType.publicKey
            ? PublicKey(packets)
            : PrivateKey(packets).publicKey as PublicKey;
        keys.add(encodeKey(publicKey, [packets]));
      }
    }
    // Backups may hold both the secret and the public copy of a key.
    final seenFingerprints = <String>{};
    keys
      ..removeWhere(
        (k) => !seenFingerprints.add(
          publicKeyFromBytes(k).fingerprint
              .map((b) => b.toRadixString(16).padLeft(2, "0"))
              .join(),
        ),
      )
      ..removeWhere(
        (k) =>
            publicKeyFromBytes(k).users
                .any((u) => UserId.tryParse(u.userID) == null),
      );
    return keys.isEmpty ? null : keys;
  } catch (_) {
    return null;
  }
}

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

  Completer<Uint8List?>? _backupCompleter;
  String? _backupText;
  final _searchController = TextEditingController();
  String? _searchControllerError;
  bool _isSearching = false;
  List<UserIdKeyFetchResult> _searchResults = [];

  List<PublicKey> _primarySearchResult = const [];
  Map<Uint8List, PublicKey?> _parsedResultKeys = const {};

  @override
  void dispose() {
    final completer = _backupCompleter;
    if (completer != null && !completer.isCompleted) completer.complete(null);
    _searchController.dispose();
    super.dispose();
  }

  Future<Uint8List?> _askBackupCode(String text) {
    final completer = Completer<Uint8List?>();
    _backupText = text;
    _backupCompleter = completer;
    _loadMode = false;
    if (mounted) setState(() {});
    return completer.future;
  }

  void _endBackupCode(Uint8List? decrypted) {
    final completer = _backupCompleter;
    if (completer == null || completer.isCompleted) return;
    completer.complete(decrypted);
    _backupCompleter = null;
    _backupText = null;
    _loadMode = true;
    if (mounted) setState(() {});
  }

  Future<void> _processSelection(String source) async {
    if (_loadMode) return;
    _loadMode = true;
    if (mounted) setState(() {});
    final result = await Future.wait([
      _processSelectionFuture(source),
      if (source != "search") Future.delayed(Durations.long1),
    ]);
    if (!mounted) return;

    ResearchPoint.trackEvent("importSource", {
      "flow": "contact",
      "source": source,
      "outcome": result.first == null
          ? "opened"
          : result.first.$1 != null
          ? "ok"
          : result.first.$2 != null
          ? "failed"
          : "cancelled",
      "keyCount": result.first?.$1?.length ?? 0,
    });

    if (result.first == null) {
      _loadMode = false;
      if (mounted) setState(() {});
      return;
    }

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop(result.first.$1);
      if (result.first.$2 != null) {
        SnackBarManager.showSnackBar(context, result.first.$2);
      }
    }
  }

  Future<(List<Uint8List>?, String?)?> _processSelectionFuture(
    String source,
  ) async {
    final appLocalizations = AppLocalizations.of(context);

    Future<(List<Uint8List>?, String?)> parseInput(
      Uint8List data,
      String failedMessage,
      String Function(int count) successMessage,
    ) async {
      final text = _tryDecodeUtf8(data);
      if (text != null && isBackupText(text)) {
        final decrypted = await _askBackupCode(text);
        if (decrypted == null) return (null, null);
        data = decrypted;
      }
      final input = data;
      final value = await compute(_tryParseArbitraryInput, input);
      if (value == null) return (null, failedMessage);
      return (value, successMessage(value.length));
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

        return parseInput(
          Uint8List.fromList(utf8.encode(data!.text!)),
          appLocalizations.addContactClipboardReadFailed,
          appLocalizations.addContactClipboardReadKeys,
        );
      case "file":
        final file = await FilePicker.pickFile();
        if (file == null) return (null, null);
        Uint8List data;
        try {
          data = await file.readAsBytes();
        } catch (_) {
          return (null, appLocalizations.addContactFileFailed);
        }
        return parseInput(
          data,
          appLocalizations.addContactFileReadFailed,
          appLocalizations.addContactFileReadKeys,
        );
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

    final searchStopwatch = Stopwatch()..start();
    var searchOutcome = "results";
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
        (_) async => [
          for (final result
              in await UserId(email: query).fetchKeyFromPublicFull(
                KeyFetchHttpClient(),
                hkpKeyServers: hkpKeyServers,
              ))
            (
              keys: result.keys.map(correctFetchedKeyState).toList(),
              origin: result.origin,
              originHost: result.originHost,
            ),
        ],
        null,
      );
      if (_searchResults.isEmpty) {
        searchOutcome = "none";
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
      searchOutcome = "failed";
      _searchControllerError = appLocalizations.addContactSearchFailed;
    }
    ResearchPoint.trackEvent("contactSearch", {
      "outcome": searchOutcome,
      "resultCount": _searchResults.length,
      "validKeyCount": _parsedResultKeys.values.nonNulls.length,
      "durationMs": searchStopwatch.elapsedMilliseconds,
      "serverCount":
          prefs?.getStringList("hkp_key_servers")?.length ??
          UserId.defaultHkpKeyServers.length,
    });
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

            final source = keyFetchSourceTitle(
              appLocalizations,
              origin: result.origin,
              originHost: result.originHost,
            );
            final title = source.title;
            keyIdentitiesVerifies = source.keyIdentitiesVerifies;
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
    final modeBackup = _backupCompleter != null
        ? BackupCodeInput(
            key: ValueKey("modeBackup"),
            onSubmit: (backupCode) async {
              final decrypted = await decryptBackup(_backupText!, backupCode);
              if (decrypted == null) {
                return appLocalizations.backupCodeInputWrong;
              }
              _endBackupCode(decrypted);
              return null;
            },
            onCancel: () => _endBackupCode(null),
          )
        : null;

    return BottomSheetMultiState(
      child: _backupCompleter != null
          ? modeBackup!
          : _loadMode
          ? null
          : _searchMode
          ? modeSearching
          : modeSelection,
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

class KeyFetchHttpClient implements user_id.HttpClientProvider {
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
