import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:material_helper/material_helper.dart';
import 'package:mobile/generated/gitbaker.g.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/main.dart';
import 'package:shared/shared.dart';

Future<void> settings(BuildContext context) async => showSettingsScreen(
  context,
  config: () {
    final appLocalizations = AppLocalizations.of(context);
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
                  keys = UserId.defaultHkpKeyServers
                      .map((s) => s.host)
                      .toList();
                }
                prefs?.setStringList("hkp_key_servers", keys);
              },
            ),
          ],
        ),
        SettingsSection(
          headline: appLocalizations.settingsMiscellaneous,
          options: [
            CustomSettingsOption(
              icon: Icon(Icons.delete),
              title: appLocalizations.settingsDeleteStoredPassphrases,
              onTap: null,
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
  },
);
