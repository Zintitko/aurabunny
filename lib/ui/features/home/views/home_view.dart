import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/app_config.dart';
import '../../../../data/repositories/bunny_repository.dart';
import '../../../../domain/models/bunny_models.dart';
import '../../../core/l10n/bunny_strings.dart';
import '../../../core/theme/bunny_theme.dart';
import '../../../core/widgets/bunny_banner_ad.dart';
import '../../../core/widgets/bunny_components.dart';
import '../../aim/views/aim_trainer_screen.dart';
import '../../settings/views/settings_screen.dart';
import '../../unlock/views/reward_unlock_sheet.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key, required this.state});

  final BunnyAppState state;

  String _drillTitle(AimDrillType drill) => switch (drill) {
    AimDrillType.crosshairPlacement => BunnyStrings.t('AIM BASICS'),
    AimDrillType.movingTargets => BunnyStrings.t('Moving Targets'),
    AimDrillType.dragHeadshot => BunnyStrings.t('Drag Headshot'),
    AimDrillType.oneTapRhythm => BunnyStrings.t('One-Tap Rhythm'),
    AimDrillType.eyeHandCoordination => BunnyStrings.t('Eye–Hand Coordination'),
  };

  String _dailyTip() {
    final tips = [
      BunnyStrings.t(
        'Keep your crosshair at head height before you peek. The smallest correction is usually the fastest one.',
      ),
      BunnyStrings.t(
        'Start centered, then use one clean upward drag. Reset your thumb position after every shot.',
      ),
      BunnyStrings.t(
        'Follow the target smoothly, settle the crosshair at center mass, and fire with intent. Accuracy matters more than shot volume.',
      ),
      BunnyStrings.t(
        'Practice the connection between what you see and how you respond. Focus on accurate taps, then work on speed.',
      ),
    ];
    final dayIndex = DateTime.now().day % tips.length;
    return tips[dayIndex];
  }

  String _routineHeadline(AimDrillType drill) => switch (drill) {
    AimDrillType.crosshairPlacement => BunnyStrings.t(
      'Your precision\nroutine.',
    ).replaceAll('\n', ' '),
    AimDrillType.movingTargets => BunnyStrings.t(
      'Your tracking\nroutine.',
    ).replaceAll('\n', ' '),
    AimDrillType.dragHeadshot => BunnyStrings.t(
      'Your rapid-drag\nroutine.',
    ).replaceAll('\n', ' '),
    AimDrillType.oneTapRhythm => BunnyStrings.t(
      'Your rhythm\nroutine.',
    ).replaceAll('\n', ' '),
    AimDrillType.eyeHandCoordination => BunnyStrings.t(
      'Your practice\nroutine.',
    ).replaceAll('\n', ' '),
  };

  void _launchDrill(
    BuildContext context,
    AimDrillType drill, {
    int durationSeconds = 45,
  }) {
    if (!state.canPlayAimDrill(drill)) {
      RewardUnlockSheet.show(context, state, featureName: _drillTitle(drill));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AimTrainerScreen(
          state: state,
          drillType: drill,
          trainingStyle: state.settings.trainingStyle,
          durationSeconds: durationSeconds,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = state.settings;
    final todayRuns = state.todayRunCount;
    final goal = settings.dailyRunGoal;
    final goalProgress = (todayRuns / max(1, goal)).clamp(0.0, 1.0);
    final recentSessions = state.sessions.take(7).toList().reversed.toList();

    return Scaffold(
      backgroundColor: BunnyColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top header bar
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.asset(
                            'assets/images/AppIcon.png',
                            width: 38,
                            height: 38,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppConfig.shortName,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                BunnyStrings.t('PRECISION · CONTROL · RHYTHM'),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                  color: BunnyColors.electricBlueBright,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!settings.isProUnlocked)
                          InkWell(
                            onTap: () => RewardUnlockSheet.show(context, state),
                            borderRadius: BorderRadius.circular(999),
                            child: BunnyPillBadge(
                              label:
                                  'PRO ${settings.rewardVideosWatched}/${AppConfig.requiredRewardVideosToUnlock}',
                              color: BunnyColors.gold,
                              icon: Icons.play_circle_fill_rounded,
                              filled: true,
                            ),
                          )
                        else
                          BunnyPillBadge(
                            label: 'PRO UNLOCKED',
                            color: BunnyColors.gold,
                            icon: Icons.verified_rounded,
                          ),
                        const SizedBox(width: 6),
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => SettingsScreen(state: state),
                              ),
                            );
                          },
                          icon: const Icon(Icons.settings_outlined),
                          tooltip: BunnyStrings.t('Settings'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Hero banner
                    BunnyHeroBanner(
                      imageAsset: 'assets/images/BunnyHero.png',
                      eyebrow: BunnyStrings.t('YOUR ROUTINE'),
                      title: _routineHeadline(settings.focusDrill),
                      subtitle: BunnyStrings.t(
                        '%lld minutes. One clear focus.',
                        [settings.routineMinutes],
                      ),
                      accentColor: BunnyColors.electricBlue,
                      height: 200,
                      bottomChild: Row(
                        children: [
                          Expanded(
                            child: BunnyPrimaryButton(
                              label: BunnyStrings.t('START DRILL'),
                              icon: Icons.play_arrow_rounded,
                              compact: true,
                              onPressed: () =>
                                  _launchDrill(context, settings.focusDrill),
                            ),
                          ),
                          const SizedBox(width: 10),
                          BunnySecondaryButton(
                            label: BunnyStrings.t('WARM-UP'),
                            compact: true,
                            expanded: false,
                            borderColor: BunnyColors.crimson.withValues(
                              alpha: 0.7,
                            ),
                            foregroundColor: BunnyColors.crimson,
                            icon: Icons.bolt_rounded,
                            onPressed: () => _launchDrill(
                              context,
                              AimDrillType.eyeHandCoordination,
                              durationSeconds: 30,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Daily Goal & Progress Dashboard
                    BunnySectionHeader(
                      title: BunnyStrings.t('YOUR PROGRESS'),
                      accentColor: BunnyColors.electricBlue,
                      trailing: BunnyPillBadge(
                        label: BunnyStrings.t('GOAL %lld', [goal]),
                        color: BunnyColors.electricBlue,
                      ),
                    ),
                    const SizedBox(height: 10),
                    BunnyCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  BunnyStrings.t('Daily Goal'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                              ),
                              Text(
                                '$todayRuns / $goal',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: BunnyColors.electricBlueBright,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: goalProgress,
                              minHeight: 8,
                              backgroundColor: BunnyColors.surfaceHighlight,
                              valueColor: const AlwaysStoppedAnimation(
                                BunnyColors.electricBlue,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: BunnyStatTile(
                                  label: BunnyStrings.t('TOTAL RUNS'),
                                  value: '${state.sessions.length}',
                                  accentColor: BunnyColors.electricBlueBright,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: BunnyStatTile(
                                  label: BunnyStrings.t('BEST ACCURACY'),
                                  value: state.sessions.isEmpty
                                      ? '--'
                                      : '${state.bestAccuracy.round()}%',
                                  accentColor: BunnyColors.emerald,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: BunnyStatTile(
                                  label: BunnyStrings.t('PERSONAL BEST'),
                                  value: state.sessions.isEmpty
                                      ? '--'
                                      : '${state.bestHits}',
                                  accentColor: BunnyColors.gold,
                                ),
                              ),
                            ],
                          ),
                          if (recentSessions.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              BunnyStrings.t('SESSION INSIGHTS'),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 92,
                              child: _AccuracyBarChart(
                                sessions: recentSessions,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Free Eye-Hand Coordination 60s Card
                    BunnySectionHeader(
                      title: BunnyStrings.t('YOUR FREE TRAINING'),
                      accentColor: BunnyColors.crimson,
                      trailing: BunnyPillBadge(
                        label: BunnyStrings.t('FREE'),
                        color: BunnyColors.emerald,
                      ),
                    ),
                    const SizedBox(height: 10),
                    BunnyCard(
                      accentColor: BunnyColors.crimson,
                      onTap: () => _launchDrill(
                        context,
                        AimDrillType.eyeHandCoordination,
                        durationSeconds: 60,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: BunnyColors.crimson.withValues(
                                alpha: 0.18,
                              ),
                              border: Border.all(
                                color: BunnyColors.crimson,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.adjust_rounded,
                              color: BunnyColors.crimson,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  BunnyStrings.t('REACTION LAB'),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.1,
                                    color: BunnyColors.crimson,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  BunnyStrings.t('Eye–Hand Coordination'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  BunnyStrings.t('60-second warm-up'),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.play_circle_fill_rounded,
                            color: BunnyColors.crimson,
                            size: 36,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Practice Tools Shortcuts
                    BunnySectionHeader(
                      title: BunnyStrings.t('PRACTICE TOOLS AVAILABLE'),
                      accentColor: BunnyColors.gold,
                    ),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.35,
                      children: [
                        _shortcutCard(
                          context,
                          title: BunnyStrings.t('Aim Training'),
                          subtitle: BunnyStrings.t('4 DRILLS'),
                          icon: Icons.gps_fixed_rounded,
                          color: BunnyColors.crimson,
                          onTap: () => state.setTab(1),
                        ),
                        _shortcutCard(
                          context,
                          title: BunnyStrings.t('Custom HUD'),
                          subtitle: BunnyStrings.t('5 CONTROL ZONES'),
                          icon: Icons.gamepad_rounded,
                          color: BunnyColors.gold,
                          onTap: () => state.setTab(2),
                        ),
                        _shortcutCard(
                          context,
                          title: BunnyStrings.t('Sensitivity lab'),
                          subtitle: BunnyStrings.t('General sensitivity %lld', [
                            state.activeSensitivity.general,
                          ]),
                          icon: Icons.tune_rounded,
                          color: BunnyColors.violet,
                          onTap: () => state.setTab(3),
                        ),
                        _shortcutCard(
                          context,
                          title: BunnyStrings.t('Device tools'),
                          subtitle: BunnyStrings.t('LIVE READINGS'),
                          icon: Icons.memory_rounded,
                          color: BunnyColors.cyan,
                          onTap: () => state.setTab(4),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Practice Tip / Daily Esports Boost Card
                    if (settings.practiceTipsEnabled ||
                        settings.dailyBoostEnabled)
                      BunnyCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.lightbulb_outline_rounded,
                              color: BunnyColors.gold,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    settings.dailyBoostEnabled
                                        ? BunnyStrings.t('Daily esports boost')
                                              .toUpperCase()
                                        : BunnyStrings.t('PRACTICE TIP'),
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.0,
                                      color: BunnyColors.gold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _dailyTip(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!settings.isProUnlocked)
                      BunnyBannerAd(adMobService: state.adMobService),
                    const SizedBox(height: 14),
                    Center(
                      child: Text(
                        BunnyStrings.t(
                          'Bunny practice only · Does not access, control, or modify another app.',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          color: BunnyColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shortcutCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return BunnyCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccuracyBarChart extends StatelessWidget {
  const _AccuracyBarChart({required this.sessions});

  final List<TrainingSession> sessions;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: sessions.asMap().entries.map((entry) {
        final s = entry.value;
        final pct = s.accuracyPercent.clamp(8, 100) / 100.0;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${s.accuracyPercent.round()}%',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: BunnyColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: pct,
                      widthFactor: 0.72,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: const LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              BunnyColors.electricBlue,
                              BunnyColors.electricBlueBright,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '#${entry.key + 1}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: BunnyColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
