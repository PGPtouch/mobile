import 'dart:convert';

import 'package:dart_pg/dart_pg.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_graphics/material_graphics.dart';
import 'package:material_helper/material_helper.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/components/passphrase_input.dart';
import 'package:mobile/components/snack_bar_manager.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:file_selector/file_selector.dart';
import 'package:shared/shared.dart';

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

/// Reads exactly one public and one private key from [input] (armored or
/// binary) and returns them as `(publicKey, privateKey)` packet list bytes.
/// If no public key is present, it is derived from the private key.
/// Returns null if the input is invalid, ambiguous or the keys don't match.
(Uint8List, Uint8List)? _tryParseIdentityKeys(Uint8List input) {
  try {
    final publicKeys = <PublicKey>[];
    final privateKeys = <PrivateKey>[];

    final text = _tryDecodeUtf8(input);
    if (text != null && text.contains("-----BEGIN PGP")) {
      final normalized = text
          .replaceAll("\r\n", "\n")
          .replaceAll("\r", "\n")
          .trim();
      for (final match in _armoredKeyBlock.allMatches(normalized)) {
        final block = match.group(0)!;
        if (match.group(1) == "PUBLIC") {
          publicKeys.addAll(
            OpenPGP.readPublicKeys(block).map((k) => k as PublicKey),
          );
        } else {
          privateKeys.add(PrivateKey.fromArmored(block));
        }
      }
    } else {
      final packetList = PacketList.decode(input);
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

    if (privateKeys.length != 1 || publicKeys.length > 1) return null;
    final privateKey = privateKeys.single;
    final publicKey = publicKeys.isEmpty
        ? privateKey.publicKey as PublicKey
        : publicKeys.single;
    if (!listEquals(publicKey.fingerprint, privateKey.fingerprint)) {
      return null;
    }
    if (publicKey.users.any((u) => UserId.tryParse(u.userID) == null)) {
      return null;
    }
    return (publicKey.packetList.encode(), privateKey.packetList.encode());
  } catch (_) {
    return null;
  }
}

bool _tryDecryptPrivateKey((Uint8List, String) args) {
  try {
    PrivateKey(PacketList.decode(args.$1)).decrypt(args.$2);
    return true;
  } catch (_) {
    return false;
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

  void _finish(String? passphrase) {
    if (_finished) return;
    _finished = true;
    final keys = _pendingKeys!;
    Navigator.of(context).pop((keys.$1, keys.$2, passphrase));
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

    final value = result.first as ((Uint8List, Uint8List)?, String?)?;
    if (value == null) {
      _loadMode = false;
      if (mounted) setState(() {});
      return;
    }

    final keys = value.$1;
    if (keys != null && isPrivateKeyEncrypted(keys.$2)) {
      final key = await compute((_) => publicKeyFromBytes(keys.$1), null);
      _pendingIdentity = key.users.map((u) => u.userID).toList();
      _pendingFingerprint = key.fingerprint;

      _pendingKeys = keys;
      _pendingMessage = value.$2;
      _loadMode = false;
      _isPassphraseMode = true;
      setState(() {});
      return;
    }

    Navigator.of(context).pop(keys == null ? null : (keys.$1, keys.$2, null));
    if (value.$2 != null) {
      SnackBarManager.showSnackBar(context, value.$2!);
    }
  }

  Future<((Uint8List, Uint8List)?, String?)?> _processSelectionFuture(
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

        final value = await compute(
          _tryParseIdentityKeys,
          Uint8List.fromList(utf8.encode(data!.text!)),
        );
        if (value == null) {
          return (null, appLocalizations.addContactClipboardReadFailed);
        }
        return (value, appLocalizations.addIdentityClipboardReadKey);
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
        final value = await compute(_tryParseIdentityKeys, data);
        if (value == null) {
          return (null, appLocalizations.addContactFileReadFailed);
        }
        return (value, appLocalizations.addIdentityFileReadKey);
    }
    return (null, null);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
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
              final valid = await compute(_tryDecryptPrivateKey, (
                _pendingKeys!.$2,
                passphrase,
              ));
              if (!mounted) return null;
              if (!valid) return appLocalizations.passphraseInputWrong;
              _finish(passphrase);
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
              : _isPassphraseMode
              ? modePassphrase!
              : modeSelection,
        ),
      ),
    );
  }
}

Future<(Uint8List, Uint8List, String?)?> startAddIdentityFlow(
  BuildContext context,
) async => await showModalBottomSheet<(Uint8List, Uint8List, String?)>(
  context: context,
  isScrollControlled: true,
  clipBehavior: Clip.antiAlias,
  builder: (_) => _IdentitySourceChooser(),
);
