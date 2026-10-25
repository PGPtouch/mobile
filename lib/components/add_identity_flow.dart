import 'dart:async';
import 'dart:convert';

import 'package:dart_pg/dart_pg.dart';
// needed for parsing armored keys
// ignore: implementation_imports
import 'package:dart_pg/src/common/armor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_graphics/material_graphics.dart';
import 'package:material_helper/material_helper.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/components/backup_code_input.dart';
import 'package:mobile/components/passphrase_input.dart';
import 'package:mobile/components/snack_bar_manager.dart';
import 'package:mobile/key_utils.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared/shared.dart';

String? _tryDecodeUtf8(Uint8List input) {
  try {
    return utf8.decode(input);
  } on FormatException {
    return null;
  }
}

String _hex(Uint8List bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, "0")).join();

final _armoredKeyBlock = RegExp(
  r"-----BEGIN PGP (PUBLIC|PRIVATE) KEY BLOCK-----[\s\S]*?-----END PGP \1 KEY BLOCK-----",
);

List<(Uint8List, Uint8List)>? _tryParseIdentityKeys(Uint8List input) {
  try {
    final packetLists = <PacketList>[];

    final text = _tryDecodeUtf8(input);
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

    final publicKeys = <PublicKey>[];
    final privateKeys = <PrivateKey>[];
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
        if (packetList.packets[starts[i]].type == PacketType.secretKey) {
          privateKeys.add(PrivateKey(packets));
        } else {
          publicKeys.add(PublicKey(packets));
        }
      }
    }

    if (privateKeys.isEmpty) return null;

    final seen = <String>{};
    final publicByFingerprint = <String, PublicKey>{};
    for (final publicKey in publicKeys) {
      if (publicByFingerprint.putIfAbsent(
            _hex(publicKey.fingerprint),
            () => publicKey,
          ) !=
          publicKey) {
        return null;
      }
    }

    final result = <(Uint8List, Uint8List)>[];
    for (final privateKey in privateKeys) {
      final fingerprint = _hex(privateKey.fingerprint);
      if (!seen.add(fingerprint)) continue;
      final publicKey =
          publicByFingerprint.remove(fingerprint) ??
          privateKey.publicKey as PublicKey;
      if (publicKey.users.any((u) => UserId.tryParse(u.userID) == null)) {
        continue;
      }
      result.add((
        encodePublicKey(publicKey, [
          for (final packetList in packetLists) packetList,
        ]),
        privateKey.packetList.encode(),
      ));
    }
    return result;
  } catch (_) {
    return null;
  }
}

class _IdentitySourceChooser extends StatefulWidget {
  const _IdentitySourceChooser();

  @override
  State<_IdentitySourceChooser> createState() => _IdentitySourceChooserState();
}

class _IdentitySourceChooserState extends State<_IdentitySourceChooser> {
  bool _loadMode = false;
  bool _isPassphraseMode = false;

  (Uint8List, Uint8List)? _pendingKeys;
  String? _pendingMessage;
  List<String>? _pendingIdentity;
  Uint8List? _pendingFingerprint;

  bool _finished = false;

  Completer<Uint8List?>? _backupCompleter;
  String? _backupText;

  @override
  void dispose() {
    final completer = _backupCompleter;
    if (completer != null && !completer.isCompleted) completer.complete(null);
    super.dispose();
  }

  void _finish(String? passphrase) {
    if (_finished) return;
    _finished = true;
    final keys = _pendingKeys!;
    Navigator.of(context).pop([(keys.$1, keys.$2, passphrase)]);
    if (_pendingMessage != null) {
      SnackBarManager.showSnackBar(context, _pendingMessage!);
    }
  }

