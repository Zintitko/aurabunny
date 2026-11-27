import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/app_config.dart';
import '../../domain/models/bunny_models.dart';
import '../../ui/core/l10n/bunny_strings.dart';
import '../services/admob_service.dart';
import '../services/local_storage_service.dart';
import '../services/review_service.dart';

class BunnyAppState extends ChangeNotifier {
  BunnyAppState({LocalStorageService? storage, ReviewService? reviewService})
    : _storage = storage ?? LocalStorageService(),
      reviewService = reviewService ?? ReviewService() {
    adMobService = AdMobService(
      onRewardVideoCompleted: recordRewardVideoWatched,
    );
  }

  final LocalStorageService _storage;
  final ReviewService reviewService;
  late final AdMobService adMobService;

  bool _initialized = false;
  bool get initialized => _initialized;

  int _selectedTabIndex = 0;
  int get selectedTabIndex => _selectedTabIndex;

  AppSettings _settings = AppSettings.defaults();
  AppSettings get settings => _settings;

  List<TrainingSession> _sessions = [];
  List<TrainingSession> get sessions => List.unmodifiable(_sessions);

  SensitivityProfile _activeSensitivity = SensitivityProfile.defaultBalanced();
  SensitivityProfile get activeSensitivity => _activeSensitivity;

  List<SensitivityProfile> _savedSensitivities = [];
  List<SensitivityProfile> get savedSensitivities =>
      List.unmodifiable(_savedSensitivities);

  HudConfiguration _hudConfig = HudConfiguration.defaults();
  HudConfiguration get hudConfig => _hudConfig;

  Future<void> init() async {
    _settings = await _storage.loadSettings();
    await BunnyStrings.load(_settings.languageCode);
    _sessions = await _storage.loadSessions();
    _activeSensitivity = await _storage.loadActiveSensitivity();
    _savedSensitivities = await _storage.loadSavedSensitivities();
    _hudConfig = await _storage.loadHudConfig();
    _initialized = true;
    notifyListeners();
  }

  void setTab(int index) {
    if (_selectedTabIndex == index) return;
    _selectedTabIndex = index;
    triggerSelectionHaptic();
    notifyListeners();
  }

