import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/app_config.dart';
import '../../../../data/repositories/bunny_repository.dart';
import '../../../core/l10n/bunny_strings.dart';
import '../../../core/theme/bunny_theme.dart';
import '../../../core/widgets/bunny_components.dart';
import '../../unlock/views/reward_unlock_sheet.dart';
import 'legal_doc_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.state});

  final BunnyAppState state;

  Future<void> _pickLanguage(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                BunnyStrings.t('App language'),
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                BunnyStrings.t('Choose the language used throughout Bunny.'),
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: BunnyStrings.supportedLanguages.map((lang) {
                    final selected = state.settings.languageCode == lang.code;
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tileColor: selected
                          ? BunnyColors.electricBlue.withValues(alpha: 0.14)
                          : null,
                      title: Text(
                        lang.nativeName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(BunnyStrings.t(lang.englishKey)),
                      trailing: selected
                          ? const Icon(
                              Icons.check_circle,
                              color: BunnyColors.electricBlue,
                            )
                          : null,
                      onTap: () async {
                        await state.updateSettings(
                          state.settings.copyWith(languageCode: lang.code),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportLocalData(BuildContext context) async {
    final jsonStr = state.buildJsonExport();
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(BunnyStrings.t('Create a local data export?')),
        content: Text(
          BunnyStrings.t(
            'Bunny will create a readable JSON file containing session dates and results plus your active Bunny configuration. It is not an import or restore file. Share it only with people or services you trust.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(BunnyStrings.t('Cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(BunnyStrings.t('Create Export')),
          ),
        ],
      ),
    );
    if (proceed != true || !context.mounted) return;

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: jsonStr,
          subject: '${AppConfig.shortName} Local Data Export (JSON)',
        ),
      );
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: jsonStr));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(BunnyStrings.t('Export shared'))),
        );
      }
    }
  }

  Future<void> _confirmResetDefaults(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(BunnyStrings.t('Restore settings defaults?')),
        content: const Text(
          'Training options will reset. Saved practice sessions will stay on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(BunnyStrings.t('Cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(BunnyStrings.t('Restore Defaults')),
          ),
        ],
      ),
    );
    if (ok == true) {
      await state.restoreSettingsDefaults();
    }
  }

  Future<void> _confirmDeleteAll(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(BunnyStrings.t('Delete all local data?')),
        content: Text(
          BunnyStrings.t(
            'Delete Bunny’s current on-device sessions and legacy records, then restore its defaults.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(BunnyStrings.t('Cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: BunnyColors.crimson,
              foregroundColor: Colors.white,
            ),
            child: Text(BunnyStrings.t('DELETE')),
          ),
        ],
      ),
    );
    if (ok == true) {
      await state.deleteAllLocalData();
      if (context.mounted) {
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([state, state.adMobService]),
      builder: (context, _) {
        final s = state.settings;
        final ads = state.adMobService;
        final currentLang = BunnyStrings.supportedLanguages.firstWhere(
          (l) => l.code == s.languageCode,
          orElse: () => BunnyStrings.supportedLanguages.first,
        );

        return Scaffold(
          backgroundColor: BunnyColors.bg,
          appBar: AppBar(title: Text(BunnyStrings.t('Settings'))),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
            children: [
              // Pro Reward Unlock Card (3 optional rewarded videos — no IAP)
              BunnyCard(
                accentColor: s.isProUnlocked
                    ? BunnyColors.emerald
                    : BunnyColors.gold,
                onTap: () => RewardUnlockSheet.show(context, state),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color:
                            (s.isProUnlocked
                                    ? BunnyColors.emerald
                                    : BunnyColors.gold)
                                .withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color:
                              (s.isProUnlocked
                                      ? BunnyColors.emerald
                                      : BunnyColors.gold)
                                  .withValues(alpha: 0.5),
                        ),
                      ),
                      child: Icon(
                        s.isProUnlocked
                            ? Icons.verified_rounded
                            : Icons.play_circle_fill_rounded,
                        color: s.isProUnlocked
                            ? BunnyColors.emerald
                            : BunnyColors.gold,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.isProUnlocked
                                ? 'PRO TRAINING UNLOCKED'
                                : 'Unlock Pro Free (${s.rewardVideosWatched}/${AppConfig.requiredRewardVideosToUnlock} videos)',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: s.isProUnlocked
                                  ? BunnyColors.emerald
                                  : BunnyColors.gold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.isProUnlocked
                                ? 'All 4 Aim drills and the 5-Finger HUD trainer are active.'
                                : 'Watch ${s.remainingRewardVideos} optional rewarded videos to unlock everything free.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: s.isProUnlocked
                          ? BunnyColors.emerald
                          : BunnyColors.gold,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Practice Settings
              BunnySectionHeader(
                title: BunnyStrings.t('Practice settings'),
                accentColor: BunnyColors.electricBlue,
              ),
              const SizedBox(height: 10),
              BunnyCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                BunnyStrings.t('Daily run goal'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                BunnyStrings.t(
                                  'Set how many Aim sessions count as a complete day.',
                                ),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        BunnyPillBadge(
                          label: BunnyStrings.t('%lld daily runs', [
                            s.dailyRunGoal,
                          ]),
                          color: BunnyColors.electricBlue,
                        ),
                      ],
                    ),
                    Slider(
                      value: s.dailyRunGoal.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      activeColor: BunnyColors.electricBlue,
                      onChanged: (v) => state.updateSettings(
                        s.copyWith(dailyRunGoal: v.round()),
                      ),
                    ),
                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(BunnyStrings.t('Training haptics')),
                      subtitle: Text(
                        BunnyStrings.t(
                          'Feel selections, confirmed hits, and completed trainer actions.',
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: s.hapticsEnabled,
                      onChanged: (v) =>
                          state.updateSettings(s.copyWith(hapticsEnabled: v)),
                    ),
                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(BunnyStrings.t('Practice tips')),
                      subtitle: Text(
                        BunnyStrings.t(
                          'Show short technique tips below each selected drill.',
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: s.practiceTipsEnabled,
                      onChanged: (v) => state.updateSettings(
                        s.copyWith(practiceTipsEnabled: v),
                      ),
                    ),
                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(BunnyStrings.t('Daily esports boost')),
                      subtitle: const Text(
                        'Show a daily practice tip card on the Home screen.',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: s.dailyBoostEnabled,
                      onChanged: (v) => state.updateSettings(
                        s.copyWith(dailyBoostEnabled: v),
                      ),
                    ),
                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(BunnyStrings.t('Keep screen awake')),
                      subtitle: Text(
                        BunnyStrings.t(
                          'Prevent the display from sleeping during full-screen drills.',
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: s.keepScreenAwake,
                      onChanged: (v) =>
                          state.updateSettings(s.copyWith(keepScreenAwake: v)),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(BunnyStrings.t('App language')),
                      subtitle: Text(currentLang.nativeName),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _pickLanguage(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Data & Setup
              BunnySectionHeader(
                title: BunnyStrings.t('Data & setup'),
                accentColor: BunnyColors.cyan,
              ),
              const SizedBox(height: 10),
              BunnyCard(
                child: Column(
                  children: [
                    if (ads.privacyOptionsRequired) ...[
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.privacy_tip_outlined,
                          color: BunnyColors.electricBlueBright,
                        ),
                        title: const Text('Ad Privacy & Consent Options'),
                        subtitle: const Text(
                          'Update your Google AdMob privacy preferences.',
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: ads.showPrivacyOptionsForm,
                      ),
                      const Divider(),
                    ],
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.ios_share_rounded,
                        color: BunnyColors.cyan,
                      ),
                      title: Text(BunnyStrings.t('Export local data')),
                      subtitle: Text(
                        BunnyStrings.t('JSON Export'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _exportLocalData(context),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.replay_rounded,
                        color: BunnyColors.electricBlueBright,
                      ),
                      title: Text(BunnyStrings.t('Replay introduction')),
                      subtitle: Text(
                        BunnyStrings.t(
                          'View the setup walkthrough again. Your saved data stays intact.',
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () async {
                        await state.replayOnboarding();
                        if (context.mounted) {
                          Navigator.of(context).popUntil((r) => r.isFirst);
                        }
                      },
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.restore_rounded,
                        color: BunnyColors.gold,
                      ),
                      title: Text(BunnyStrings.t('Restore settings defaults')),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _confirmResetDefaults(context),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.delete_forever_rounded,
                        color: BunnyColors.crimson,
                      ),
                      title: Text(
                        BunnyStrings.t('Delete all local data'),
                        style: const TextStyle(color: BunnyColors.crimson),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: BunnyColors.crimson,
                      ),
                      onTap: () => _confirmDeleteAll(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Legal & About
              BunnySectionHeader(
                title: BunnyStrings.t('About'),
                accentColor: BunnyColors.textSecondary,
              ),
              const SizedBox(height: 10),
              BunnyCard(
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.star_rate_rounded,
                        color: BunnyColors.gold,
                      ),
                      title: Text(BunnyStrings.t('Write a Review')),
                      subtitle: Text(
                        BunnyStrings.t(
                          'Rate Bunny on the App Store and share your experience.',
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                      onTap: state.reviewService.openWriteReviewPage,
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.mail_outline_rounded,
                        color: BunnyColors.electricBlueBright,
                      ),
                      title: Text(BunnyStrings.t('Support')),
                      subtitle: const Text(
                        AppConfig.supportEmail,
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.copy_rounded, size: 18),
                      onTap: () async {
                        await Clipboard.setData(
                          const ClipboardData(text: AppConfig.supportEmail),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Support email copied: ${AppConfig.supportEmail}',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(BunnyStrings.t('Privacy Policy')),
                      subtitle: Text(
                        BunnyStrings.t(
                          'How the app handles and protects your data.',
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const LegalDocScreen(
                            docType: LegalDocType.privacy,
                          ),
                        ),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(BunnyStrings.t('Terms & Conditions')),
                      subtitle: Text(
                        BunnyStrings.t('Agreement and app license'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              const LegalDocScreen(docType: LegalDocType.terms),
                        ),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(BunnyStrings.t('Open-source licenses')),
                      subtitle: Text(
                        BunnyStrings.t(
                          'Review the license included with Bunny’s bundled Poppins font.',
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const LegalDocScreen(
                            docType: LegalDocType.poppinsLicense,
                          ),
                        ),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(BunnyStrings.t('App version')),
                      trailing: Text(
                        BunnyStrings.t('Version %@ · Build %@', [
                          AppConfig.version,
                          AppConfig.buildNumber,
                        ]),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: BunnyColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
