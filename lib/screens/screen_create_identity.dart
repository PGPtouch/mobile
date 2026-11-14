import 'package:dart_pg/dart_pg.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:material_graphics/material_graphics.dart';
import 'package:material_helper/material_helper.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared/shared.dart';
import 'package:zxcvbn/zxcvbn.dart';

import '../components/bottom_sheet_multi_state.dart';
import '../components/keyed_animated_list.dart';
import '../components/research_point.dart';
import '../components/snack_bar_manager.dart';
import '../database/key_store.dart';
import '../key_utils.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';

typedef _UserIdData = ({String? name, String? comment, String email});

enum _CreateIdentityAdvancedAlgorithmType {
  curve25519,
  rsa;

  String getDisplayName() => switch (this) {
    .curve25519 => "Curve25519",
    .rsa => "RSA",
  };

  bool getIsRecommended() => switch (this) {
    .curve25519 => true,
    _ => false,
  };

  KeyType toDartPg() => switch (this) {
    .curve25519 => .curve25519,
    .rsa => .rsa,
  };
}

enum _CreateIdentityRsaKeySize {
  rsa2048,
  rsa3072,
  rsa4096;

  int getSize() => switch (this) {
    .rsa2048 => 2048,
    .rsa3072 => 3072,
    .rsa4096 => 4096,
  };

  String getAssociation(AppLocalizations appLocalizations) => switch (this) {
    .rsa2048 => appLocalizations.createIdentityRsaKeySizeNormal,
    .rsa3072 => appLocalizations.createIdentityRsaKeySizeMedium,
    .rsa4096 => appLocalizations.createIdentityRsaKeySizeHigh,
  };

  RSAKeySize toDartPg() => switch (this) {
    .rsa2048 => .normal,
    .rsa3072 => .high,
    .rsa4096 => .ultraHigh,
  };
}

class ScreenCreateIdentity extends StatefulWidget {
  const new({super.key});

  @override
  State<ScreenCreateIdentity> createState() => _ScreenCreateIdentityState();
}

class _ScreenCreateIdentityState extends State<ScreenCreateIdentity> {
  final _now = DateTime.now();

  DateTime? _expirationDate;
  final List<_UserIdData> _userIds = [];
  String? _passphrase;

  _CreateIdentityAdvancedAlgorithmType _advancedAlgorithm = .curve25519;
  _CreateIdentityRsaKeySize _advancedRsaKeySize = .rsa2048;
  bool _advancedAllowKeyEncryption = true;

  @override
  void initState() {
    super.initState();
    assert(
      KeyStoreHandler.instance.isLocked == false,
      "KeyStore must be unlocked to create a new identity",
    );
  }

