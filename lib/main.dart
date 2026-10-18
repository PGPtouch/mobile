import 'package:hyphenatorx/hyphenatorx.dart';
import 'package:material_helper/material_helper.dart';
import 'package:material_graphics/material_graphics.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/components/add_contact_flow.dart';
import 'package:mobile/components/add_identity_flow.dart';
import 'package:mobile/components/step_by_step_guide_dialog.dart';
import 'package:mobile/database/contact_store.dart';
import 'package:mobile/database/key_store.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/screens/screen_identities.dart';
import 'package:mobile/screens/settings.dart';
import 'package:shared/shared.dart';

import 'components/protocol_manager_builder.dart';
import 'components/protocol_permission_builder.dart';
import 'screens/screen_contacts.dart';
import 'screens/screen_run.dart';
import 'database/key_store.dart' as key_store;

Hyphenator? hyphenator;
String? hyphenatorLanguage;

String hyphenate(String text) {
  if (hyphenator == null) return text;
  return hyphenator!.hyphenateText(text);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Preferences.init();
  materialAppsFallbackColor = Colors.teal;
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) => ThemedMaterialApp(
    title: null,
    onGenerateTitle: (context) {
      final lang = Localizations.localeOf(context).languageCode;
      final resolvedLang = switch (lang) {
        "en" => "en_us",
        "de" => "de_1996",
        _ => Hyphenator.languageAbbr().contains(lang) ? lang : null,
      };
      if (resolvedLang != null && resolvedLang != hyphenatorLanguage) {
        Hyphenator.loadAsyncByAbbr(resolvedLang).then((value) {
          hyphenatorLanguage = resolvedLang;
          hyphenator = value;
        });
      }

      return AppLocalizations.of(context).appTitle;
    },
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

  int? _selectedKey;
  String? _selectedKeyUserIdDisplay;
  String? _selectedKeyFingerprint;

  @override
  void initState() {
    super.initState();
    KeyStoreHandler.instance.addListener(onUpdate);
    _pageController = PageController(initialPage: 1);
    _navigationBlockingController = AnimationController(
      vsync: this,
      duration: ExpressiveCurves.expressiveEffects.slowDuration,
    );

    _selectedKey = prefs!.getInt("selectedKey");
    _selectedKeyUserIdDisplay = prefs!.getString("selectedKeyUserId");
  }

  @override
  void dispose() {
    KeyStoreHandler.instance.removeListener(onUpdate);
    super.dispose();
  }

  void onUpdate() {
    if (mounted) setState(() {});
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
          final contactMode = protocol.displayState?.lastEvent?.contactMode;
          final result = protocol.displayState?.lastEvent?.result;

          final contactsBody = ScreenContacts();
          final runBody = ScreenRun(
            permissions: permissions,
            protocol: protocol,
            selectedKey: _selectedKey,
            selectedKeyUserIdDisplay: _selectedKeyUserIdDisplay,
            selectedKeyFingerprint: _selectedKeyFingerprint,
          );
          final identitiesBody = ScreenIdentities(
            onIdentitySelected: (id, display, fingerprint) {
              _selectedKey = id;
              _selectedKeyUserIdDisplay = display;
              _selectedKeyFingerprint = fingerprint;
              prefs!.setInt("selectedKey", id);
              prefs!.setString("selectedKeyUserId", display);
              prefs!.setString("selectedKeyFingerprint", fingerprint);

              _currentPage = 1;
              if (mounted) setState(() {});
              _pageController.animateToPage(
                _currentPage,
                duration: ExpressiveCurves.expressiveSpatial.normalDuration,
                curve: ExpressiveCurves.expressiveSpatial.normal,
              );
            },
          );

          final body = TweenAnimationBuilder<ColorScheme>(
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
            duration: ExpressiveCurves.expressiveSpatial.normalDuration,
            curve: ExpressiveCurves.expressiveSpatial.normal,
            builder: (_, colorScheme, _) => Scaffold(
              backgroundColor: _currentPage == 1
                  ? colorScheme.surface
                  : ColorScheme.of(context).surface,
              appBar: AppBar(
                forceMaterialTransparency: true,
                automaticallyImplyLeading: false,
                title: AnimatedSwitcher(
                  duration: ExpressiveCurves.expressiveSpatial.normalDuration,
                  switchInCurve: ExpressiveCurves.expressiveSpatial.normal,
                  switchOutCurve:
                      ExpressiveCurves.expressiveSpatial.normal.flipped,
                  layoutBuilder: (currentChild, previousChildren) => SizedBox(
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
                    onPressed: () async {
                      if (_navigationBlocked) return;
                      final appLocalizations = AppLocalizations.of(context);
                      final result = await KeyStoreHandler.instance.unlock(
                        appLocalizations,
                      );
                      if (result == UnlockResult.deviceReauthRequired) {
                        showKeyStoreReauthRequiredDialog(context);
                      }
                    },
                    tooltip: KeyStoreHandler.instance.isLocked
                        ? AppLocalizations.of(context).appBarUnlockTooltip
                        : AppLocalizations.of(context).appBarUnlockedTooltip,
                    icon: KeyStoreHandler.instance.isLocked
                        ? Icon(Icons.lock)
                        : Icon(Icons.lock_open),
                  ),
                  IconButton(
                    onPressed: () {
                      if (_navigationBlocked) return;
                      settings(context);
                    },
                    tooltip: AppLocalizations.of(context).appBarSettingsTooltip,
                    icon: Icon(Icons.tune),
                  ),
                ],
              ),
              floatingActionButton:
                  _currentPage != 1 &&
                      (_currentPage != 2 || !KeyStoreHandler.instance.isLocked)
                  ? FloatingActionButton(
                      onPressed: () async {
                        if (_currentPage == 1 || _navigationBlocked) return;
                        switch (_currentPage) {
                          case 0:
                            final keys = await startAddContactFlow(context);
                            if (keys == null) return;
                            for (final keyRaw in keys) {
                              final key = publicKeyFromBytes(keyRaw);
                              if (await (contactStore.select(
                                    contactStore.contacts,
                                  )..where(
                                    (c) =>
                                        c.fingerprint.equals(key.fingerprint),
                                  ))
                                  .get()
                                  .then((value) => value.isNotEmpty)) {
                                continue;
                              }
                              contactStore.insertContact(
                                ContactsCompanion.insert(
                                  fingerprint: key.fingerprint,
                                  data: key.packetList.encode(),
                                ),
                                key.users.map((user) => user.userID).toList(),
                              );
                            }
                          case 2:
                            final keys = await startAddIdentityFlow(context);
                            if (keys == null) return;
                            final keyStore = KeyStoreHandler.instance.keyStore;
                            if (keyStore == null) return;
                            for (final (publicKey, privateKey, passphrase)
                                in keys) {
                              final key = publicKeyFromBytes(publicKey);
                              if (await (keyStore.select(keyStore.keys)..where(
                                    (k) =>
                                        k.fingerprint.equals(key.fingerprint),
                                  ))
                                  .get()
                                  .then((value) => value.isNotEmpty)) {
                                continue;
                              }
                              await keyStore.insertKey(
                                KeysCompanion.insert(
                                  fingerprint: key.fingerprint,
                                  publicData: publicKey,
                                  privateData: privateKey,
                                ),
                                key.users.map((user) => user.userID).toList(),
                              );
                              if (passphrase != null) {
                                await KeyStoreHandler.instance.setKeyPassphrase(
                                  key.fingerprint,
                                  passphrase,
                                );
                              }
                            }
                        }
                      },
                      tooltip: AppLocalizations.of(context).contactsAddTooltip,
                      child: Icon(Icons.add),
                    )
                  : null,
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
                position: Tween<Offset>(begin: Offset(0, 0), end: Offset(0, 1))
                    .animate(
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
                          duration:
                              ExpressiveCurves.expressiveSpatial.normalDuration,
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
                    data: Theme.of(context).copyWith(colorScheme: colorScheme),
                    child: LayoutBuilder(
                      builder: (context, constraints) => Stack(
                        children: [
                          // ...?protocol.nfcAntennaLocations?.map(
                          //   (l) => Align(
                          //     alignment: Alignment(
                          //       l.x * 2 - 1,
                          //       l.y * 2 - 1,
                          //     ),
                          //     child: DecoratedBox(
                          //       decoration: MaterialShapes.cookie6Sided
                          //           .toShapeDecoration(
                          //             color: colorScheme.secondaryContainer,
                          //           ),
                          //       child: SizedBox.square(
                          //         dimension: 64,
                          //         child: Center(
                          //           child: Icon(
                          //             Icons.nfc,
                          //             color:
                          //                 colorScheme.onSecondaryContainer,
                          //           ),
                          //         ),
                          //       ),
                          //     ),
                          //   ),
                          // ),
                          SizedBox.expand(child: runBody),
                        ],
                      ),
                    ),
                  ),
                  identitiesBody,
                ],
              ),
            ),
          );
          return PopScope(
            canPop: protocol.displayState == null,
            onPopInvokedWithResult: (didPop, _) async {
              if (didPop) return;
              await protocol.stop();
            },
            child: body,
          );
        },
      ),
    );
  }
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
