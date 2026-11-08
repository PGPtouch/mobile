import 'package:material_graphics/material_graphics.dart';
import 'package:material_helper/material_helper.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';

Future<void> showStepByStepGuideDialog(
  BuildContext context, {
  required String title,
  String? description,
  required List<({String title, String? subtitle, Widget? icon})> steps,
}) {
  final messageText = description == null ? null : hyphenate(description);

  final stepWidgets = steps
      .asMap()
      .entries
      .map(
        (step) => MaterialListTile(
          leading: Transform.translate(
            offset: Offset(0, -2),
            child: Text(
              (step.key + 1).toString().padLeft(2, "0"),
              style: TextTheme.of(context).labelLarge!.bagelFatOne
                  .copyWith(fontSize: 24),
            ),
          ),
          title: Text(step.value.title),
          subtitle: step.value.subtitle != null
              ? Text(step.value.subtitle!)
              : null,
          trailing: step.value.icon,
          backgroundStyle: .lightened,
        ),
      )
      .toList();

  return showAlertDialog(
    context: context,
    title: title,
    contentPadding: EdgeInsets.zero,
    content: Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (messageText != null)
            MaterialListTile(
              title: Text(messageText, textAlign: .justify),
              backgroundStyle: .lightened,
              titleStyle: .text,
            ),
          ...MaterialListTile.group(stepWidgets),
        ],
      ),
    ),
  );
}

Future<void> showKeyStoreReauthRequiredDialog(BuildContext context) {
  final appLocalizations = AppLocalizations.of(context);
  return showStepByStepGuideDialog(
    context,
    title: appLocalizations.vaultUnlockDeviceReauthRequiredTitle,
    description: appLocalizations.vaultUnlockDeviceReauthRequiredMessage,
    steps: [
      (
        title: appLocalizations.vaultUnlockDeviceReauthRequiredStep1,
        subtitle: null,
        icon: Icon(Icons.phonelink_lock_rounded),
      ),
      (
        title: appLocalizations.vaultUnlockDeviceReauthRequiredStep2,
        subtitle: null,
        icon: Icon(Icons.face_unlock_rounded),
      ),
      (
        title: appLocalizations.vaultUnlockDeviceReauthRequiredStep3,
        subtitle: null,
        icon: Icon(Icons.replay_rounded),
      ),
    ],
  );
}
