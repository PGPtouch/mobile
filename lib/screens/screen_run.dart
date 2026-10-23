import 'package:flutter/foundation.dart';
import 'package:material_graphics/material_graphics.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/components/protocol_manager_builder.dart';
import 'package:mobile/components/protocol_permission_builder.dart';
import 'package:mobile/l10n/app_localizations.dart';

import '../database/key_store.dart' as key_store;

class ScreenRun extends StatefulWidget {
  final ProtocolManagerState protocol;
  final ProtocolPermissionState permissions;

  final int? selectedKey;
  final String? selectedKeyUserIdDisplay;
  final String? selectedKeyFingerprint;

  const ScreenRun({
    super.key,
    required this.protocol,
    required this.permissions,
    required this.selectedKey,
    required this.selectedKeyUserIdDisplay,
    required this.selectedKeyFingerprint,
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
              // Text(
              //   appLocalizations.deviceRole(
              //     deviceRole?.value?.name ?? appLocalizations.unknown,
              //   ),
              // ),
              // Text(
              //   appLocalizations.transactionResult(
              //     result?.value?.mode.toString() ?? appLocalizations.unknown,
              //   ),
              // ),
              if (result?.value?.additionalInfo != null &&
                  result?.value?.mode == .success)
                Card.outlined(
                  margin: EdgeInsets.only(bottom: 4, top: 2),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisSize: .min,
                      children: [
                        Text(result?.value?.additionalInfo.userIds.join(", ")),
                        Text(
                          formatFingerprint(
                            result?.value?.additionalInfo.fingerprint,
                          ),
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.googleSansCode,
                        ),
                      ],
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
                    widget.selectedKey == null ||
                        contactMode.value != .done ||
                        !widget.permissions.areRadiosEnabled
                    ? null
                    : _start,
                child: Text(appLocalizations.restartTransaction),
              ),
              Text(widget.selectedKeyUserIdDisplay ?? ""),
              Text(
                formatFingerprint(
                  transportFingerprintToBytes(
                    widget.selectedKeyFingerprint ?? "",
                  )!,
                ),
                style: DefaultTextStyle.of(context).style.googleSansCode,
              ),
            ]
          : [
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
                    widget.selectedKey == null ||
                        !widget.permissions.areRadiosEnabled ||
                        !widget.permissions.arePermissionsGranted
                    ? null
                    : _start,
                child: Text(appLocalizations.startTransaction),
              ),
              Text(widget.selectedKeyUserIdDisplay ?? ""),
              Text(
                formatFingerprint(
                  transportFingerprintToBytes(
                    widget.selectedKeyFingerprint ?? "",
                  )!,
                ),
                style: DefaultTextStyle.of(context).style.googleSansCode,
              ),
              if (widget.permissions.isNfcAvailable == false)
                Text(appLocalizations.nfcNotAvailable),
              if (widget.permissions.isBluetoothAvailable == false)
                Text(appLocalizations.bluetoothNotAvailable),
            ],
    );
  }

  Future<void> _start() async {
    if (widget.selectedKey == null) return;
    final appLocalizations = AppLocalizations.of(context);
    await widget.protocol.start(
      key_store.KeyStorePgpProvider(
        context,
        appLocalizations,
        id: widget.selectedKey!,
      ),
    );
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
    ].join().trim(),
    [
      for (var i
          in parts
              .skip((parts.length / 2).ceil())
              .toList()
              .asMap()
              .entries) ...[i.value, if (i.key.isOdd) " "],
    ].join().trim(),
  ].join("\n");
}

Uint8List? transportFingerprintToBytes(String fingerprint) {
  final buffer = StringBuffer();
  final list = <int>[];
  for (var char in fingerprint.split("")) {
    if (char.trim().isEmpty) continue;
    buffer.write(char);
    if (buffer.length % 2 == 0) {
      list.add(int.parse(buffer.toString(), radix: 16));
      buffer.clear();
    }
  }
  return Uint8List.fromList(list);
}
