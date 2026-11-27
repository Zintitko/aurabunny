import 'package:flutter/material.dart';

import '../../../../core/app_config.dart';
import '../../../../data/repositories/bunny_repository.dart';
import '../../../../data/services/admob_service.dart';
import '../../../core/l10n/bunny_strings.dart';
import '../../../core/theme/bunny_theme.dart';
import '../../../core/widgets/bunny_components.dart';
import '../../settings/views/legal_doc_screen.dart';

/// Voluntary 3-Rewarded-Video Pro Unlock Sheet.
///
/// AdMob & Apple App Store Policy Compliant:
/// - Clear upfront disclosure of the 3-video requirement & exact unlock reward
/// - 100% opt-in: user explicitly taps to watch each individual video
/// - Never auto-chains videos back-to-back (includes brief pacing cooldown)
/// - Saves progress persistently after every completed video (1/3 -> 2/3 -> 3/3)
/// - Always provides an escape hatch back to free training
class RewardUnlockSheet extends StatefulWidget {
  const RewardUnlockSheet({super.key, required this.state, this.featureName});

  final BunnyAppState state;
  final String? featureName;

  static Future<void> show(
    BuildContext context,
    BunnyAppState state, {
    String? featureName,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: BunnyColors.bg,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.92,
        child: RewardUnlockSheet(state: state, featureName: featureName),
      ),
    );
  }

  @override
  State<RewardUnlockSheet> createState() => _RewardUnlockSheetState();
}

class _RewardUnlockSheetState extends State<RewardUnlockSheet> {
  @override
  void initState() {
    super.initState();
    final ads = widget.state.adMobService;
    if (ads.rewardState == RewardAdLoadState.idle ||
        ads.rewardState == RewardAdLoadState.unavailable) {
      ads.loadRewardedAd();
    }
  }

