import 'dart:async';

import 'package:dart_pg/dart_pg.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_graphics/material_graphics.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/main.dart';

const String backupCodeCharacters = "123456789ABCDEFGHIJKLMNPQRSTUVWXYZ";

final _backupVersionHeader = RegExp(
  r"^BackupVersion:\s*2\s*$",
  multiLine: true,
);

/// Whether [text] is an OpenKeychain "Backup Format v2" file: an armored
/// message carrying the `BackupVersion: 2` armor header.
bool isBackupText(String text) {
  final normalized = text
      .replaceAll("\r\n", "\n")
      .replaceAll("\r", "\n")
      .trim();
  if (!normalized.startsWith("-----BEGIN PGP MESSAGE-----")) return false;
  final headerEnd = normalized.indexOf("\n\n");
  if (headerEnd == -1) return false;
  return _backupVersionHeader.hasMatch(normalized.substring(0, headerEnd));
}

Future<Uint8List?> decryptBackup(String armored, String backupCode) => compute((
  _,
) {
  try {
    return OpenPGP.decrypt(armored, passwords: [backupCode]).literalData.binary;
  } catch (_) {
    return null;
  }
}, null);

class BackupCodeInput extends StatefulWidget {
  /// The callback on a successful submission of the passphrase.
  ///
  /// If this returns a string, it is displayed as an error message. This should
  /// remove the [BackupCodeInput] widget from view, as the widget will stay
  /// in a loading state if this returns no error.
  final FutureOr<String?> Function(String backupCode) onSubmit;

  /// The callback when the user cancels the input.
  ///
  /// This should remove the [BackupCodeInput] widget from view. See [onSubmit].
  final FutureOr<void> Function()? onCancel;

  const new({super.key, required this.onSubmit, this.onCancel});

  @override
  State<BackupCodeInput> createState() => _BackupCodeInputState();
}

class _BackupCodeInputState extends State<BackupCodeInput> {
  bool _isLoading = false;

  String? _error;
  final _errors = <int>{};

  final List<TextEditingController> _controllers = List.generate(
    24,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(24, (_) => FocusNode());
  late final List<List<TextEditingController>> _styledControllerPairs = () {
    final pairs = <List<TextEditingController>>[];
    for (var i = 0; i < _controllers.length; i += 4) {
      pairs.add(_controllers.sublist(i, i + 4));
    }
    return pairs;
  }();

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    _errors.clear();
    if (mounted) setState(() {});

    for (var controller in _controllers.asMap().entries) {
      if (controller.value.text.isEmpty ||
          controller.value.text.length != 1 ||
          !backupCodeCharacters.contains(controller.value.text)) {
        _errors.add(controller.key);
      }
    }
    if (_errors.isNotEmpty) {
      _isLoading = false;
      if (mounted) setState(() {});
      return;
    }

    final formattedInput = _controllers
        .asMap()
        .entries
        .map((e) => "${e.key % 4 == 0 && e.key != 0 ? "-" : ""}${e.value.text}")
        .join()
        .toUpperCase();
    Future.value(widget.onSubmit(formattedInput))
        .catchError((e) => e.toString())
        .then((error) {
          if (error != null) _isLoading = false;
          _error = error;
          for (var i = 0; i < _controllers.length; i++) {
            _errors.add(i);
          }
          if (mounted) setState(() {});
        });
  }

  void _cancel() => widget.onCancel?.call();

  void _focusPrevious(int index) {
    if (index <= 0) return;
    _focusNodes[index - 1].requestFocus();
  }

