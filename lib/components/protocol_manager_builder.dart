import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:shared/shared.dart';

import '../states.dart';

typedef NfcAntennaLocations = List<({double x, double y})>;

class ProtocolManagerState {
  final DisplayState? displayState;
  final NfcAntennaLocations? nfcAntennaLocations;

  final Future<void> Function(PgpProvider pgpProvider) _start;
  final Future<void> Function() _stop;
  Future<void> start(PgpProvider pgpProvider) => _start.call(pgpProvider);
  Future<void> stop() => _stop.call();

  const ProtocolManagerState({
    required this.displayState,
    required this.nfcAntennaLocations,
    required this._start,
    required this._stop,
  });
}

class ProtocolManagerBuilder extends StatefulWidget {
  final VoidCallback? onStart;
  final VoidCallback? onDone;

  const ProtocolManagerBuilder({
    super.key,
    required this.builder,
    this.onStart,
    this.onDone,
  });

  final Widget Function(ProtocolManagerState state) builder;

  @override
  State<ProtocolManagerBuilder> createState() => _ProtocolManagerBuilderState();
}

class _ProtocolManagerBuilderState extends State<ProtocolManagerBuilder>
    with WidgetsBindingObserver {
  ProtocolManager? _protocolManager;
  DisplayState? _lastProtocolDisplayState;
  StreamSubscription<DisplayEvent>? _lastProtocolDisplayStateSubscription;
  NfcAntennaLocations? _nfcAntennaLocations;

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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lastProtocolDisplayStateSubscription?.cancel();
    resetNfcDiscovery("App");
    NfcHceGuard.instance.release("App");
    NfcHaptics.instance.reset();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        restrictNfcDiscoveryToTypeA("App");
        NfcHceGuard.instance.engage("App");
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        resetNfcDiscovery("App");
        NfcHceGuard.instance.release("App");
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _stopProtocolManager() async {
    await _protocolManager?.close();
    _protocolManager = null;
    _lastProtocolDisplayStateSubscription?.cancel();
    _lastProtocolDisplayStateSubscription = null;
    _lastProtocolDisplayState = null;
    NfcHaptics.instance.reset();
    if (mounted) setState(() {});
    widget.onDone?.call();
  }

  Future<void> _startProtocolManager(PgpProvider pgpProvider) async {
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
          if (event.contactMode.value == .done) widget.onDone?.call();
        });

    try {
      widget.onStart?.call();
      await _protocolManager!.start(pgpProvider, privateKeyPassphrase: "");
    } catch (e, st) {
      log("ProtocolManager", "start failed: $e\n$st");
      await _stopProtocolManager();
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder.call(
    ProtocolManagerState(
      displayState: _lastProtocolDisplayState,
      nfcAntennaLocations: _nfcAntennaLocations,
      start: _startProtocolManager,
      stop: _stopProtocolManager,
    ),
  );
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
