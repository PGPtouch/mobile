import 'dart:async';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:dart_pg/dart_pg.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:material_helper/material_helper.dart';
import 'package:material_graphics/material_graphics.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile/generated/gitbaker.g.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:nfc_util/android.dart' as nfc_android;
import 'package:nfc_util/nfc_util.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared/shared.dart';
import 'package:open_settings_plus/open_settings_plus.dart';

import 'states.dart';

void main() {
  materialAppsFallbackColor = Colors.teal;
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) => ThemedMaterialApp(
    title: null,
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    home: MainScreen(),
    localizationsDelegates: [
      MaterialHelperLocalizations.delegate,
      AppLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    useSystemColorScheme: false,
  );
}

class MainScreen extends StatefulWidget {
  const new({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  int _pendingPageAnimations = 0;
  int _currentPage = 1;

  bool _navigationBlocked = false;
  late final AnimationController _navigationBlockingController;

  bool _isGeneratingKeys = false;
  PrivateKey? _keyPair;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1);
    _navigationBlockingController = AnimationController(
      vsync: this,
      duration: ExpressiveCurves.expressiveEffects.slowDuration,
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

  @override
  Widget build(BuildContext context) {
    return ProtocolPermissionBuilder(
      builder: (permissions) => ProtocolManagerBuilder(
        onStart: () {
          _navigationBlocked = true;
          if (mounted) setState(() {});
          _navigationBlockingController.forward();
          _pageController.animateToPage(
            1,
            duration: ExpressiveCurves.expressiveSpatial.normalDuration,
            curve: ExpressiveCurves.expressiveSpatial.normal,
          );
        },
        onDone: () {
          _navigationBlocked = false;
          if (mounted) setState(() {});
          _navigationBlockingController.reverse();
        },
        builder: (protocol) {
          final displayState = protocol.displayState?.lastEvent;
          final contactMode = displayState?.contactMode;
          final deviceRole = displayState?.deviceRole;
          final result = displayState?.result;

          Future<void> start() async {
            if (_keyPair == null) return;
            await protocol.start(
              Uint8List.fromList(_keyPair!.publicKey.packetList.encode()),
              Uint8List.fromList(_keyPair!.packetList.encode()),
              privateKeyPassphrase: "passphrase",
            );
          }

          final contactsBody = Center(child: Text("Contacts Body"));
          final runBody = Builder(
            builder: (context) {
              final appLocalizations = AppLocalizations.of(context);
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: contactMode != null
                    ? [
                        Text(switch (contactMode.value) {
                          .initializing =>
                            appLocalizations.contactModeInitializing,
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
                            result?.value?.mode.toString() ??
                                appLocalizations.unknown,
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
                                _formatFingerprint(
                                  result?.value?.additionalInfo.fingerprint,
                                ),
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      fontFamily: "GoogleSansCode",
                                      package: "material_graphics",
                                    ),
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
                          onPressed: protocol.stop,
                          child: Text(appLocalizations.stopTransaction),
                        ),
                        OutlinedButton(
                          onPressed:
                              _keyPair == null ||
                                  contactMode.value != .done ||
                                  !permissions.areRadiosEnabled
                              ? null
                              : start,
                          child: Text(appLocalizations.restartTransaction),
                        ),
                        Text(
                          _formatFingerprint(_keyPair!.fingerprint),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontFamily: "GoogleSansCode",
                                package: "material_graphics",
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
                        if (permissions.canRequestPermissions)
                          OutlinedButton(
                            onPressed: permissions.requestPermissions,
                            child: Text(appLocalizations.grantPermissions),
                          ),
                        if (permissions.isNfcEnabled == false)
                          OutlinedButton(
                            onPressed: permissions.openNfcSettings,
                            child: Text(appLocalizations.enableNfc),
                          ),
                        if (permissions.isBluetoothEnabled == false)
                          OutlinedButton(
                            onPressed: permissions.openBluetoothSettings,
                            child: Text(appLocalizations.enableBluetooth),
                          ),
                        FilledButton(
                          onPressed:
                              _keyPair == null ||
                                  _isGeneratingKeys ||
                                  !permissions.areRadiosEnabled ||
                                  !permissions.arePermissionsGranted
                              ? null
                              : start,
                          child: Text(appLocalizations.startTransaction),
                        ),
                        if (_keyPair != null)
                          Text(
                            _formatFingerprint(_keyPair!.fingerprint),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontFamily: "GoogleSansCode",
                                  package: "material_graphics",
                                  fontSize: 10,
                                  color: ColorScheme.of(context)
                                      .onSurfaceVariant,
                                ),
                          ),
                        if (permissions.isNfcAvailable == false)
                          Text(appLocalizations.nfcNotAvailable),
                        if (permissions.isBluetoothAvailable == false)
                          Text(appLocalizations.bluetoothNotAvailable),
                      ],
              );
            },
          );
          final identitiesBody = Center(child: Text("Identities Body"));

          return TweenAnimationBuilder<ColorScheme>(
            tween: ColorSchemeTween(
              begin: ColorScheme.of(context),
              end: () {
                final color = switch (contactMode?.value) {
                  .initializing => Colors.yellow,
                  .tapOther => Colors.purple,
                  .holdOther => Colors.cyan,
                  .done =>
                    result?.value?.mode == .success
                        ? Colors.green
                        : Colors.redAccent,
                  _ => null,
                };
                final current = ColorScheme.of(context);
                if (color != null) {
                  return ColorScheme.fromSeed(
                    seedColor: color,
                    brightness: current.brightness,
                  );
                }
                return current;
              }(),
            ),
            duration: Durations.medium1,
            curve: Curves.easeInOut,
            builder: (_, colorScheme, _) => TweenAnimationBuilder<Color?>(
              tween: ColorTween(
                begin: colorScheme.surface,
                end: _currentPage == 1
                    ? colorScheme.surface
                    : ColorScheme.of(context).surface,
              ),
              duration: Durations.medium1,
              curve: Curves.easeInOut,
              builder: (_, backgroundColor, _) {
                return Scaffold(
                  backgroundColor: backgroundColor,
                  appBar: AppBar(
                    forceMaterialTransparency: true,
                    automaticallyImplyLeading: false,
                    title: AnimatedSwitcher(
                      duration:
                          ExpressiveCurves.expressiveSpatial.normalDuration,
                      switchInCurve: ExpressiveCurves.expressiveSpatial.normal,
                      switchOutCurve:
                          ExpressiveCurves.expressiveSpatial.normal.flipped,
                      layoutBuilder: (currentChild, previousChildren) =>
                          SizedBox(
                            width: double.infinity,
                            child: Stack(
                              alignment: AlignmentDirectional.centerStart,
                              children: [...previousChildren, ?currentChild],
                            ),
                          ),
                      transitionBuilder: (child, animation) =>
                          _TitleSlideTransition(
                            animation: animation,
                            curve: ExpressiveCurves.expressiveSpatial.normal,
                            child: child,
                          ),
                      child: Text(
                        key: ValueKey(_currentPage),
                        switch (_currentPage) {
                          0 => AppLocalizations.of(context).navContacts,
                          2 => AppLocalizations.of(context).navIdentities,
                          _ => AppLocalizations.of(context).appTitle,
                        },
                      ),
                    ),
                    actions: [
                      IconButton(
                        onPressed: () => showAboutScreen(
                          context,
                          referenceMaterialApps: false,
                          githubUrl: Uri.parse(
                            "https://github.com/PGPtouch/mobile",
                          ),
                          gitBakerData: GitBaker.toJson(),
                          iconUseDarkAssetFallback: true,
                        ),
                        icon: Icon(Icons.live_help_outlined),
                      ),
                    ],
                  ),
                  // extendBodyBehindAppBar: true,
                  // bottomNavigationBar:
                  //     ValueListenableBuilder<TapToShareGuardState>(
                  //       valueListenable: NfcHceGuard.instance.state,
                  //       builder: (context, guard, _) {
                  //         if (!guard.shouldWarn) return const SizedBox.shrink();
                  //         final appLocalizations = AppLocalizations.of(context);
                  //         return SafeArea(
                  //           child: ListTile(
                  //             leading: const Icon(Icons.warning_amber_rounded),
                  //             title: Text(
                  //               appLocalizations.tapToShareInterferingTitle,
                  //             ),
                  //             subtitle: Text(
                  //               appLocalizations.tapToShareInterferingMessage,
                  //             ),
                  //           ),
                  //         );
                  //       },
                  //     ),
                  bottomNavigationBar: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: Offset(0, 0),
                          end: Offset(0, 1),
                        ).animate(
                          CurvedAnimation(
                            parent: _navigationBlockingController,
                            curve: ExpressiveCurves.expressiveEffects.slow,
                            reverseCurve:
                                ExpressiveCurves.expressiveEffects.slow.flipped,
                          ),
                        ),
                    child: NavigationBar(
                      height: 64,
                      labelBehavior: .alwaysHide,
                      selectedIndex: _currentPage,
                      onDestinationSelected: (value) {
                        if (_navigationBlocked || value == _currentPage) return;
                        _currentPage = value;
                        if (mounted) setState(() {});
                        _pendingPageAnimations++;
                        _pageController
                            .animateToPage(
                              value,
                              duration: ExpressiveCurves
                                  .expressiveSpatial
                                  .normalDuration,
                              curve: ExpressiveCurves.expressiveSpatial.normal,
                            )
                            .whenComplete(() {
                              _pendingPageAnimations--;
                            });
                      },
                      destinations: [
                        NavigationDestination(
                          icon: Icon(Icons.groups_2_outlined),
                          selectedIcon: Icon(Icons.groups_2),
                          label: AppLocalizations.of(context).navContacts,
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.rocket_launch_outlined),
                          selectedIcon: Icon(Icons.rocket_launch),
                          label: AppLocalizations.of(context).navStartRun,
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.badge_outlined),
                          selectedIcon: Icon(Icons.badge),
                          label: AppLocalizations.of(context).navIdentities,
                        ),
                      ],
                    ),
                  ),
                  body: PageView(
                    controller: _pageController,
                    onPageChanged: (value) {
                      if (_pendingPageAnimations > 0) return;
                      _currentPage = value;
                      if (mounted) setState(() {});
                    },
                    physics: _navigationBlocked
                        ? NeverScrollableScrollPhysics()
                        : null,
                    children: [
                      contactsBody,
                      Theme(
                        data: Theme.of(context)
                            .copyWith(colorScheme: colorScheme),
                        child: LayoutBuilder(
                          builder: (context, constraints) => Stack(
                            children: [
                              ...?protocol.nfcAntennaLocations?.map(
                                (l) => Align(
                                  alignment: Alignment(
                                    l.x * 2 - 1,
                                    l.y * 2 - 1,
                                  ),
                                  child: DecoratedBox(
                                    decoration: MaterialShapes.cookie6Sided
                                        .toShapeDecoration(
                                          color: colorScheme.secondaryContainer,
                                        ),
                                    child: SizedBox.square(
                                      dimension: 64,
                                      child: Center(
                                        child: Icon(
                                          Icons.nfc,
                                          color:
                                              colorScheme.onSecondaryContainer,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox.expand(child: runBody),
                            ],
                          ),
                        ),
                      ),
                      identitiesBody,
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

typedef NfcAntennaLocations = List<({double x, double y})>;

class ProtocolManagerState {
  final DisplayState? displayState;
  final NfcAntennaLocations? nfcAntennaLocations;

  final Future<void> Function(
    Uint8List pgpPublicKey,
    Uint8List pgpPrivateKey, {
    String? privateKeyPassphrase,
  })
  _start;
  final Future<void> Function() _stop;
  Future<void> start(
    Uint8List pgpPublicKey,
    Uint8List pgpPrivateKey, {
    String? privateKeyPassphrase,
  }) => _start.call(
    pgpPublicKey,
    pgpPrivateKey,
    privateKeyPassphrase: privateKeyPassphrase,
  );
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

  Future<void> _startProtocolManager(
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
          if (event.contactMode.value == .done) widget.onDone?.call();
        });

    try {
      widget.onStart?.call();
      await _protocolManager!.start(
        LocalPgpProvider(pgpPublicKey, pgpPrivateKey),
        privateKeyPassphrase: privateKeyPassphrase,
      );
    } catch (e, st) {
      log("ProtocolManager", "start failed: $e\n$st");
      rethrow;
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
      case OpenSettingsPlusAndroid settings:
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
      case OpenSettingsPlusAndroid settings:
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

class ColorSchemeTween extends Tween<ColorScheme> {
  ColorSchemeTween({required super.begin, required super.end});

  @override
  ColorScheme lerp(double t) => ColorScheme.lerp(begin!, end!, t);
}

class _TitleSlideTransition extends StatefulWidget {
  const _TitleSlideTransition({
    required this.animation,
    required this.curve,
    required this.child,
  });

  final Animation<double> animation;
  final Curve curve;
  final Widget child;

  @override
  State<_TitleSlideTransition> createState() => _TitleSlideTransitionState();
}

class _TitleSlideTransitionState extends State<_TitleSlideTransition> {
  double? _exitStartTime;
  double _exitStartProgress = 1;

  Animation<double> get _clock {
    final animation = widget.animation;
    return animation is CurvedAnimation ? animation.parent : animation;
  }

  (double, double) _frame() {
    final time = _clock.value;
    if (widget.animation.status != AnimationStatus.reverse) {
      _exitStartTime = null;
      final progress = widget.curve.transform(time);
      return (-(1 - progress), progress);
    }
    if (_exitStartTime == null) {
      _exitStartTime = time.clamp(0.001, 1.0);
      _exitStartProgress = widget.curve.transform(_exitStartTime!);
    }
    final startTime = _exitStartTime!;
    final exit = widget.curve.transform((1 - time / startTime).clamp(0.0, 1.0));
    final startOffset = -(1 - _exitStartProgress);
    return (
      startOffset + (1 - startOffset) * exit,
      _exitStartProgress * (1 - exit),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.animation,
    child: widget.child,
    builder: (context, child) {
      final (offset, opacity) = _frame();
      return FractionalTranslation(
        translation: Offset(0, offset),
        child: Opacity(opacity: opacity.clamp(0.0, 1.0), child: child),
      );
    },
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

String _formatFingerprint(List<int> fingerprint) {
  final parts = fingerprint
      .map((b) => b.toRadixString(16).padLeft(2, "0").toUpperCase())
      .toList();
  return [
    parts.take((parts.length / 2).ceil()).join(" "),
    parts.skip((parts.length / 2).ceil()).join(" "),
  ].join("\n");
}