  Future<void> _createIdentity() async {
    assert(
      _passphrase != null && _userIds.isNotEmpty,
      "Passphrase and at least one User ID are required to create an identity",
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      clipBehavior: Clip.antiAlias,
      builder: (_) => BottomSheetMultiState(child: null),
    );

    final userIds = _userIds
        .map(
          (u) => UserId(
            name: u.name,
            comment: u.comment,
            email: u.email,
          ).toString(),
        )
        .toList();
    final passphrase = _passphrase!;
    final type = _advancedAlgorithm.toDartPg();
    final rsaKeySize = _advancedRsaKeySize.toDartPg();
    final signOnly = !_advancedAllowKeyEncryption;
    final keyExpiry = _expirationDate == null
        ? 0
        : _expirationDate!
              .difference(DateTime.now())
              .inSeconds
              .clamp(1, 0xFFFFFFFF);
    final stopwatch = Stopwatch()..start();
    final identity = await compute(
      (_) => OpenPGP.generateKey(
        userIds,
        passphrase,
        type: type,
        rsaKeySize: rsaKeySize,
        keyExpiry: keyExpiry,
        signOnly: signOnly,
      ),
      null,
    );
    final generationMs = stopwatch.elapsedMilliseconds;

    final privateKey = identity as PrivateKey;
    final publicKey = privateKey.publicKey as PublicKey;
    final publicData = await compute(
      (publicKey) => encodeKey(publicKey, const []),
      publicKey,
    );
    final privateData = await compute(
      (privateKey) => encodeKey(privateKey, const []),
      privateKey,
    );
    await KeyStoreHandler.instance.keyStore!.insertKey(
      KeysCompanion.insert(
        fingerprint: identity.fingerprint,
        publicData: publicData,
        privateData: privateData,
        isRevoked: isPublicKeyDataRevoked(publicData),
        createdAt: identity.creationTime,
        expiresAt: .absentIfNull(keyExpirationTime(publicKey)),
      ),
      identity.users.map((user) => user.userID).toList(),
    );
    await KeyStoreHandler.instance.setKeyPassphrase(
      identity.fingerprint,
      passphrase,
    );

    ResearchPoint.trackEvent("identityCreated", {
      "algorithm": _advancedAlgorithm.name,
      "rsaKeySize": ?(_advancedAlgorithm == .rsa
          ? _advancedRsaKeySize.getSize()
          : null),
      "userIdCount": userIds.length,
      "hasExpiry": _expirationDate != null,
      "canEncrypt": _advancedAllowKeyEncryption,
      "generationMs": generationMs,
    });

    if (!mounted) return;
    SnackBarManager.showSnackBar(
      context,
      AppLocalizations.of(context).createIdentityCreated,
    );
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
    if (navigator.canPop()) navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final canCreate = _passphrase != null && _userIds.isNotEmpty;

    final child = Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            leading: CloseButton(),
            flexibleSpace: MaterialFlexibleSpaceBar(
              title: Text(appLocalizations.createIdentityTitle),
            ),
            actions: [
              Padding(
                padding: EdgeInsetsDirectional.only(end: 8),
                child: TextButton(
                  onPressed: canCreate ? _createIdentity : null,
                  child: Text(appLocalizations.createIdentityCreate),
                ),
              ),
            ],
            expandedHeight: 172,
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              MaterialListTile(
                leading: Icon(Icons.auto_fix_high_outlined),
                title: Builder(
                  builder: (context) => Text(
                    hyphenate(appLocalizations.createIdentityHint),
                    style: DefaultTextStyle.of(context).style
                        .copyWith(height: 1.2),
                  ),
                ),
                titleStyle: .text,
              ),
              ...MaterialListTile.group(
                headline: MaterialListTileHeadline(Text("")),
                [
                  MaterialListTile(
                    title: Text(appLocalizations.passphraseInputLabel),
                    subtitle: Text(
                      _passphrase != null
                          ? appLocalizations.createIdentityPassphraseSet
                          : appLocalizations.valueMissing,
                    ),
                    onTap: () async {
                      final passphrase = await showPromptDialog(
                        context: context,
                        title: appLocalizations
                            .createIdentityPassphraseDialogTitle,
                        description: appLocalizations
                            .createIdentityPassphraseDialogDescription,
                        placeholder: "ImInLoveWithPGP",
                        autofillHints: [AutofillHints.newPassword],
                        autocorrect: false,
                        obscure: true,
                        keyboardType: .visiblePassword,
                        capitalization: .none,
                        quickValidator: (value) => value.isNotEmpty,
                        action: PromptDialogActions.toggleObscure(context),
                        validator: (value) async {
                          if (value.isEmpty) return null;
                          final result = Zxcvbn().evaluate(
                            value,
                            userInputs: [
                              "PGP",
                              "GPG",
                              "PGPtouch",
                              "Passphrase",
                              "Password",
                              "ImInLoveWithPGP",
                            ],
                          );
                          if (result.score == null || result.score! < 2) {
                            return hyphenate(
                              result.feedback.warning != null &&
                                      result.feedback.warning!.isNotEmpty
                                  ? "${l10nMapZxcvbnFeedbackWarning(result.feedback.warning!, appLocalizations: appLocalizations).replaceFirst(RegExp(r"\.$"), "")}."
                                  : appLocalizations
                                        .createIdentityPassphraseInsecure(
                                          NumberFormat.compactLong(
                                            locale: appLocalizations.localeName,
                                          ).format(result.guesses),
                                        ),
                            );
                          }
                          return null;
                        },
                      );
                      if (passphrase != null && passphrase.isNotEmpty) {
                        _passphrase = passphrase;
                        if (mounted) setState(() {});
                      }
                    },
                  ),
                  MaterialListTile(
                    title: Text(appLocalizations.identityExpiration),
                    subtitle: Text(
                      _expirationDate == null
                          ? appLocalizations.valueMissing
                          : DateFormat.yMMMd(appLocalizations.localeName)
                                .format(_expirationDate!),
                    ),
                    trailing: _expirationDate != null
                        ? Transform.translate(
                            offset: Offset(8, 0),
                            child: IconButton(
                              onPressed: () {
                                _expirationDate = null;
                                if (mounted) setState(() {});
                              },
                              icon: Icon(Icons.delete_outline),
                              tooltip: appLocalizations
                                  .createIdentityExpirationRemoveTooltip,
                            ),
                          )
                        : null,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime(
                          _now.year + 4,
                          _now.month,
                          _now.day,
                        ),
                        firstDate: _now,
                        lastDate: DateTime(
                          _now.year + 20,
                          _now.month,
                          _now.day,
                        ),
                        initialDatePickerMode: .year,
                      );
                      if (date != null) {
                        _expirationDate = date;
                        if (mounted) setState(() {});
                      }
                    },
                  ),
                ],
              ),

              ...MaterialListTile.group(
                headline: MaterialListTileHeadline(
                  Text(appLocalizations.createIdentityUserIdsHeadline),
                ),
                _userIds.map((userId) {
                  final hasName =
                      userId.name != null && userId.name!.isNotEmpty;
                  final hasComment =
                      userId.comment != null && userId.comment!.isNotEmpty;
                  return MaterialListTile(
                    title: Text(
                      "${hasName ? userId.name : userId.email}${hasComment ? " ${appLocalizations.identityComment(userId.comment!)}" : ""}",
                    ),
                    subtitle: hasName ? Text(userId.email) : null,
                    trailing: Transform.translate(
                      offset: Offset(8, 0),
                      child: IconButton(
                        onPressed: () {
                          _userIds.remove(userId);
                          if (mounted) setState(() {});
                        },
                        icon: Icon(Icons.delete_outline),
                        tooltip:
                            appLocalizations.createIdentityUserIdRemoveTooltip,
                      ),
                    ),
                    onTap: () async {
                      final data = await showDialog<_UserIdData>(
                        context: context,
                        builder: (context) =>
                            _UserIdInputDialog(initialData: userId),
                      );
                      if (data != null) {
                        final index = _userIds.indexOf(userId);
                        if (index != -1) {
                          _userIds[index] = data;
                          if (mounted) setState(() {});
                        }
                      }
                    },
                  );
                }).toList(),
              ),
              MaterialListTile(
                leading: Icon(Icons.add),
                title: Text(appLocalizations.createIdentityUserIdAdd),
                onTap: () async {
                  final data = await showDialog<_UserIdData>(
                    context: context,
                    builder: (context) => _UserIdInputDialog(),
                  );
                  if (data != null) {
                    _userIds.add(data);
                    if (mounted) setState(() {});
                  }
                },
              ),

              FoldAwayMaterialListTileGroup(
                headline: MaterialListTileHeadline(
                  Text(appLocalizations.createIdentityAdvancedHeadline),
                ),
                tiles: [
                  MaterialListTile(
                    title: Text(appLocalizations.createIdentityAlgorithmTitle),
                    subtitle: Text(_advancedAlgorithm.getDisplayName()),
                    onTap: () async {
                      final selection = await showRadioDialog(
                        context: context,
                        title:
                            appLocalizations.createIdentityAlgorithmDialogTitle,
                        initialValue: _advancedAlgorithm,
                        items: _CreateIdentityAdvancedAlgorithmType.values,
                        titleGenerator: (item) => item.getDisplayName(),
                        iconGenerator: (item) => item.getIsRecommended()
                            ? Tooltip(
                                message: appLocalizations
                                    .createIdentityAlgorithmRecommendedTooltip,
                                child: Icon(Icons.star),
                              )
                            : null,
                      );
                      if (selection != null) {
                        _advancedAlgorithm = selection;
                        if (mounted) setState(() {});
                      }
                    },
                  ),
                  if (_advancedAlgorithm == .rsa)
                    MaterialListTile(
                      title: Text(
                        appLocalizations.createIdentityRsaKeySizeTitle,
                      ),
                      subtitle: Text(
                        "${_advancedRsaKeySize.getAssociation(appLocalizations)} (${_advancedRsaKeySize.getSize()})",
                      ),
                      onTap: () async {
                        final selection = await showRadioDialog(
                          context: context,
                          title: appLocalizations
                              .createIdentityRsaKeySizeDialogTitle,
                          initialValue: _advancedRsaKeySize,
                          items: _CreateIdentityRsaKeySize.values,
                          titleGenerator: (item) =>
                              item.getAssociation(appLocalizations),
                          subtitleGenerator: (item) =>
                              item.getSize().toString(),
                        );
                        if (selection != null) {
                          _advancedRsaKeySize = selection;
                          if (mounted) setState(() {});
                        }
                      },
                    ),
                  MaterialSwitchListTile(
                    value: _advancedAllowKeyEncryption,
                    onChanged: (value) {
                      _advancedAllowKeyEncryption = value;
                      if (mounted) setState(() {});
                    },
                    title: Text(
                      appLocalizations.createIdentityAllowKeyEncryptionTitle,
                    ),
                    subtitle: Text(
                      appLocalizations
                          .createIdentityAllowKeyEncryptionDescription,
                    ),
                  ),
                ],
                layoutBuilder: (context, items) {
                  final keyed = items.map((e) {
                    final key =
                        (switch ((e as MaterialListTileBorderStyle).child) {
                          final MaterialListTile tile => tile.title!,
                          final MaterialSwitchListTile tile => tile.title!,
                          _ => throw Exception("Unexpected child type"),
                        } as Text).data;
                    return KeyedSubtree(key: ValueKey(key), child: e);
                  });
                  return KeyedAnimatedList(children: keyed.toList());
                },
              ),
              MaterialListTileBottomSpacer(),
            ]),
          ),
        ],
      ),
    );

    final isChanged =
        _passphrase != null ||
        _userIds.isNotEmpty ||
        _expirationDate != null ||
        _advancedAlgorithm != .curve25519 ||
        _advancedAllowKeyEncryption != true;
    return PopScope(
      canPop: !isChanged,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || !isChanged) return;
        final wantPop = await showDiscardDialog(context);
        if (wantPop && context.mounted) {
          final navigator = Navigator.of(context);
          if (navigator.canPop()) navigator.pop();
        }
      },
      child: child,
    );
  }
}

