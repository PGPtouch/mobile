import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared/shared.dart';

import '../database/key_store.dart' as key_store;
import '../states.dart';
import 'research_point.dart';

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

  final Widget Function(ProtocolManagerState state) builder;

  const ProtocolManagerBuilder({
    super.key,
    required this.builder,
    this.onStart,
    this.onDone,
  });

  @override
  State<ProtocolManagerBuilder> createState() => _ProtocolManagerBuilderState();
}

/// Bookkeeping for a single exchange attempt, reported once as
/// `exchangeAttempt` when it reaches a final outcome.
class _ExchangeAttempt {
  final PgpProvider provider;
  final int retryIndex;
  final Stopwatch total = Stopwatch()..start();
  Duration? tapAt;
  Duration? holdAt;
  DisplayContactMode stage = DisplayContactMode.initializing;
  ProtocolRole? role;
  int backgroundCount = 0;
  bool reported = false;

  _ExchangeAttempt(this.provider, this.retryIndex);
}

Future<String> _loadDeviceModel() async {
  try {
    final info = await DeviceInfoPlugin().androidInfo;
    return "${info.manufacturer} ${info.model}";
  } catch (_) {
    return "unknown";
  }
}

class _ProtocolManagerBuilderState extends State<ProtocolManagerBuilder>
    with WidgetsBindingObserver {
  static final Future<String> _deviceModel = _loadDeviceModel();

  ProtocolManager? _protocolManager;
  DisplayState? _lastProtocolDisplayState;
  StreamSubscription<DisplayEvent>? _lastProtocolDisplayStateSubscription;
  NfcAntennaLocations? _nfcAntennaLocations;

  _ExchangeAttempt? _attempt;
  int _unsuccessfulAttemptsInRow = 0;

  Future<void> _reportAttempt(String outcome, String reason) async {
    final attempt = _attempt;
    if (attempt == null || attempt.reported) return;
    attempt.reported = true;
    attempt.total.stop();
    final end = attempt.total.elapsed;
    final tapAt = attempt.tapAt;
    final holdAt = attempt.holdAt;

    if (outcome == "success") {
      _unsuccessfulAttemptsInRow = 0;
    } else if (outcome != "cancelled") {
      _unsuccessfulAttemptsInRow++;
    }

    // Phase durations; a phase that was never reached is omitted. The init
    // phase includes unlocking the key store, decrypting the private key and
    // any passphrase prompt; decryptMs isolates the decryption.
    final provider = attempt.provider;
    ResearchPoint.trackEvent("exchangeAttempt", {
      "outcome": outcome,
      "reason": reason,
      "role": attempt.role?.name ?? "unknown",
      "stage": attempt.stage.name,
      "durationMs": end.inMilliseconds,
      "initMs": (tapAt ?? holdAt ?? end).inMilliseconds,
      "decryptMs": ?(provider is key_store.KeyStorePgpProvider
          ? provider.decryptMs
          : null),
      "tapMs": ?(tapAt == null
          ? null
          : ((holdAt ?? end) - tapAt).inMilliseconds),
      "holdMs": ?(holdAt == null ? null : (end - holdAt).inMilliseconds),
      "retryIndex": attempt.retryIndex,
      "backgroundCount": attempt.backgroundCount,
      "antennaKnown": _nfcAntennaLocations?.isNotEmpty ?? false,
      "device": await _deviceModel,
    });
  }

  void _trackDisplayEvent(DisplayEvent event) {
    final attempt = _attempt;
    if (attempt == null || attempt.reported) return;

    attempt.role = event.deviceRole.value ?? attempt.role;
    final mode = event.contactMode.value;
    if (mode.index > attempt.stage.index) attempt.stage = mode;
    if (mode == DisplayContactMode.tapOther) {
      attempt.tapAt ??= attempt.total.elapsed;
    } else if (mode == DisplayContactMode.holdOther) {
      attempt.holdAt ??= attempt.total.elapsed;
    }
    if (mode != DisplayContactMode.done) return;

    final result = event.result.value;
    switch (result?.mode) {
      case DisplayMode.success:
        _reportAttempt("success", "none");
      case DisplayMode.error:
        _reportAttempt("error", result!.errorMode?.name ?? "unknown");
      case DisplayMode.failure:
        if (result!.failureMode == DisplayFailureMode.suppliedKeysFailed) {
          final provider = attempt.provider;
          final abortReason = provider is key_store.KeyStorePgpProvider
              ? provider.abortReason
              : null;
          if (abortReason ==
              key_store.KeyStorePgpProvider.passphraseCancelled) {
            _reportAttempt("cancelled", abortReason!);
          } else {
            _reportAttempt("failure", abortReason ?? "suppliedKeysFailed");
          }
        } else {
          _reportAttempt("failure", result.failureMode?.name ?? "unknown");
        }
      case null:
        _reportAttempt("failure", "unknown");
    }
  }

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
    _reportAttempt("abandoned", "disposed");
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
        final attempt = _attempt;
        if (attempt != null && !attempt.reported) attempt.backgroundCount++;
        resetNfcDiscovery("App");
        NfcHceGuard.instance.release("App");
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _stopProtocolManager() async {
    _reportAttempt("abandoned", "stopped");
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
    _reportAttempt("abandoned", "restarted");
    _attempt = _ExchangeAttempt(pgpProvider, _unsuccessfulAttemptsInRow);

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
          _trackDisplayEvent(event);
          NfcHaptics.instance.onDisplayEvent(event);
          if (mounted) setState(() {});
          if (event.contactMode.value == .done) widget.onDone?.call();
        });

    try {
      widget.onStart?.call();
      await _protocolManager!.start(pgpProvider, privateKeyPassphrase: "");
    } catch (e, st) {
      final abortReason = pgpProvider is key_store.KeyStorePgpProvider
          ? pgpProvider.abortReason
          : null;
      if (abortReason == key_store.KeyStorePgpProvider.passphraseCancelled) {
        _reportAttempt("cancelled", abortReason!);
      } else {
        _reportAttempt("failure", abortReason ?? e.runtimeType.toString());
      }
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
      "fingerprint=${result.additionalInfo?.fingerprint ?? "unknown"}",
    DisplayMode.error => "errorMode=${result.errorMode}",
    DisplayMode.failure => "failureMode=${result.failureMode}",
  };
  return "mode=${result.mode} $details"
      "${result.additionalInfo != null && result.mode != DisplayMode.success ? " additionalInfo=${result.additionalInfo}" : ""}";
}
