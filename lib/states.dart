import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart'
    show AppLifecycleState, WidgetsBinding, WidgetsBindingObserver;
import 'package:shared/shared.dart';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
// ignore: implementation_imports
import 'package:bluetooth_low_energy_android/src/api.g.dart'
    show PeripheralManagerHostApi;
import 'package:nfc_util/android.dart' as nfc_android;
import 'package:nfc_util/nfc_util.dart';

// MARK: Shared constants

Uint8List nfcAid = Uint8List.fromList([
  0xF0,
  0x7C,
  0x90,
  0x3F,
  0x23,
  0x4A,
  0x76,
  0x18,
]);

const _nfcApduPort = 0;
const _nfcBootstrapLength = 96;
const _nfcBootstrapResponseLength = _nfcBootstrapLength + 2;

const _nfcPushCla = 0x80;
const _nfcPushIns = 0x00;
final _nfcStatusSuccess = Uint8List.fromList([0x90, 0x00]);
final _nfcStatusWrongLength = Uint8List.fromList([0x67, 0x00]);
final _nfcStatusWrongData = Uint8List.fromList([0x6A, 0x80]);
final _nfcStatusFileNotFound = Uint8List.fromList([0x6A, 0x82]);
final _nfcStatusInsNotSupported = Uint8List.fromList([0x6D, 0x00]);

const _tapToShareChannel = MethodChannel("mobile/tap_to_share");
const _hapticsChannel = MethodChannel("mobile/haptics");
final _gestureExchangeAid = Uint8List.fromList([
  0xA0,
  0x00,
  0x00,
  0x04,
  0x76,
  0x09,
]);

final UUID _bleRequestCharacteristicUuid = UUID.fromString(
  bleCharacteristicRequest,
);
final UUID _bleResponseCharacteristicUuid = UUID.fromString(
  bleCharacteristicResponse,
);

const _nativeOperationTimeout = Duration(seconds: 10);
Future<T> _withTimeout<T>(Future<T> future, String label) {
  return future.timeout(
    _nativeOperationTimeout,
    onTimeout: () {
      log("native", "$label timed out after $_nativeOperationTimeout");
      throw TimeoutException("$label timed out after $_nativeOperationTimeout");
    },
  );
}

String _bytesToHex(Uint8List bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, "0")).join().toUpperCase();

