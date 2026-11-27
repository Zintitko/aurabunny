import 'package:flutter/material.dart';

import '../../../../core/app_config.dart';
import '../../../../data/repositories/bunny_repository.dart';
import '../../../../domain/models/bunny_models.dart';
import '../../../core/l10n/bunny_strings.dart';
import '../../../core/theme/bunny_theme.dart';
import '../../../core/widgets/bunny_components.dart';
import '../../unlock/views/reward_unlock_sheet.dart';
import 'aim_trainer_screen.dart';

class AimTabView extends StatefulWidget {
  const AimTabView({super.key, required this.state});

  final BunnyAppState state;

  @override
  State<AimTabView> createState() => _AimTabViewState();
}

class _AimTabViewState extends State<AimTabView> {
  AimDrillType _selectedDrill = AimDrillType.dragHeadshot;

  @override
  void initState() {
    super.initState();
    _selectedDrill = widget.state.settings.focusDrill;
  }

  List<_DrillMeta> get _drills => [
    _DrillMeta(
      type: AimDrillType.crosshairPlacement,
      title: BunnyStrings.t('AIM BASICS'),
      badge: BunnyStrings.t('BEGINNER'),
      subtitle: BunnyStrings.t(
        'Build head-height crosshair placement with short, controlled corrections.',
      ),
      previewText: BunnyStrings.t(
        'Preview: crosshair placement on a practice dummy.',
      ),
      tip: BunnyStrings.t(
        'Keep your crosshair at head height before you peek. The smallest correction is usually the fastest one.',
      ),
      icon: Icons.gps_fixed_rounded,
      color: BunnyColors.electricBlue,
      durationSeconds: 45,
    ),
    _DrillMeta(
      type: AimDrillType.movingTargets,
      title: BunnyStrings.t('Moving Targets'),
      badge: BunnyStrings.t('INTERMEDIATE'),
      subtitle: BunnyStrings.t(
        'Track moving targets and fire only when your crosshair is centered.',
      ),
      previewText: BunnyStrings.t(
        'Preview: follow a moving target with the crosshair.',
      ),
      tip: BunnyStrings.t(
        'Follow the target smoothly, settle the crosshair at center mass, and fire with intent. Accuracy matters more than shot volume.',
      ),
      icon: Icons.track_changes_rounded,
      color: BunnyColors.cyan,
      durationSeconds: 45,
    ),
    _DrillMeta(
      type: AimDrillType.dragHeadshot,
      title: BunnyStrings.t('Drag Headshot'),
      badge: BunnyStrings.t('ADVANCED'),
      subtitle: BunnyStrings.t(
        'Chest-to-head swipe training with clear feedback.',
      ),
      previewText: BunnyStrings.t(
        'Preview: a controlled upward path from chest to head.',
      ),
      tip: BunnyStrings.t(
        'Begin on the chest marker, then hold FIRE and make one smooth upward swipe through the head. Avoid short drags, sideways drift, and over-dragging.',
      ),
      icon: Icons.swipe_up_rounded,
      color: BunnyColors.crimson,
      durationSeconds: 45,
    ),
    _DrillMeta(
      type: AimDrillType.oneTapRhythm,
      title: BunnyStrings.t('One-Tap Rhythm'),
      badge: BunnyStrings.t('3-STEP CHAIN'),
      subtitle: BunnyStrings.t('Drag, switch, and sprint sequence practice.'),
      previewText: BunnyStrings.t(
        'Preview: practice the drag, switch, and sprint sequence.',
      ),
      tip: BunnyStrings.t(
        "Bunny's practice sequence is drag first, then SWITCH and SPRINT. Its short timing windows are training cues only; timing varies by player and context.",
      ),
      icon: Icons.flash_on_rounded,
      color: BunnyColors.gold,
      durationSeconds: 45,
    ),
  ];

