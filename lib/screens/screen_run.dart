import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:icon_craft/icon_craft.dart';
import 'package:material_graphics/material_graphics.dart';
import 'package:material_helper/material_helper.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared/shared.dart';

import '../components/identity_tile.dart';
import '../components/protocol_manager_builder.dart';
import '../components/protocol_permission_builder.dart';
import '../database/key_store.dart' as key_store;
import '../l10n/app_localizations.dart';
import '../main.dart';

class ScreenRun extends StatefulWidget {
  final ProtocolManagerState protocol;
  final ProtocolPermissionState permissions;

  final int? selectedKey;
  final String? selectedKeyUserIdDisplay;
  final DateTime? selectedKeyExpiration;

  final VoidCallback onSelectIdentityRequest;
  final VoidCallback onSelectedIdentityDetailsRequest;

  const ScreenRun({
    super.key,
    required this.protocol,
    required this.permissions,
    required this.selectedKey,
    required this.selectedKeyUserIdDisplay,
    required this.selectedKeyExpiration,
    required this.onSelectIdentityRequest,
    required this.onSelectedIdentityDetailsRequest,
  });

  @override
  State<ScreenRun> createState() => _ScreenRunState();
}

class _ScreenRunState extends State<ScreenRun> {
  final _startButtonState = GlobalKey<_ScreenRunStateButtonState>();

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final size = MediaQuery.sizeOf(context);

    final displayState = widget.protocol.displayState?.lastEvent;
    final contactMode = displayState?.contactMode;
    final result = displayState?.result;

