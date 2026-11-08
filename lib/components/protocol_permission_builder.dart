import 'dart:async';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nfc_util/android.dart' as nfc_android;
import 'package:nfc_util/nfc_util.dart';
import 'package:open_settings_plus/open_settings_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../states.dart';

class ProtocolPermissionState {
  final List<Permission>? requiredPermissions;
  final Map<Permission, PermissionStatus>? permissionStatuses;

  final bool? isNfcAvailable;
  final bool? isNfcEnabled;

  final bool? isBluetoothAvailable;
  final bool? isBluetoothEnabled;

  final Future<void> Function() _requestPermissions;
  final Future<void> Function() _openNfcSettings;
  final Future<void> Function() _openBluetoothSettings;
  Future<void> requestPermissions() => _requestPermissions.call();
  Future<void> openNfcSettings() => _openNfcSettings.call();
  Future<void> openBluetoothSettings() => _openBluetoothSettings.call();

  const ProtocolPermissionState({
    required this.requiredPermissions,
    required this.permissionStatuses,
    required this.isNfcAvailable,
    required this.isNfcEnabled,
    required this.isBluetoothAvailable,
    required this.isBluetoothEnabled,
    required this._requestPermissions,
    required this._openNfcSettings,
    required this._openBluetoothSettings,
  });

  bool get arePermissionsGranted =>
      permissionStatuses != null &&
      permissionStatuses!.values.every(
        (status) => status == PermissionStatus.granted,
      );

  bool get canRequestPermissions =>
      requiredPermissions != null && !arePermissionsGranted;

  bool get areRadiosEnabled =>
      isNfcEnabled == true && isBluetoothEnabled == true;
}

class ProtocolPermissionBuilder extends StatefulWidget {
  const ProtocolPermissionBuilder({super.key, required this.builder});

  final Widget Function(ProtocolPermissionState state) builder;

  @override
  State<ProtocolPermissionBuilder> createState() =>
      _ProtocolPermissionBuilderState();
}

class _ProtocolPermissionBuilderState extends State<ProtocolPermissionBuilder>
    with WidgetsBindingObserver {
  List<Permission>? _requiredPermissions;
  Map<Permission, PermissionStatus>? _permissionStatuses;

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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nfcAdapterSubscription?.cancel();
    _bluetoothStateSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkNfcAvailability();
      _checkBluetoothAvailability();
    }
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

  Future<void> _requestPermissions() async {
    _permissionStatuses = await _requiredPermissions!.request();
    if (_permissionStatuses!.values.any(
      (status) => status == PermissionStatus.permanentlyDenied,
    )) {
      await openAppSettings();
    }
    if (mounted) setState(() {});
  }

  Future<void> _openNfcSettings() async {
    switch (OpenSettingsPlus.shared) {
      case final OpenSettingsPlusAndroid settings:
        final ok = await settings.sendAndroidIntent(
          "android.settings.panel.action.NFC",
        );
        if (!ok) await settings.nfc();
      default:
        throw Exception("Platform not supported");
    }
  }

  Future<void> _openBluetoothSettings() async {
    switch (OpenSettingsPlus.shared) {
      case final OpenSettingsPlusAndroid settings:
        final ok = await settings.sendAndroidIntent(
          "android.bluetooth.adapter.action.REQUEST_ENABLE",
        );
        if (!ok) await settings.bluetooth();
      default:
        throw Exception("Platform not supported");
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder.call(
    ProtocolPermissionState(
      requiredPermissions: _requiredPermissions,
      permissionStatuses: _permissionStatuses,
      isNfcAvailable: _isNfcAvailable,
      isNfcEnabled: _isNfcEnabled,
      isBluetoothAvailable: _isBluetoothAvailable,
      isBluetoothEnabled: _isBluetoothEnabled,
      requestPermissions: _requestPermissions,
      openNfcSettings: _openNfcSettings,
      openBluetoothSettings: _openBluetoothSettings,
    ),
  );
}
