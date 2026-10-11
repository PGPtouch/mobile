import 'dart:async';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:dart_pg/dart_pg.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:nfc_util/android.dart' as nfc_android;
import 'package:nfc_util/nfc_util.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared/shared.dart';
import 'package:open_settings_plus/open_settings_plus.dart';

import 'states.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  bool _isGeneratingKeys = false;
  PrivateKey? _keyPair;

  ProtocolManager? _protocolManager;
  DisplayState? _lastProtocolDisplayState;
  StreamSubscription<DisplayEvent>? _lastProtocolDisplayStateSubscription;

  List<Permission>? _requiredPermissions;
  Map<Permission, PermissionStatus>? _permissionStatuses;
  List<({double x, double y})>? _nfcAntennaLocations;

  bool? _isNfcAvailable;
  bool? _isNfcEnabled;
  bool? _isBluetoothAvailable;
  bool? _isBluetoothEnabled;
  StreamSubscription<NfcAdapterState>? _nfcAdapterSubscription;
  StreamSubscription<BluetoothLowEnergyStateChangedEventArgs>?
  _bluetoothStateSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    restrictNfcDiscoveryToTypeA("App");
    NfcHceGuard.instance.engage("App");
    getNfcAntennaLocations().then((locations) {
      _nfcAntennaLocations = locations;
      if (mounted) setState(() {});
    });
    DeviceInfoPlugin().androidInfo.then((info) async {
      _requiredPermissions = info.version.sdkInt >= 31
          ? [
              Permission.bluetoothScan,
              Permission.bluetoothConnect,
              Permission.bluetoothAdvertise,
            ]
          : [Permission.locationWhenInUse];
      _permissionStatuses = {};
      for (final permission in _requiredPermissions!) {
        _permissionStatuses![permission] = await permission.status;
      }
      if (mounted) setState(() {});
    });

    _nfcAdapterSubscription = nfc_android
        .NfcUtilAndroid
        .instance
        .onAdapterStateChanged
        .listen((_) => _checkNfcAvailability());
    _bluetoothStateSubscription = CentralManager().stateChanged.listen(
      (event) => _applyBluetoothState(event.state),
    );
    _checkNfcAvailability();
    _checkBluetoothAvailability();
  }

  Future<void> _checkNfcAvailability() async {
    try {
      final availability = await NfcUtil.instance.checkAvailability();
      final available = availability != NfcAvailability.unsupported;
      final enabled = availability == NfcAvailability.enabled;
      if (available != _isNfcAvailable || enabled != _isNfcEnabled) {
        _isNfcAvailable = available;
        _isNfcEnabled = enabled;
        if (mounted) setState(() {});
      }
    } catch (e) {
      log("MainApp", "NFC availability check failed: $e");
    }
  }

  Future<void> _checkBluetoothAvailability() async {
    try {
      final manager = CentralManager();
      var state = manager.state;
      if (state == BluetoothLowEnergyState.unknown) {
        state = await manager.stateChanged
            .map((event) => event.state)
            .firstWhere((s) => s != BluetoothLowEnergyState.unknown)
            .timeout(
              const Duration(seconds: 3),
              onTimeout: () => manager.state,
            );
      }
      _applyBluetoothState(state);
    } catch (e) {
      log("MainApp", "Bluetooth availability check failed: $e");
    }
  }

  void _applyBluetoothState(BluetoothLowEnergyState state) {
    if (state == BluetoothLowEnergyState.unknown) return;
    final available = state != BluetoothLowEnergyState.unsupported;
    final enabled = state == BluetoothLowEnergyState.unauthorized
        ? null
        : state == BluetoothLowEnergyState.poweredOn;
    if (available != _isBluetoothAvailable || enabled != _isBluetoothEnabled) {
      _isBluetoothAvailable = available;
      _isBluetoothEnabled = enabled;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nfcAdapterSubscription?.cancel();
    _bluetoothStateSubscription?.cancel();
    resetNfcDiscovery("App");
    NfcHceGuard.instance.release("App");
    NfcHaptics.instance.reset();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // `inactive`/`hidden` are transient (a system dialog, the app switcher, a
    // brief window-focus change): the app is still visible or about to be
    // again, which is exactly when a tap can happen, so they are left alone.
    // Only `paused`/`detached` mean the app has really left the foreground.
    // The Tap to share claim is re-taken on every resume and given back here
    // (MainActivity.onPause also drops it natively, which does not depend on
    // this callback getting to run before the process is frozen).
    switch (state) {
      case AppLifecycleState.resumed:
        restrictNfcDiscoveryToTypeA("App");
        NfcHceGuard.instance.engage("App");
        _checkNfcAvailability();
        _checkBluetoothAvailability();
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        resetNfcDiscovery("App");
        NfcHceGuard.instance.release("App");
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> startProtocolManager(
    Uint8List pgpPublicKey,
    Uint8List pgpPrivateKey, {
    String? privateKeyPassphrase,
  }) async {
    await _protocolManager?.close();
    NfcHaptics.instance.reset();
    final nfcSender = NfcSender();
    _protocolManager = ProtocolManager(
      nfcSenderState: nfcSender,
      nfcReceiverState: NfcReceiver(nfcSender),
      bluetoothSenderState: BluetoothSender(),
      bluetoothReceiverState: BluetoothReceiver(),
    );

    _lastProtocolDisplayStateSubscription?.cancel();
    _lastProtocolDisplayState = _protocolManager!.run.displayState;
    _lastProtocolDisplayStateSubscription = _lastProtocolDisplayState!.events
        .listen((event) {
          log(
            "DisplayState",
            "contactMode=${event.contactMode.value} "
                "deviceRole=${event.deviceRole.value} "
                "result=${_formatDisplayResult(event.result.value)}",
          );
          NfcHaptics.instance.onDisplayEvent(event);
          if (mounted) setState(() {});
        });

    try {
      await _protocolManager!.start(
        pgpPublicKey,
        pgpPrivateKey,
        privateKeyPassphrase: privateKeyPassphrase,
      );
    } catch (e, st) {
      log("ProtocolManager", "start failed: $e\n$st");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayState = _lastProtocolDisplayState?.lastEvent;
    final contactMode = displayState?.contactMode;
    final deviceRole = displayState?.deviceRole;
    final result = displayState?.result;

    Future<void> start() async {
      if (_keyPair == null) return;
      await startProtocolManager(
        Uint8List.fromList(_keyPair!.publicKey.packetList.encode()),
        Uint8List.fromList(_keyPair!.packetList.encode()),
        privateKeyPassphrase: "passphrase",
      );
    }

    final body = Builder(
      builder: (context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: contactMode != null
            ? [
                Text(switch (contactMode.value) {
                  .initializing => "Initializing...",
                  .tapOther => "Tap other",
                  .holdOther => "Hold...",
                  .done =>
                    result?.value?.mode == .success ? "Success!" : "Failure",
                }, style: Theme.of(context).textTheme.headlineLarge),
                Text("Device Role: ${deviceRole?.value?.name ?? "Unknown"}"),
                Text("Result: ${result?.value?.mode ?? "Unknown"}"),
                if (result?.value?.additionalInfo != null &&
                    result?.value?.mode == .success)
                  Card.outlined(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    color: Color.alphaBlend(
                      Colors.green.withValues(alpha: 0.075),
                      Colors.white,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        _formatFingerprint(
                          result?.value?.additionalInfo.fingerprint,
                        ),
                        style: Theme.of(context).textTheme.labelLarge
                            ?.copyWith(fontFamily: "monospace"),
                      ),
                    ),
                  ),
                if (result?.value?.mode == .error)
                  Text("Error: ${result?.value?.errorMode ?? "Unknown"}"),
                if (result?.value?.mode == .failure)
                  Text("Failure: ${result?.value?.failureMode ?? "Unknown"}"),
                if (result?.value?.additionalInfo != null &&
                    result?.value?.mode == .failure)
                  Text("(${result?.value?.additionalInfo ?? "No details"})"),
                OutlinedButton(
                  onPressed:
                      _keyPair == null ||
                          contactMode.value != .done ||
                          _isNfcEnabled != true ||
                          _isBluetoothEnabled != true
                      ? null
                      : start,
                  child: Text("Restart transaction"),
                ),
                Text(
                  _formatFingerprint(_keyPair!.fingerprint),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: "monospace",
                    fontSize: 10,
                    color: Colors.blueGrey,
                  ),
                ),
              ]
            : [
                OutlinedButton(
                  onPressed: () async {
                    if (_isGeneratingKeys) return;
                    _isGeneratingKeys = true;
                    if (mounted) setState(() {});

                    _keyPair = await compute(
                      (_) => OpenPGP.generateKey(
                        ["Device <device@example.com>"],
                        "passphrase",
                        type: KeyType.rsa,
                      ) as PrivateKey,
                      null,
                    );
                    _isGeneratingKeys = false;
                    if (mounted) setState(() {});
                  },
                  child: Text("Generate keys"),
                ),
                OutlinedButton(
                  onPressed:
                      _requiredPermissions == null ||
                          (_permissionStatuses != null &&
                              _permissionStatuses!.values.every(
                                (status) => status == PermissionStatus.granted,
                              ))
                      ? null
                      : () async {
                          _permissionStatuses = await _requiredPermissions!
                              .request();
                          if (_permissionStatuses!.values.any(
                            (status) =>
                                status == PermissionStatus.permanentlyDenied,
                          )) {
                            await openAppSettings();
                          }
                          if (mounted) setState(() {});
                        },
                  child: Text("Grant permissions"),
                ),
                if (_isNfcEnabled == false)
                  OutlinedButton(
                    onPressed: () async => switch (OpenSettingsPlus.shared) {
                      OpenSettingsPlusAndroid settings =>
                        settings
                            .sendAndroidIntent(
                              "android.settings.panel.action.NFC",
                            )
                            .then((ok) => ok ? true : settings.nfc()),
                      _ => throw Exception("Platform not supported"),
                    },
                    child: Text("Enable NFC"),
                  ),
                if (_isBluetoothEnabled == false)
                  OutlinedButton(
                    onPressed: () async => switch (OpenSettingsPlus.shared) {
                      OpenSettingsPlusAndroid settings =>
                        settings
                            .sendAndroidIntent(
                              "android.bluetooth.adapter.action.REQUEST_ENABLE",
                            )
                            .then((ok) => ok ? true : settings.bluetooth()),
                      _ => throw Exception("Platform not supported"),
                    },
                    child: Text("Enable Bluetooth"),
                  ),
                FilledButton(
                  onPressed:
                      _keyPair == null ||
                          _isGeneratingKeys ||
                          _isNfcEnabled != true ||
                          _isBluetoothEnabled != true ||
                          _permissionStatuses == null ||
                          _permissionStatuses!.values.any(
                            (status) => status != PermissionStatus.granted,
                          )
                      ? null
                      : start,
                  child: Text("Start transaction"),
                ),
                if (_keyPair != null)
                  Text(
                    _formatFingerprint(_keyPair!.fingerprint),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: "monospace",
                      fontSize: 10,
                      color: Colors.blueGrey,
                    ),
                  ),
                if (_isNfcAvailable == false)
                  Text("NFC is not available on this device."),
                if (_isBluetoothAvailable == false)
                  Text("Bluetooth is not available on this device."),
              ],
      ),
    );
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        bottomNavigationBar: ValueListenableBuilder<TapToShareGuardState>(
          valueListenable: NfcHceGuard.instance.state,
          builder: (context, guard, _) => guard.shouldWarn
              ? SafeArea(
                  child: Material(
                    color: Colors.amber.shade100,
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber_rounded),
                      title: const Text("Tap to share is interfering"),
                      subtitle: Text(
                        "Android's Tap to share could not be blocked. Turn it "
                        "off in Settings > Google > Quick Share > Tap to "
                        "share, or taps may open the contact-share popup.",
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        body: AnimatedContainer(
          duration: Durations.medium1,
          curve: Curves.easeInOut,
          color: switch (contactMode?.value) {
            .initializing => Colors.yellow,
            .tapOther => Colors.purple,
            .holdOther => Colors.teal,
            .done =>
              result?.value?.mode == .success ? Colors.green : Colors.redAccent,
            _ => Colors.grey,
          }.withValues(alpha: 0.2),
          width: double.infinity,
          child: Stack(
            children: [
              ...?_nfcAntennaLocations?.map(
                (l) => Align(
                  alignment: Alignment(l.x * 2 - 1, l.y * 2 - 1),
                  child: Builder(
                    builder: (context) => DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ColorScheme.of(context).primary
                            .withValues(alpha: 1 / 3),
                      ),
                      child: SizedBox.square(
                        dimension: 64,
                        child: Center(child: Icon(Icons.nfc)),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox.expand(child: body),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDisplayResult(DisplayResult? result) {
  if (result == null) return "null";
  final details = switch (result.mode) {
    DisplayMode.success =>
      "fingerprint="
          "${result.additionalInfo?.fingerprint ?? "unknown"}",
    DisplayMode.error => "errorMode=${result.errorMode}",
    DisplayMode.failure => "failureMode=${result.failureMode}",
  };
  return "mode=${result.mode} $details"
      "${result.additionalInfo != null && result.mode != DisplayMode.success ? " additionalInfo=${result.additionalInfo}" : ""}";
}

String _formatFingerprint(List<int> fingerprint) {
  final parts = fingerprint
      .map((b) => b.toRadixString(16).padLeft(2, "0").toUpperCase())
      .toList();
  return [
    parts.take((parts.length / 2).ceil()).join(" "),
    parts.skip((parts.length / 2).ceil()).join(" "),
  ].join("\n");
}