Future<bool> showDiscardDialog(BuildContext context) {
  final appLocalizations = AppLocalizations.of(context);
  return showConfirmationDialog(
    context: context,
    title: appLocalizations.discardDialogTitle,
    content: Text(appLocalizations.discardDialogDescription),
    promotedActions: {.negative},
  );
}

class _UserIdInputDialog extends StatefulWidget {
  final _UserIdData? initialData;
  const new({this.initialData});

  @override
  State<_UserIdInputDialog> createState() => _UserIdInputDialogState();
}

class _UserIdInputDialogState extends State<_UserIdInputDialog> {
  var _showCommentField = false;

  late final _controllerName = TextEditingController(
    text: widget.initialData?.name,
  );
  late final _controllerComment = TextEditingController(
    text: widget.initialData?.comment,
  );
  late final _controllerEmail = TextEditingController(
    text: widget.initialData?.email,
  );

  String? nameError;
  String? commentError;
  String? emailError;

  void submit() {
    final appLocalizations = AppLocalizations.of(context);
    nameError = null;
    commentError = null;
    emailError = null;
    if (mounted) setState(() {});

    final name = _controllerName.text.trim().isNotEmpty
        ? _controllerName.text.trim()
        : null;
    final comment = _controllerComment.text.trim().isNotEmpty
        ? _controllerComment.text.trim()
        : null;
    final email = _controllerEmail.text.trim();

    if (email.isEmpty) {
      emailError = appLocalizations.userIdEmailEmpty;
      if (mounted) setState(() {});
      return;
    } else if (!email.contains('@')) {
      emailError = appLocalizations.userIdEmailMissingAt;
      if (mounted) setState(() {});
      return;
    } else if (email.length < 3) {
      emailError = appLocalizations.userIdEmailTooShort;
      if (mounted) setState(() {});
      return;
    }

    if (comment?.contains(")") ?? false) {
      commentError = appLocalizations.userIdCommentInvalidCharacter;
      if (mounted) setState(() {});
      return;
    }

    if (UserId.tryParse(
          UserId(name: name, comment: comment, email: email).toString(),
        ) ==
        null) {
      emailError = appLocalizations.userIdInvalid;
      if (mounted) setState(() {});
      return;
    }

    Navigator.of(context).pop((name: name, comment: comment, email: email));
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final commentBracketsParts = appLocalizations.userIdCommentBrackets.split(
      "<br>",
    );
    return ScrollingAlertDialog(
      title: Text(
        widget.initialData != null
            ? appLocalizations.userIdDialogTitleEdit
            : appLocalizations.userIdDialogTitleNew,
      ),
      content: SingleChildScrollView(
        child: KeyedAnimatedList(
          children: [
            TextField(
              key: ValueKey("nameField"),
              controller: _controllerName,
              autofocus: true,
              autocorrect: true,
              autofillHints: [AutofillHints.name],
              keyboardType: TextInputType.name,
              textCapitalization: .words,
              textInputAction: .next,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: appLocalizations.userIdNameLabel,
                hintText: "John Doe",
                errorText: nameError,
                suffixIcon: IconButton(
                  onPressed: () {
                    _showCommentField = !_showCommentField;
                    if (mounted) setState(() {});
                  },
                  icon: TweenAnimationBuilder(
                    tween: Tween(
                      begin: 0.0,
                      end: _showCommentField ? 0.5 : 0.0,
                    ),
                    duration: ExpressiveCurves.expressiveEffects.normalDuration,
                    curve: ExpressiveCurves.expressiveEffects.normal,
                    builder: (_, value, _) => RotationTransition(
                      turns: AlwaysStoppedAnimation(value),
                      child: Icon(Icons.expand_more),
                    ),
                  ),
                ),
              ),
            ),
            TweenAnimationBuilder(
              key: ValueKey("spacer1"),
              tween: Tween(begin: 0.0, end: _showCommentField ? 8.0 : 0.0),
              duration: ExpressiveCurves.expressiveEffects.normalDuration,
              curve: ExpressiveCurves.expressiveEffects.normal,
              builder: (_, value, _) => SizedBox(height: value),
            ),
            if (_showCommentField)
              Column(
                key: ValueKey("commentField"),
                mainAxisSize: .min,
                children: [
                  TextField(
                    controller: _controllerComment,
                    autocorrect: true,
                    keyboardType: TextInputType.text,
                    textCapitalization: .sentences,
                    textInputAction: .next,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      prefixText: commentBracketsParts.first,
                      suffixText: commentBracketsParts.length > 1
                          ? commentBracketsParts.last
                          : null,
                      labelText: appLocalizations.userIdCommentLabel,
                      hintText: appLocalizations.userIdCommentHint,
                      errorText: commentError,
                    ),
                  ),
                  SizedBox(height: 12),
                ],
              ),
            SizedBox(key: ValueKey("spacer2"), height: 8),
            TextField(
              key: ValueKey("emailField"),
              controller: _controllerEmail,
              autocorrect: true,
              autofillHints: [AutofillHints.email],
              keyboardType: TextInputType.emailAddress,
              textCapitalization: .none,
              textInputAction: .done,
              onSubmitted: (_) => submit(),
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: appLocalizations.userIdEmailLabel,
                hintText: "user@example.com",
                errorText: emailError,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: submit,
          child: Text(appLocalizations.userIdSubmit),
        ),
      ],
    );
  }
}