  void _handleChange(int currentBigIndex, int currentIndex, String value) {
    final index = currentBigIndex * 4 + currentIndex;

    void checkCompletion() {
      final code = _controllers.map((c) => c.text).join();
      if (code.length == _controllers.length) _submit();
    }

    if (value.length > 1) {
      final cleanText = value
          .toUpperCase()
          .split("")
          .where(backupCodeCharacters.contains)
          .join();

      for (int i = 0; i < _controllers.length; i++) {
        int targetIndex = index + i;
        if (targetIndex < _controllers.length && i < cleanText.length) {
          _controllers[targetIndex].text = cleanText[i];
          _focusNodes[targetIndex].requestFocus();
        }
      }
      checkCompletion();
      return;
    }

    if (value.isNotEmpty && index < _controllers.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty) {
      _focusPrevious(index);
    }
    checkCompletion();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final colorScheme = ColorScheme.of(context);
    final textTheme = TextTheme.of(context);

    final charWidth = (TextPainter(
      text: TextSpan(text: "W", style: textTheme.bodyMedium!.googleSansCode),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout()).width;

    return PopScope(
      canPop: !_isLoading,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _cancel();
      },
      child: Padding(
        padding:
            MediaQuery.viewInsetsOf(context) +
            MediaQuery.paddingOf(context) +
            const EdgeInsets.all(16).copyWith(top: 14, bottom: 8),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .center,
          children: [
            Text(
              hyphenate(appLocalizations.backupCodeInputPrompt),
              textAlign: .justify,
            ),
            SizedBox(height: 4),
            AnimatedSize(
              curve: ExpressiveCurves.expressiveEffects.slow,
              duration: ExpressiveCurves.expressiveEffects.slowDuration,
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              child: Column(
                mainAxisSize: .min,
                crossAxisAlignment: .start,
                children: _error != null
                    ? [
                        SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: Builder(
                            builder: (context) => Text(
                              _error!,
                              style: DefaultTextStyle.of(context).style
                                  .copyWith(color: colorScheme.error),
                            ),
                          ),
                        ),
                      ]
                    : [],
              ),
            ),
            Wrap(
              children: _styledControllerPairs
                  .asMap()
                  .entries
                  .map(
                    (controllers) => Row(
                      mainAxisSize: .min,
                      children: [
                        ...controllers.value.asMap().entries.map((controller) {
                          final fieldIndex =
                              controllers.key * 4 + controller.key;
                          final focusNode = _focusNodes[fieldIndex];
                          return SizedBox(
                            width: charWidth * 2 + 16,
                            child: Focus(
                              onKeyEvent: (node, event) {
                                if (event is KeyDownEvent &&
                                    event.logicalKey ==
                                        LogicalKeyboardKey.backspace &&
                                    controller.value.text.isEmpty) {
                                  _focusPrevious(fieldIndex);
                                  return KeyEventResult.handled;
                                }
                                return KeyEventResult.ignored;
                              },
                              child: TextField(
                                controller: controller.value,
                                focusNode: focusNode,
                                autofocus:
                                    controllers.key == 0 && controller.key == 0,
                                textInputAction: .next,
                                textCapitalization: .characters,
                                style: textTheme.bodyMedium!.googleSansCode,
                                textAlign: .center,
                                maxLength:
                                    _controllers.length +
                                    (_controllers.length - 1) ~/ 4,
                                maxLengthEnforcement: .none,
                                buildCounter: (
                                  _, {
                                  required currentLength,
                                  required isFocused,
                                  required maxLength,
                                }) => null,
                                inputFormatters: [
                                  TextInputFormatter.withFunction((
                                    oldValue,
                                    newValue,
                                  ) {
                                    if (newValue.text.length > 1 &&
                                        oldValue.text.isEmpty) {
                                      return newValue;
                                    }
                                    if (newValue.text.length > 1) {
                                      return TextEditingValue(
                                        text: newValue.text.substring(
                                          newValue.text.length - 1,
                                        ),
                                        selection:
                                            const TextSelection.collapsed(
                                              offset: 1,
                                            ),
                                      );
                                    }
                                    return newValue;
                                  }),
                                ],
                                onChanged: (value) => _handleChange(
                                  controllers.key,
                                  controller.key,
                                  value,
                                ),
                                decoration: InputDecoration(
                                  error: _errors.contains(fieldIndex)
                                      ? SizedBox.shrink()
                                      : null,
                                ),
                              ),
                            ),
                          );
                        }),
                        SizedBox(width: charWidth * 1),
                      ],
                    ),
                  )
                  .toList(),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisSize: .max,
              children: [
                Expanded(child: SizedBox()),
                FilledButton.icon(
                  onPressed: _submit,
                  icon: _isLoading
                      ? SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator(
                            color: colorScheme.onPrimary,
                            strokeWidth: 3,
                          ),
                        )
                      : null,
                  label: Text(appLocalizations.passphraseInputContinue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<({String backupCode})?> showBackupCodeInputDialog(
  BuildContext context, {
  FutureOr<String?> Function(String backupCode)? validate,
}) => showModalBottomSheet<({String backupCode})?>(
  context: context,
  isScrollControlled: true,
  clipBehavior: Clip.antiAlias,
  builder: (context) => BackupCodeInput(
    onSubmit: (backupCode) async {
      final validation = validate != null
          ? await Future.value(validate.call(backupCode))
                .catchError((e) => e.toString())
          : null;
      if (validation != null) return validation;
      if (context.mounted) {
        Navigator.of(context).pop((backupCode: backupCode));
      }
      return null;
    },
  ),
);