bool _bytesEqual(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

Uint8List _nfcSelectApdu(int port) =>
    Uint8List.fromList([0x00, 0xA4, 0x04, port, nfcAid.length, ...nfcAid]);

Uint8List _nfcPushApdu(Uint8List bootstrap) => Uint8List.fromList([
  _nfcPushCla,
  _nfcPushIns,
  0x00,
  0x00,
  bootstrap.length,
  ...bootstrap,
]);

Future<bool> _ensureBluetoothReady(BluetoothLowEnergyManager manager) async {
  log("BLE", "_ensureBluetoothReady($manager): initial state=${manager.state}");

  Future<BluetoothLowEnergyState> nextKnownState({required Duration timeout}) =>
      manager.stateChanged
          .map((event) => event.state)
          .firstWhere((state) => state != BluetoothLowEnergyState.unknown)
          .timeout(
            timeout,
            onTimeout: () {
              log(
                "BLE",
                "awaiting stateChanged timed out, state=${manager.state}",
              );
              return manager.state;
            },
          );

  var state = manager.state;
  if (state == BluetoothLowEnergyState.unknown) {
    log("BLE", "state unknown, awaiting stateChanged...");
    state = await nextKnownState(timeout: const Duration(seconds: 3));
    log("BLE", "state resolved to $state");
  }

  if (state == BluetoothLowEnergyState.unauthorized) {
    log("BLE", "unauthorized, requesting authorize()...");
    final granted = await manager.authorize();
    log("BLE", "authorize() granted=$granted");
    state = granted
        ? await nextKnownState(timeout: const Duration(seconds: 10))
        : manager.state;
    log("BLE", "post-authorize state=$state");
  }

  final ready = state == BluetoothLowEnergyState.poweredOn;
  log("BLE", "_ensureBluetoothReady($manager) => $ready (state=$state)");
  return ready;
}

mixin _DisposeOnce {
  bool _alreadyDisposed = false;

  bool get disposeAlreadyRan {
    if (_alreadyDisposed) return true;
    _alreadyDisposed = true;
    return false;
  }
}

// MARK: NFC

/// Restricts NFC discovery to NFC-A (API 35+). Retried because the plugin's
/// activity may not be attached yet; failures are ignored.
Future<void> restrictNfcDiscoveryToTypeA(
  String tag, {
  int attempts = 3,
  Duration retryDelay = const Duration(milliseconds: 150),
}) async {
  for (var attempt = 1; attempt <= attempts; attempt++) {
    try {
      await nfc_android.NfcUtilAndroid.instance.setDiscoveryTechnology(
        poll: {nfc_android.NfcPollTech.nfcA},
        listen: {nfc_android.NfcListenTech.nfcA},
      );
      log(tag, "setDiscoveryTechnology(nfcA-only) applied (attempt $attempt)");
      return;
    } catch (e, st) {
      final isLastAttempt = attempt == attempts;
      log(
        tag,
        "setDiscoveryTechnology failed on attempt $attempt"
        "${isLastAttempt ? ', giving up' : ', retrying'}: $e\n$st",
      );
      if (isLastAttempt) return;
      await Future.delayed(retryDelay);
    }
  }
}

Future<void> resetNfcDiscovery(String tag) async {
  try {
    await nfc_android.NfcUtilAndroid.instance.resetDiscoveryTechnology();
  } catch (e, st) {
    log(tag, "resetDiscoveryTechnology failed (ignoring): $e\n$st");
  }
}

/// One control point of a [HapticPattern.envelope]: the vibrator ramps
/// linearly to [amplitude] (0-1) at [frequencyHz] over [durationMs].
typedef HapticPoint = ({int durationMs, double amplitude, double frequencyHz});

/// A haptic pattern, played by the native `Haptics` class (see
/// `Haptics.kt`) with the communication-request usage.
///
/// The best representation the device supports is played: the [envelope]
/// (needs frequency control, Android 16+), else [timings] with [amplitudes].
/// Vibrators without amplitude control do not vibrate.
///
/// A pattern can repeat from a point on ([envelopeRepeatFrom] and
/// [repeatFrom], indices into the respective lists); everything before is
/// played once.
@immutable
final class HapticPattern {
  const HapticPattern({
    required this.timings,
    required this.amplitudes,
    this.repeatFrom,
    this.envelope,
    this.envelopeRepeatFrom,
  });

  /// Waveform in ms, one amplitude (0-255) per timing.
  final List<int> timings;
  final List<int> amplitudes;
  final int? repeatFrom;

  final List<HapticPoint>? envelope;
  final int? envelopeRepeatFrom;

  bool get repeats => repeatFrom != null;

  Duration get duration =>
      Duration(milliseconds: timings.fold(0, (sum, timing) => sum + timing));

  Map<String, Object?> toArguments() => {
    "timings": timings,
    "amplitudes": amplitudes,
    "repeatFrom": repeatFrom,
    "envelopeRepeatFrom": envelopeRepeatFrom,
    "envelope": envelope
        ?.map(
          (point) => {
            "durationMs": point.durationMs,
            "amplitude": point.amplitude,
            "frequencyHz": point.frequencyHz,
          },
        )
        .toList(),
  };
}

/// Haptics for the tap flow, driven by the protocol's [DisplayEvent]s:
///
///  * hold other: a very light, repeating swell and fade until done;
///  * done: a success or a failure pattern.
///
/// This is played natively with the communication-request usage, which
/// outranks the hardware-feedback usage of Android's own "tag discovered"
/// vibration, but nothing masks that one: it is not suppressed.
///
/// An ongoing repeating vibration wins ties against a new non-repeating
/// one, so the swell is always cancelled before a one-shot pattern starts.
/// One-shot patterns never cut each other off: later ones wait their turn.
/// Everything is cancelled when the app leaves the foreground.
final class NfcHaptics with WidgetsBindingObserver {
  NfcHaptics._();

  static final NfcHaptics instance = NfcHaptics._();

  /// From the Hapticlabs project: a 0.1 intensity sine that sweeps in from the
  /// lowest frequency to 80 Hz over 125 ms and back out over 125 ms, followed
  /// by a 750 ms pause. Frequencies are clamped to what the device supports,
  /// and the sweep's easing curve is linear.
  ///
  /// Without frequency control only the amplitude is left, so the waveform is
  /// a half sine peaking at 0.1 * 255 with the same 1 s cycle.
  static const _swellEnvelope = <HapticPoint>[
    (durationMs: 1, amplitude: 0.1, frequencyHz: 1),
    (durationMs: 125, amplitude: 0.1, frequencyHz: 80),
    (durationMs: 125, amplitude: 0.1, frequencyHz: 1),
    (durationMs: 1, amplitude: 0, frequencyHz: 1),
    (durationMs: 748, amplitude: 0, frequencyHz: 1),
  ];
  static const _swellTimings = [25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 750];
  static const _swellAmplitudes = [4, 12, 18, 23, 26, 26, 23, 18, 12, 4, 0];

  /// A 750 ms break, then the swell, repeated.
  static const _swell = HapticPattern(
    envelope: [
      (durationMs: 750, amplitude: 0, frequencyHz: 1),
      ..._swellEnvelope,
    ],
    envelopeRepeatFrom: 1,
    timings: [750, ..._swellTimings],
    amplitudes: [0, ..._swellAmplitudes],
    repeatFrom: 1,
  );

  /// From the Hapticlabs project: an 8 ms saw pulse at 0.3 intensity and
  /// 120 Hz, a 75 ms pause, a 10 ms saw pulse at 0.4 and 96.4 Hz, a 100 ms
  /// pause and a 100 ms sine at 120 Hz that swells from 0.01 to 0.12
  /// intensity over 64 ms, fades to 0.08 over the last 24 ms and sweeps up to
  /// 230 Hz over the last 64 ms. Easing curves are linear.
  ///
  /// The waveform fallback plays the sine part at three times its intensity:
  /// at 0.02-0.12 it is not felt on a Pixel 9 Pro, whose vibrator has no
  /// frequency control, right after the two much stronger pulses.
  static const _success = HapticPattern(
    envelope: [
      (durationMs: 4, amplitude: 0.3, frequencyHz: 120),
      (durationMs: 4, amplitude: 0, frequencyHz: 120),
      (durationMs: 75, amplitude: 0, frequencyHz: 120),
      (durationMs: 5, amplitude: 0.4, frequencyHz: 96.38),
      (durationMs: 5, amplitude: 0, frequencyHz: 96.38),
      (durationMs: 100, amplitude: 0, frequencyHz: 120),
      (durationMs: 1, amplitude: 0.01, frequencyHz: 120),
      (durationMs: 35, amplitude: 0.0719, frequencyHz: 120),
      (durationMs: 28, amplitude: 0.12, frequencyHz: 168.28),
      (durationMs: 12, amplitude: 0.12, frequencyHz: 188.97),
      (durationMs: 24, amplitude: 0.08, frequencyHz: 230.35),
      (durationMs: 2, amplitude: 0, frequencyHz: 230.35),
    ],
    timings: [8, 75, 10, 100, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10],
    amplitudes: [77, 0, 102, 0, 15, 27, 42, 54, 66, 81, 93, 93, 81, 69],
  );

  /// From the Hapticlabs project: an 8 ms saw pulse at 0.4 intensity and
  /// 120 Hz, a 75 ms pause, a 10 ms saw pulse at 0.3 and 96.4 Hz, a 50 ms
  /// pause, then twice, 10 ms apart, a 70 ms sine at 0.12 intensity that
  /// swells from 0.01 over 47.6 ms and fades back, with the frequency falling
  /// from 230 Hz to 120 Hz over 40 ms and on to the lowest the device
  /// supports. Easing curves are linear. The waveform fallback plays the sine
  /// parts at three times their intensity, as for [_success].
  static const _failure = HapticPattern(
    envelope: [
      (durationMs: 4, amplitude: 0.4, frequencyHz: 120),
      (durationMs: 4, amplitude: 0, frequencyHz: 120),
      (durationMs: 75, amplitude: 0, frequencyHz: 120),
      (durationMs: 5, amplitude: 0.3, frequencyHz: 96.38),
      (durationMs: 5, amplitude: 0, frequencyHz: 96.38),
      (durationMs: 50, amplitude: 0, frequencyHz: 230),
      (durationMs: 1, amplitude: 0.01, frequencyHz: 230),
      (durationMs: 39, amplitude: 0.1024, frequencyHz: 120),
      (durationMs: 8, amplitude: 0.12, frequencyHz: 89.9),
      (durationMs: 22, amplitude: 0.01, frequencyHz: 1),
      (durationMs: 10, amplitude: 0, frequencyHz: 1),
      (durationMs: 1, amplitude: 0.01, frequencyHz: 230),
      (durationMs: 39, amplitude: 0.1024, frequencyHz: 120),
      (durationMs: 8, amplitude: 0.12, frequencyHz: 89.9),
      (durationMs: 22, amplitude: 0.01, frequencyHz: 1),
      (durationMs: 2, amplitude: 0, frequencyHz: 1),
    ],
    timings: [
      8, 75, 10, 50, //
      10, 10, 10, 10, 10, 10, 10, 10, //
      10, 10, 10, 10, 10, 10, 10,
    ],
    amplitudes: [
      102, 0, 77, 0, //
      18, 33, 51, 69, 87, 63, 27, 0, //
      18, 33, 51, 69, 87, 63, 27,
    ],
  );

  DisplayContactMode? _mode;
  bool _foreground = true;
  bool _observing = false;
  bool _capabilitiesLogged = false;
  // Invalidates everything scheduled but not yet started.
  int _epoch = 0;
  // When the running one-shot pattern ends.
  DateTime? _busyUntil;
  Future<void> _queue = Future.value();

  void onDisplayEvent(DisplayEvent event) {
    final mode = event.contactMode.value;
    if (mode == _mode) return;
    _mode = mode;
    _observe();
    switch (mode) {
      case DisplayContactMode.initializing:
        _invalidate();
        _serialized(_cancel);
      case DisplayContactMode.tapOther:
        _invalidate();
        _serialized(_cancel);
      case DisplayContactMode.holdOther:
        _whenIdle(_epoch, _startSwell);
      case DisplayContactMode.done:
        final success = event.result.value?.mode == DisplayMode.success;
        _invalidate(keepBusy: success);
        _whenIdle(_epoch, () => _oneShot(success ? _success : _failure));
    }
  }

  /// Cancels everything, for when the protocol is torn down.
  void reset() {
    _mode = null;
    _invalidate();
    _serialized(_cancel);
    if (_observing) {
      WidgetsBinding.instance.removeObserver(this);
      _observing = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = switch (state) {
      AppLifecycleState.resumed || AppLifecycleState.inactive => true,
      AppLifecycleState.hidden ||
      AppLifecycleState.paused ||
      AppLifecycleState.detached => false,
    };
    if (foreground == _foreground) return;
    _foreground = foreground;
    _invalidate();
    if (!foreground) {
      _serialized(_cancel);
    } else {
      _whenIdle(_epoch, _startSwell);
    }
  }

  void _observe() {
    if (_observing) return;
    _observing = true;
    _foreground = _appIsForeground;
    WidgetsBinding.instance.addObserver(this);
  }

  bool get _appIsForeground {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    return lifecycle == null ||
        lifecycle == AppLifecycleState.resumed ||
        lifecycle == AppLifecycleState.inactive;
  }

  void _invalidate({bool keepBusy = false}) {
    _epoch++;
    if (!keepBusy) _busyUntil = null;
  }

  Future<void> _serialized(Future<void> Function() operation) {
    final next = _queue.then((_) => operation());
    _queue = next.catchError((Object _) {});
    return next;
  }

  /// Runs [action] once the running one-shot pattern is over, unless
  /// something invalidated [epoch] in the meantime.
  void _whenIdle(int epoch, Future<void> Function() action) {
    _serialized(() async {
      if (epoch != _epoch || !_foreground) return;
      final remaining = _busyUntil?.difference(DateTime.now());
      if (remaining != null && remaining > Duration.zero) {
        Timer(remaining, () => _whenIdle(epoch, action));
        return;
      }
      await action();
    });
  }

  Future<void> _cancel() async {
    try {
      await _hapticsChannel.invokeMethod<void>("cancel");
    } catch (e, st) {
      log("NfcHaptics", "cancel failed: $e\n$st");
    }
  }

  Future<void> _startSwell() async {
    if (_mode != DisplayContactMode.holdOther) return;
    await _play(_swell);
  }

  Future<void> _oneShot(HapticPattern pattern) async {
    final epoch = _epoch;
    await _play(pattern);
    if (epoch != _epoch) return;
    _busyUntil = DateTime.now().add(pattern.duration);
  }

  /// Replaces whatever is playing with [pattern].
  Future<void> _play(HapticPattern pattern) async {
    try {
      if (!_capabilitiesLogged) {
        _capabilitiesLogged = true;
        final capabilities = await _hapticsChannel
            .invokeMapMethod<String, Object?>("capabilities");
        log("NfcHaptics", "capabilities: $capabilities");
      }
      final how = await _hapticsChannel.invokeMethod<String>(
        "play",
        pattern.toArguments(),
      );
      log(
        "NfcHaptics",
        "played ${pattern.repeats ? "repeating " : ""}pattern as $how",
      );
    } catch (e, st) {
      log("NfcHaptics", "playing pattern failed: $e\n$st");
    }
  }
}

@immutable
final class TapToShareGuardState {
  const TapToShareGuardState({
    this.systemFeaturePresent,
    this.claimEffective,
    this.detail = "",
  });

  final bool? systemFeaturePresent;

  final bool? claimEffective;

  final String detail;

  bool get shouldWarn =>
      systemFeaturePresent == true && claimEffective == false;
}

/// Claims the Tap to share AID so Play Services never gets the SELECT. Held
/// for the app's foreground lifetime.
final class NfcHceGuard {
  NfcHceGuard._();

  static final NfcHceGuard instance = NfcHceGuard._();

  final _hce = nfc_android.HostCardEmulation.instance;

  final ValueNotifier<TapToShareGuardState> state = ValueNotifier(
    const TapToShareGuardState(),
  );

  Object? _sessionOwner;
  Uint8List Function(Uint8List apdu)? _sessionHandler;
  bool _ourAidSelected = false;
  Future<void> _queue = Future.value();

  void attachSession(Object owner, Uint8List Function(Uint8List apdu) handler) {
    _sessionOwner = owner;
    _sessionHandler = handler;
  }

  /// No-op unless [owner] is still the attached session.
  void detachSession(Object owner) {
    if (!identical(_sessionOwner, owner)) return;
    _sessionOwner = null;
    _sessionHandler = null;
  }

  Future<void> engage(String tag) => _serialized(() => _engage(tag));

  Future<void> release(String tag) => _serialized(() => _release(tag));

  Future<void> _serialized(Future<void> Function() operation) {
    final next = _queue.then((_) => operation());
    _queue = next.catchError((Object _) {});
    return next;
  }

  Future<void> _engage(String tag) async {
    try {
      _hce.onApduReceived = _onApdu;
      _hce.onDeactivated = (reason) {
        _ourAidSelected = false;
        log("NfcHceGuard", "onDeactivated: reason=$reason");
      };

      final system = await _readSystemStatus();
      final guarded = <Uint8List>[_gestureExchangeAid, ?system.secondaryAid];

      final guardRegistered = await _register([nfcAid, ...guarded]);
      if (!guardRegistered) {
        log("NfcHceGuard", "[$tag] claiming Tap to share AID refused");
        await _register([nfcAid]);
      }

      final foreground = _appIsForeground;
      final effective = guardRegistered && foreground && await _verify(guarded);
      if (guardRegistered && !effective) {
        // A claim that does not win leaves the AID contested; keep only ours.
        log("NfcHceGuard", "[$tag] claim not effective, withdrawing it");
        await _register([nfcAid]);
      }

      state.value = TapToShareGuardState(
        systemFeaturePresent: system.featurePresent,
        // Unknown while off screen.
        claimEffective: effective ? true : (foreground ? false : null),
        detail: system.detail,
      );
      log(
        "NfcHceGuard][$tag",
        "engaged: featurePresent=${system.featurePresent} "
            "foreground=$foreground claimEffective=${state.value.claimEffective} "
            "(${system.detail})",
      );
    } catch (e, st) {
      log("NfcHceGuard", "[$tag] engage failed: $e\n$st");
    }
  }

  Future<void> _release(String tag) async {
    _ourAidSelected = false;
    try {
      await _hce.setPreferredService(false);
    } catch (e, st) {
      log("NfcHceGuard][$tag", "setPreferredService(false) failed: $e\n$st");
    }
    try {
      await _hce.unregisterAids();
    } catch (e, st) {
      log("NfcHceGuard", "[$tag] unregisterAids failed: $e\n$st");
    }
    _hce.onApduReceived = null;
    _hce.onDeactivated = null;
    state.value = TapToShareGuardState(
      systemFeaturePresent: state.value.systemFeaturePresent,
      detail: state.value.detail,
    );
    log("NfcHceGuard", "[$tag] released");
  }

  /// A null lifecycle state counts as foreground.
  bool get _appIsForeground {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    return lifecycle == null || lifecycle == AppLifecycleState.resumed;
  }

  Future<bool> _register(List<Uint8List> aids) async {
    try {
      final registered = await _hce.registerAids(
        aids.map(_bytesToHex).toList(),
      );
      log(
        "NfcHceGuard",
        "registerAids(${aids.map(_bytesToHex).join(",")}) "
            "=> $registered",
      );
      return registered;
    } catch (e, st) {
      log("NfcHceGuard", "registerAids failed: $e\n$st");
      return false;
    }
  }

  Future<bool> _verify(List<Uint8List> guarded) async {
    for (var attempt = 1; attempt <= 5; attempt++) {
      try {
        await _hce.setPreferredService(true);
        var all = true;
        for (final aid in guarded) {
          all &= await _hce.isDefaultServiceForAid(_bytesToHex(aid));
        }
        if (all) return true;
      } catch (e, st) {
        log("NfcHceGuard", "verify attempt $attempt failed: $e\n$st");
      }
      await Future.delayed(const Duration(milliseconds: 250));
    }
    return false;
  }

  Future<_SystemTapToShare> _readSystemStatus() async {
    try {
      final status = await _tapToShareChannel.invokeMapMethod<String, Object?>(
        "status",
      );
      if (status == null) return const _SystemTapToShare.unknown();
      final gesture = status["gestureExchangeComponent"] as String?;
      final tapService = status["tapEventServiceComponent"] as String?;
      final secondary = _parseAid(status["secondaryAid"] as String?);
      return _SystemTapToShare(
        featurePresent: gesture != null || tapService != null,
        secondaryAid: secondary,
        detail: "gestureExchange=$gesture tapEventService=$tapService",
      );
    } on MissingPluginException {
      return const _SystemTapToShare.unknown();
    } on PlatformException catch (e) {
      log("NfcHceGuard", "reading Tap to share status failed: $e");
      return const _SystemTapToShare.unknown();
    }
  }

  void _onApdu(Uint8List apdu) {
    Uint8List response;
    try {
      response = _answer(apdu);
    } catch (e, st) {
      log("NfcHceGuard", "answering APDU failed: $e\n$st");
      response = Uint8List.fromList([0x6F, 0x00]);
    }
    _hce.respond(response).catchError((e, st) {
      log("NfcHceGuard", "respond failed: $e\n$st");
    });
  }

  Uint8List _answer(Uint8List apdu) {
    final selected = _selectedAid(apdu);
    if (selected != null) {
      _ourAidSelected = _bytesEqual(selected, nfcAid);
      if (!_ourAidSelected) {
        log(
          "NfcHceGuard",
          "SELECT ${_bytesToHex(selected)} -> not found "
              "(keeping Tap to share out)",
        );
        return _nfcStatusFileNotFound;
      }
    } else if (!_ourAidSelected) {
      return _nfcStatusInsNotSupported;
    }
    final handler = _sessionHandler;
    if (handler == null) {
      log("NfcHceGuard", "APDU for our AID but no active session");
      return _nfcStatusFileNotFound;
    }
    return handler(apdu);
  }

  Uint8List? _selectedAid(Uint8List apdu) {
    if (apdu.length < 5 || apdu[1] != 0xA4 || apdu[2] != 0x04) return null;
    final length = apdu[4];
    if (apdu.length < 5 + length) return null;
    return apdu.sublist(5, 5 + length);
  }

  Uint8List? _parseAid(String? hex) {
    if (hex == null ||
        hex.length < 10 ||
        hex.length > 32 ||
        hex.length.isOdd ||
        !RegExp(r"^[0-9A-Fa-f]+$").hasMatch(hex)) {
      return null;
    }
    return Uint8List.fromList([
      for (var i = 0; i < hex.length; i += 2)
        int.parse(hex.substring(i, i + 2), radix: 16),
    ]);
  }
}

final class _SystemTapToShare {
  const _SystemTapToShare({
    required this.featurePresent,
    required this.secondaryAid,
    required this.detail,
  });

  const _SystemTapToShare.unknown()
    : featurePresent = null,
      secondaryAid = null,
      detail = "status unavailable";

  final bool? featurePresent;
  final Uint8List? secondaryAid;
  final String detail;
}

/// NFC antenna positions as fractions of the device width/height.
///
/// Measurements are from the top-left corner with the screen facing the viewer.
/// Null when unknown or on foldable devices.
Future<List<({double x, double y})>?> getNfcAntennaLocations() async =>
    switch (Platform.operatingSystem) {
      "android" =>
        (await _tapToShareChannel.invokeListMethod<Map>("antennaLocations"))
            ?.map((antenna) {
              final x = (antenna["x"] as num).toDouble();
              final y = (antenna["y"] as num).toDouble();
              return (x: x, y: y);
            })
            .toList(),
      _ => null,
    };

final class NfcSender extends NfcSenderState with _DisposeOnce {
  final _hce = nfc_android.HostCardEmulation.instance;

  @override
  Future<bool> isAvailable() async {
    final supported = await _hce.isSupported();
    log("NfcSender", "isAvailable: supported=$supported");

    try {
      final antennas = await getNfcAntennaLocations();
      if (antennas == null) {
        log(
          "NfcAntenna",
          "location unavailable (needs Android 14+ and OEM data, or device is foldable)",
        );
      } else if (antennas.isEmpty) {
        log("NfcAntenna", "no antennas reported");
      }
      for (final (i, a) in (antennas ?? []).indexed) {
        log(
          "NfcAntenna",
          "antenna $i: x=${a.x.toStringAsFixed(3)} y=${a.y.toStringAsFixed(3)}",
        );
      }
    } catch (e) {
      log("NfcAntenna", "reading antenna location failed: $e");
    }

    return supported;
  }

  @override
  Future<void> start() async {
    final bytes = data!.toBytes();
    log("NfcSender", "start: aid=${_bytesToHex(nfcAid)} bytes=$bytes");
    NfcHceGuard.instance.attachSession(this, (apdu) {
      log("NfcSender", "onApduReceived: $apdu");
      if (apdu.length >= 2 &&
          apdu[0] == _nfcPushCla &&
          apdu[1] == _nfcPushIns) {
        return _handlePush(apdu);
      }
      try {
        emit(NfcSenderEvent.selected());
        // ignore: avoid_catching_errors
      } on StateError {
        // already disposed
      }
      return Uint8List.fromList([...bytes, 0x90, 0x00]);
    });
    await NfcHceGuard.instance.engage("NfcSender");
    await restrictNfcDiscoveryToTypeA("NfcSender");
    log("NfcSender", "start complete");
  }

  Uint8List _handlePush(Uint8List apdu) {
    if (apdu.length < 5 ||
        apdu[4] != _nfcBootstrapLength ||
        apdu.length < 5 + _nfcBootstrapLength) {
      log("NfcSender", "push rejected: wrong length ${apdu.length}");
      return _nfcStatusWrongLength;
    }
    final received = apdu.sublist(5, 5 + _nfcBootstrapLength);
    try {
      emit(NfcSenderEvent(received: received));
    } catch (e, st) {
      log("NfcSender", "push rejected: $e\n$st");
      return _nfcStatusWrongData;
    }
    log("NfcSender", "push accepted: $received");
    return _nfcStatusSuccess;
  }

  @override
  Future<void> dispose() async {
    if (disposeAlreadyRan) {
      log("NfcSender", "dispose: already disposed, skipping");
      return;
    }
    log("NfcSender", "dispose");
    // The guard's claim and the NFC-A restriction outlive the session.
    NfcHceGuard.instance.detachSession(this);
    await super.dispose();
  }
}

final class NfcReceiver extends NfcReceiverState with _DisposeOnce {
  final NfcSenderState _sender;
  NfcReceiver(this._sender);

  bool _transceiving = false;
  Uint8List? _lastReceived;

  @override
  Future<bool> isAvailable() async {
    final availability = await NfcUtil.instance.checkAvailability();
    log("NfcReceiver", "isAvailable: availability=$availability");
    return availability == NfcAvailability.enabled;
  }

  @override
  Future<void> start() async {
    log("NfcReceiver", "start: enabling foreground dispatch");
    _lastReceived = null;
    nfc_android.NfcUtilAndroid.instance.onTagFromIntent = _handleTag;
    await nfc_android.NfcUtilAndroid.instance.enableForegroundDispatch();
    await restrictNfcDiscoveryToTypeA("NfcReceiver");
    log("NfcReceiver", "start complete");
  }

  Future<void> _handleTag(NfcTag tag) async {
    final isoDep = nfc_android.IsoDep.from(tag);
    if (isoDep == null) {
      log("NfcReceiver", "ignoring non-ISO-DEP tag");
      return;
    }
    // Ignore re-entrant deliveries for the same tap.
    if (_transceiving) {
      log("NfcReceiver", "transceive already in progress, ignoring tag");
      return;
    }
    _transceiving = true;
    try {
      log("NfcReceiver", "transceiving select APDU...");
      final response = await _withTimeout(
        isoDep.transceive(_nfcSelectApdu(_nfcApduPort)),
        "NFC transceive",
      );
      log("NfcReceiver", "transceive response: $response");
      if (response.length != _nfcBootstrapResponseLength) {
        log(
          "NfcReceiver",
          "unexpected response length ${response.length} "
              "(expected $_nfcBootstrapResponseLength), ignoring",
        );
        return;
      }
      // Also require the success status word.
      if (response[response.length - 2] != 0x90 ||
          response[response.length - 1] != 0x00) {
        log(
          "NfcReceiver",
          "unexpected status word "
              "${_bytesToHex(response.sublist(response.length - 2))}, ignoring",
        );
        return;
      }
      final received = response.sublist(0, response.length - 2);
      final last = _lastReceived;
      if (last != null &&
          last.length == received.length &&
          _bytesEqual(last, received)) {
        log("NfcReceiver", "ignoring duplicate redelivered bootstrap");
        return;
      }
      _lastReceived = received;
      // Best effort, before emitting.
      await _pushOwnBootstrap(isoDep);
      log("NfcReceiver", "emitting NfcReceiverEvent: $received");
      emit(NfcReceiverEvent(received: received));
    } catch (e, st) {
      log("NfcReceiver", "transceive failed: $e\n$st");
    } finally {
      _transceiving = false;
    }
  }

  Future<void> _pushOwnBootstrap(nfc_android.IsoDep isoDep) async {
    final bootstrap = _sender.data?.toBytes();
    if (bootstrap == null) return;
    try {
      final response = await _withTimeout(
        isoDep.transceive(_nfcPushApdu(bootstrap)),
        "NFC push",
      );
      log("NfcReceiver", "push response: $response");
    } catch (e, st) {
      log("NfcReceiver", "push failed (ignoring): $e\n$st");
    }
  }

  @override
  Future<void> dispose() async {
    if (disposeAlreadyRan) {
      log("NfcReceiver", "dispose: already disposed, skipping");
      return;
    }
    log("NfcReceiver", "dispose");
    try {
      await nfc_android.NfcUtilAndroid.instance.disableForegroundDispatch();
    } catch (e, st) {
      log("NfcReceiver", "dispose: disableForegroundDispatch failed: $e\n$st");
    }
    nfc_android.NfcUtilAndroid.instance.onTagFromIntent = null;
    await super.dispose();
  }
}

// MARK: Bluetooth

final class BluetoothSender extends BluetoothSenderState with _DisposeOnce {
  final CentralManager _centralManager = CentralManager();
  StreamSubscription<GATTCharacteristicNotifiedEventArgs>? _notifySubscription;
  StreamSubscription<PeripheralConnectionStateChangedEventArgs>?
  _connectionStateSubscription;
  Peripheral? _peripheral;
  GATTCharacteristic? _requestCharacteristic;

  @override
  Future<bool> isAvailable() => _ensureBluetoothReady(_centralManager);

  @override
  Future<bool> connect(String sessionId) async {
    log("BluetoothSender", "connect: sessionId=$sessionId");
    if (_peripheral != null) {
      log("BluetoothSender", "already connected, disconnecting stale link");
      await disconnect();
    }

    final serviceUuid = UUID.fromString(sessionId);
    final discovered = Completer<Peripheral?>();
    final discoverySubscription = _centralManager.discovered.listen((event) {
      log(
        "BluetoothSender",
        "discovered peripheral=${event.peripheral.uuid} "
            "rssi=${event.rssi} serviceUUIDs=${event.advertisement.serviceUUIDs}",
      );
      if (!discovered.isCompleted) discovered.complete(event.peripheral);
    });
    log("BluetoothSender", "startDiscovery(serviceUUIDs: [$serviceUuid])");
    await _centralManager.startDiscovery(serviceUUIDs: [serviceUuid]);
    final peripheral = await discovered.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        log("BluetoothSender", "discovery timed out after 10s");
        return null;
      },
    );
    await _centralManager.stopDiscovery();
    await discoverySubscription.cancel();
    if (peripheral == null) {
      log("BluetoothSender", "connect failed: no peripheral discovered");
      return false;
    }

    // Registered before connect() so a racing disconnect isn't missed.
    _connectionStateSubscription = _centralManager.connectionStateChanged
        .listen((event) {
          if (event.peripheral.uuid != peripheral.uuid) return;
          log(
            "BluetoothSender",
            "connectionStateChanged: "
                "peripheral=${event.peripheral.uuid} state=${event.state}",
          );
          if (event.state == ConnectionState.disconnected) {
            // Clear stale state when the remote drops the link.
            log("BluetoothSender", "peripheral disconnected unexpectedly");
            _forgetLink();
            peripheralDisconnected();
          }
        });

    try {
      log("BluetoothSender", "connecting to peripheral $peripheral...");
      await _withTimeout(_centralManager.connect(peripheral), "connect");
      try {
        final mtu = await _withTimeout(
          _centralManager.requestMTU(peripheral, mtu: 517),
          "requestMTU",
        );
        log("BluetoothSender", "negotiated MTU: $mtu");
      } catch (e, st) {
        log("BluetoothSender", "requestMTU failed: $e\n$st");
      }
      log("BluetoothSender", "connected, discovering GATT...");
      final services = await _withTimeout(
        _centralManager.discoverGATT(peripheral),
        "discoverGATT",
      );
      log(
        "BluetoothSender",
        "discovered services: "
            "${services.map((s) => s.uuid).toList()}",
      );
      GATTService? service;
      for (final candidate in services) {
        if (candidate.uuid == serviceUuid) {
          service = candidate;
          break;
        }
      }

      GATTCharacteristic? requestCharacteristic;
      GATTCharacteristic? responseCharacteristic;
      for (final characteristic in service?.characteristics ?? const []) {
        if (characteristic.uuid == _bleRequestCharacteristicUuid) {
          requestCharacteristic = characteristic;
        } else if (characteristic.uuid == _bleResponseCharacteristicUuid) {
          responseCharacteristic = characteristic;
        }
      }
      log(
        "BluetoothSender",
        "service=${service?.uuid} "
            "requestCharacteristic=${requestCharacteristic?.uuid} "
            "responseCharacteristic=${responseCharacteristic?.uuid}",
      );
      if (requestCharacteristic == null || responseCharacteristic == null) {
        log(
          "BluetoothSender",
          "connect failed: missing expected characteristics",
        );
        _forgetLink();
        try {
          await _withTimeout(
            _centralManager.disconnect(peripheral),
            "disconnect (missing characteristics)",
          );
        } catch (e, st) {
          log(
            "BluetoothSender",
            "disconnect after missing characteristics failed: $e\n$st",
          );
        }
        return false;
      }

      await _withTimeout(
        _centralManager.setCharacteristicNotifyState(
          peripheral,
          responseCharacteristic,
          state: true,
        ),
        "setCharacteristicNotifyState",
      );
      log("BluetoothSender", "notify state enabled on response characteristic");
      _notifySubscription = _centralManager.characteristicNotified.listen((
        event,
      ) async {
        log(
          "BluetoothSender",
          "characteristicNotified: "
              "peripheral=${event.peripheral.uuid} "
              "characteristic=${event.characteristic.uuid} value=${event.value}",
        );
        if (event.peripheral.uuid == peripheral.uuid &&
            event.characteristic.uuid == _bleResponseCharacteristicUuid) {
          await notificationHandler(event.value);
        }
      });

      _peripheral = peripheral;
      _requestCharacteristic = requestCharacteristic;
      log("BluetoothSender", "connect succeeded");
      return true;
    } catch (e, st) {
      log("BluetoothSender", "connect failed: $e\n$st");
      _forgetLink();
      try {
        await _withTimeout(
          _centralManager.disconnect(peripheral),
          "disconnect (connect failed)",
        );
      } catch (e, st) {
        log(
          "BluetoothSender",
          "disconnect after failed connect failed: $e\n$st",
        );
      }
      rethrow;
    }
  }

  void _forgetLink() {
    _notifySubscription?.cancel();
    _notifySubscription = null;
    _connectionStateSubscription?.cancel();
    _connectionStateSubscription = null;
    _peripheral = null;
    _requestCharacteristic = null;
  }

  @override
  Future<void> disconnect() async {
    log("BluetoothSender", "disconnect");
    final peripheral = _peripheral;
    _forgetLink();
    if (peripheral != null) {
      try {
        await _withTimeout(
          _centralManager.disconnect(peripheral),
          "disconnect",
        );
      } catch (e, st) {
        log("BluetoothSender", "disconnect: native disconnect failed: $e\n$st");
      }
    }
  }

  @override
  Future<bool> isConnected() async => _peripheral != null;

  @override
  Future<void> send(Uint8List data) async {
    log("BluetoothSender", "send: ${data.length} bytes: $data");
    final peripheral = _peripheral;
    final characteristic = _requestCharacteristic;
    if (peripheral == null || characteristic == null) {
      throw StateError("BluetoothSender is not connected to a peripheral.");
    }
    await _withTimeout(
      _centralManager.writeCharacteristic(
        peripheral,
        characteristic,
        value: data,
        type: GATTCharacteristicWriteType.withResponse,
      ),
      "writeCharacteristic",
    );
    log("BluetoothSender", "send complete");
  }

  @override
  Future<void> dispose() async {
    if (disposeAlreadyRan) {
      log("BluetoothSender", "dispose: already disposed, skipping");
      return;
    }
    log("BluetoothSender", "dispose");
    await disconnect();
    await super.dispose();
  }
}