  void _startSelectedDrill(_DrillMeta meta) {
    if (!widget.state.canPlayAimDrill(meta.type)) {
      RewardUnlockSheet.show(context, widget.state, featureName: meta.title);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AimTrainerScreen(
          state: widget.state,
          drillType: meta.type,
          trainingStyle: widget.state.settings.trainingStyle,
          durationSeconds: meta.durationSeconds,
        ),
      ),
    );
  }

  void _startCoordination() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AimTrainerScreen(
          state: widget.state,
          drillType: AimDrillType.eyeHandCoordination,
          trainingStyle: widget.state.settings.trainingStyle,
          durationSeconds: 60,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.state.settings;
    final selectedMeta = _drills.firstWhere(
      (d) => d.type == _selectedDrill,
      orElse: () => _drills[2],
    );
    final lastRun = widget.state.latestForDrill(selectedMeta.type);
    final canPlay = widget.state.canPlayAimDrill(selectedMeta.type);

    return Scaffold(
      backgroundColor: BunnyColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            BunnyHeroBanner(
              imageAsset: 'assets/images/AimTrainingHero.png',
              eyebrow: BunnyStrings.t('AIM DRILLS'),
              title: BunnyStrings.t('Four ways to\ntrain your aim.'),
              subtitle: BunnyStrings.t(
                'Practice tracking, precision, and controlled drag sequences.',
              ),
              accentColor: BunnyColors.crimson,
              height: 190,
              trailingBadge: settings.isProUnlocked
                  ? const BunnyPillBadge(
                      label: 'PRO UNLOCKED',
                      color: BunnyColors.gold,
                      filled: true,
                    )
                  : BunnyPillBadge(
                      label: settings.freeAimSessionUsed
                          ? '${settings.rewardVideosWatched}/${AppConfig.requiredRewardVideosToUnlock} VIDEOS'
                          : BunnyStrings.t('1 free session available'),
                      color: settings.freeAimSessionUsed
                          ? BunnyColors.gold
                          : BunnyColors.emerald,
                    ),
            ),
            const SizedBox(height: 20),

            // Training Style Selector (2 STYLES)
            BunnySectionHeader(
              title: BunnyStrings.t('SELECT TRAINING STYLE'),
              accentColor: BunnyColors.crimson,
              trailing: BunnyPillBadge(
                label: BunnyStrings.t('2 STYLES'),
                color: BunnyColors.crimson,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _styleButton(
                    style: TrainingStyle.precision,
                    title: BunnyStrings.t('Precision'),
                    subtitle: BunnyStrings.t('Controlled sequences'),
                    icon: Icons.center_focus_strong_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _styleButton(
                    style: TrainingStyle.rapidDrag,
                    title: BunnyStrings.t('Rapid drag'),
                    subtitle: BunnyStrings.t('Fast Drag'),
                    icon: Icons.bolt_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 4 Aim Drills
            BunnySectionHeader(
              title: BunnyStrings.t('ALL DRILLS'),
              accentColor: BunnyColors.crimson,
              trailing: BunnyPillBadge(
                label: BunnyStrings.t('4 DRILLS'),
                color: BunnyColors.crimson,
              ),
            ),
            const SizedBox(height: 10),
            ..._drills.map((meta) {
              final isSelected = meta.type == _selectedDrill;
              final drillLast = widget.state.latestForDrill(meta.type);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: BunnyCard(
                  accentColor: isSelected ? meta.color : null,
                  onTap: () {
                    widget.state.triggerSelectionHaptic();
                    setState(() => _selectedDrill = meta.type);
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: meta.color.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: meta.color.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Icon(meta.icon, color: meta.color, size: 23),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    meta.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                BunnyPillBadge(
                                  label: meta.badge,
                                  color: meta.color,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              meta.subtitle,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontSize: 12.5),
                            ),
                            if (drillLast != null) ...[
                              const SizedBox(height: 5),
                              Text(
                                '${BunnyStrings.t('LATEST')}: ${drillLast.hits} ${BunnyStrings.t('hits')} · ${drillLast.accuracyPercent.round()}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: meta.color,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: isSelected ? meta.color : BunnyColors.textMuted,
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 8),
            // Drill Preview + Start CTA
            BunnyCard(
              accentColor: selectedMeta.color,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      BunnyPillBadge(
                        label: BunnyStrings.t('DRILL PREVIEW'),
                        color: selectedMeta.color,
                      ),
                      const Spacer(),
                      Text(
                        BunnyStrings.t('%lld SEC', [
                          selectedMeta.durationSeconds,
                        ]),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: BunnyColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    selectedMeta.previewText,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (settings.practiceTipsEnabled) ...[
                    const SizedBox(height: 6),
                    Text(
                      selectedMeta.tip,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontSize: 12.5),
                    ),
                  ],
                  if (lastRun != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: BunnyStatTile(
                            label: BunnyStrings.t('LAST HITS'),
                            value: '${lastRun.hits}',
                            accentColor: selectedMeta.color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: BunnyStatTile(
                            label: BunnyStrings.t('LAST ACCURACY'),
                            value: '${lastRun.accuracyPercent.round()}%',
                            accentColor: BunnyColors.emerald,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  BunnyPrimaryButton(
                    label: canPlay
                        ? (settings.isProUnlocked
                              ? BunnyStrings.t('START DRILL')
                              : BunnyStrings.t('Start free session'))
                        : 'Watch ${settings.remainingRewardVideos} Videos to Unlock',
                    color: canPlay ? selectedMeta.color : BunnyColors.gold,
                    foregroundColor:
                        (canPlay && selectedMeta.color != BunnyColors.gold)
                        ? Colors.white
                        : Colors.black,
                    icon: canPlay
                        ? Icons.play_arrow_rounded
                        : Icons.play_circle_fill_rounded,
                    onPressed: () => _startSelectedDrill(selectedMeta),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Always-Free Eye-Hand Coordination Lab
            BunnySectionHeader(
              title: BunnyStrings.t('REACTION LAB'),
              accentColor: BunnyColors.emerald,
              trailing: BunnyPillBadge(
                label: BunnyStrings.t('FREE'),
                color: BunnyColors.emerald,
              ),
            ),
            const SizedBox(height: 10),
            BunnyCard(
              accentColor: BunnyColors.emerald,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.adjust_rounded,
                        color: BunnyColors.crimson,
                        size: 26,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          BunnyStrings.t('Eye–Hand Coordination'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        '60s',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: BunnyColors.emerald,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    BunnyStrings.t(
                      'Practice the connection between what you see and how you respond. Focus on accurate taps, then work on speed.',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  BunnyPrimaryButton(
                    label: BunnyStrings.t('Start free training'),
                    color: BunnyColors.emerald,
                    foregroundColor: Colors.black,
                    icon: Icons.play_arrow_rounded,
                    compact: true,
                    onPressed: _startCoordination,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _styleButton({
    required TrainingStyle style,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = widget.state.settings.trainingStyle == style;
    return BunnyCard(
      padding: const EdgeInsets.all(13),
      accentColor: selected ? BunnyColors.crimson : null,
      onTap: () {
        widget.state.triggerSelectionHaptic();
        widget.state.updateSettings(
          widget.state.settings.copyWith(trainingStyle: style),
        );
      },
      child: Row(
        children: [
          Icon(
            icon,
            color: selected ? BunnyColors.crimson : BunnyColors.textMuted,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: selected
                        ? BunnyColors.textPrimary
                        : BunnyColors.textSecondary,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
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
  }
}

class _DrillMeta {
  const _DrillMeta({
    required this.type,
    required this.title,
    required this.badge,
    required this.subtitle,
    required this.previewText,
    required this.tip,
    required this.icon,
    required this.color,
    required this.durationSeconds,
  });

  final AimDrillType type;
  final String title;
  final String badge;
  final String subtitle;
  final String previewText;
  final String tip;
  final IconData icon;
  final Color color;
  final int durationSeconds;
}
