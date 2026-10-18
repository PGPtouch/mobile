import 'dart:async';
import 'dart:typed_data';

import 'package:material_graphics/material_graphics.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/main.dart';

class PassphraseInput extends StatefulWidget {
  /// The identity for which the passphrase is being requested.
  ///
  /// This is displayed to the user for visual indication. Usually, this should
  /// be an email address.
  final List<String> identity;

  /// The fingerprint of the key this passphrase is for.
  ///
  /// This is displayed to the user for visual indication.
  final Uint8List fingerprint;

  /// Whether the passphrase input can be skipped by the user.
  ///
  /// This will call [onCancel] when the user chooses to skip the input. While
  /// the user is normally also able to cancel, this will display a prominent
  /// skip option.
  final bool skippable;

  /// The callback on a successful submission of the passphrase.
  ///
  /// If this returns a string, it is displayed as an error message. This should
  /// remove the [PassphraseInput] widget from view, as the widget will become
  /// reeditable by the user.
  final FutureOr<String?> Function(String passphrase, bool remember) onSubmit;

  /// The callback when the user cancels the input.
  ///
  /// This should remove the [PassphraseInput] widget from view. See [onSubmit].
  final FutureOr<void> Function(bool skipped)? onCancel;

  const new({
    super.key,
    required this.identity,
    required this.fingerprint,
    this.skippable = false,
    required this.onSubmit,
    this.onCancel,
  });

  @override
  State<PassphraseInput> createState() => _PassphraseInputState();
}

class _PassphraseInputState extends State<PassphraseInput> {
  bool _isLoading = false;
  bool _passkeyVisible = false;
  String? _error;

  final TextEditingController _controller = TextEditingController();
  bool _remember = false;

  void _submit() {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    if (mounted) setState(() {});
    Future.value(widget.onSubmit(_controller.text, _remember)).then((error) {
      if (error != null) _isLoading = false;
      _error = error;
      if (mounted) setState(() {});
    });
  }

  void _cancel(bool skipped) => widget.onCancel?.call(skipped);

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !_isLoading,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _cancel(widget.skippable);
      },
      child: Padding(
        padding:
            MediaQuery.viewInsetsOf(context) +
            MediaQuery.paddingOf(context) +
            const EdgeInsets.all(16).copyWith(top: 14, bottom: 8),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            Text(
              "${hyphenate(appLocalizations.passphraseInputPrompt)} ${widget.identity.map((e) => appLocalizations.enquote(e)).join(", ")}",
            ),
            SizedBox(height: 16),
            AnimatedSize(
              curve: ExpressiveCurves.expressiveEffects.slow,
              duration: ExpressiveCurves.expressiveEffects.slowDuration,
              alignment: Alignment.topCenter,
              child: TextField(
                controller: _controller,
                autofocus: true,
                autocorrect: false,
                enableIMEPersonalizedLearning: false,
                onSubmitted: (_) => _submit(),
                textInputAction: .done,
                keyboardType: .visiblePassword,
                autofillHints: [AutofillHints.password],
                enabled: !_isLoading,
                obscureText: !_passkeyVisible,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: appLocalizations.passphraseInputLabel,
                  helperText: hyphenate(appLocalizations.passphraseInputHelper),
                  helperMaxLines: 3,
                  errorText: _error,
                  errorMaxLines: 3,
                  suffixIcon: IconButton(
                    onPressed: () {
                      _passkeyVisible = !_passkeyVisible;
                      if (mounted) setState(() {});
                    },
                    icon: Icon(
                      _passkeyVisible
                          ? Icons.visibility
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            CheckboxListTile(
              value: _remember,
              onChanged: (bool? value) {
                _remember = value ?? false;
                if (mounted) setState(() {});
              },
              minTileHeight: 0,
              contentPadding: EdgeInsets.zero,
              minVerticalPadding: 0,
              title: Text(appLocalizations.passphraseInputRemember),
              subtitle: Text(
                appLocalizations.passphraseInputRememberDescription,
              ),
            ),
            SizedBox(height: 6),
            Row(
              mainAxisSize: .max,
              children: [
                if (widget.skippable)
                  TextButton(
                    onPressed: !_isLoading ? () => _cancel(true) : null,
                    child: Text(appLocalizations.passphraseInputSkip),
                  ),
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

Future<({String passphrase, bool remember})?> showPassphraseInputDialog(
  BuildContext context, {
  required List<String> identity,
  required Uint8List fingerprint,
  FutureOr<String?> Function(String passphrase)? validate,
  bool skippable = false,
}) => showModalBottomSheet<({String passphrase, bool remember})?>(
  context: context,
  builder: (context) => PassphraseInput(
    identity: identity,
    fingerprint: fingerprint,
    skippable: skippable,
    onSubmit: (passphrase, remember) async {
      final validation = validate != null
          ? await Future.value(validate.call(passphrase))
          : null;
      if (validation != null) return validation;
      if (!context.mounted) return null;
      Navigator.of(context).pop((passphrase: passphrase, remember: remember));
      return null;
    },
  ),
);