    if (_startButtonState.currentState != null) {
      if (contactMode != null) {
        switch (contactMode.value) {
          case .initializing:
            _startButtonState.currentState!
              ..enableJittering = false
              ..enableSecondTick = true
              ..enableToNextFull = false
              ..errorDisplay = false
              ..resultDisplay = false
              ..warningDisplay = false;
          case .tapOther:
            _startButtonState.currentState!
              ..enableJittering = false
              ..enableSecondTick = false
              ..enableToNextFull = true
              ..errorDisplay = false
              ..resultDisplay = false
              ..warningDisplay = false;
          case .holdOther:
            _startButtonState.currentState!
              ..enableJittering = true
              ..enableSecondTick = false
              ..enableToNextFull = false
              ..errorDisplay = false
              ..resultDisplay = false
              ..warningDisplay = false;
          case .done:
            final success = result?.value?.mode == .success;
            _startButtonState.currentState!
              ..enableJittering = false
              ..enableSecondTick = false
              ..enableToNextFull = true
              ..errorDisplay = !success
              ..resultDisplay = success
              ..warningDisplay = false;
        }
      } else {
        _startButtonState.currentState!
          ..enableJittering = false
          ..enableSecondTick = false
          ..enableToNextFull = false
          ..errorDisplay = false
          ..resultDisplay = false
          ..warningDisplay = false;
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        ScreenRunStateButton(
          key: _startButtonState,
          onTap:
              widget.permissions.isNfcAvailable == false ||
                  widget.permissions.isBluetoothAvailable == false
              ? null
              : widget.permissions.canRequestPermissions
              ? widget.permissions.requestPermissions
              : widget.permissions.isNfcEnabled == false
              ? widget.permissions.openNfcSettings
              : widget.permissions.isBluetoothEnabled == false
              ? widget.permissions.openBluetoothSettings
              : widget.selectedKey == null
              ? widget.onSelectIdentityRequest
              : (widget.permissions.areRadiosEnabled &&
                        widget.permissions.arePermissionsGranted &&
                        contactMode == null
                    ? _start
                    : null),
          builder: (context, foregroundColor, backgroundColor) {
            final textTheme = TextTheme.of(context);

            Widget infoTile(String keyPrefix, Object icon, String text) =>
                Center(
                  key: ValueKey("screenRunStateButtonMode$keyPrefix"),
                  child: Padding(
                    padding: const EdgeInsets.all(64),
                    child: Column(
                      mainAxisSize: .min,
                      crossAxisAlignment: .center,
                      children: [
                        icon is IconData
                            ? Icon(icon, size: 32, color: foregroundColor)
                            : icon as Widget,
                        SizedBox(height: 8),
                        Text(
                          hyphenate(text),
                          textAlign: .justify,
                          style: textTheme.bodyLarge!.copyWith(
                            color: foregroundColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );

            if (widget.permissions.isNfcAvailable == false) {
              return infoTile(
                "NfcUnavailable",
                IconCraft(
                  Icon(Icons.nfc, size: 32, color: foregroundColor),
                  Icon(Icons.close, size: 32, color: foregroundColor),
                  alignment: Alignment.bottomRight + Alignment(0.5, 0.5),
                  decoration: IconDecoration(
                    border: IconBorder(width: 8, color: backgroundColor),
                  ),
                ),
                appLocalizations.nfcUnavailableHint,
              );
            } else if (widget.permissions.isBluetoothAvailable == false) {
              return infoTile(
                "BluetoothUnavailable",
                Icons.bluetooth_disabled,
                appLocalizations.bluetoothUnavailableHint,
              );
            }

            if (widget.permissions.canRequestPermissions) {
              return infoTile(
                "Permissions",
                Icons.security,
                appLocalizations.permissionsRequiredHint,
              );
            } else if (widget.permissions.isNfcEnabled == false) {
              return infoTile(
                "Nfc",
                Icons.nfc,
                appLocalizations.nfcDisabledHint,
              );
            } else if (widget.permissions.isBluetoothEnabled == false) {
              return infoTile(
                "Bluetooth",
                Icons.bluetooth,
                appLocalizations.bluetoothDisabledHint,
              );
            }

            if (widget.selectedKey == null) {
              return Center(
                key: ValueKey("screenRunStateButtonModeSelectedKeyNull"),
                child: Icon(
                  Icons.south_east_rounded,
                  size: 64,
                  color: foregroundColor.withValues(alpha: 0.25),
                ),
              );
            }

            if (contactMode?.value case .initializing || .holdOther) {
              return SizedBox(
                key: ValueKey(
                  "screenRunStateButtonMode${contactMode!.value == .initializing ? "Initializing" : "HoldOther"}",
                ),
              );
            } else if (contactMode?.value == .tapOther) {
              return ScreenRunStateButtonTapOtherAnimation(
                key: ValueKey("screenRunStateButtonModeTapOther"),
              );
            }

            if (contactMode?.value == .done) {
              // TODO: replace placeholder done screen
              final doneStyle = textTheme.bodyMedium!.copyWith(
                color: foregroundColor,
              );
              return Column(
                mainAxisSize: .max,
                mainAxisAlignment: .center,
                crossAxisAlignment: .center,
                children: [
                  if (result?.value?.additionalInfo != null &&
                      result?.value?.mode == .success)
                    Column(
                      mainAxisSize: .min,
                      children: [
                        Text(
                          result?.value?.additionalInfo.userIds.join(", "),
                          style: doneStyle,
                        ),
                        Text(
                          formatFingerprint(
                            result?.value?.additionalInfo.fingerprint,
                          ),
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.googleSansCode
                              .copyWith(color: foregroundColor),
                        ),
                      ],
                    ),
                  if (result?.value?.mode == .error)
                    Text(
                      appLocalizations.runError(
                        result?.value?.errorMode?.toString() ??
                            appLocalizations.unknown,
                      ),
                      style: doneStyle,
                    ),
                  if (result?.value?.mode == .failure)
                    Text(
                      appLocalizations.runFailureReason(
                        result?.value?.failureMode?.toString() ??
                            appLocalizations.unknown,
                      ),
                      style: doneStyle,
                    ),
                  if (result?.value?.additionalInfo != null &&
                      result?.value?.mode == .failure)
                    Text(
                      appLocalizations.runAdditionalInfo(
                        result?.value?.additionalInfo?.toString() ??
                            appLocalizations.noDetails,
                      ),
                      style: doneStyle,
                    ),
                ],
              );
            }

            return Center(
              key: ValueKey("screenRunStateButtonModeIdle"),
              child: Text(
                appLocalizations.goButton,
                style: textTheme.displaySmall!
                    .copyWith(
                      color: foregroundColor,
                      decoration: .underline,
                      decorationColor: foregroundColor,
                      fontVariations: [
                        FontVariation.width(115),
                        FontVariation("GRAD", -1000),
                        FontVariation.slant(-5),
                      ],
                    )
                    .googleSansFlexExt(weight: 700, roundness: 100),
              ),
            );
          },
        ),
        ScreenRunKeyInfoTile(
          userIds: widget.selectedKeyUserIdDisplay != null
              ? widget.selectedKeyUserIdDisplay!
                    .split(",")
                    .map(UserId.tryParse)
                    .whereType<UserId>()
                    .toList()
              : [],
          onTap: contactMode == null
              ? () {
                  if (widget.selectedKeyUserIdDisplay == null) {
                    widget.onSelectIdentityRequest();
                  } else {
                    widget.onSelectedIdentityDetailsRequest();
                  }
                }
              : null,
        ),
        TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: contactMode != null ? 1 : 0),
          duration: ExpressiveCurves.expressiveEffects.normalDuration,
          curve: ExpressiveCurves.expressiveEffects.normal,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, value * -2),
              child: child,
            ),
          ),
          child: Row(
            mainAxisAlignment: .center,
            children: [
              Transform.translate(
                offset: Offset(2, 0),
                child: IconButton.outlined(
                  onPressed: widget.protocol.stop,
                  tooltip: contactMode != null && contactMode.value != .done
                      ? appLocalizations.stopRun
                      : appLocalizations.discardRun,
                  icon: Icon(
                    contactMode?.value != .done ? Icons.close : Icons.clear_all,
                  ),
                  style: IconButton.styleFrom(
                    minimumSize: Size.square(34),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(-2, 0),
                child: OutlinedButton.icon(
                  onPressed: contactMode?.value == .done ? _start : null,
                  icon: Icon(Icons.chevron_right),
                  label: Text(appLocalizations.newRun),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.square(34),
                    padding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: size.height / 12),
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

class ScreenRunStateButton extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget Function(
    BuildContext context,
    Color foregroundColor,
    Color backgroundColor,
  )
  builder;

  const new({super.key, required this.onTap, required this.builder});

  @override
  State<ScreenRunStateButton> createState() => _ScreenRunStateButtonState();
}

class _ScreenRunStateButtonState extends State<ScreenRunStateButton> {
  late final Timer _timeBase;
  DateTime? _timeBaseLast;
  int? _timeJitterLastDirection;
  bool _didNextFull = false;

  final _validStopValues = [
    1 / 12,
    2 / 12,
    3 / 12,
    4 / 12,
    5 / 12,
    6 / 12,
    7 / 12,
    8 / 12,
    9 / 12,
    10 / 12,
    11 / 12,
    12 / 12,
  ];

  var enableToNextFull = false;
  var enableJittering = false;
  var enableSecondTick = false;
  var _turns = 0.0;

  var errorDisplay = false;
  var warningDisplay = false;
  var resultDisplay = false;

  @override
  void initState() {
    super.initState();
    _timeBase = Timer.periodic(Duration(milliseconds: 10), (timer) {
      final now = DateTime.now();

      if (!enableToNextFull && _didNextFull) {
        _didNextFull = false;
        if (mounted) setState(() {});
      }
      if (!enableJittering && _timeJitterLastDirection != null) {
        _turns += _timeJitterLastDirection! / 96;
        _timeJitterLastDirection = null;
        if (mounted) setState(() {});
      }

      if (enableToNextFull) {
        if (_didNextFull) return;
        _didNextFull = true;
        _turns = _turns.floorToDouble();
        if (mounted) setState(() {});
        return;
      }

      if (enableJittering) {
        if (_timeBaseLast == null ||
            now.difference(_timeBaseLast!).inMilliseconds > 100) {
          _timeBaseLast = now;
          _timeJitterLastDirection ??= Random().nextBool() ? 1 : -1;
          _turns += _timeJitterLastDirection! / 96;
          _timeJitterLastDirection = -_timeJitterLastDirection!;
          if (mounted) setState(() {});
        }
        return;
      }

      final asInteger = _turns.floor();
      final rest = _turns - asInteger;

      final closestStopValue = _validStopValues.reduce(
        (a, b) => (rest - a).abs() < (rest - b).abs() ? a : b,
      );
      if (rest != closestStopValue) {
        _turns = asInteger + closestStopValue;
        if (mounted) setState(() {});
      }

      if (enableSecondTick) {
        if (_timeBaseLast == null ||
            now.difference(_timeBaseLast!).inMilliseconds >= 500) {
          _timeBaseLast = now;
          _turns += 1 / 12;
          if (mounted) setState(() {});
        }
        return;
      }
    });
  }

  @override
  void dispose() {
    _timeBase.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);

    final contentColor = resultDisplay
        ? colorScheme.onPrimaryContainer
        : colorScheme.onPrimary;
    final content = TweenAnimationBuilder(
      tween: ColorTween(begin: contentColor, end: contentColor),
      duration: ExpressiveCurves.expressiveEffects.normalDuration,
      curve: ExpressiveCurves.expressiveEffects.normal,
      builder: (context, color, _) => AnimatedSwitcher(
        duration: ExpressiveCurves.expressiveEffects.normalDuration,
        switchInCurve: ExpressiveCurves.expressiveEffects.normal,
        switchOutCurve: ExpressiveCurves.expressiveEffects.normal.flipped,
        child: widget.builder(
          context,
          color!,
          errorDisplay
              ? colorScheme.error
              : warningDisplay
              ? Colors.deepOrange.harmonizeWith(colorScheme.primary)
              : resultDisplay
              ? colorScheme.primaryContainer
              : colorScheme.primary,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AspectRatio(
        aspectRatio: 1 / 1,
        child: TweenAnimationBuilder(
          tween: Tween(begin: _turns, end: _turns),
          duration: ExpressiveCurves.expressiveEffects.normalDuration,
          curve: ExpressiveCurves.expressiveEffects.normal,
          builder: (_, turns, child) => TweenAnimationBuilder(
            tween: ShapeBorderTween(
              begin: MaterialShapeBorder(shape: MaterialShapes.cookie12Sided),
              end: MaterialShapeBorder(
                shape: errorDisplay
                    ? MaterialShapes.pentagon
                    : resultDisplay || warningDisplay
                    ? MaterialShapes.square
                    : MaterialShapes.cookie12Sided,
                side: resultDisplay
                    ? BorderSide(color: colorScheme.primary)
                    : BorderSide.none,
              ),
            ),
            duration: ExpressiveCurves.expressiveEffects.normalDuration,
            curve: ExpressiveCurves.expressiveEffects.normal,
            builder: (_, shape, _) => TweenAnimationBuilder(
              tween: ColorTween(
                begin: colorScheme.primary,
                end: errorDisplay
                    ? colorScheme.error
                    : warningDisplay
                    ? Colors.deepOrange.harmonizeWith(colorScheme.primary)
                    : resultDisplay
                    ? colorScheme.primaryContainer
                    : colorScheme.primary,
              ),
              duration: ExpressiveCurves.expressiveEffects.normalDuration,
              curve: ExpressiveCurves.expressiveEffects.normal,
              builder: (_, color, _) => Stack(
                alignment: Alignment.center,
                children: [
                  RotationTransition(
                    turns: AlwaysStoppedAnimation(turns),
                    child: DecoratedBox(
                      decoration: ShapeDecoration(color: color, shape: shape!),
                      child: SizedBox.expand(),
                    ),
                  ),
                  child!,
                ],
              ),
            ),
          ),
          child: GestureDetector(
            onTap: widget.onTap,
            behavior: .opaque,
            child: content,
          ),
        ),
      ),
    );
  }
}

class ScreenRunStateButtonTapOtherAnimation extends StatefulWidget {
  const new({super.key});

  @override
  State<ScreenRunStateButtonTapOtherAnimation> createState() =>
      _ScreenRunStateButtonTapOtherAnimationState();
}

class _ScreenRunStateButtonTapOtherAnimationState
    extends State<ScreenRunStateButtonTapOtherAnimation>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: Duration(seconds: 5),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (_, Widget? child) {
      final colorMapper =
          _ScreenRunStateButtonTapOtherAnimationSvgColorMapper.of(context);
      final opacity = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 0,
            end: 1,
          ).chain(CurveTween(curve: ExpressiveCurves.expressiveEffects.slow)),
          weight: 1.25,
        ),
        TweenSequenceItem(tween: ConstantTween(1), weight: 5 - (1 + .3 + .2)),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 1,
            end: 0,
          ).chain(CurveTween(curve: ExpressiveCurves.expressiveEffects.slow)),
          weight: 0.3,
        ),
        TweenSequenceItem(tween: ConstantTween(0), weight: 0.2),
      ]).evaluate(_controller);
      final value = TweenSequence<double>([
        TweenSequenceItem(tween: ConstantTween(1), weight: .6),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 1,
            end: 0,
          ).chain(CurveTween(curve: ExpressiveCurves.expressiveSpatial.slow)),
          weight: .65,
        ),
        TweenSequenceItem(tween: ConstantTween(0), weight: 5 - (.6 + .65)),
      ]).evaluate(_controller);
      return Padding(
        padding: const EdgeInsets.all(96),
        child: Opacity(
          opacity: opacity,
          child: Stack(
            children: [
              Transform.rotate(
                angle: value * (pi / 8),
                child: Transform.translate(
                  offset: Offset(value * 58 + 6, value * -32),
                  child: SvgPicture.asset(
                    "assets/touchAnimation/Phone2.svg",
                    colorMapper: colorMapper,
                  ),
                ),
              ),
              Transform.rotate(
                angle: -value * (pi / 8),
                child: Transform.translate(
                  offset: Offset(-value * 70 - 6, value * -32),
                  child: SvgPicture.asset(
                    "assets/touchAnimation/Phone1.svg",
                    colorMapper: colorMapper,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ScreenRunStateButtonTapOtherAnimationSvgColorMapper extends ColorMapper {
  final Color primary;
  final Color primaryContainer;
  const _ScreenRunStateButtonTapOtherAnimationSvgColorMapper({
    required this.primary,
    required this.primaryContainer,
  });

  factory _ScreenRunStateButtonTapOtherAnimationSvgColorMapper.of(
    BuildContext context,
  ) {
    final colorScheme = ColorScheme.of(context);
    return _ScreenRunStateButtonTapOtherAnimationSvgColorMapper(
      primary: colorScheme.primary,
      primaryContainer: colorScheme.primaryContainer,
    );
  }

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) => switch (color) {
    const Color(0xFFFF0000) => primaryContainer,
    const Color(0xFF00FF00) => primaryContainer.withValues(alpha: 0.6),
    const Color(0xFF0000FF) => primary,
    _ => color,
  };

  @override
  bool operator ==(Object other) =>
      other is _ScreenRunStateButtonTapOtherAnimationSvgColorMapper &&
      other.primary == primary &&
      other.primaryContainer == primaryContainer;

  @override
  int get hashCode => Object.hash(primary, primaryContainer);
}

class ScreenRunKeyInfoTile extends StatelessWidget {
  final List<UserId> userIds;
  final VoidCallback? onTap;

  const new({super.key, required this.userIds, required this.onTap});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder(
    tween: Tween(begin: 1.0, end: onTap != null ? 1.0 : 0.0),
    duration: ExpressiveCurves.expressiveEffects.normalDuration,
    curve: ExpressiveCurves.expressiveEffects.normal,
    builder: (_, value, _) {
      final colorScheme = ColorScheme.of(context);
      final textTheme = TextTheme.of(context);

      late final Widget avatar;
      late final Widget child;
      if (userIds.isNotEmpty) {
        final ids = userIds.map((i) {
          return (
            titleFirst: i.name ?? i.email,
            titleSecond: i.comment != null ? " (${i.comment})" : null,
            subtitle: i.name == null ? null : i.email,
          );
        });

        avatar = SizedBox.square(
          dimension: 22 * value + 26,
          child: FittedBox(
            fit: BoxFit.cover,
            child: IdentityTileAvatar(
              user: .new(userIds.first),
              backgroundColor: colorScheme.secondary,
              foregroundColor: colorScheme.onSecondary,
            ),
          ),
        );
        child = Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: ids
              .map(
                (id) => [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: id.titleFirst),
                        if (id.titleSecond != null)
                          TextSpan(
                            text: id.titleSecond,
                            style: textTheme.bodySmall!
                                .copyWith(
                                  height: 0,
                                  color: colorScheme.onSecondaryContainer,
                                  fontVariations: [
                                    FontVariation.width(110),
                                    FontVariation("GRAD", 60),
                                  ],
                                )
                                .googleSansFlexExt(roundness: 55),
                          ),
                      ],
                    ),
                    maxLines: (value + 1).round(),
                    softWrap: false,
                    overflow: .ellipsis,
                    style: textTheme.bodyLarge!
                        .copyWith(
                          height: 1,
                          color: colorScheme.onSecondaryContainer,
                          fontVariations: [
                            FontVariation.width(25 * value + 90),
                            FontVariation("GRAD", -20 * (1 - value)),
                          ],
                        )
                        .googleSansFlexExt(weight: 500, roundness: 55),
                  ),
                  if (id.subtitle != null)
                    Align(
                      alignment: .topStart,
                      heightFactor: value,
                      widthFactor: value,
                      child: FadeTransition(
                        opacity: AlwaysStoppedAnimation(value),
                        child: Padding(
                          padding: ids.length > 1
                              ? const EdgeInsetsDirectional.only(start: 8)
                              : EdgeInsets.zero,
                          child: Text(
                            id.subtitle!,
                            maxLines: 1,
                            softWrap: false,
                            overflow: .ellipsis,
                            style: textTheme.labelLarge!
                                .copyWith(
                                  height: 1.2,
                                  color: colorScheme.onSecondaryContainer,
                                  fontVariations: [FontVariation.width(95)],
                                )
                                .googleSansFlexExt(roundness: 100),
                          ),
                        ),
                      ),
                    ),
                ],
              )
              .expand((x) => x)
              .toList(),
        );
      } else {
        avatar = CircleAvatar(
          radius: 12 * value + 8,
          backgroundColor: colorScheme.secondary,
          foregroundColor: colorScheme.onSecondary,
          child: Icon(Icons.question_mark_rounded),
        );
        child = Text(
          AppLocalizations.of(context).selectIdentity,
          style: textTheme.bodyLarge!
              .copyWith(
                height: 1,
                color: colorScheme.onSecondaryContainer,
                fontVariations: [FontVariation.width(85)],
              )
              .googleSansFlexExt(weight: 450, roundness: 55),
          maxLines: 1,
          softWrap: false,
          overflow: .ellipsis,
        );
      }

      final widget = TweenAnimationBuilder(
        tween: EdgeInsetsGeometryTween(
          begin: EdgeInsetsDirectional.all(24),
          end: onTap != null
              ? EdgeInsetsDirectional.all(24)
              : (EdgeInsetsDirectional.all(4) +
                    (userIds.length != 1
                        ? EdgeInsetsDirectional.all(8)
                        : EdgeInsetsDirectional.zero) +
                    EdgeInsetsDirectional.only(end: 2)),
        ),
        duration: ExpressiveCurves.expressiveEffects.normalDuration,
        curve: ExpressiveCurves.expressiveEffects.normal,
        builder: (_, padding, _) => Padding(
          padding: padding,
          child: Row(
            mainAxisSize: .min,
            children: [
              avatar,
              SizedBox(
                width: userIds.length <= 1 ? 12 * value + 4 : 8 * value + 8,
              ),
              Flexible(child: child),
              SizeTransition(
                sizeFactor: AlwaysStoppedAnimation(value),
                alignment: .centerEnd,
                axis: .horizontal,
                child: Transform.translate(
                  offset: Offset(8, 0),
                  child: Icon(Icons.chevron_right),
                ),
              ),
            ],
          ),
        ),
      );
      final shape = RoundedSuperellipseBorder(
        side: BorderSide(color: colorScheme.secondary, width: 1),
        borderRadius: BorderRadius.circular(32),
      );
      return Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
        child: GestureDetector(
          onTap: onTap,
          child: ClipPath(
            clipper: ShapeBorderClipper(shape: shape),
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: colorScheme.secondaryContainer,
                shape: shape,
              ),
              child: widget,
            ),
          ),
        ),
      );
    },
  );
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
    if (buffer.length.isEven) {
      list.add(int.parse(buffer.toString(), radix: 16));
      buffer.clear();
    }
  }
  return Uint8List.fromList(list);
}
