import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../data/repositories/bunny_repository.dart';
import '../../../../domain/models/bunny_models.dart';
import '../../../core/l10n/bunny_strings.dart';
import '../../../core/theme/bunny_theme.dart';
import '../../../core/widgets/bunny_components.dart';

enum _SequenceStage { drag, switchWeapon, sprint }

class AimTrainerScreen extends StatefulWidget {
  const AimTrainerScreen({
    super.key,
    required this.state,
    required this.drillType,
    required this.trainingStyle,
    this.durationSeconds = 45,
  });

  final BunnyAppState state;
  final AimDrillType drillType;
  final TrainingStyle trainingStyle;
  final int durationSeconds;

  @override
  State<AimTrainerScreen> createState() => _AimTrainerScreenState();
}

class _AimTrainerScreenState extends State<AimTrainerScreen>
    with SingleTickerProviderStateMixin {
  final Random _rng = Random();
  late int _secondsLeft;
  bool _paused = false;
  bool _completed = false;

  // Metrics
  int _hits = 0;
  int _attempts = 0;
  int _chains = 0;
  int _timeouts = 0;
  final List<int> _responseTimesMs = [];
  final List<int> _chainTimesMs = [];
  String _feedbackBanner = '';
  Color _feedbackColor = BunnyColors.electricBlue;

  // Spatial positions in normalized [0..1] arena coordinates
  Offset _crosshair = const Offset(0.5, 0.56);
  Offset _targetCenter = const Offset(0.5, 0.44);
  double _targetVelocityX = 0.28;
  double _targetVelocityY = 0.06;
  int _activeWeaponSlot = 1;

  // Drag headshot trail
  final List<Offset> _dragTrail = [];
  Offset? _dragStart;
  Offset? _dragCurrent;

  // One-Tap Rhythm (Drag -> Switch -> Sprint)
  _SequenceStage _sequenceStage = _SequenceStage.drag;
  DateTime? _stageStartedAt;
  DateTime? _chainStartedAt;
  Timer? _stageTimer;

  // Eye-Hand Coordination target timer
  DateTime? _ringSpawnedAt;
  Timer? _ringTimeoutTimer;
  double _ringRemainingFraction = 1.0;

  Timer? _countdownTimer;
  Ticker? _ticker;
  Duration _lastTick = Duration.zero;

  double get _sensMultiplier {
    final g = widget.state.activeSensitivity.general;
    final styleBoost = widget.trainingStyle == TrainingStyle.rapidDrag
        ? 1.22
        : 0.92;
    return ((0.55 + (g / 200.0) * 1.15) * styleBoost).clamp(0.5, 2.0);
  }

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.durationSeconds;
    widget.state.setWakelockForDrill(true);
    _resetTargetForDrill();
    _startTimers();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _stageTimer?.cancel();
    _ringTimeoutTimer?.cancel();
    _ticker?.dispose();
    widget.state.setWakelockForDrill(false);
    super.dispose();
  }

  void _startTimers() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_paused || _completed || !mounted) return;
      if (_secondsLeft <= 1) {
        timer.cancel();
        _completeSession();
      } else {
        setState(() => _secondsLeft--);
      }
    });

    _ticker?.dispose();
    _ticker = createTicker((elapsed) {
      if (_paused || _completed) {
        _lastTick = elapsed;
        return;
      }
      final dt = (elapsed - _lastTick).inMicroseconds / 1000000.0;
      _lastTick = elapsed;
      if (dt <= 0 || dt > 0.1) return;

      if (widget.drillType == AimDrillType.movingTargets) {
        final speedFactor = widget.trainingStyle == TrainingStyle.rapidDrag
            ? 1.35
            : 0.95;
        double nx = _targetCenter.dx + _targetVelocityX * speedFactor * dt;
        double ny = _targetCenter.dy + _targetVelocityY * speedFactor * dt;
        if (nx < 0.16 || nx > 0.84) {
          _targetVelocityX = -_targetVelocityX;
          nx = nx.clamp(0.16, 0.84);
        }
        if (ny < 0.24 || ny > 0.56) {
          _targetVelocityY = -_targetVelocityY;
          ny = ny.clamp(0.24, 0.56);
        }
        setState(() => _targetCenter = Offset(nx, ny));
      } else if (widget.drillType == AimDrillType.eyeHandCoordination &&
          _ringSpawnedAt != null) {
        final ms = DateTime.now().difference(_ringSpawnedAt!).inMilliseconds;
        final frac = (1.0 - ms / 1500.0).clamp(0.0, 1.0);
        setState(() => _ringRemainingFraction = frac);
      }
    })..start();
  }

  void _resetTargetForDrill() {
    _stageTimer?.cancel();
    _ringTimeoutTimer?.cancel();
    switch (widget.drillType) {
      case AimDrillType.crosshairPlacement:
        _targetCenter = Offset(
          0.22 + _rng.nextDouble() * 0.56,
          0.32 + _rng.nextDouble() * 0.24,
        );
        _crosshair = const Offset(0.5, 0.62);
      case AimDrillType.movingTargets:
        _targetCenter = const Offset(0.5, 0.40);
        _targetVelocityX = (_rng.nextBool() ? 1 : -1) * 0.30;
        _targetVelocityY = (_rng.nextBool() ? 1 : -1) * 0.08;
        _crosshair = const Offset(0.5, 0.44);
      case AimDrillType.dragHeadshot:
        _targetCenter = Offset(0.30 + _rng.nextDouble() * 0.40, 0.42);
        _crosshair = Offset(_targetCenter.dx, _targetCenter.dy + 0.10);
      case AimDrillType.oneTapRhythm:
        _sequenceStage = _SequenceStage.drag;
        _targetCenter = Offset(0.34 + _rng.nextDouble() * 0.32, 0.42);
        _crosshair = Offset(_targetCenter.dx, _targetCenter.dy + 0.10);
      case AimDrillType.eyeHandCoordination:
        _spawnCoordinationRing();
    }
  }

  void _spawnCoordinationRing() {
    _ringTimeoutTimer?.cancel();
    _targetCenter = Offset(
      0.16 + _rng.nextDouble() * 0.68,
      0.18 + _rng.nextDouble() * 0.64,
    );
    _ringSpawnedAt = DateTime.now();
    _ringRemainingFraction = 1.0;
    _ringTimeoutTimer = Timer(const Duration(milliseconds: 1500), () {
      if (_paused || _completed || !mounted) return;
      setState(() {
        _attempts++;
        _timeouts++;
        _feedbackBanner = BunnyStrings.t('MISS');
        _feedbackColor = BunnyColors.crimson;
        _spawnCoordinationRing();
      });
    });
  }

  void _showFeedback(String text, Color color) {
    _feedbackBanner = text;
    _feedbackColor = color;
  }

  // Crosshair Placement / Moving Targets Fire Action
  void _fireAtCrosshair() {
    if (_paused || _completed) return;
    final headCenter = Offset(_targetCenter.dx, _targetCenter.dy - 0.08);
    final distHead = (_crosshair - headCenter).distance;
    final distBody = (_crosshair - _targetCenter).distance;

    setState(() {
      _attempts++;
      if (distHead <= 0.085) {
        _hits++;
        widget.state.triggerImpactHaptic(heavy: true);
        _showFeedback(BunnyStrings.t('HEADSHOT'), BunnyColors.gold);
        if (widget.drillType == AimDrillType.crosshairPlacement) {
          _resetTargetForDrill();
        }
      } else if (distBody <= 0.125) {
        _hits++;
        widget.state.triggerImpactHaptic();
        _showFeedback(BunnyStrings.t('HIT'), BunnyColors.emerald);
        if (widget.drillType == AimDrillType.crosshairPlacement) {
          _resetTargetForDrill();
        }
      } else {
        _showFeedback(BunnyStrings.t('MISS'), BunnyColors.crimson);
      }
    });
  }

  // Drag Headshot & Stage 1 of One-Tap Rhythm
  void _onDragFireEnd(Offset deltaPx) {
    if (_paused || _completed) return;
    if (widget.drillType == AimDrillType.oneTapRhythm &&
        _sequenceStage != _SequenceStage.drag) {
      return;
    }

    final upward = -deltaPx.dy * _sensMultiplier;
    final lateral = deltaPx.dx.abs();

    setState(() {
      _attempts++;
      _dragTrail.clear();
      _dragStart = null;
      _dragCurrent = null;

      if (upward < 42) {
        _showFeedback(BunnyStrings.t('TOO SHORT'), BunnyColors.amber);
      } else if (upward > 215) {
        _showFeedback(BunnyStrings.t('OVERDRAG'), BunnyColors.crimson);
      } else if (lateral > upward * 0.55) {
        _showFeedback(BunnyStrings.t('KEEP IT VERTICAL'), BunnyColors.amber);
      } else {
        _hits++;
        widget.state.triggerImpactHaptic(heavy: true);
        if (widget.drillType == AimDrillType.oneTapRhythm) {
          _showFeedback(BunnyStrings.t('SWITCH WEAPON NOW'), BunnyColors.gold);
          _sequenceStage = _SequenceStage.switchWeapon;
          _chainStartedAt = DateTime.now();
          _stageStartedAt = DateTime.now();
          _startSequenceWindowTimer(isSwitch: true);
        } else {
          _showFeedback(BunnyStrings.t('HEADSHOT'), BunnyColors.gold);
          _resetTargetForDrill();
        }
      }
    });
  }

  void _startSequenceWindowTimer({required bool isSwitch}) {
    _stageTimer?.cancel();
    final windowMs = widget.trainingStyle == TrainingStyle.rapidDrag
        ? 1100
        : 1650;
    _stageTimer = Timer(Duration(milliseconds: windowMs), () {
      if (_paused || _completed || !mounted) return;
      setState(() {
        _timeouts++;
        _showFeedback(
          isSwitch
              ? BunnyStrings.t('SWITCH WINDOW MISSED')
              : BunnyStrings.t('SPRINT WINDOW MISSED'),
          BunnyColors.crimson,
        );
        _sequenceStage = _SequenceStage.drag;
      });
    });
  }

  void _onSequenceSwitchTap() {
    if (_paused ||
        _completed ||
        _sequenceStage != _SequenceStage.switchWeapon) {
      return;
    }
    _stageTimer?.cancel();
    final ms = _stageStartedAt != null
        ? DateTime.now().difference(_stageStartedAt!).inMilliseconds
        : 250;
    widget.state.triggerImpactHaptic();
    setState(() {
      _responseTimesMs.add(ms);
      _activeWeaponSlot = _activeWeaponSlot == 1 ? 2 : 1;
      _sequenceStage = _SequenceStage.sprint;
      _stageStartedAt = DateTime.now();
      _showFeedback(
        BunnyStrings.t('SPRINT NOW'),
        BunnyColors.electricBlueBright,
      );
    });
    _startSequenceWindowTimer(isSwitch: false);
  }

  void _onSequenceSprintTap() {
    if (_paused || _completed || _sequenceStage != _SequenceStage.sprint) {
      return;
    }
    _stageTimer?.cancel();
    final now = DateTime.now();
    final stepMs = _stageStartedAt != null
        ? now.difference(_stageStartedAt!).inMilliseconds
        : 250;
    final totalChainMs = _chainStartedAt != null
        ? now.difference(_chainStartedAt!).inMilliseconds
        : 550;
    widget.state.triggerImpactHaptic(heavy: true);
    setState(() {
      _responseTimesMs.add(stepMs);
      _chainTimesMs.add(totalChainMs);
      _chains++;
      _showFeedback(
        '${BunnyStrings.t('HEADSHOT')} · ${totalChainMs}ms',
        BunnyColors.emerald,
      );
      _sequenceStage = _SequenceStage.drag;
      _resetTargetForDrill();
    });
  }

  void _onCoordinationHit() {
    if (_paused || _completed) return;
    final ms = _ringSpawnedAt != null
        ? DateTime.now().difference(_ringSpawnedAt!).inMilliseconds
        : 350;
    widget.state.triggerImpactHaptic();
    setState(() {
      _hits++;
      _attempts++;
      _responseTimesMs.add(ms);
      _showFeedback(BunnyStrings.t('%lld ms', [ms]), BunnyColors.emerald);
      _spawnCoordinationRing();
    });
  }

  void _onCoordinationMiss() {
    if (_paused || _completed) return;
    setState(() {
      _attempts++;
      _showFeedback(BunnyStrings.t('MISS'), BunnyColors.crimson);
    });
  }

  Future<void> _completeSession() async {
    _countdownTimer?.cancel();
    _stageTimer?.cancel();
    _ringTimeoutTimer?.cancel();

    int? medianMs;
    int? bestMs;
    if (_responseTimesMs.isNotEmpty) {
      final sorted = [..._responseTimesMs]..sort();
      medianMs = sorted[sorted.length ~/ 2];
      bestMs = sorted.first;
    }

    int? avgChain;
    int? fastestChain;
    if (_chainTimesMs.isNotEmpty) {
      avgChain = (_chainTimesMs.reduce((a, b) => a + b) / _chainTimesMs.length)
          .round();
      fastestChain = _chainTimesMs.reduce(min);
    }

    final session = TrainingSession(
      id: 'session-${DateTime.now().millisecondsSinceEpoch}',
      drillType: widget.drillType,
      trainingStyle: widget.trainingStyle,
      completedAt: DateTime.now(),
      durationSeconds: widget.durationSeconds,
      hits: _hits,
      attempts: _attempts,
      chains: _chains,
      timeouts: _timeouts,
      avgResponseMs: medianMs,
      bestResponseMs: bestMs,
      avgChainMs: avgChain,
      fastestChainMs: fastestChain,
    );
    await widget.state.addSession(session);
    if (!mounted) return;
    setState(() => _completed = true);

    // Politely request native Apple/Google in-app review after the results
    // screen settles (only if 2+ sessions completed and outside 60-day cooldown).
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      widget.state.reviewService.maybeRequestInAppReview(
        totalCompletedSessions: widget.state.sessions.length,
      );
    });
  }

  void _restart() {
    setState(() {
      _secondsLeft = widget.durationSeconds;
      _paused = false;
      _completed = false;
      _hits = 0;
      _attempts = 0;
      _chains = 0;
      _timeouts = 0;
      _responseTimesMs.clear();
      _chainTimesMs.clear();
      _feedbackBanner = '';
      _resetTargetForDrill();
    });
    _startTimers();
  }

  String _drillName() => switch (widget.drillType) {
    AimDrillType.crosshairPlacement => BunnyStrings.t('AIM BASICS'),
    AimDrillType.movingTargets => BunnyStrings.t('Moving Targets'),
    AimDrillType.dragHeadshot => BunnyStrings.t('Drag Headshot'),
    AimDrillType.oneTapRhythm => BunnyStrings.t('One-Tap Rhythm'),
    AimDrillType.eyeHandCoordination => BunnyStrings.t('Eye–Hand Coordination'),
  };

  @override
  Widget build(BuildContext context) {
    if (_completed) {
      return _buildCompleteSummary();
    }

    final acc = _attempts == 0 ? 0 : ((_hits / _attempts) * 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFF04060B),
      body: SafeArea(
        child: Column(
          children: [
            // Tactical HUD Top Bar + Compass
            Container(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              decoration: const BoxDecoration(
                color: BunnyColors.bgElevated,
                border: Border(
                  bottom: BorderSide(color: BunnyColors.borderSubtle),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: BunnyStrings.t('Close aim session'),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              BunnyStrings.t('NW   330   N   15   NE'),
                              style: const TextStyle(
                                fontSize: 10,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w700,
                                color: BunnyColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _drillName(),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _paused = !_paused),
                        icon: Icon(
                          _paused
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                        ),
                        tooltip: BunnyStrings.t('Pause session'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _hudChip(
                        BunnyStrings.t('TIME'),
                        '0:${_secondsLeft.toString().padLeft(2, '0')}',
                        BunnyColors.crimson,
                      ),
                      _hudChip(
                        widget.drillType == AimDrillType.oneTapRhythm
                            ? BunnyStrings.t('CHAINS')
                            : BunnyStrings.t('HITS'),
                        widget.drillType == AimDrillType.oneTapRhythm
                            ? '$_chains'
                            : '$_hits',
                        BunnyColors.gold,
                      ),
                      _hudChip(
                        BunnyStrings.t('ACCURACY'),
                        '$acc%',
                        BunnyColors.emerald,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arena Canvas
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: widget.drillType == AimDrillType.eyeHandCoordination
                        ? _buildCoordinationArena()
                        : _buildTacticalArena(),
                  ),
                  if (_feedbackBanner.isNotEmpty)
                    Positioned(
                      top: 14,
                      left: 20,
                      right: 20,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: _feedbackColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: _feedbackColor),
                          ),
                          child: Text(
                            _feedbackBanner,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                              letterSpacing: 1.0,
                              color: _feedbackColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_paused)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.8),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
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
                                      'Paused at %@. Resume when ready.',
                                      ['0:${_secondsLeft.toString().padLeft(2, '0')}'],
                                    ),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                  const SizedBox(height: 18),
                                  BunnyPrimaryButton(
                                    label: BunnyStrings.t('RESUME DRILL'),
                                    onPressed: () =>
                                        setState(() => _paused = false),
                                  ),
                                  const SizedBox(height: 10),
                                  BunnySecondaryButton(
                                    label: BunnyStrings.t('Close aim session'),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoordinationArena() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = 76.0;
        final left = (_targetCenter.dx * (constraints.maxWidth - size)).clamp(
          12.0,
          constraints.maxWidth - size - 12,
        );
        final top = (_targetCenter.dy * (constraints.maxHeight - size)).clamp(
          48.0,
          constraints.maxHeight - size - 16,
        );

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _onCoordinationMiss(),
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _ArenaGridPainter())),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Text(
                  BunnyStrings.t('Tap inside the ring within 1.5 seconds.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: BunnyColors.textMuted,
                  ),
                ),
              ),
              Positioned(
                left: left,
                top: top,
                child: GestureDetector(
                  onTapDown: (_) => _onCoordinationHit(),
                  child: SizedBox(
                    width: size,
                    height: size,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: size,
                          height: size,
                          child: CircularProgressIndicator(
                            value: _ringRemainingFraction,
                            strokeWidth: 4,
                            backgroundColor: BunnyColors.crimson.withValues(
                              alpha: 0.2,
                            ),
                            valueColor: const AlwaysStoppedAnimation(
                              BunnyColors.crimson,
                            ),
                          ),
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: BunnyColors.crimson.withValues(alpha: 0.35),
                            border: Border.all(
                              color: BunnyColors.crimson,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTacticalArena() {
    final isDragDrill =
        widget.drillType == AimDrillType.dragHeadshot ||
        widget.drillType == AimDrillType.oneTapRhythm;
    final isOneTap = widget.drillType == AimDrillType.oneTapRhythm;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final targetPx = Offset(_targetCenter.dx * w, _targetCenter.dy * h);
        final crosshairPx = Offset(_crosshair.dx * w, _crosshair.dy * h);

        return Stack(
          children: [
            // Background grid + dummy silhouette + crosshair + drag trail
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: isDragDrill
                    ? null
                    : (details) {
                        if (_paused) return;
                        setState(() {
                          _crosshair = Offset(
                            (_crosshair.dx +
                                    (details.delta.dx / w) * _sensMultiplier)
                                .clamp(0.05, 0.95),
                            (_crosshair.dy +
                                    (details.delta.dy / h) * _sensMultiplier)
                                .clamp(0.10, 0.85),
                          );
                        });
                      },
                child: CustomPaint(
                  painter: _TacticalArenaPainter(
                    targetCenter: targetPx,
                    crosshair: crosshairPx,
                    dragTrail: _dragTrail,
                    highlightHead: isDragDrill,
                  ),
                ),
              ),
            ),

            // Instruction hint
            Positioned(
              bottom: 138,
              left: 16,
              right: 16,
              child: Center(
                child: Text(
                  isOneTap
                      ? BunnyStrings.t('DRAG  →  SWITCH  →  SPRINT')
                      : isDragDrill
                      ? BunnyStrings.t('HOLD FIRE · SWIPE CHEST TO HEAD')
                      : BunnyStrings.t('DRAG TO AIM'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: BunnyColors.textSecondary,
                  ),
                ),
              ),
            ),

            // One-Tap Rhythm Switch & Sprint buttons
            if (isOneTap) ...[
              Positioned(
                left: 20,
                bottom: 28,
                child: _actionCircleButton(
                  label: '${BunnyStrings.t('SWITCH')}\nW$_activeWeaponSlot',
                  active: _sequenceStage == _SequenceStage.switchWeapon,
                  color: BunnyColors.gold,
                  onTap: _onSequenceSwitchTap,
                ),
              ),
              Positioned(
                left: 116,
                bottom: 28,
                child: _actionCircleButton(
                  label: BunnyStrings.t('SPRINT'),
                  active: _sequenceStage == _SequenceStage.sprint,
                  color: BunnyColors.electricBlueBright,
                  onTap: _onSequenceSprintTap,
                ),
              ),
            ],

            // Right Fire / Drag-Fire Control
            Positioned(
              right: 26,
              bottom: 24,
              child: GestureDetector(
                onTap: isDragDrill ? null : _fireAtCrosshair,
                onPanStart: isDragDrill
                    ? (d) {
                        if (_paused) return;
                        _dragStart = d.globalPosition;
                        _dragCurrent = d.globalPosition;
                        setState(() {
                          _dragTrail
                            ..clear()
                            ..add(targetPx + const Offset(0, 34));
                        });
                      }
                    : null,
                onPanUpdate: isDragDrill
                    ? (d) {
                        if (_paused || _dragStart == null) return;
                        _dragCurrent = d.globalPosition;
                        final delta = _dragCurrent! - _dragStart!;
                        setState(() {
                          _crosshair = Offset(
                            (_targetCenter.dx + (delta.dx / w) * 0.55).clamp(
                              0.1,
                              0.9,
                            ),
                            (_targetCenter.dy +
                                    0.10 +
                                    (delta.dy / h) * _sensMultiplier)
                                .clamp(0.08, 0.86),
                          );
                          _dragTrail.add(
                            Offset(_crosshair.dx * w, _crosshair.dy * h),
                          );
                        });
                      }
                    : null,
                onPanEnd: isDragDrill
                    ? (_) {
                        if (_dragStart != null && _dragCurrent != null) {
                          _onDragFireEnd(_dragCurrent! - _dragStart!);
                        }
                      }
                    : null,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: BunnyColors.crimson.withValues(alpha: 0.25),
                    border: Border.all(
                      color:
                          (!isOneTap || _sequenceStage == _SequenceStage.drag)
                          ? BunnyColors.crimson
                          : BunnyColors.border,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: BunnyColors.crimson.withValues(alpha: 0.35),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isDragDrill
                            ? Icons.swipe_up_rounded
                            : Icons.local_fire_department_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isDragDrill
                            ? BunnyStrings.t('DRAG')
                            : BunnyStrings.t('FIRE'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _actionCircleButton({
    required String label,
    required bool active,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 82,
        height: 82,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active
              ? color.withValues(alpha: 0.32)
              : BunnyColors.surface.withValues(alpha: 0.8),
          border: Border.all(
            color: active ? color : BunnyColors.border,
            width: active ? 3 : 1.5,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.45),
                    blurRadius: 16,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : BunnyColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _hudChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: BunnyColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: BunnyColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: BunnyColors.textMuted,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteSummary() {
    final acc = _attempts == 0 ? 0 : ((_hits / _attempts) * 100).round();
    final medianMs = _responseTimesMs.isEmpty
        ? null
        : (([..._responseTimesMs]..sort())[_responseTimesMs.length ~/ 2]);
    final bestMs = _responseTimesMs.isEmpty
        ? null
        : _responseTimesMs.reduce(min);
    final fastestChain = _chainTimesMs.isEmpty
        ? null
        : _chainTimesMs.reduce(min);

    return Scaffold(
      backgroundColor: BunnyColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BunnyPillBadge(
                label: BunnyStrings.t('DRILL COMPLETE'),
                color: BunnyColors.emerald,
                icon: Icons.check_circle_rounded,
              ),
              const SizedBox(height: 12),
              Text(
                _drillName(),
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 6),
              Text(
                BunnyStrings.t('Session saved locally.'),
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: BunnyColors.emerald),
              ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.7,
                children: [
                  BunnyStatTile(
                    label: widget.drillType == AimDrillType.oneTapRhythm
                        ? BunnyStrings.t('CHAINS')
                        : BunnyStrings.t('TARGETS HIT'),
                    value: widget.drillType == AimDrillType.oneTapRhythm
                        ? '$_chains'
                        : '$_hits',
                    accentColor: BunnyColors.gold,
                  ),
                  BunnyStatTile(
                    label: BunnyStrings.t('ACCURACY'),
                    value: '$acc%',
                    accentColor: BunnyColors.emerald,
                  ),
                  BunnyStatTile(
                    label: BunnyStrings.t('ATTEMPTS'),
                    value: '$_attempts',
                    accentColor: BunnyColors.electricBlueBright,
                  ),
                  BunnyStatTile(
                    label: fastestChain != null
                        ? BunnyStrings.t('FASTEST CHAIN')
                        : medianMs != null
                        ? BunnyStrings.t('MEDIAN RESPONSE')
                        : BunnyStrings.t('TIMEOUTS'),
                    value: fastestChain != null
                        ? '${fastestChain}ms'
                        : medianMs != null
                        ? '${medianMs}ms'
                        : '$_timeouts',
                    accentColor: BunnyColors.crimson,
                    subtitle: bestMs != null
                        ? '${BunnyStrings.t('BEST · MS')}: $bestMs'
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              BunnyCard(
                child: Text(
                  _attempts == 0
                      ? BunnyStrings.t(
                          'No attempts recorded. Your next rep is a chance to practice.',
                        )
                      : BunnyStrings.t(
                          'Review hits and accuracy after practice',
                        ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const Spacer(),
              BunnyPrimaryButton(
                label: BunnyStrings.t('RUN DRILL AGAIN'),
                color: BunnyColors.crimson,
                icon: Icons.replay_rounded,
                onPressed: () async {
                  await widget.state.adMobService
                      .recordCompletedActivityAndMaybeShowInterstitial();
                  if (mounted) _restart();
                },
              ),
              const SizedBox(height: 10),
              BunnySecondaryButton(
                label: BunnyStrings.t('Done'),
                onPressed: () async {
                  await widget.state.adMobService
                      .recordCompletedActivityAndMaybeShowInterstitial();
                  if (mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArenaGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..strokeWidth = 1;
    const step = 34.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TacticalArenaPainter extends CustomPainter {
  _TacticalArenaPainter({
    required this.targetCenter,
    required this.crosshair,
    required this.dragTrail,
    required this.highlightHead,
  });

  final Offset targetCenter;
  final Offset crosshair;
  final List<Offset> dragTrail;
  final bool highlightHead;

  @override
  void paint(Canvas canvas, Size size) {
    // Background tactical grid
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..strokeWidth = 1;
    const step = 36.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Horizon line
    canvas.drawLine(
      Offset(0, size.height * 0.48),
      Offset(size.width, size.height * 0.48),
      Paint()
        ..color = BunnyColors.electricBlue.withValues(alpha: 0.16)
        ..strokeWidth = 1.5,
    );

    // Practice dummy body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: targetCenter + const Offset(0, 26),
        width: 64,
        height: 86,
      ),
      const Radius.circular(18),
    );
    canvas.drawRRect(
      bodyRect,
      Paint()..color = BunnyColors.surfaceHighlight.withValues(alpha: 0.9),
    );
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..color = BunnyColors.electricBlue.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Chest marker
    final chestPos = targetCenter + const Offset(0, 18);
    canvas.drawCircle(
      chestPos,
      7,
      Paint()..color = BunnyColors.electricBlueBright.withValues(alpha: 0.8),
    );

    // Head target marker
    final headPos = targetCenter - const Offset(0, 36);
    canvas.drawCircle(
      headPos,
      24,
      Paint()
        ..color = (highlightHead ? BunnyColors.crimson : BunnyColors.gold)
            .withValues(alpha: 0.25),
    );
    canvas.drawCircle(
      headPos,
      22,
      Paint()
        ..color = highlightHead ? BunnyColors.crimson : BunnyColors.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawCircle(
      headPos,
      6,
      Paint()..color = highlightHead ? BunnyColors.crimson : BunnyColors.gold,
    );

    // Drag trajectory trail
    if (dragTrail.length > 1) {
      final path = Path()..moveTo(dragTrail.first.dx, dragTrail.first.dy);
      for (final pt in dragTrail.skip(1)) {
        path.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = BunnyColors.gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // Reticle / Crosshair
    final reticlePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;
    const arm = 13.0;
    const gap = 5.0;
    canvas.drawLine(
      crosshair + const Offset(-arm, 0),
      crosshair + const Offset(-gap, 0),
      reticlePaint,
    );
    canvas.drawLine(
      crosshair + const Offset(gap, 0),
      crosshair + const Offset(arm, 0),
      reticlePaint,
    );
    canvas.drawLine(
      crosshair + const Offset(0, -arm),
      crosshair + const Offset(0, -gap),
      reticlePaint,
    );
    canvas.drawLine(
      crosshair + const Offset(0, gap),
      crosshair + const Offset(0, arm),
      reticlePaint,
    );
    canvas.drawCircle(crosshair, 2.5, Paint()..color = BunnyColors.crimson);
  }

  @override
  bool shouldRepaint(covariant _TacticalArenaPainter oldDelegate) => true;
}