  void _openLegal(LegalDocType type) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LegalDocScreen(docType: type)),
    );
  }

  Future<void> _watchNextVideo() async {
    final earned = await widget.state.adMobService.showRewardedAd();
    if (!mounted) return;
    if (earned && widget.state.settings.isProUnlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All Pro Aim drills & 5-Finger HUD unlocked!'),
          backgroundColor: BunnyColors.surfaceHighlight,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.state, widget.state.adMobService]),
      builder: (context, _) {
        final settings = widget.state.settings;
        final ads = widget.state.adMobService;
        final total = AppConfig.requiredRewardVideosToUnlock;
        final watched = settings.rewardVideosWatched;
        final unlocked = settings.isProUnlocked;
        final nextStep = (watched + 1).clamp(1, total);

        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
                child: Row(
                  children: [
                    BunnyPillBadge(
                      label: unlocked
                          ? 'PRO UNLOCKED'
                          : 'REWARD UNLOCK · $watched/$total',
                      color: BunnyColors.gold,
                      icon: Icons.play_circle_fill_rounded,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: BunnyStrings.t('Done'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                  children: [
                    BunnyHeroBanner(
                      imageAsset: 'assets/images/HUDYellowBanner.png',
                      eyebrow: BunnyStrings.t('FULL AIM ACCESS'),
                      title: unlocked
                          ? 'Pro Training Unlocked'
                          : 'Unlock Free With Videos',
                      subtitle: unlocked
                          ? 'Every Aim drill and the Five-Finger HUD playground are unlocked on this device.'
                          : widget.featureName != null
                          ? 'Watch $total short optional videos (one at a time) to unlock ${widget.featureName!} and all Pro drills.'
                          : 'Watch $total short optional videos (one at a time) to unlock all 4 Aim drills and the Five-Finger HUD trainer.',
                      accentColor: BunnyColors.gold,
                      height: 178,
                    ),
                    const SizedBox(height: 16),

                    // 3-Step Persistent Progress Tracker
                    BunnyCard(
                      accentColor: unlocked
                          ? BunnyColors.emerald
                          : BunnyColors.gold,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'UNLOCK PROGRESS',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: unlocked
                                          ? BunnyColors.emerald
                                          : BunnyColors.gold,
                                    ),
                              ),
                              const Spacer(),
                              Text(
                                '$watched / $total videos watched',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: unlocked
                                      ? BunnyColors.emerald
                                      : BunnyColors.gold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: List.generate(total, (i) {
                              final done = i < watched;
                              final isCurrent = i == watched && !unlocked;
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: i < total - 1 ? 8 : 0,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: done
                                          ? BunnyColors.emerald.withValues(
                                              alpha: 0.18,
                                            )
                                          : isCurrent
                                          ? BunnyColors.gold.withValues(
                                              alpha: 0.15,
                                            )
                                          : BunnyColors.bgElevated,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: done
                                            ? BunnyColors.emerald
                                            : isCurrent
                                            ? BunnyColors.gold
                                            : BunnyColors.border,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          done
                                              ? Icons.check_circle_rounded
                                              : Icons.ondemand_video_rounded,
                                          color: done
                                              ? BunnyColors.emerald
                                              : isCurrent
                                              ? BunnyColors.gold
                                              : BunnyColors.textMuted,
                                          size: 22,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Video ${i + 1}',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: done
                                                ? BunnyColors.emerald
                                                : isCurrent
                                                ? BunnyColors.gold
                                                : BunnyColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            unlocked
                                ? 'All 3 videos completed. Pro access is active on this device.'
                                : 'Your progress is saved after every completed video. You can pause and finish anytime.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // What unlocks
                    BunnyCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INCLUDED IN PRO UNLOCK',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: BunnyColors.gold),
                          ),
                          const SizedBox(height: 10),
                          _benefitRow(BunnyStrings.t('All 4 aim trainers')),
                          _benefitRow(
                            BunnyStrings.t(
                              'Five-finger HUD & emulator references',
                            ),
                          ),
                          _benefitRow(
                            BunnyStrings.t(
                              'Precision & Rapid Drag training styles',
                            ),
                          ),
                          _benefitRow(
                            BunnyStrings.t('Eye–Hand Coordination stays free.'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    if (unlocked)
                      BunnyPrimaryButton(
                        label: BunnyStrings.t('Done'),
                        color: BunnyColors.emerald,
                        foregroundColor: Colors.black,
                        icon: Icons.check_rounded,
                        onPressed: () => Navigator.pop(context),
                      )
                    else if (!ads.isSupportedPlatform) ...[
                      BunnyCard(
                        child: Text(
                          'Rewarded video ads are available on iOS and Android devices.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ] else if (ads.rewardState ==
                        RewardAdLoadState.loading) ...[
                      BunnyPrimaryButton(
                        label: 'Loading video ad…',
                        color: BunnyColors.surfaceHighlight,
                        foregroundColor: BunnyColors.textSecondary,
                        onPressed: null,
                      ),
                    ] else if (ads.rewardState == RewardAdLoadState.ready) ...[
                      BunnyPrimaryButton(
                        label: ads.isInCooldown
                            ? 'Ready in ${ads.cooldownSecondsRemaining}s…'
                            : 'Watch Video ($nextStep/$total)',
                        color: BunnyColors.gold,
                        foregroundColor: Colors.black,
                        icon: Icons.play_arrow_rounded,
                        onPressed: ads.isInCooldown ? null : _watchNextVideo,
                      ),
                    ] else ...[
                      BunnyPrimaryButton(
                        label: 'Try Loading Video Again',
                        color: BunnyColors.gold,
                        foregroundColor: Colors.black,
                        icon: Icons.refresh_rounded,
                        onPressed: ads.loadRewardedAd,
                      ),
                    ],

                    if (ads.statusMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        ads.statusMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: BunnyColors.goldBright,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          BunnyStrings.t('Continue with free training'),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => _openLegal(LegalDocType.privacy),
                          child: Text(
                            BunnyStrings.t('Privacy Policy'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: BunnyColors.textSecondary,
                            ),
                          ),
                        ),
                        const Text(
                          '·',
                          style: TextStyle(color: BunnyColors.textMuted),
                        ),
                        TextButton(
                          onPressed: () => _openLegal(LegalDocType.terms),
                          child: Text(
                            BunnyStrings.t('Terms of Use'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: BunnyColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'No purchase required. Rewarded videos are served by Google AdMob and are always optional.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 11,
                        color: BunnyColors.textMuted,
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

  Widget _benefitRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.check_circle_rounded,
              size: 16,
              color: BunnyColors.gold,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13.5))),
        ],
      ),
    );
  }
}
