import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/app_config.dart';
import '../../../core/l10n/bunny_strings.dart';
import '../../../core/theme/bunny_theme.dart';
import '../../../core/widgets/bunny_components.dart';

enum LegalDocType { privacy, terms, poppinsLicense }

class LegalDocScreen extends StatelessWidget {
  const LegalDocScreen({super.key, required this.docType});

  final LegalDocType docType;

  @override
  Widget build(BuildContext context) {
    final title = switch (docType) {
      LegalDocType.privacy => BunnyStrings.t('Privacy Policy'),
      LegalDocType.terms => BunnyStrings.t('Terms & Conditions'),
      LegalDocType.poppinsLicense => BunnyStrings.t('Open-source licenses'),
    };

    return Scaffold(
      backgroundColor: BunnyColors.bg,
      appBar: AppBar(title: Text(title)),
      body: docType == LegalDocType.poppinsLicense
          ? FutureBuilder<String>(
              future: rootBundle.loadString('assets/licenses/Poppins-OFL.txt'),
              builder: (context, snapshot) {
                final text =
                    snapshot.data ??
                    BunnyStrings.t(
                      'The bundled Poppins license file could not be loaded.',
                    );
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: BunnyCard(
                    child: SelectableText(
                      text,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: BunnyColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            )
          : ListView(
              padding: const EdgeInsets.all(18),
              children: docType == LegalDocType.privacy
                  ? _privacySections(context)
                  : _termsSections(context),
            ),
    );
  }

  List<Widget> _privacySections(BuildContext context) {
    final items = [
      (
        BunnyStrings.t('Privacy at Bunny'),
        'This Privacy Policy explains how ${AppConfig.appName} handles information on your device. Provider: ${AppConfig.developerName} (${AppConfig.supportEmail}). Full online policy: ${AppConfig.privacyPolicyUrl}',
      ),
      (
        BunnyStrings.t('Local training and preference data'),
        'Practice sessions, HUD layouts, sensitivity presets, language preferences, and rewarded-video unlock progress are stored locally on your device. ${AppConfig.appName} has no account system and does not upload your practice records to a developer server.',
      ),
      (
        'Advertising & Google AdMob',
        '${AppConfig.appName} is free to use and displays optional rewarded video ads, frequency-capped interstitial ads at natural post-session breaks, and non-intrusive banner ads powered by Google AdMob. On iOS, we ask for your permission via Apple App Tracking Transparency (ATT) before requesting personalized ads. If you decline tracking, Google AdMob serves non-personalized ads. In regions requiring consent (such as the EEA and UK), you can update your ad privacy choices anytime from Settings.',
      ),
      (
        BunnyStrings.t('Device and network readings'),
        'Device readings are processed locally inside ${AppConfig.shortName} and are not sent to its developer. The optional TLS estimate contacts www.apple.com, so Apple and network providers receive normal connection metadata. ${AppConfig.shortName} does not save the TLS result.',
      ),
      (
        BunnyStrings.t('Retention and deletion'),
        'You can export your local training JSON summary or permanently delete all local data and reset preferences from Settings at any time. You may also revoke ad tracking permission in iOS Settings → Privacy & Security → Tracking.',
      ),
    ];

    return [
      BunnyPillBadge(
        label: '${AppConfig.shortName.toUpperCase()} · LOCAL FIRST',
        color: BunnyColors.electricBlue,
      ),
      const SizedBox(height: 8),
      Text(
        BunnyStrings.t('Effective September 18, 2026'),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 16),
      ...items.map(
        (item) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: BunnyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.$1, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                SelectableText(
                  item.$2,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _termsSections(BuildContext context) {
    final items = [
      (
        BunnyStrings.t('What Bunny provides'),
        '${AppConfig.appName} is an independent, on-device esports practice and setup companion. It provides touch-practice simulations, Aim drills, local progress history, HUD and sensitivity presets, and device-information tools. ${AppConfig.shortName} does not connect to, read from, modify, automate, or promise compatibility with any external game.',
      ),
      (
        BunnyStrings.t('Apple Standard EULA'),
        BunnyStrings.t(
          'Apple’s Standard End User License Agreement (“Standard EULA”) governs the license to the downloaded app unless a different license is presented by Apple. These Terms supplement the Standard EULA for Bunny’s features. If they conflict, the Standard EULA controls the app license. Mandatory consumer rights under applicable law remain unaffected.',
        ),
      ),
      (
        'Rewarded Video Feature Unlocks',
        '${AppConfig.appName} contains no paid subscriptions or in-app purchases. Advanced training features (unlimited Aim drills and the Five-Finger HUD playground) can be unlocked for free by voluntarily watching ${AppConfig.requiredRewardVideosToUnlock} rewarded video ads served by Google AdMob. Each completed video saves progress locally on your device.',
      ),
      (
        BunnyStrings.t('Training and device-information disclaimer'),
        BunnyStrings.t(
          'Bunny is a practice aid, not a guarantee of rank, accuracy, competitive results, device performance, network quality, or success in any game. Results in Bunny are touch-practice measurements and may not reproduce the physics, latency, controls, or scoring of another app.',
        ),
      ),
      (
        BunnyStrings.t('Support'),
        'For questions regarding these Terms or ${AppConfig.appName}, contact ${AppConfig.developerName} at ${AppConfig.supportEmail}. Privacy Policy: ${AppConfig.privacyPolicyUrl}',
      ),
    ];

    return [
      BunnyPillBadge(
        label: '${AppConfig.shortName.toUpperCase()} · FAIR USE',
        color: BunnyColors.gold,
      ),
      const SizedBox(height: 8),
      Text(
        BunnyStrings.t('Effective September 18, 2026'),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 16),
      ...items.map(
        (item) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: BunnyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.$1, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                SelectableText(
                  item.$2,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }
}