Widget _foldAwayMaterialListTileGroupDefaultLayoutBuilder(
  _,
  List<Widget> items,
) => Column(mainAxisSize: MainAxisSize.min, children: items);

class FoldAwayMaterialListTileGroup extends StatefulWidget {
  final MaterialListTileHeadline headline;
  final List<Widget> tiles;
  final bool initiallyExpanded;
  final Widget Function(BuildContext context, List<Widget> items) layoutBuilder;

  const new({
    super.key,
    required this.headline,
    required this.tiles,
    this.initiallyExpanded = false,
    this.layoutBuilder = _foldAwayMaterialListTileGroupDefaultLayoutBuilder,
  });

  @override
  State<FoldAwayMaterialListTileGroup> createState() =>
      _FoldAwayMaterialListTileGroupState();
}

class _FoldAwayMaterialListTileGroupState
    extends State<FoldAwayMaterialListTileGroup>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded = widget.initiallyExpanded;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Durations.medium1,
    value: widget.initiallyExpanded ? 1.0 : 0.0,
  );

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final textTheme = TextTheme.of(context);

    final animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    final items = List.generate(
      widget.tiles.length,
      (index) => MaterialListTileBorderStyle(
        borderTop: index != 0 ? MaterialListTileBorder.open : null,
        borderBottom: index != widget.tiles.length - 1
            ? MaterialListTileBorder.open
            : null,
        child: widget.tiles[index],
      ),
    );

    return Column(
      mainAxisSize: .min,
      children: [
        GestureDetector(
          onTap: () {
            _isExpanded = !_isExpanded;
            if (mounted) setState(() {});

            if (_isExpanded) {
              _controller.forward();
            } else {
              _controller.reverse();
            }
          },
          child: Row(
            mainAxisSize: .max,
            crossAxisAlignment: .end,
            children: [
              Expanded(child: widget.headline),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 12, bottom: 8),
                child: RotationTransition(
                  turns: Tween(begin: 1.0, end: 0.5).animate(animation),
                  child: Icon(
                    Icons.expand_more,
                    color: colorScheme.primary,
                    size: textTheme.labelLarge!.fontSize! * 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizeTransition(
          sizeFactor: animation,
          alignment: Alignment.topCenter,
          child: widget.layoutBuilder(context, items),
        ),
      ],
    );
  }
}

String l10nMapZxcvbnFeedbackWarning(
  String warning, {
  required AppLocalizations appLocalizations,
}) {
  return switch (warning) {
    "Straight rows of keys are easy to guess" =>
      appLocalizations.zxcvbnWarningStraightRows,
    "Short keyboard patterns are easy to guess" =>
      appLocalizations.zxcvbnWarningShortKeyboardPatterns,
    'Repeats like "aaa" are easy to guess' =>
      appLocalizations.zxcvbnWarningRepeatsSingleChar,
    'Repeats like "abcabcabc" are only slightly harder to guess than "abc"' =>
      appLocalizations.zxcvbnWarningRepeatsMultiChar,
    "Sequences like abc or 6543 are easy to guess" =>
      appLocalizations.zxcvbnWarningSequences,
    "Recent years are easy to guess" =>
      appLocalizations.zxcvbnWarningRecentYears,
    "Dates are often easy to guess" => appLocalizations.zxcvbnWarningDates,
    "This is a top-10 common password" =>
      appLocalizations.zxcvbnWarningTop10Password,
    "This is a top-100 common password" =>
      appLocalizations.zxcvbnWarningTop100Password,
    "This is a very common password" =>
      appLocalizations.zxcvbnWarningVeryCommonPassword,
    "This is similar to a commonly used password" =>
      appLocalizations.zxcvbnWarningSimilarToCommonPassword,
    "A word by itself is easy to guess" =>
      appLocalizations.zxcvbnWarningWordByItself,
    "Names and surnames by themselves are easy to guess" =>
      appLocalizations.zxcvbnWarningNamesByThemselves,
    "Common names and surnames are easy to guess" =>
      appLocalizations.zxcvbnWarningCommonNames,
    _ => warning,
  };
}
