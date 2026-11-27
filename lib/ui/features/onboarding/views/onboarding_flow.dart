import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/app_config.dart';
import '../../../../data/repositories/bunny_repository.dart';
import '../../../../domain/models/bunny_models.dart';
import '../../../core/l10n/bunny_strings.dart';
import '../../../core/theme/bunny_theme.dart';
import '../../../core/widgets/bunny_components.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key, required this.state});

  final BunnyAppState state;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _step = 0; // 0: Welcome, 1: Experience, 2: Focus, 3: Fingers, 4: Goal, 5: Warm-up, 6: Ready
  ExperienceLevel _experience = ExperienceLevel.intermediate;
  AimDrillType _focusDrill = AimDrillType.dragHeadshot;
  FingerSetup _fingerSetup = FingerSetup.fourFinger;
  int _routineMinutes = 10;
  int _weeklyDays = 5;

  // Embedded 30-second warm-up state
  bool _warmupActive = false;
  bool _warmupCompleted = false;
  bool _warmupPaused = false;
  int _warmupSecondsLeft = 30;
  int _warmupHits = 0;
  int _warmupAttempts = 0;
  final List<int> _reactionTimesMs = [];
  DateTime? _targetSpawnedAt;
  Offset _targetNormalizedPos = const Offset(0.5, 0.5);
  Timer? _countdownTimer;
  Timer? _targetTimeoutTimer;
  final Random _rng = Random();

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _targetTimeoutTimer?.cancel();
    super.dispose();
  }

  void _startWarmup() {
    widget.state.triggerImpactHaptic();
    setState(() {
      _warmupActive = true;
      _warmupCompleted = false;
      _warmupPaused = false;
      _warmupSecondsLeft = 30;
      _warmupHits = 0;
      _warmupAttempts = 0;
      _reactionTimesMs.clear();
    });
    _spawnWarmupTarget();
    _startWarmupTimers();
  }

  void _startWarmupTimers() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_warmupPaused || !mounted) return;
      if (_warmupSecondsLeft <= 1) {
        timer.cancel();
        _finishWarmup();
      } else {
        setState(() => _warmupSecondsLeft--);
      }
    });
  }

  void _spawnWarmupTarget() {
    _targetTimeoutTimer?.cancel();
    setState(() {
      _targetNormalizedPos = Offset(
        0.16 + _rng.nextDouble() * 0.68,
        0.18 + _rng.nextDouble() * 0.64,
      );
      _targetSpawnedAt = DateTime.now();
    });
    _targetTimeoutTimer = Timer(const Duration(milliseconds: 1700), () {
      if (!_warmupActive || _warmupPaused || !mounted) return;
      setState(() => _warmupAttempts++);
      _spawnWarmupTarget();
    });
  }

  void _onWarmupTargetTap() {
    if (_warmupPaused) return;
    final elapsed = _targetSpawnedAt != null
        ? DateTime.now().difference(_targetSpawnedAt!).inMilliseconds
        : 450;
    widget.state.triggerImpactHaptic();
    setState(() {
      _warmupHits++;
      _warmupAttempts++;
      _reactionTimesMs.add(elapsed);
    });
    _spawnWarmupTarget();
  }

  void _onWarmupMissTap() {
    if (_warmupPaused) return;
    setState(() => _warmupAttempts++);
  }

  void _finishWarmup() {
    _countdownTimer?.cancel();
    _targetTimeoutTimer?.cancel();
    final medianMs = _medianResponseMs();
    final bestMs = _reactionTimesMs.isEmpty
        ? null
        : _reactionTimesMs.reduce(min);
    widget.state.addSession(
      TrainingSession(
        id: 'warmup-${DateTime.now().millisecondsSinceEpoch}',
        drillType: AimDrillType.eyeHandCoordination,
        trainingStyle: TrainingStyle.precision,
        completedAt: DateTime.now(),
        durationSeconds: 30,
        hits: _warmupHits,
        attempts: _warmupAttempts,
        avgResponseMs: medianMs,
        bestResponseMs: bestMs,
      ),
    );
    setState(() {
      _warmupActive = false;
      _warmupCompleted = true;
    });
  }

  int? _medianResponseMs() {
    if (_reactionTimesMs.isEmpty) return null;
    final sorted = [..._reactionTimesMs]..sort();
    return sorted[sorted.length ~/ 2];
  }

  Future<void> _confirmLeaveWarmup() async {
    setState(() => _warmupPaused = true);
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(BunnyStrings.t('Leave this warm-up?')),
        content: Text(
          BunnyStrings.t(
            'Your timer is paused. Leaving discards this short sample and returns to your routine.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(BunnyStrings.t('Keep warm-up')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: BunnyColors.crimson),
            child: Text(BunnyStrings.t('Leave warm-up')),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (leave == true) {
      _countdownTimer?.cancel();
      _targetTimeoutTimer?.cancel();
      setState(() {
        _warmupActive = false;
        _warmupPaused = false;
      });
    } else {
      setState(() => _warmupPaused = false);
    }
  }

  Future<void> _showLanguageSheet() async {
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
                BunnyStrings.t('Choose your language'),
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: BunnyStrings.supportedLanguages.map((lang) {
                    final selected =
                        widget.state.settings.languageCode == lang.code;
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
                        await widget.state.updateSettings(
                          widget.state.settings.copyWith(
                            languageCode: lang.code,
                          ),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) setState(() {});
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

  Future<void> _finishOnboarding({required bool openAimTab}) async {
    await widget.state.completeOnboarding(
      experience: _experience,
      focusDrill: _focusDrill,
      fingerSetup: _fingerSetup,
      routineMinutes: _routineMinutes,
      weeklyGoalDays: _weeklyDays,
    );
    if (openAimTab) {
      widget.state.setTab(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_warmupActive) {
      return _buildWarmupArena();
    }

    return Scaffold(
      backgroundColor: BunnyColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            if (_step > 0) _buildProgressHeader(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: KeyedSubtree(
                  key: ValueKey('step-$_step-$_warmupCompleted'),
                  child: switch (_step) {
                    0 => _buildWelcomeStep(),
                    1 => _buildExperienceStep(),
                    2 => _buildFocusStep(),
                    3 => _buildFingerStep(),
                    4 => _buildScheduleStep(),
                    5 =>
                      _warmupCompleted
                          ? _buildWarmupResultStep()
                          : _buildWarmupPromptStep(),
                    _ => _buildReadyStep(),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    final progress = (_step / 6).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => setState(() => _step = (_step - 1).clamp(0, 6)),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            tooltip: BunnyStrings.t('Back'),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: BunnyColors.surfaceHighlight,
                valueColor: const AlwaysStoppedAnimation(
                  BunnyColors.electricBlue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text('$_step / 6', style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 360,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/OnboardingHero.png',
                fit: BoxFit.cover,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      BunnyColors.bg.withValues(alpha: 0.2),
                      BunnyColors.bg.withValues(alpha: 0.85),
                      BunnyColors.bg,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/BunnyLaunchLogo.png',
                      width: 42,
                      height: 42,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppConfig.appName.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: BunnyColors.electricBlueBright),
                    ),
                  ),
                  InkWell(
                    onTap: _showLanguageSheet,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: BunnyColors.surface.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: BunnyColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.language_rounded,
                            size: 16,
                            color: BunnyColors.electricBlueBright,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            BunnyStrings.currentCode.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              BunnyPillBadge(
                label: BunnyStrings.t('INDEPENDENT PRACTICE SIMULATOR'),
                color: BunnyColors.electricBlue,
              ),
              const SizedBox(height: 14),
              Text(
                BunnyStrings.t('PRACTICE. ADAPT.\nIMPROVE.'),
                style: Theme.of(context).textTheme.displayLarge
                    ?.copyWith(fontSize: 34, letterSpacing: -0.5),
              ),
              const SizedBox(height: 10),
              Text(
                BunnyStrings.t('A training routine built around you.'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: BunnyColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                BunnyStrings.t(
                  'Bunny is an independent practice simulator and is not affiliated with or endorsed by any game publisher. Its trainers run only inside Bunny and do not access, control, or change another app.',
                ),
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontSize: 12, color: BunnyColors.textMuted),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: BunnyColors.electricBlueBright,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    BunnyStrings.t('About 2 minutes to get set up'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              BunnyPrimaryButton(
                label: BunnyStrings.t('Get started'),
                icon: Icons.arrow_forward_rounded,
                onPressed: () {
                  widget.state.triggerSelectionHaptic();
                  setState(() => _step = 1);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExperienceStep() {
    final options = [
      (
        ExperienceLevel.beginner,
        BunnyStrings.t('New to aim training'),
        BunnyStrings.t('Guide me through the basics'),
        Icons.flag_rounded,
      ),
      (
        ExperienceLevel.intermediate,
        BunnyStrings.t('I train sometimes'),
        BunnyStrings.t('Help me find a routine'),
        Icons.bolt_rounded,
      ),
      (
        ExperienceLevel.experienced,
        BunnyStrings.t('I have a routine'),
        BunnyStrings.t('Keep the guidance brief'),
        Icons.military_tech_rounded,
      ),
    ];

    return _buildSelectionScaffold(
      eyebrow: BunnyStrings.t('YOUR STARTING POINT'),
      title: BunnyStrings.t('Where are\nyou starting?'),
      subtitle: BunnyStrings.t('We’ll match the guidance to your experience.'),
      accent: BunnyColors.electricBlue,
      children: options.map((opt) {
        final selected = _experience == opt.$1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: BunnyCard(
            accentColor: selected ? BunnyColors.electricBlue : null,
            onTap: () {
              widget.state.triggerSelectionHaptic();
              setState(() => _experience = opt.$1);
            },
            child: Row(
              children: [
                _iconBox(
                  opt.$4,
                  selected ? BunnyColors.electricBlue : BunnyColors.textMuted,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opt.$2,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        opt.$3,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                _radioCircle(selected, BunnyColors.electricBlue),
              ],
            ),
          ),
        );
      }).toList(),
      ctaLabel: BunnyStrings.t('Continue'),
      onContinue: () => setState(() => _step = 2),
    );
  }

  Widget _buildFocusStep() {
    final options = [
      (
        AimDrillType.crosshairPlacement,
        BunnyStrings.t('AIM BASICS'),
        BunnyStrings.t("We'll start with controlled target placement."),
        Icons.gps_fixed_rounded,
        BunnyColors.electricBlue,
      ),
      (
        AimDrillType.movingTargets,
        BunnyStrings.t('Moving Targets'),
        BunnyStrings.t("We'll put moving-target practice first."),
        Icons.track_changes_rounded,
        BunnyColors.cyan,
      ),
      (
        AimDrillType.dragHeadshot,
        BunnyStrings.t('Drag Headshot'),
        BunnyStrings.t("We'll practice a controlled upward drag."),
        Icons.swipe_up_rounded,
        BunnyColors.crimson,
      ),
      (
        AimDrillType.oneTapRhythm,
        BunnyStrings.t('One-Tap Rhythm'),
        BunnyStrings.t("We'll work through a deliberate action sequence."),
        Icons.flash_on_rounded,
        BunnyColors.gold,
      ),
    ];

    return _buildSelectionScaffold(
      eyebrow: BunnyStrings.t('YOUR FOCUS'),
      title: BunnyStrings.t('What do you want\nto sharpen?'),
      subtitle: BunnyStrings.t('Choose the focus for your first routine.'),
      accent: BunnyColors.crimson,
      children: options.map((opt) {
        final selected = _focusDrill == opt.$1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: BunnyCard(
            accentColor: selected ? opt.$5 : null,
            onTap: () {
              widget.state.triggerSelectionHaptic();
              setState(() => _focusDrill = opt.$1);
            },
            child: Row(
              children: [
                _iconBox(opt.$4, opt.$5),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opt.$2,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        opt.$3,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                _radioCircle(selected, opt.$5),
              ],
            ),
          ),
        );
      }).toList(),
      ctaLabel: BunnyStrings.t('Continue'),
      onContinue: () => setState(() => _step = 3),
    );
  }

  Widget _buildFingerStep() {
    final options = [
      (
        FingerSetup.twoFinger,
        '2-Finger Thumbs',
        BunnyStrings.t('Included for free'),
        false,
      ),
      (
        FingerSetup.threeFinger,
        '3-Finger Hybrid',
        BunnyStrings.t('Included for free'),
        false,
      ),
      (
        FingerSetup.fourFinger,
        '4-Finger Claw',
        BunnyStrings.t('Included for free'),
        false,
      ),
      (
        FingerSetup.fiveFinger,
        BunnyStrings.t('Five-finger claw'),
        BunnyStrings.t('LEFT 3 · RIGHT 2'),
        true,
      ),
    ];

    return _buildSelectionScaffold(
      eyebrow: BunnyStrings.t('YOUR SETUP'),
      title: BunnyStrings.t('How do\nyou play?'),
      subtitle: BunnyStrings.t('Choose your usual finger setup.'),
      accent: BunnyColors.gold,
      children: [
        ...options.map((opt) {
          final selected = _fingerSetup == opt.$1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: BunnyCard(
              accentColor: selected ? BunnyColors.gold : null,
              onTap: () {
                widget.state.triggerSelectionHaptic();
                setState(() => _fingerSetup = opt.$1);
              },
              child: Row(
                children: [
                  _iconBox(
                    opt.$4 ? Icons.pan_tool_rounded : Icons.touch_app_rounded,
                    opt.$4 ? BunnyColors.gold : BunnyColors.electricBlue,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                opt.$2,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            if (opt.$4) ...[
                              const SizedBox(width: 8),
                              BunnyPillBadge(
                                label: BunnyStrings.t('PRO'),
                                color: BunnyColors.gold,
                                filled: true,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          opt.$3,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  _radioCircle(selected, BunnyColors.gold),
                ],
              ),
            ),
          );
        }),
        if (_fingerSetup == FingerSetup.fiveFinger)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Five-finger claw unlocks free after watching 3 optional rewarded videos. Your starter layout uses four fingers.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontSize: 12, color: BunnyColors.goldBright),
            ),
          ),
      ],
      ctaLabel: BunnyStrings.t('Continue'),
      onContinue: () => setState(() => _step = 4),
    );
  }

  Widget _buildScheduleStep() {
    final weeklyMinutes = _routineMinutes * _weeklyDays;
    return _buildSelectionScaffold(
      eyebrow: BunnyStrings.t('YOUR WEEK'),
      title: BunnyStrings.t('Give your routine\na rhythm.'),
      subtitle: BunnyStrings.t('How much time feels right for you?'),
      accent: BunnyColors.violet,
      children: [
        BunnyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                BunnyStrings.t('Routine length'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                BunnyStrings.t(
                  'Pick the option that fits how long you want to train.',
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              Row(
                children: [5, 10, 15].map((mins) {
                  final selected = _routineMinutes == mins;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () {
                          widget.state.triggerSelectionHaptic();
                          setState(() => _routineMinutes = mins);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: selected
                                ? BunnyColors.violet.withValues(alpha: 0.22)
                                : BunnyColors.bgElevated,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? BunnyColors.violet
                                  : BunnyColors.border,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '$mins',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? BunnyColors.violetBright
                                      : BunnyColors.textPrimary,
                                ),
                              ),
                              Text(
                                BunnyStrings.t('%lld min', [
                                  mins,
                                ]).replaceAll('$mins ', ''),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: BunnyColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        BunnyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      BunnyStrings.t('Weekly practice goal'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  BunnyPillBadge(
                    label: BunnyStrings.t('%lld days per week', [_weeklyDays]),
                    color: BunnyColors.electricBlue,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: _weeklyDays.toDouble(),
                min: 1,
                max: 7,
                divisions: 6,
                activeColor: BunnyColors.electricBlue,
                onChanged: (v) {
                  setState(() => _weeklyDays = v.round());
                },
              ),
              Text(
                BunnyStrings.t('About %lld minutes a week', [weeklyMinutes]),
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: BunnyColors.electricBlueBright),
              ),
              const SizedBox(height: 2),
              Text(
                BunnyStrings.t('Adjust your goal anytime'),
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontSize: 12, color: BunnyColors.textMuted),
              ),
            ],
          ),
        ),
      ],
      ctaLabel: BunnyStrings.t('Build my routine'),
      onContinue: () => setState(() => _step = 5),
    );
  }

  Widget _buildWarmupPromptStep() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BunnyPillBadge(
            label: BunnyStrings.t('BUNNY / QUICK WARM-UP'),
            color: BunnyColors.crimson,
          ),
          const SizedBox(height: 14),
          Text(
            BunnyStrings.t('Start with\na solid warm-up.'),
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 8),
          Text(
            BunnyStrings.t('30 seconds. Just tap.'),
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: BunnyColors.crimson),
          ),
          const SizedBox(height: 18),
          BunnyCard(
            accentColor: BunnyColors.crimson,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: BunnyColors.crimson.withValues(alpha: 0.2),
                        border: Border.all(
                          color: BunnyColors.crimson,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.adjust_rounded,
                        color: BunnyColors.crimson,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            BunnyStrings.t('Eye–Hand Coordination'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            BunnyStrings.t('30 seconds'),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  BunnyStrings.t(
                    'A red target appears. Tap it, then find the next. Each tap is a chance to get comfortable.',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  BunnyStrings.t(
                    'Tap each red target before it disappears. No score to beat.',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: BunnyColors.textMuted, fontSize: 12.5),
                ),
              ],
            ),
          ),
          const Spacer(),
          BunnyPrimaryButton(
            label: BunnyStrings.t('Try the 30-second warm-up'),
            color: BunnyColors.crimson,
            icon: Icons.play_arrow_rounded,
            onPressed: _startWarmup,
          ),
          const SizedBox(height: 10),
          BunnySecondaryButton(
            label: BunnyStrings.t('Skip for now'),
            onPressed: () => setState(() => _step = 6),
          ),
        ],
      ),
    );
  }

  Widget _buildWarmupArena() {
    final accuracy = _warmupAttempts == 0
        ? 0
        : ((_warmupHits / _warmupAttempts) * 100).round();
    return Scaffold(
      backgroundColor: const Color(0xFF04060B),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _confirmLeaveWarmup,
                    icon: const Icon(Icons.close_rounded),
                    tooltip: BunnyStrings.t('Exit warm-up'),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '0:${_warmupSecondsLeft.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: BunnyColors.crimson,
                          ),
                        ),
                        Text(
                          '${BunnyStrings.t('HITS')} $_warmupHits · $accuracy%',
                          style: const TextStyle(
                            fontSize: 11,
                            color: BunnyColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        setState(() => _warmupPaused = !_warmupPaused),
                    icon: Icon(
                      _warmupPaused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                    ),
                    tooltip: BunnyStrings.t('Pause warm-up'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final targetSize = 66.0;
                  final left =
                      (_targetNormalizedPos.dx *
                              (constraints.maxWidth - targetSize))
                          .clamp(8.0, constraints.maxWidth - targetSize - 8);
                  final top =
                      (_targetNormalizedPos.dy *
                              (constraints.maxHeight - targetSize))
                          .clamp(8.0, constraints.maxHeight - targetSize - 8);

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (_) => _onWarmupMissTap(),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(painter: _GridPainter()),
                        ),
                        Positioned(
                          left: left,
                          top: top,
                          child: GestureDetector(
                            onTapDown: (_) => _onWarmupTargetTap(),
                            child: Container(
                              width: targetSize,
                              height: targetSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: BunnyColors.crimson.withValues(
                                  alpha: 0.28,
                                ),
                                border: Border.all(
                                  color: BunnyColors.crimson,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: BunnyColors.crimson.withValues(
                                      alpha: 0.55,
                                    ),
                                    blurRadius: 18,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: BunnyColors.crimson,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_warmupPaused)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.78),
                              child: Center(
                                child: BunnyCard(
                                  padding: const EdgeInsets.all(22),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        BunnyStrings.t('SESSION PAUSED'),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        BunnyStrings.t(
                                          'Your timer is paused. Resume when you are ready.',
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 18),
                                      BunnyPrimaryButton(
                                        label: BunnyStrings.t('Resume warm-up'),
                                        onPressed: () => setState(
                                          () => _warmupPaused = false,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarmupResultStep() {
    final acc = _warmupAttempts == 0
        ? 0
        : ((_warmupHits / _warmupAttempts) * 100).round();
    final median = _medianResponseMs();
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BunnyPillBadge(
            label: BunnyStrings.t('YOUR FIRST RESULT'),
            color: BunnyColors.emerald,
          ),
          const SizedBox(height: 14),
          Text(
            BunnyStrings.t('Your first rep.\nDone.'),
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 8),
          Text(
            BunnyStrings.t('A short snapshot of your practice.'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: BunnyStatTile(
                  label: BunnyStrings.t('TARGETS HIT'),
                  value: '$_warmupHits',
                  accentColor: BunnyColors.crimson,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: BunnyStatTile(
                  label: BunnyStrings.t('ACCURACY'),
                  value: '$acc%',
                  accentColor: BunnyColors.emerald,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: BunnyStatTile(
                  label: BunnyStrings.t('MEDIAN RESPONSE'),
                  value: median != null ? '${median}ms' : '--',
                  accentColor: BunnyColors.electricBlueBright,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          BunnyCard(
            child: Text(
              BunnyStrings.t(
                'A starting snapshot. Your next rep is a chance to practice.',
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const Spacer(),
          BunnyPrimaryButton(
            label: BunnyStrings.t('Build on this'),
            onPressed: () => setState(() => _step = 6),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyStep() {
    final routineTitle = switch (_focusDrill) {
      AimDrillType.crosshairPlacement => BunnyStrings.t(
        'Your precision\nroutine.',
      ),
      AimDrillType.movingTargets => BunnyStrings.t('Your tracking\nroutine.'),
      AimDrillType.dragHeadshot => BunnyStrings.t('Your rapid-drag\nroutine.'),
      AimDrillType.oneTapRhythm => BunnyStrings.t('Your rhythm\nroutine.'),
      AimDrillType.eyeHandCoordination => BunnyStrings.t(
        'Your practice\nroutine.',
      ),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BunnyPillBadge(
            label: BunnyStrings.t('YOUR PRACTICE ROUTINE'),
            color: BunnyColors.electricBlue,
          ),
          const SizedBox(height: 14),
          Text(
            BunnyStrings.t('You’re in.\nLet’s make it count.'),
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 16),
          BunnyHeroBanner(
            imageAsset: 'assets/images/BunnyHero.png',
            eyebrow: BunnyStrings.t('MADE FOR YOUR FOCUS'),
            title: routineTitle,
            subtitle: BunnyStrings.t('Based on your %lld-minute routine.', [
              _routineMinutes,
            ]),
            accentColor: BunnyColors.electricBlue,
            height: 185,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: BunnyStatTile(
                  label: BunnyStrings.t('YOUR TIME'),
                  value: BunnyStrings.t('%lld min', [_routineMinutes]),
                  accentColor: BunnyColors.electricBlueBright,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: BunnyStatTile(
                  label: BunnyStrings.t('YOUR WEEK'),
                  value: '$_weeklyDays d/wk',
                  accentColor: BunnyColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            BunnyStrings.t('Your setup and weekly goal are saved.'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          BunnyPrimaryButton(
            label: BunnyStrings.t('Start my first session'),
            icon: Icons.play_arrow_rounded,
            onPressed: () => _finishOnboarding(openAimTab: true),
          ),
          const SizedBox(height: 10),
          BunnySecondaryButton(
            label: BunnyStrings.t('Explore Bunny first'),
            onPressed: () => _finishOnboarding(openAimTab: false),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionScaffold({
    required String eyebrow,
    required String title,
    required String subtitle,
    required Color accent,
    required List<Widget> children,
    required String ctaLabel,
    required VoidCallback onContinue,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BunnyPillBadge(label: eyebrow, color: accent),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: 6),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          Expanded(child: ListView(children: children)),
          const SizedBox(height: 12),
          BunnyPrimaryButton(
            label: ctaLabel,
            color: accent,
            foregroundColor: accent == BunnyColors.gold
                ? Colors.black
                : Colors.white,
            onPressed: () {
              widget.state.triggerSelectionHaptic();
              onContinue();
            },
          ),
        ],
      ),
    );
  }

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _radioCircle(bool selected, Color color) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? color : BunnyColors.border,
          width: 2,
        ),
        color: selected ? color : Colors.transparent,
      ),
      child: selected
          ? Icon(
              Icons.check,
              size: 14,
              color: color == BunnyColors.gold ? Colors.black : Colors.white,
            )
          : null,
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    const step = 36.0;
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