  void triggerSelectionHaptic() {
    if (_settings.hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  void triggerImpactHaptic({bool heavy = false}) {
    if (_settings.hapticsEnabled) {
      if (heavy) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    }
  }

  Future<void> setWakelockForDrill(bool active) async {
    if (!_settings.keepScreenAwake) return;
    try {
      if (active) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } catch (_) {
      // Ignore on unsupported platforms/tests.
    }
  }

  Future<void> updateSettings(AppSettings updated) async {
    final languageChanged = updated.languageCode != _settings.languageCode;
    _settings = updated;
    if (languageChanged) {
      await BunnyStrings.load(updated.languageCode);
    }
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> completeOnboarding({
    required ExperienceLevel experience,
    required AimDrillType focusDrill,
    required FingerSetup fingerSetup,
    required int routineMinutes,
    required int weeklyGoalDays,
  }) async {
    final effectiveHudSetup =
        (fingerSetup == FingerSetup.fiveFinger && !_settings.isProUnlocked)
        ? FingerSetup.fourFinger
        : fingerSetup;
    _hudConfig = _hudConfig.copyWith(
      fingerSetup: effectiveHudSetup,
      controls: HudConfiguration.presetControls(
        effectiveHudSetup,
        _hudConfig.spacing,
      ),
    );
    await _storage.saveHudConfig(_hudConfig);

    _settings = _settings.copyWith(
      onboardingCompleted: true,
      experienceLevel: experience,
      focusDrill: focusDrill,
      routineMinutes: routineMinutes,
      weeklyGoalDays: weeklyGoalDays,
    );
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> replayOnboarding() async {
    _settings = _settings.copyWith(onboardingCompleted: false);
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> addSession(TrainingSession session) async {
    _sessions = [session, ..._sessions];
    await _storage.saveSessions(_sessions);
    if (!_settings.isProUnlocked &&
        session.drillType != AimDrillType.eyeHandCoordination &&
        !_settings.freeAimSessionUsed) {
      _settings = _settings.copyWith(freeAimSessionUsed: true);
      await _storage.saveSettings(_settings);
    }
    notifyListeners();
  }

  Future<void> updateActiveSensitivity(SensitivityProfile profile) async {
    _activeSensitivity = profile.copyWith(updatedAt: DateTime.now());
    await _storage.saveActiveSensitivity(_activeSensitivity);
    notifyListeners();
  }

  Future<void> rollSensitivityPreset({required bool fastDrag}) async {
    final rng = Random();
    int roll() => fastDrag ? 150 + rng.nextInt(51) : 30 + rng.nextInt(51);
    await updateActiveSensitivity(
      _activeSensitivity.copyWith(
        name: fastDrag ? 'Fast Drag' : 'Precision',
        general: roll(),
        redDot: roll(),
        scope2x: roll(),
        scope4x: roll(),
        sniperScope: roll(),
        freeLook: roll(),
      ),
    );
  }

  Future<void> applyBalancedSensitivity() async {
    await updateActiveSensitivity(SensitivityProfile.defaultBalanced());
  }

  Future<void> saveSensitivityPreset(String name) async {
    final preset = _activeSensitivity.copyWith(
      id: 'preset-${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim().isEmpty ? 'Custom Setup' : name.trim(),
      updatedAt: DateTime.now(),
    );
    _savedSensitivities = [preset, ..._savedSensitivities];
    await _storage.saveSavedSensitivities(_savedSensitivities);
    notifyListeners();
  }

  Future<void> deleteSensitivityPreset(String id) async {
    _savedSensitivities = _savedSensitivities.where((p) => p.id != id).toList();
    await _storage.saveSavedSensitivities(_savedSensitivities);
    notifyListeners();
  }

  Future<void> updateHudConfig(HudConfiguration config) async {
    _hudConfig = config;
    await _storage.saveHudConfig(_hudConfig);
    notifyListeners();
  }

  Future<void> resetHudLayout() async {
    final reset = _hudConfig.copyWith(
      controlSize: 1.0,
      controlOpacity: 0.88,
      controls: HudConfiguration.presetControls(
        _hudConfig.fingerSetup,
        _hudConfig.spacing,
      ),
    );
    await updateHudConfig(reset);
  }

  Future<void> recordRewardVideoWatched() async {
    final nextCount = (_settings.rewardVideosWatched + 1).clamp(
      0,
      AppConfig.requiredRewardVideosToUnlock,
    );
    _settings = _settings.copyWith(rewardVideosWatched: nextCount);
    await _storage.saveSettings(_settings);
    triggerImpactHaptic(
      heavy: nextCount >= AppConfig.requiredRewardVideosToUnlock,
    );
    notifyListeners();
  }

  Future<void> restoreSettingsDefaults() async {
    final defaults = AppSettings.defaults().copyWith(
      onboardingCompleted: _settings.onboardingCompleted,
      languageCode: _settings.languageCode,
      rewardVideosWatched: _settings.rewardVideosWatched,
      freeAimSessionUsed: _settings.freeAimSessionUsed,
    );
    await updateSettings(defaults);
  }

  Future<void> deleteAllLocalData() async {
    await _storage.deleteAllLocalData();
    await reviewService.clearReviewHistory();
    _settings = AppSettings.defaults();
    await BunnyStrings.load('en');
    _sessions = [];
    _activeSensitivity = SensitivityProfile.defaultBalanced();
    _savedSensitivities = [];
    _hudConfig = HudConfiguration.defaults();
    _selectedTabIndex = 0;
    notifyListeners();
  }

  // Computed metrics for Home & Aim dashboards
  int get todayRunCount {
    final now = DateTime.now();
    return _sessions.where((s) {
      return s.completedAt.year == now.year &&
          s.completedAt.month == now.month &&
          s.completedAt.day == now.day;
    }).length;
  }

  int get activeDaysThisWeek {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 6));
    final days = <String>{};
    for (final s in _sessions) {
      if (!s.completedAt.isBefore(
        DateTime(cutoff.year, cutoff.month, cutoff.day),
      )) {
        days.add(
          '${s.completedAt.year}-${s.completedAt.month}-${s.completedAt.day}',
        );
      }
    }
    return days.length;
  }

  double get bestAccuracy {
    if (_sessions.isEmpty) return 0;
    return _sessions.map((s) => s.accuracyPercent).reduce(max);
  }

  int get bestHits {
    if (_sessions.isEmpty) return 0;
    return _sessions.map((s) => s.hits).reduce(max);
  }

  TrainingSession? get latestSession =>
      _sessions.isEmpty ? null : _sessions.first;

  TrainingSession? latestForDrill(AimDrillType drill) {
    for (final s in _sessions) {
      if (s.drillType == drill) return s;
    }
    return null;
  }

  bool canPlayAimDrill(AimDrillType drill) {
    if (drill == AimDrillType.eyeHandCoordination) return true;
    if (_settings.isProUnlocked) return true;
    return !_settings.freeAimSessionUsed;
  }

  String buildJsonExport() {
    final payload = {
      'app': AppConfig.appName,
      'version': AppConfig.version,
      'build': AppConfig.buildNumber,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'settings': _settings.toJson(),
      'activeSensitivity': _activeSensitivity.toJson(),
      'savedSensitivities': _savedSensitivities.map((p) => p.toJson()).toList(),
      'hudConfiguration': _hudConfig.toJson(),
      'sessions': _sessions.map((s) => s.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  @override
  void dispose() {
    adMobService.dispose();
    super.dispose();
  }
}
