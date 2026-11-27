import 'package:flutter/material.dart';

import '../../../../core/app_config.dart';
import '../../../../data/repositories/bunny_repository.dart';
import '../../../../domain/models/bunny_models.dart';
import '../../../core/l10n/bunny_strings.dart';
import '../../../core/theme/bunny_theme.dart';
import '../../../core/widgets/bunny_components.dart';
import '../../unlock/views/reward_unlock_sheet.dart';

class HudTabView extends StatefulWidget {
  const HudTabView({super.key, required this.state});

  final BunnyAppState state;

  @override
  State<HudTabView> createState() => _HudTabViewState();
}

class _HudTabViewState extends State<HudTabView> {
  String? _selectedControlId;
  bool _showEmulatorSheet = false;

  void _selectFingerSetup(FingerSetup setup) {
    widget.state.triggerSelectionHaptic();
    final cfg = widget.state.hudConfig;
    widget.state.updateHudConfig(
      cfg.copyWith(
        fingerSetup: setup,
        controls: HudConfiguration.presetControls(setup, cfg.spacing),
      ),
    );
  }

  void _selectSpacing(FiveFingerSpacing spacing) {
    widget.state.triggerSelectionHaptic();
    final cfg = widget.state.hudConfig;
    widget.state.updateHudConfig(
      cfg.copyWith(
        spacing: spacing,
        controls: HudConfiguration.presetControls(cfg.fingerSetup, spacing),
      ),
    );
  }