final class BluetoothReceiver extends BluetoothReceiverState with _DisposeOnce {
  final PeripheralManager _peripheralManager = PeripheralManager();
  StreamSubscription<GATTCharacteristicWriteRequestedEventArgs>?
  _writeSubscription;
  StreamSubscription<CentralConnectionStateChangedEventArgs>?
  _connectionStateSubscription;

  /// `BluetoothGattServer.addService` returns false (surfacing as a bare
  /// IllegalStateException) when the plugin's GATT server was closed or never
  /// registered, e.g. after the plugin re-initialized. The plugin only reopens
  /// the server on Bluetooth state changes, so reopen it here on failure.
  Future<void> _addServiceWithRetry(GATTService service) async {
    const maxAttempts = 4;
    final hostApi = PeripheralManagerHostApi();
    for (var attempt = 1; ; attempt++) {
      try {
        await _withTimeout(
          _peripheralManager.removeAllServices(),
          "removeAllServices",
        );
        await _withTimeout(
          _peripheralManager.addService(service),
          "addService",
        );
        return;
      } on PlatformException catch (e) {
        if (attempt == maxAttempts || !Platform.isAndroid) rethrow;
        log(
          "BluetoothReceiver",
          "addService attempt $attempt/$maxAttempts failed: ${e.code}, "
              "reopening GATT server",
        );
        try {
          await hostApi.closeGATTServer();
        } on PlatformException catch (_) {}
        await hostApi.openGATTServer();
        // Server registration completes asynchronously on the native side.
        await Future<void>.delayed(Duration(milliseconds: 300 * attempt));
      }
    }
  }

