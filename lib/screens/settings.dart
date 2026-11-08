import 'dart:convert';

// not publicly exposed
// ignore: implementation_imports
import 'package:dart_pg/src/enum/armor_type.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:icon_craft/icon_craft.dart';
import 'package:material_helper/material_helper.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared/shared.dart';

import '../components/identity_tile.dart';
import '../components/research_point.dart';
import '../components/snack_bar_manager.dart';
import '../database/key_store.dart';
import '../generated/gitbaker.g.dart';
import '../key_utils.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import 'screen_contacts.dart';

SettingsConfig settings(
  BuildContext context,
  VoidCallback? Function() clearSelected,
) {
  final appLocalizations = AppLocalizations.of(context);
  final colorScheme = ColorScheme.of(context);
  SettingsConfig exportingSettings() => SettingsConfig(
    title: appLocalizations.settingsExporting,
    description: hyphenate(appLocalizations.settingsExportingDescription),
    sections: [
      SettingsSection(
        headline: "",
        options: [
          CustomSettingsOption(
            icon: Icon(Icons.groups_2_outlined),
            title: appLocalizations.settingsExportAllContacts,
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final keys =
                  (await contactStore.select(contactStore.contacts).get())
                      .map((c) => c.data)
                      .toList();
              if (keys.isEmpty) {
                SnackBarManager.showSnackBarOn(
                  messenger,
                  appLocalizations.settingsExportNoContacts,
                );
                return;
              }

              try {
                final chained = chainKeys(keys);
                final path = await FilePicker.saveFile(
                  fileName: "Contacts.pgp",
                  bytes: chained,
                );
                if (path != null) {
                  SnackBarManager.showSnackBarOn(
                    messenger,
                    appLocalizations.settingsExportContactsSuccess,
                  );
                }
              } catch (_) {
                SnackBarManager.showSnackBarOn(
                  messenger,
                  appLocalizations.settingsExportContactsFailed,
                );
              }
            },
          ),
          CustomSettingsOption(
            icon: Icon(Icons.badge_outlined),
            title: appLocalizations.settingsExportAllIdentities,
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final confirmed = await showConfirmationDialog(
                context: context,
                icon: Icon(Icons.warning_amber_rounded),
                title: appLocalizations.settingsExportInsecureTitle,
                content: Text(
                  hyphenate(appLocalizations.settingsExportInsecureDescription),
                  textAlign: .justify,
                ),
              );
              if (!confirmed) return;

              final unlocked = await KeyStoreHandler.instance.unlock(
                appLocalizations,
              );
              if (unlocked != .unlocked) return;
              final keyStore = KeyStoreHandler.instance.keyStore!;

              final keys = (await keyStore.select(keyStore.keys).get())
                  .map((i) => i.privateData)
                  .toList();
              if (keys.isEmpty) {
                SnackBarManager.showSnackBarOn(
                  messenger,
                  appLocalizations.settingsExportNoIdentities,
                );
                return;
              }

              try {
                final chained = chainKeys(keys);
                final path = await FilePicker.saveFile(
                  fileName: "Identities.pgp",
                  bytes: chained,
                );
                if (path != null) {
                  SnackBarManager.showSnackBarOn(
                    messenger,
                    appLocalizations.settingsExportIdentitiesSuccess,
                  );
                }
              } catch (_) {
                SnackBarManager.showSnackBarOn(
                  messenger,
                  appLocalizations.settingsExportIdentitiesFailed,
                );
              }
            },
          ),
          CustomSettingsOption(
            icon: IconCraft(
              Icon(Icons.badge_outlined),
              Icon(Icons.cloud),
              alignment: Alignment.bottomRight,
              decoration: IconDecoration(
                border: IconBorder(
                  color: colorScheme.brightness == Brightness.light
                      ? colorScheme.surfaceContainerLowest
                      : colorScheme.surfaceBright,
                ),
              ),
            ),
            title: appLocalizations.settingsExportAllIdentitiesBackup,
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final unlocked = await KeyStoreHandler.instance.unlock(
                appLocalizations,
              );
              if (unlocked != .unlocked) return;
              final keyStore = KeyStoreHandler.instance.keyStore!;

              final keys = (await keyStore.select(keyStore.keys).get())
                  .map(
                    (i) => [
                      (type: ArmorType.publicKey, bytes: i.publicData),
                      (type: ArmorType.privateKey, bytes: i.privateData),
                    ],
                  )
                  .expand((x) => x)
                  .toList();
              if (keys.isEmpty) {
                SnackBarManager.showSnackBarOn(
                  messenger,
                  appLocalizations.settingsExportNoIdentities,
                );
                return;
              }

              try {
                if (!context.mounted) return;
                final backupCode = ValueNotifier<String?>(null);
                final confirmedFuture = showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  clipBehavior: Clip.antiAlias,
                  builder: (context) =>
                      BackupCodeOutput(backupCode: backupCode),
                );
                final backup = await backupFormat(keys);
                backupCode.value = backup.backupCode;

                final confirmed = await confirmedFuture;
                if (confirmed != true) return;

                final path = await FilePicker.saveFile(
                  fileName: "Identities.pgp",
                  bytes: utf8.encode(backup.data),
                );
                if (path != null) {
                  SnackBarManager.showSnackBarOn(
                    messenger,
                    appLocalizations.settingsExportIdentitiesSuccess,
                  );
                }
              } catch (_) {
                SnackBarManager.showSnackBarOn(
                  messenger,
                  appLocalizations.settingsExportIdentitiesFailed,
                );
              }
            },
          ),
        ],
      ),
    ],
  );

  return SettingsConfig(
    sections: [
      SettingsSection(
        options: [
          CheckSettingsOption(
            title: appLocalizations.settingsHkpKeyServers,
            value:
                prefs?.getStringList("hkp_key_servers") ??
                UserId.defaultHkpKeyServers.map((s) => s.host).toList(),
            items: UserId.commonHkpKeyServers.map((s) => s.host).toList(),
            titleGenerator: (item) =>
                UserId.commonHkpKeyServers
                    .firstWhereOrNull((s) => s.host == item)
                    ?.displayName ??
                item,
            subtitleGenerator: (item) =>
                UserId.commonHkpKeyServers
                    .firstWhereOrNull((s) => s.host == item)
                    ?.host ??
                "",
            iconGenerator: (item) =>
                (UserId.commonHkpKeyServers
                        .firstWhereOrNull((s) => s.host == item)
                        ?.keyIdentitiesVerifies ??
                    false)
                ? Tooltip(
                    message: hyphenate(
                      appLocalizations
                          .addContactSearchResultIdentityVerifiedTooltip,
                    ),
                    child: Icon(Icons.how_to_reg_outlined),
                  )
                : null,
            allowEmpty: true,
            onChanged: (value) {
              var keys = value.toList();
              if (keys.isEmpty) {
                keys = UserId.defaultHkpKeyServers.map((s) => s.host).toList();
              }
              prefs?.setStringList("hkp_key_servers", keys);
            },
          ),
          SwitchSettingsOption(
            title: appLocalizations.settingsBetaFeatures,
            subtitle: appLocalizations.settingsBetaFeaturesDescription,
            value: prefs?.getBool("beta") ?? false,
            onChanged: (value) => prefs?.setBool("beta", value),
          ),
        ],
      ),
      SettingsSection(
        headline: appLocalizations.settingsMiscellaneous,
        options: [
          NavigationSettingsOption(
            icon: Icon(Icons.upload_outlined),
            title: appLocalizations.settingsExporting,
            newScreen: exportingSettings,
          ),
        ],
      ),
      SettingsSection(
        options: [
          CustomSettingsOption(
            title: appLocalizations.settingsClearSelectedIdentity,
            subtitle: appLocalizations.settingsClearSelectedIdentityDescription,
            onTap: () {
              clearSelected()?.call();
              SnackBarManager.showSnackBar(
                context,
                appLocalizations.settingsClearSelectedIdentitySuccess,
              );
            },
            enabled: () => clearSelected() != null,
          ),
        ],
      ),
      SettingsSection(
        options: [
          NavigationSettingsOption(
            icon: Icon(Icons.privacy_tip_outlined),
            title: appLocalizations.settingsPrivacy,
            newScreen: () => SettingsConfig(
              title: appLocalizations.settingsPrivacy,
              sections: [
                SettingsSection(
                  options: [
                    SwitchSettingsOption(
                      title: appLocalizations.settingsEnableTracking,
                      subtitle:
                          appLocalizations.settingsEnableTrackingDescription,
                      value: ResearchPoint.enabled,
                      onChanged: (value) {
                        prefs?.setBool("researchEnabled", value);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          CustomSettingsOption(
            icon: Icon(Icons.info_outline),
            title: appLocalizations.settingsAboutApp,
            onTap: () => showAboutScreen(
              context,
              referenceMaterialApps: false,
              githubUrl: Uri.parse("https://github.com/PGPtouch/mobile"),
              gitBakerData: GitBaker.toJson(),
              iconUseDarkAssetFallback: true,
            ),
          ),
        ],
      ),
      if (kDebugMode)
        SettingsSection(
          headline: "Framework tests",
          options: [
            SettingsOptionBuilder(
              builder: (_, _) => Row(
                mainAxisSize: .max,
                mainAxisAlignment: .spaceEvenly,
                children: [
                  MaterialLoadingIndicator(),
                  MaterialLoadingIndicator(style: .contained),
                ],
              ),
            ),
          ],
        ),
    ],
  );
}

Future<void> showSettings(
  BuildContext context,
  VoidCallback? Function() clearSelected,
) =>
    showSettingsScreen(context, config: () => settings(context, clearSelected));
