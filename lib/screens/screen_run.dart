import 'package:dart_pg/dart_pg.dart';
import 'package:flutter/foundation.dart';
import 'package:material_graphics/material_graphics.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/components/protocol_manager_builder.dart';
import 'package:mobile/components/protocol_permission_builder.dart';
import 'package:mobile/l10n/app_localizations.dart';

bool _isGeneratingKeys = false;
PrivateKey? _keyPair;

class ScreenRun extends StatefulWidget {
  final ProtocolManagerState protocol;
  final ProtocolPermissionState permissions;

  const ScreenRun({
    super.key,
    required this.protocol,
    required this.permissions,
  });

  @override
  State<ScreenRun> createState() => _ScreenRunState();
}

class _ScreenRunState extends State<ScreenRun> {
  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);

    final displayState = widget.protocol.displayState?.lastEvent;
    final contactMode = displayState?.contactMode;
    final deviceRole = displayState?.deviceRole;
    final result = displayState?.result;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: contactMode != null
          ? [
              Text(switch (contactMode.value) {
                .initializing => appLocalizations.contactModeInitializing,
                .tapOther => appLocalizations.contactModeTapOther,
                .holdOther => appLocalizations.contactModeHoldOther,
                .done =>
                  result?.value?.mode == .success
                      ? appLocalizations.transactionSuccess
                      : appLocalizations.transactionFailure,
              }, style: Theme.of(context).textTheme.headlineLarge),
              Text(
                appLocalizations.deviceRole(
                  deviceRole?.value?.name ?? appLocalizations.unknown,
                ),
              ),
              Text(
                appLocalizations.transactionResult(
                  result?.value?.mode.toString() ?? appLocalizations.unknown,
                ),
              ),
              if (result?.value?.additionalInfo != null &&
                  result?.value?.mode == .success)
                Card.outlined(
                  margin: EdgeInsets.symmetric(vertical: 4),
                  color: ColorScheme.of(context).secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      formatFingerprint(
                        result?.value?.additionalInfo.fingerprint,
                      ),
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.googleSansCode,
                    ),
                  ),
                ),
              if (result?.value?.mode == .error)
                Text(
                  appLocalizations.transactionError(
                    result?.value?.errorMode?.toString() ??
                        appLocalizations.unknown,
                  ),
                ),
              if (result?.value?.mode == .failure)
                Text(
                  appLocalizations.transactionFailureReason(
                    result?.value?.failureMode?.toString() ??
                        appLocalizations.unknown,
                  ),
                ),
              if (result?.value?.additionalInfo != null &&
                  result?.value?.mode == .failure)
                Text(
                  appLocalizations.transactionAdditionalInfo(
                    result?.value?.additionalInfo?.toString() ??
                        appLocalizations.noDetails,
                  ),
                ),
              OutlinedButton(
                onPressed: widget.protocol.stop,
                child: Text(appLocalizations.stopTransaction),
              ),
              OutlinedButton(
                onPressed:
                    _keyPair == null ||
                        contactMode.value != .done ||
                        !widget.permissions.areRadiosEnabled
                    ? null
                    : _start,
                child: Text(appLocalizations.restartTransaction),
              ),
              Text(
                formatFingerprint(_keyPair!.fingerprint),
                style: Theme.of(context).textTheme.bodySmall?.googleSansCode
                    .copyWith(
                      fontSize: 10,
                      color: ColorScheme.of(context).onSurfaceVariant,
                    ),
              ),
            ]
          : [
              OutlinedButton(
                onPressed: _generateKeys,
                child: Text(appLocalizations.generateKeys),
              ),
              if (widget.permissions.canRequestPermissions)
                OutlinedButton(
                  onPressed: widget.permissions.requestPermissions,
                  child: Text(appLocalizations.grantPermissions),
                ),
              if (widget.permissions.isNfcEnabled == false)
                OutlinedButton(
                  onPressed: widget.permissions.openNfcSettings,
                  child: Text(appLocalizations.enableNfc),
                ),
              if (widget.permissions.isBluetoothEnabled == false)
                OutlinedButton(
                  onPressed: widget.permissions.openBluetoothSettings,
                  child: Text(appLocalizations.enableBluetooth),
                ),
              FilledButton(
                onPressed:
                    _keyPair == null ||
                        _isGeneratingKeys ||
                        !widget.permissions.areRadiosEnabled ||
                        !widget.permissions.arePermissionsGranted
                    ? null
                    : _start,
                child: Text(appLocalizations.startTransaction),
              ),
              if (_keyPair != null)
                Text(
                  formatFingerprint(_keyPair!.fingerprint),
                  style: Theme.of(context).textTheme.bodySmall?.googleSansCode
                      .copyWith(
                        fontSize: 10,
                        color: ColorScheme.of(context).onSurfaceVariant,
                      ),
                ),
              if (widget.permissions.isNfcAvailable == false)
                Text(appLocalizations.nfcNotAvailable),
              if (widget.permissions.isBluetoothAvailable == false)
                Text(appLocalizations.bluetoothNotAvailable),
            ],
    );
  }

  Future<void> _start() async {
    if (_keyPair == null) return;
    await widget.protocol.start(
      Uint8List.fromList(_keyPair!.publicKey.packetList.encode()),
      Uint8List.fromList(_keyPair!.packetList.encode()),
      privateKeyPassphrase: "passphrase",
    );
  }

  Future<void> _generateKeys() async {
    if (_isGeneratingKeys) return;
    setState(() => _isGeneratingKeys = true);

    final keyPair = await compute(
      (_) => OpenPGP.generateKey(
        ["Device <device@example.com>"],
        "passphrase",
        type: KeyType.rsa,
      ) as PrivateKey,
      null,
    );
    if (!mounted) return;
    setState(() {
      _keyPair = keyPair;
      _isGeneratingKeys = false;
    });
  }
}

String formatFingerprint(List<int> fingerprint) {
  final parts = fingerprint
      .map((b) => b.toRadixString(16).padLeft(2, "0").toUpperCase())
      .toList();
  return [
    [
      for (var i
          in parts
              .take((parts.length / 2).ceil())
              .toList()
              .asMap()
              .entries) ...[i.value, if (i.key.isOdd) " "],
    ].join(),
    [
      for (var i
          in parts
              .skip((parts.length / 2).ceil())
              .toList()
              .asMap()
              .entries) ...[i.value, if (i.key.isOdd) " "],
    ].join(),
  ].join("\n");
}