  @override
  Future<void> start() async {
    log("BluetoothReceiver", "start: data(sessionId)=$data");
    if (!await _ensureBluetoothReady(_peripheralManager)) {
      log("BluetoothReceiver", "Bluetooth peripheral not ready, aborting");
      throw StateError("Bluetooth peripheral is not available.");
    }

    final serviceUuid = UUID.fromString(data!);
    log("BluetoothReceiver", "serviceUuid=$serviceUuid");
    final requestCharacteristic = GATTCharacteristic.mutable(
      uuid: _bleRequestCharacteristicUuid,
      properties: [
        GATTCharacteristicProperty.write,
        GATTCharacteristicProperty.writeWithoutResponse,
      ],
      permissions: [GATTCharacteristicPermission.write],
      descriptors: [],
    );
    final responseCharacteristic = GATTCharacteristic.mutable(
      uuid: _bleResponseCharacteristicUuid,
      properties: [GATTCharacteristicProperty.notify],
      permissions: [GATTCharacteristicPermission.read],
      descriptors: [],
    );

    await _addServiceWithRetry(
      GATTService(
        uuid: serviceUuid,
        isPrimary: true,
        includedServices: [],
        characteristics: [requestCharacteristic, responseCharacteristic],
      ),
    );
    log("BluetoothReceiver", "service added");

    _connectionStateSubscription = _peripheralManager.connectionStateChanged
        .listen((event) {
          log(
            "BluetoothReceiver",
            "connectionStateChanged: "
                "central=${event.central.uuid} state=${event.state}",
          );
          if (event.state == ConnectionState.disconnected) {
            centralDisconnected(central: event.central.uuid);
          }
        });

    _writeSubscription = _peripheralManager.characteristicWriteRequested.listen(
      (event) async {
        log(
          "BluetoothReceiver",
          "characteristicWriteRequested: "
              "characteristic=${event.characteristic.uuid} "
              "value=${event.request.value}",
        );
        if (event.characteristic.uuid != requestCharacteristic.uuid) {
          log(
            "BluetoothReceiver",
            "ignoring write for unrelated characteristic",
          );
          return;
        }
        await _withTimeout(
          _peripheralManager.respondWriteRequest(event.request),
          "respondWriteRequest",
        );
        log("BluetoothReceiver", "responded to write request, dispatching...");
        await readRequestHandler(
          event.request.value,
          central: event.central.uuid,
          (response) {
            log("BluetoothReceiver", "notifying response: $response");
            return _withTimeout(
              _peripheralManager.notifyCharacteristic(
                event.central,
                responseCharacteristic,
                value: response,
              ),
              "notifyCharacteristic",
            );
          },
        );
      },
    );

    log("BluetoothReceiver", "starting advertising...");
    await _withTimeout(
      _peripheralManager.startAdvertising(
        Advertisement(serviceUUIDs: [serviceUuid]),
      ),
      "startAdvertising",
    );
    log("BluetoothReceiver", "advertising started, start complete");
  }

  @override
  Future<void> dispose() async {
    if (disposeAlreadyRan) {
      log("BluetoothReceiver", "dispose: already disposed, skipping");
      return;
    }
    log("BluetoothReceiver", "dispose");
    try {
      await _withTimeout(
        _peripheralManager.stopAdvertising(),
        "stopAdvertising",
      );
    } catch (e, st) {
      log("BluetoothReceiver", "dispose: stopAdvertising failed: $e\n$st");
    }
    await _writeSubscription?.cancel();
    _writeSubscription = null;
    await _connectionStateSubscription?.cancel();
    _connectionStateSubscription = null;
    try {
      await _withTimeout(
        _peripheralManager.removeAllServices(),
        "removeAllServices",
      );
    } catch (e, st) {
      log("BluetoothReceiver", "dispose: removeAllServices failed: $e\n$st");
    }
    await super.dispose();
  }
}

void log(String domain, String message) {
  if (kDebugMode) {
    if (message.isEmpty) return;
    debugPrint("[$domain] $message");
  }
}