  void _processSelection(String source) async {
    if (_loadMode) return;
    _loadMode = true;
    if (mounted) setState(() {});
    final result = await Future.wait([
      _processSelectionFuture(source),
      Future.delayed(Durations.long1),
    ]);
    if (!mounted) return;

    final value = result.first as (List<(Uint8List, Uint8List)>?, String?)?;
    if (value == null) {
      _loadMode = false;
      if (mounted) setState(() {});
      return;
    }

    final keys = value.$1;
    if (keys != null &&
        keys.length == 1 &&
        isPrivateKeyEncrypted(keys.single.$2)) {
      final pair = keys.single;
      final key = await compute((_) => publicKeyFromBytes(pair.$1), null);
      if (!mounted) return;
      _pendingIdentity = key.users.map((u) => u.userID).toList();
      _pendingFingerprint = key.fingerprint;

      _pendingKeys = pair;
      _pendingMessage = value.$2;
      _loadMode = false;
      _isPassphraseMode = true;
      setState(() {});
      return;
    }

    Navigator.of(context).pop(
      keys == null
          ? null
          : [for (final k in keys) (k.$1, k.$2, null as String?)],
    );
    if (value.$2 != null) {
      SnackBarManager.showSnackBar(context, value.$2!);
    }
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

  Future<(List<(Uint8List, Uint8List)>?, String?)> _parseInput(
    Uint8List data,
    String failedMessage,
    String Function(int count) successMessage,
  ) async {
    final text = _tryDecodeUtf8(data);
    if (text != null && isBackupText(text)) {
      Uint8List? decrypted;
      decrypted = await _askBackupCode(text);
      if (decrypted == null) return (null, null);
      data = decrypted;
    }
    final value = await compute(_tryParseIdentityKeys, data);
    if (value == null) return (null, failedMessage);
    return (value, successMessage(value.length));
  }

  Future<(List<(Uint8List, Uint8List)>?, String?)?> _processSelectionFuture(
    String source,
  ) async {
    final appLocalizations = AppLocalizations.of(context);

    switch (source) {
      case "create":
        break;
      case "clipboard":
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        if (data?.text == null) {
          return (null, appLocalizations.addContactClipboardEmpty);
        }

        return _parseInput(
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
        return _parseInput(
          data,
          appLocalizations.addContactFileReadFailed,
          appLocalizations.addContactFileReadKeys,
        );
    }
    return (null, null);
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final size = MediaQuery.sizeOf(context);

    final modeSelection = Column(
      key: ValueKey("modeSelection"),
      mainAxisSize: .min,
      children: [
        SizedBox(height: 16),
        ...MaterialListTile.group([
          MaterialListTile(
            title: Text(appLocalizations.addIdentitySourceCreate),
            onTap: () => _processSelection("create"),
            trailing: Icon(Icons.playlist_add),
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
    final modePassphrase = _pendingIdentity != null
        ? PassphraseInput(
            key: ValueKey("modePassphrase"),
            identity: _pendingIdentity!,
            fingerprint: _pendingFingerprint!,
            skippable: true,
            onSubmit: (passphrase, remember) async {
              final valid =
                  await decryptPrivateKey(_pendingKeys!.$2, passphrase) != null;
              if (!mounted) return null;
              if (!valid) return appLocalizations.passphraseInputWrong;
              _finish(remember ? passphrase : null);
              return null;
            },
            onCancel: (skipped) {
              if (_finished) return;
              if (skipped) {
                _finish(null);
                return;
              }
              _pendingKeys = null;
              _pendingMessage = null;
              _isPassphraseMode = false;
              setState(() {});
            },
          )
        : null;
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
          child: _backupCompleter != null
              ? modeBackup!
              : _loadMode
              ? modeLoading
              : _isPassphraseMode
              ? modePassphrase!
              : modeSelection,
        ),
      ),
    );
  }
}

Future<List<(Uint8List, Uint8List, String?)>?> startAddIdentityFlow(
  BuildContext context,
) async => await showModalBottomSheet<List<(Uint8List, Uint8List, String?)>>(
  context: context,
  isScrollControlled: true,
  clipBehavior: Clip.antiAlias,
  builder: (_) => _IdentitySourceChooser(),
);