  void _openPlayground() {
    final cfg = widget.state.hudConfig;
    if (cfg.fingerSetup == FingerSetup.fiveFinger &&
        !widget.state.settings.isProUnlocked) {
      RewardUnlockSheet.show(
        context,
        widget.state,
        featureName: BunnyStrings.t('Five-finger HUD'),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _HudPlaygroundScreen(state: widget.state),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.state.hudConfig;
    final isFiveFinger = cfg.fingerSetup == FingerSetup.fiveFinger;
    final isFiveLocked = isFiveFinger && !widget.state.settings.isProUnlocked;

    return Scaffold(
      backgroundColor: BunnyColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            BunnyHeroBanner(
              imageAsset: 'assets/images/HUDYellowBanner.png',
              eyebrow: BunnyStrings.t('FIVE-FINGER HUD LAB'),
              title: BunnyStrings.t('Build your HUD.\nTrain every finger.'),
              subtitle: BunnyStrings.t(
                'Choose your grip, fine-tune your controls, and preview your layout before you train.',
              ),
              accentColor: BunnyColors.gold,
              height: 190,
            ),
            const SizedBox(height: 18),

            // Finger Layout Selector
            BunnySectionHeader(
              title: BunnyStrings.t('YOUR CONTROLS'),
              accentColor: BunnyColors.gold,
              trailing: BunnyPillBadge(
                label: BunnyStrings.t('5 CONTROL ZONES'),
                color: BunnyColors.gold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _fingerTab(FingerSetup.twoFinger, '2F'),
                const SizedBox(width: 8),
                _fingerTab(FingerSetup.threeFinger, '3F'),
                const SizedBox(width: 8),
                _fingerTab(FingerSetup.fourFinger, '4F'),
                const SizedBox(width: 8),
                _fingerTab(FingerSetup.fiveFinger, '5F PRO', isPro: true),
              ],
            ),
            if (isFiveFinger) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _spacingChip(
                      FiveFingerSpacing.compact,
                      BunnyStrings.t('Compact'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _spacingChip(
                      FiveFingerSpacing.balanced,
                      BunnyStrings.t('Balanced'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _spacingChip(
                      FiveFingerSpacing.wide,
                      BunnyStrings.t('Wide'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),

            // Interactive Draggable HUD Preview Canvas
            BunnyCard(
              padding: const EdgeInsets.all(12),
              accentColor: BunnyColors.gold,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        BunnyStrings.t('Drag to adjust'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: BunnyColors.gold,
                        ),
                      ),
                      const Spacer(),
                      if (isFiveLocked)
                        BunnyPillBadge(
                          label:
                              '${widget.state.settings.rewardVideosWatched}/${AppConfig.requiredRewardVideosToUnlock} VIDEOS',
                          color: BunnyColors.gold,
                        )
                      else
                        Text(
                          BunnyStrings.t('LEFT 3 · RIGHT 2'),
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: BunnyColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF05080F),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: BunnyColors.border),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final w = constraints.maxWidth;
                            final h = constraints.maxHeight;
                            final baseBtnSize = 44.0 * cfg.controlSize;
                            return Stack(
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _HudGridPainter(),
                                  ),
                                ),
                                // Center crosshair reference
                                const Center(
                                  child: Icon(
                                    Icons.add_rounded,
                                    color: Colors.white24,
                                    size: 22,
                                  ),
                                ),
                                ...cfg.controls.map((ctrl) {
                                  final size = ctrl.isPrimary
                                      ? baseBtnSize * 1.12
                                      : baseBtnSize * 0.9;
                                  final left = (ctrl.x * w - size / 2).clamp(
                                    4.0,
                                    w - size - 4,
                                  );
                                  final top = (ctrl.y * h - size / 2).clamp(
                                    4.0,
                                    h - size - 4,
                                  );
                                  final isSelected =
                                      _selectedControlId == ctrl.id;
                                  final zoneColor = _colorForZone(
                                    ctrl.fingerZone,
                                  );

                                  return Positioned(
                                    left: left,
                                    top: top,
                                    child: GestureDetector(
                                      onTap: () {
                                        widget.state.triggerSelectionHaptic();
                                        setState(
                                          () => _selectedControlId = ctrl.id,
                                        );
                                      },
                                      onPanUpdate: (details) {
                                        final nx =
                                            ((ctrl.x * w + details.delta.dx) /
                                                    w)
                                                .clamp(0.06, 0.94);
                                        final ny =
                                            ((ctrl.y * h + details.delta.dy) /
                                                    h)
                                                .clamp(0.10, 0.90);
                                        final updated = cfg.controls
                                            .map(
                                              (c) => c.id == ctrl.id
                                                  ? c.copyWith(x: nx, y: ny)
                                                  : c,
                                            )
                                            .toList();
                                        widget.state.updateHudConfig(
                                          cfg.copyWith(controls: updated),
                                        );
                                        setState(
                                          () => _selectedControlId = ctrl.id,
                                        );
                                      },
                                      child: Opacity(
                                        opacity: cfg.controlOpacity,
                                        child: Container(
                                          width: size,
                                          height: size,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: zoneColor.withValues(
                                              alpha: isSelected ? 0.42 : 0.22,
                                            ),
                                            border: Border.all(
                                              color: isSelected
                                                  ? Colors.white
                                                  : zoneColor,
                                              width: isSelected ? 2.2 : 1.5,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              BunnyStrings.t(ctrl.labelKey),
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Finger Zone Legend
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _zoneLegend(
                        BunnyStrings.t('L MIDDLE'),
                        BunnyColors.crimson,
                      ),
                      _zoneLegend(BunnyStrings.t('L INDEX'), BunnyColors.gold),
                      _zoneLegend(
                        BunnyStrings.t('L THUMB'),
                        BunnyColors.electricBlue,
                      ),
                      _zoneLegend(
                        BunnyStrings.t('R INDEX'),
                        BunnyColors.violet,
                      ),
                      _zoneLegend(
                        BunnyStrings.t('R THUMB'),
                        BunnyColors.emerald,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Size & Opacity Controls
            BunnyCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        BunnyStrings.t('CONTROL SIZE'),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const Spacer(),
                      Text(
                        '${(cfg.controlSize * 100).round()}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: BunnyColors.gold,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: cfg.controlSize,
                    min: 0.7,
                    max: 1.35,
                    activeColor: BunnyColors.gold,
                    onChanged: (v) => widget.state.updateHudConfig(
                      cfg.copyWith(controlSize: v),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        BunnyStrings.t('CONTROL OPACITY'),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const Spacer(),
                      Text(
                        '${(cfg.controlOpacity * 100).round()}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: BunnyColors.gold,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: cfg.controlOpacity,
                    min: 0.35,
                    max: 1.0,
                    activeColor: BunnyColors.gold,
                    onChanged: (v) => widget.state.updateHudConfig(
                      cfg.copyWith(controlOpacity: v),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: BunnySecondaryButton(
                          label: BunnyStrings.t('RESET'),
                          compact: true,
                          onPressed: () {
                            widget.state.triggerSelectionHaptic();
                            widget.state.resetHudLayout();
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: BunnyPrimaryButton(
                          label: BunnyStrings.t('Save my layout'),
                          color: BunnyColors.gold,
                          foregroundColor: Colors.black,
                          compact: true,
                          onPressed: () {
                            widget.state.triggerImpactHaptic();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(BunnyStrings.t('Saved locally.')),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Launch Interactive HUD Trainer
            BunnyPrimaryButton(
              label: isFiveLocked
                  ? 'Watch ${widget.state.settings.remainingRewardVideos} Videos to Unlock 5F Trainer'
                  : BunnyStrings.t('START LANDSCAPE HUD TRAINER'),
              color: BunnyColors.gold,
              foregroundColor: Colors.black,
              icon: isFiveLocked
                  ? Icons.play_circle_fill_rounded
                  : Icons.sports_esports_rounded,
              onPressed: _openPlayground,
            ),
            const SizedBox(height: 18),

            // Emulator / Keybind Reference Section
            BunnyCard(
              onTap: () =>
                  setState(() => _showEmulatorSheet = !_showEmulatorSheet),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.keyboard_rounded,
                        color: BunnyColors.electricBlueBright,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              BunnyStrings.t(
                                'Five-finger HUD & emulator references',
                              ),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              BunnyStrings.t(
                                'Keyboard and mouse layouts, including side buttons',
                              ),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _showEmulatorSheet
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                      ),
                    ],
                  ),
                  if (_showEmulatorSheet) ...[
                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 10),
                    ..._emulatorBindings().map(
                      (pair) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                pair.$1,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: BunnyColors.textSecondary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: BunnyColors.bgElevated,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: BunnyColors.border),
                              ),
                              child: Text(
                                pair.$2,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: BunnyColors.electricBlueBright,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              BunnyStrings.t(
                'These controls exist only inside Bunny’s practice trainer. They do not access, control, or change another app.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: BunnyColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<(String, String)> _emulatorBindings() => [
    (BunnyStrings.t('Move'), BunnyStrings.t('W / A / S / D')),
    (BunnyStrings.t('Primary fire'), BunnyStrings.t('Left click')),
    (BunnyStrings.t('Scope / ADS'), BunnyStrings.t('Right click')),
    (
      BunnyStrings.t('Jump + crouch'),
      '${BunnyStrings.t('Space')} / ${BunnyStrings.t('C')}',
    ),
    (BunnyStrings.t('Reload'), BunnyStrings.t('R')),
    (BunnyStrings.t('Interact / revive'), BunnyStrings.t('F')),
    (BunnyStrings.t('Wall'), BunnyStrings.t('Mouse 4')),
    (BunnyStrings.t('Sprint'), BunnyStrings.t('Mouse 5')),
    (BunnyStrings.t('Weapon 1'), BunnyStrings.t('Scroll up')),
    (BunnyStrings.t('Weapon 2'), BunnyStrings.t('Scroll down')),
    (BunnyStrings.t('Melee'), BunnyStrings.t('Scroll wheel click')),
    (BunnyStrings.t('Heal'), BunnyStrings.t('V')),
    (BunnyStrings.t('Backpack'), BunnyStrings.t('Tab')),
  ];

  Color _colorForZone(String zone) => switch (zone) {
    'L MIDDLE' => BunnyColors.crimson,
    'L INDEX' => BunnyColors.gold,
    'L THUMB' => BunnyColors.electricBlue,
    'R INDEX' => BunnyColors.violet,
    _ => BunnyColors.emerald,
  };

  Widget _zoneLegend(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _fingerTab(FingerSetup setup, String label, {bool isPro = false}) {
    final selected = widget.state.hudConfig.fingerSetup == setup;
    return Expanded(
      child: InkWell(
        onTap: () => _selectFingerSetup(setup),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? BunnyColors.gold.withValues(alpha: 0.2)
                : BunnyColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? BunnyColors.gold : BunnyColors.border,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected
                  ? BunnyColors.gold
                  : isPro
                  ? BunnyColors.goldBright
                  : BunnyColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _spacingChip(FiveFingerSpacing spacing, String label) {
    final selected = widget.state.hudConfig.spacing == spacing;
    return InkWell(
      onTap: () => _selectSpacing(spacing),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? BunnyColors.electricBlue.withValues(alpha: 0.2)
              : BunnyColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? BunnyColors.electricBlue : BunnyColors.border,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected
                ? BunnyColors.electricBlueBright
                : BunnyColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _HudPlaygroundScreen extends StatefulWidget {
  const _HudPlaygroundScreen({required this.state});

  final BunnyAppState state;

  @override
  State<_HudPlaygroundScreen> createState() => _HudPlaygroundScreenState();
}

class _HudPlaygroundScreenState extends State<_HudPlaygroundScreen> {
  final Set<String> _activeZones = {};
  int _completedHolds = 0;
  bool _completed = false;

  void _onZoneDown(String zone) {
    widget.state.triggerImpactHaptic();
    setState(() {
      _activeZones.add(zone);
      if (_completedHolds < 10) {
        _completedHolds++;
      }
      if (_completedHolds >= 10) {
        _completed = true;
      }
    });
  }

  void _onZoneUp(String zone) {
    setState(() => _activeZones.remove(zone));
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.state.hudConfig;
    return Scaffold(
      backgroundColor: const Color(0xFF04060B),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: BunnyStrings.t('Back to HUD setup'),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          BunnyStrings.t('ALL FIVE AT ONCE'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: BunnyColors.gold,
                          ),
                        ),
                        Text(
                          BunnyStrings.t(
                            '%lld of 5 zones active, %lld of 10 holds completed',
                            [_activeZones.length, _completedHolds],
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            color: BunnyColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _completedHolds = 0;
                      _completed = false;
                    }),
                    child: Text(BunnyStrings.t('RESET')),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _completed
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: BunnyCard(
                          accentColor: BunnyColors.gold,
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                color: BunnyColors.gold,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                BunnyStrings.t('PLAYGROUND COMPLETE'),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                BunnyStrings.t('Train every finger.'),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 18),
                              BunnyPrimaryButton(
                                label: BunnyStrings.t('PLAY AGAIN'),
                                color: BunnyColors.gold,
                                foregroundColor: Colors.black,
                                onPressed: () async {
                                  await widget.state.adMobService
                                      .recordCompletedActivityAndMaybeShowInterstitial();
                                  if (mounted) {
                                    setState(() {
                                      _completedHolds = 0;
                                      _completed = false;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 10),
                              BunnySecondaryButton(
                                label: BunnyStrings.t('Back to HUD setup'),
                                onPressed: () async {
                                  await widget.state.adMobService
                                      .recordCompletedActivityAndMaybeShowInterstitial();
                                  if (context.mounted) Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final h = constraints.maxHeight;
                        final baseSize = 68.0 * cfg.controlSize;
                        return Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(painter: _HudGridPainter()),
                            ),
                            ...cfg.controls.map((ctrl) {
                              final size = ctrl.isPrimary
                                  ? baseSize * 1.1
                                  : baseSize * 0.9;
                              final left = (ctrl.x * w - size / 2).clamp(
                                8.0,
                                w - size - 8,
                              );
                              final top = (ctrl.y * h - size / 2).clamp(
                                8.0,
                                h - size - 8,
                              );
                              final active = _activeZones.contains(
                                ctrl.fingerZone,
                              );
                              return Positioned(
                                left: left,
                                top: top,
                                child: Listener(
                                  onPointerDown: (_) =>
                                      _onZoneDown(ctrl.fingerZone),
                                  onPointerUp: (_) =>
                                      _onZoneUp(ctrl.fingerZone),
                                  onPointerCancel: (_) =>
                                      _onZoneUp(ctrl.fingerZone),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 100),
                                    width: size,
                                    height: size,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          (active
                                                  ? BunnyColors.gold
                                                  : BunnyColors.electricBlue)
                                              .withValues(
                                                alpha: active ? 0.55 : 0.22,
                                              ),
                                      border: Border.all(
                                        color: active
                                            ? Colors.white
                                            : BunnyColors.gold,
                                        width: active ? 3 : 2,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          BunnyStrings.t(ctrl.labelKey),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          ctrl.fingerZone,
                                          style: const TextStyle(
                                            fontSize: 8.5,
                                            color: BunnyColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HudGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..strokeWidth = 1;
    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
