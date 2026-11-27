import '../../core/app_config.dart';

enum AimDrillType {
  crosshairPlacement,
  movingTargets,
  dragHeadshot,
  oneTapRhythm,
  eyeHandCoordination,
}

enum TrainingStyle { precision, rapidDrag }

enum ExperienceLevel { beginner, intermediate, experienced }

enum FingerSetup { twoFinger, threeFinger, fourFinger, fiveFinger }

enum FiveFingerSpacing { compact, balanced, wide }

class TrainingSession {
  const TrainingSession({
    required this.id,
    required this.drillType,
    required this.trainingStyle,
    required this.completedAt,
    required this.durationSeconds,
    required this.hits,
    required this.attempts,
    this.chains = 0,
    this.timeouts = 0,
    this.avgResponseMs,
    this.bestResponseMs,
    this.avgChainMs,
    this.fastestChainMs,
  });

  final String id;
  final AimDrillType drillType;
  final TrainingStyle trainingStyle;
  final DateTime completedAt;
  final int durationSeconds;
  final int hits;
  final int attempts;
  final int chains;
  final int timeouts;
  final int? avgResponseMs;
  final int? bestResponseMs;
  final int? avgChainMs;
  final int? fastestChainMs;

  double get accuracyPercent {
    if (attempts <= 0) return 0;
    return ((hits / attempts) * 100).clamp(0, 100);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'drillType': drillType.name,
    'trainingStyle': trainingStyle.name,
    'completedAt': completedAt.toIso8601String(),
    'durationSeconds': durationSeconds,
    'hits': hits,
    'attempts': attempts,
    'chains': chains,
    'timeouts': timeouts,
    'avgResponseMs': avgResponseMs,
    'bestResponseMs': bestResponseMs,
    'avgChainMs': avgChainMs,
    'fastestChainMs': fastestChainMs,
  };

  factory TrainingSession.fromJson(Map<String, dynamic> json) {
    return TrainingSession(
      id:
          json['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      drillType: AimDrillType.values.firstWhere(
        (e) => e.name == json['drillType'],
        orElse: () => AimDrillType.eyeHandCoordination,
      ),
      trainingStyle: TrainingStyle.values.firstWhere(
        (e) => e.name == json['trainingStyle'],
        orElse: () => TrainingStyle.precision,
      ),
      completedAt:
          DateTime.tryParse(json['completedAt'] as String? ?? '') ??
          DateTime.now(),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 30,
      hits: (json['hits'] as num?)?.toInt() ?? 0,
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      chains: (json['chains'] as num?)?.toInt() ?? 0,
      timeouts: (json['timeouts'] as num?)?.toInt() ?? 0,
      avgResponseMs: (json['avgResponseMs'] as num?)?.toInt(),
      bestResponseMs: (json['bestResponseMs'] as num?)?.toInt(),
      avgChainMs: (json['avgChainMs'] as num?)?.toInt(),
      fastestChainMs: (json['fastestChainMs'] as num?)?.toInt(),
    );
  }
}

class SensitivityProfile {
  const SensitivityProfile({
    required this.id,
    required this.name,
    required this.general,
    required this.redDot,
    required this.scope2x,
    required this.scope4x,
    required this.sniperScope,
    required this.freeLook,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final int general;
  final int redDot;
  final int scope2x;
  final int scope4x;
  final int sniperScope;
  final int freeLook;
  final DateTime updatedAt;

  static SensitivityProfile defaultBalanced() => SensitivityProfile(
    id: 'default-balanced',
    name: 'Balanced',
    general: 125,
    redDot: 112,
    scope2x: 96,
    scope4x: 82,
    sniperScope: 58,
    freeLook: 118,
    updatedAt: DateTime.now(),
  );

  SensitivityProfile copyWith({
    String? id,
    String? name,
    int? general,
    int? redDot,
    int? scope2x,
    int? scope4x,
    int? sniperScope,
    int? freeLook,
    DateTime? updatedAt,
  }) {
    return SensitivityProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      general: general ?? this.general,
      redDot: redDot ?? this.redDot,
      scope2x: scope2x ?? this.scope2x,
      scope4x: scope4x ?? this.scope4x,
      sniperScope: sniperScope ?? this.sniperScope,
      freeLook: freeLook ?? this.freeLook,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'general': general,
    'redDot': redDot,
    'scope2x': scope2x,
    'scope4x': scope4x,
    'sniperScope': sniperScope,
    'freeLook': freeLook,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory SensitivityProfile.fromJson(Map<String, dynamic> json) {
    return SensitivityProfile(
      id: json['id'] as String? ?? 'custom',
      name: json['name'] as String? ?? 'Balanced',
      general: (json['general'] as num?)?.toInt() ?? 125,
      redDot: (json['redDot'] as num?)?.toInt() ?? 112,
      scope2x: (json['scope2x'] as num?)?.toInt() ?? 96,
      scope4x: (json['scope4x'] as num?)?.toInt() ?? 82,
      sniperScope: (json['sniperScope'] as num?)?.toInt() ?? 58,
      freeLook: (json['freeLook'] as num?)?.toInt() ?? 118,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class HudControlItem {
  const HudControlItem({
    required this.id,
    required this.labelKey,
    required this.x,
    required this.y,
    required this.fingerZone,
    this.isPrimary = false,
  });

  final String id;
  final String labelKey;
  final double x; // normalized 0..1
  final double y; // normalized 0..1
  final String fingerZone; // L THUMB, L INDEX, L MIDDLE, R THUMB, R INDEX
  final bool isPrimary;

  HudControlItem copyWith({double? x, double? y}) => HudControlItem(
    id: id,
    labelKey: labelKey,
    x: x ?? this.x,
    y: y ?? this.y,
    fingerZone: fingerZone,
    isPrimary: isPrimary,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'labelKey': labelKey,
    'x': x,
    'y': y,
    'fingerZone': fingerZone,
    'isPrimary': isPrimary,
  };

  factory HudControlItem.fromJson(Map<String, dynamic> json) => HudControlItem(
    id: json['id'] as String? ?? 'fire',
    labelKey: json['labelKey'] as String? ?? 'FIRE',
    x: (json['x'] as num?)?.toDouble() ?? 0.5,
    y: (json['y'] as num?)?.toDouble() ?? 0.5,
    fingerZone: json['fingerZone'] as String? ?? 'R THUMB',
    isPrimary: json['isPrimary'] as bool? ?? false,
  );
}

class HudConfiguration {
  const HudConfiguration({
    required this.fingerSetup,
    required this.spacing,
    required this.controlSize,
    required this.controlOpacity,
    required this.controls,
  });

  final FingerSetup fingerSetup;
  final FiveFingerSpacing spacing;
  final double controlSize; // 0.7..1.35
  final double controlOpacity; // 0.35..1.0
  final List<HudControlItem> controls;

  static List<HudControlItem> presetControls(
    FingerSetup setup,
    FiveFingerSpacing spacing,
  ) {
    final spread = switch (spacing) {
      FiveFingerSpacing.compact => -0.04,
      FiveFingerSpacing.balanced => 0.0,
      FiveFingerSpacing.wide => 0.045,
    };

    switch (setup) {
      case FingerSetup.twoFinger:
        return [
          const HudControlItem(
            id: 'move',
            labelKey: 'MOVE',
            x: 0.16,
            y: 0.72,
            fingerZone: 'L THUMB',
            isPrimary: true,
          ),
          const HudControlItem(
            id: 'sprint',
            labelKey: 'SPRINT',
            x: 0.16,
            y: 0.42,
            fingerZone: 'L THUMB',
          ),
          const HudControlItem(
            id: 'fire',
            labelKey: 'FIRE',
            x: 0.84,
            y: 0.72,
            fingerZone: 'R THUMB',
            isPrimary: true,
          ),
          const HudControlItem(
            id: 'scope',
            labelKey: 'SCOPE',
            x: 0.86,
            y: 0.40,
            fingerZone: 'R THUMB',
          ),
          const HudControlItem(
            id: 'jump',
            labelKey: 'JUMP',
            x: 0.72,
            y: 0.56,
            fingerZone: 'R THUMB',
          ),
          const HudControlItem(
            id: 'crouch',
            labelKey: 'CROUCH',
            x: 0.70,
            y: 0.78,
            fingerZone: 'R THUMB',
          ),
          const HudControlItem(
            id: 'switch',
            labelKey: 'SWITCH',
            x: 0.54,
            y: 0.84,
            fingerZone: 'R THUMB',
          ),
          const HudControlItem(
            id: 'heal',
            labelKey: 'HEAL',
            x: 0.34,
            y: 0.82,
            fingerZone: 'L THUMB',
          ),
        ];
      case FingerSetup.threeFinger:
        return [
          const HudControlItem(
            id: 'move',
            labelKey: 'MOVE',
            x: 0.16,
            y: 0.74,
            fingerZone: 'L THUMB',
            isPrimary: true,
          ),
          const HudControlItem(
            id: 'fire_l',
            labelKey: 'FIRE',
            x: 0.14,
            y: 0.24,
            fingerZone: 'L INDEX',
            isPrimary: true,
          ),
          const HudControlItem(
            id: 'barrier',
            labelKey: 'BARRIER',
            x: 0.28,
            y: 0.28,
            fingerZone: 'L INDEX',
          ),
          const HudControlItem(
            id: 'fire',
            labelKey: 'DRAG',
            x: 0.84,
            y: 0.70,
            fingerZone: 'R THUMB',
            isPrimary: true,
          ),
          const HudControlItem(
            id: 'scope',
            labelKey: 'SCOPE',
            x: 0.86,
            y: 0.38,
            fingerZone: 'R THUMB',
          ),
          const HudControlItem(
            id: 'jump',
            labelKey: 'JUMP',
            x: 0.72,
            y: 0.52,
            fingerZone: 'R THUMB',
          ),
          const HudControlItem(
            id: 'crouch',
            labelKey: 'CROUCH',
            x: 0.70,
            y: 0.78,
            fingerZone: 'R THUMB',
          ),
          const HudControlItem(
            id: 'switch',
            labelKey: 'SWITCH',
            x: 0.52,
            y: 0.84,
            fingerZone: 'R THUMB',
          ),
          const HudControlItem(
            id: 'reload',
            labelKey: 'RELOAD',
            x: 0.68,
            y: 0.30,
            fingerZone: 'R THUMB',
          ),
        ];
      case FingerSetup.fourFinger:
        return [
          const HudControlItem(
            id: 'move',
            labelKey: 'MOVE',
            x: 0.16,
            y: 0.74,
            fingerZone: 'L THUMB',
            isPrimary: true,
          ),
          const HudControlItem(
            id: 'fire_l',
            labelKey: 'FIRE',
            x: 0.14,
            y: 0.22,
            fingerZone: 'L INDEX',
            isPrimary: true,
          ),
          const HudControlItem(
            id: 'barrier',
            labelKey: 'BARRIER',
            x: 0.29,
            y: 0.26,
            fingerZone: 'L INDEX',
          ),
          const HudControlItem(
            id: 'scope',
            labelKey: 'SCOPE',
            x: 0.85,
            y: 0.22,
            fingerZone: 'R INDEX',
            isPrimary: true,
          ),
          const HudControlItem(
            id: 'jump',
            labelKey: 'JUMP',
            x: 0.71,
            y: 0.26,
            fingerZone: 'R INDEX',
          ),
          const HudControlItem(
            id: 'fire',
            labelKey: 'DRAG',
            x: 0.84,
            y: 0.72,
            fingerZone: 'R THUMB',
            isPrimary: true,
          ),
          const HudControlItem(
            id: 'crouch',
            labelKey: 'CROUCH',
            x: 0.70,
            y: 0.76,
            fingerZone: 'R THUMB',
          ),
          const HudControlItem(
            id: 'switch',
            labelKey: 'SWITCH',
            x: 0.50,
            y: 0.84,
            fingerZone: 'R THUMB',
          ),
          const HudControlItem(
            id: 'sprint',
            labelKey: 'SPRINT',
            x: 0.16,
            y: 0.45,
            fingerZone: 'L THUMB',
          ),
        ];
      case FingerSetup.fiveFinger:
        return [
          HudControlItem(
            id: 'fire_l',
            labelKey: 'FIRE',
            x: (0.12 - spread * 0.4).clamp(0.08, 0.22),
            y: 0.19,
            fingerZone: 'L MIDDLE',
            isPrimary: true,
          ),
          HudControlItem(
            id: 'switch',
            labelKey: 'SWITCH',
            x: (0.28 + spread * 0.5).clamp(0.22, 0.36),
            y: 0.22,
            fingerZone: 'L INDEX',
            isPrimary: true,
          ),
          HudControlItem(
            id: 'barrier',
            labelKey: 'BARRIER',
            x: (0.26 + spread * 0.4).clamp(0.20, 0.34),
            y: 0.44,
            fingerZone: 'L INDEX',
          ),
          HudControlItem(
            id: 'move',
            labelKey: 'MOVE',
            x: (0.15 - spread * 0.3).clamp(0.10, 0.22),
            y: 0.76,
            fingerZone: 'L THUMB',
            isPrimary: true,
          ),
          HudControlItem(
            id: 'sprint',
            labelKey: 'SPRINT',
            x: (0.31 + spread * 0.3).clamp(0.26, 0.38),
            y: 0.76,
            fingerZone: 'L THUMB',
          ),
          HudControlItem(
            id: 'scope',
            labelKey: 'SCOPE',
            x: (0.86 + spread * 0.4).clamp(0.78, 0.91),
            y: 0.20,
            fingerZone: 'R INDEX',
            isPrimary: true,
          ),
          HudControlItem(
            id: 'jump',
            labelKey: 'JUMP',
            x: (0.72 - spread * 0.5).clamp(0.64, 0.78),
            y: 0.24,
            fingerZone: 'R INDEX',
          ),
          HudControlItem(
            id: 'fire',
            labelKey: 'DRAG',
            x: (0.84 + spread * 0.3).clamp(0.76, 0.90),
            y: 0.72,
            fingerZone: 'R THUMB',
            isPrimary: true,
          ),
          HudControlItem(
            id: 'crouch',
            labelKey: 'CROUCH',
            x: (0.69 - spread * 0.3).clamp(0.62, 0.75),
            y: 0.78,
            fingerZone: 'R THUMB',
          ),
        ];
    }
  }

  static HudConfiguration defaults() => HudConfiguration(
    fingerSetup: FingerSetup.fourFinger,
    spacing: FiveFingerSpacing.balanced,
    controlSize: 1.0,
    controlOpacity: 0.88,
    controls: presetControls(
      FingerSetup.fourFinger,
      FiveFingerSpacing.balanced,
    ),
  );

  HudConfiguration copyWith({
    FingerSetup? fingerSetup,
    FiveFingerSpacing? spacing,
    double? controlSize,
    double? controlOpacity,
    List<HudControlItem>? controls,
  }) => HudConfiguration(
    fingerSetup: fingerSetup ?? this.fingerSetup,
    spacing: spacing ?? this.spacing,
    controlSize: controlSize ?? this.controlSize,
    controlOpacity: controlOpacity ?? this.controlOpacity,
    controls: controls ?? this.controls,
  );

  Map<String, dynamic> toJson() => {
    'fingerSetup': fingerSetup.name,
    'spacing': spacing.name,
    'controlSize': controlSize,
    'controlOpacity': controlOpacity,
    'controls': controls.map((c) => c.toJson()).toList(),
  };

  factory HudConfiguration.fromJson(Map<String, dynamic> json) {
    final setup = FingerSetup.values.firstWhere(
      (e) => e.name == json['fingerSetup'],
      orElse: () => FingerSetup.fourFinger,
    );
    final spacing = FiveFingerSpacing.values.firstWhere(
      (e) => e.name == json['spacing'],
      orElse: () => FiveFingerSpacing.balanced,
    );
    final rawControls = json['controls'] as List<dynamic>?;
    return HudConfiguration(
      fingerSetup: setup,
      spacing: spacing,
      controlSize: (json['controlSize'] as num?)?.toDouble() ?? 1.0,
      controlOpacity: (json['controlOpacity'] as num?)?.toDouble() ?? 0.88,
      controls: rawControls != null && rawControls.isNotEmpty
          ? rawControls
                .map((e) => HudControlItem.fromJson(e as Map<String, dynamic>))
                .toList()
          : presetControls(setup, spacing),
    );
  }
}

class AppSettings {
  const AppSettings({
    required this.onboardingCompleted,
    required this.languageCode,
    required this.experienceLevel,
    required this.focusDrill,
    required this.trainingStyle,
    required this.routineMinutes,
    required this.weeklyGoalDays,
    required this.dailyRunGoal,
    required this.hapticsEnabled,
    required this.practiceTipsEnabled,
    required this.keepScreenAwake,
    required this.dailyReminderEnabled,
    required this.reminderHour,
    required this.reminderMinute,
    required this.dailyBoostEnabled,
    required this.rewardVideosWatched,
    required this.freeAimSessionUsed,
  });

  final bool onboardingCompleted;
  final String languageCode;
  final ExperienceLevel experienceLevel;
  final AimDrillType focusDrill;
  final TrainingStyle trainingStyle;
  final int routineMinutes;
  final int weeklyGoalDays;
  final int dailyRunGoal;
  final bool hapticsEnabled;
  final bool practiceTipsEnabled;
  final bool keepScreenAwake;
  final bool dailyReminderEnabled;
  final int reminderHour;
  final int reminderMinute;
  final bool dailyBoostEnabled;
  final int rewardVideosWatched;
  final bool freeAimSessionUsed;

  bool get isProUnlocked =>
      rewardVideosWatched >= AppConfig.requiredRewardVideosToUnlock;

  int get remainingRewardVideos =>
      (AppConfig.requiredRewardVideosToUnlock - rewardVideosWatched).clamp(
        0,
        AppConfig.requiredRewardVideosToUnlock,
      );

  static AppSettings defaults() => const AppSettings(
    onboardingCompleted: false,
    languageCode: 'en',
    experienceLevel: ExperienceLevel.intermediate,
    focusDrill: AimDrillType.dragHeadshot,
    trainingStyle: TrainingStyle.precision,
    routineMinutes: 10,
    weeklyGoalDays: 5,
    dailyRunGoal: 3,
    hapticsEnabled: true,
    practiceTipsEnabled: true,
    keepScreenAwake: true,
    dailyReminderEnabled: false,
    reminderHour: 19,
    reminderMinute: 0,
    dailyBoostEnabled: true,
    rewardVideosWatched: 0,
    freeAimSessionUsed: false,
  );

  AppSettings copyWith({
    bool? onboardingCompleted,
    String? languageCode,
    ExperienceLevel? experienceLevel,
    AimDrillType? focusDrill,
    TrainingStyle? trainingStyle,
    int? routineMinutes,
    int? weeklyGoalDays,
    int? dailyRunGoal,
    bool? hapticsEnabled,
    bool? practiceTipsEnabled,
    bool? keepScreenAwake,
    bool? dailyReminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    bool? dailyBoostEnabled,
    int? rewardVideosWatched,
    bool? freeAimSessionUsed,
  }) {
    return AppSettings(
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      languageCode: languageCode ?? this.languageCode,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      focusDrill: focusDrill ?? this.focusDrill,
      trainingStyle: trainingStyle ?? this.trainingStyle,
      routineMinutes: routineMinutes ?? this.routineMinutes,
      weeklyGoalDays: weeklyGoalDays ?? this.weeklyGoalDays,
      dailyRunGoal: dailyRunGoal ?? this.dailyRunGoal,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      practiceTipsEnabled: practiceTipsEnabled ?? this.practiceTipsEnabled,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      dailyBoostEnabled: dailyBoostEnabled ?? this.dailyBoostEnabled,
      rewardVideosWatched: rewardVideosWatched ?? this.rewardVideosWatched,
      freeAimSessionUsed: freeAimSessionUsed ?? this.freeAimSessionUsed,
    );
  }

  Map<String, dynamic> toJson() => {
    'onboardingCompleted': onboardingCompleted,
    'languageCode': languageCode,
    'experienceLevel': experienceLevel.name,
    'focusDrill': focusDrill.name,
    'trainingStyle': trainingStyle.name,
    'routineMinutes': routineMinutes,
    'weeklyGoalDays': weeklyGoalDays,
    'dailyRunGoal': dailyRunGoal,
    'hapticsEnabled': hapticsEnabled,
    'practiceTipsEnabled': practiceTipsEnabled,
    'keepScreenAwake': keepScreenAwake,
    'dailyReminderEnabled': dailyReminderEnabled,
    'reminderHour': reminderHour,
    'reminderMinute': reminderMinute,
    'dailyBoostEnabled': dailyBoostEnabled,
    'rewardVideosWatched': rewardVideosWatched,
    'freeAimSessionUsed': freeAimSessionUsed,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final d = AppSettings.defaults();
    return AppSettings(
      onboardingCompleted:
          json['onboardingCompleted'] as bool? ?? d.onboardingCompleted,
      languageCode: json['languageCode'] as String? ?? d.languageCode,
      experienceLevel: ExperienceLevel.values.firstWhere(
        (e) => e.name == json['experienceLevel'],
        orElse: () => d.experienceLevel,
      ),
      focusDrill: AimDrillType.values.firstWhere(
        (e) => e.name == json['focusDrill'],
        orElse: () => d.focusDrill,
      ),
      trainingStyle: TrainingStyle.values.firstWhere(
        (e) => e.name == json['trainingStyle'],
        orElse: () => d.trainingStyle,
      ),
      routineMinutes:
          (json['routineMinutes'] as num?)?.toInt() ?? d.routineMinutes,
      weeklyGoalDays:
          (json['weeklyGoalDays'] as num?)?.toInt() ?? d.weeklyGoalDays,
      dailyRunGoal: (json['dailyRunGoal'] as num?)?.toInt() ?? d.dailyRunGoal,
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? d.hapticsEnabled,
      practiceTipsEnabled:
          json['practiceTipsEnabled'] as bool? ?? d.practiceTipsEnabled,
      keepScreenAwake: json['keepScreenAwake'] as bool? ?? d.keepScreenAwake,
      dailyReminderEnabled:
          json['dailyReminderEnabled'] as bool? ?? d.dailyReminderEnabled,
      reminderHour: (json['reminderHour'] as num?)?.toInt() ?? d.reminderHour,
      reminderMinute:
          (json['reminderMinute'] as num?)?.toInt() ?? d.reminderMinute,
      dailyBoostEnabled:
          json['dailyBoostEnabled'] as bool? ?? d.dailyBoostEnabled,
      rewardVideosWatched:
          ((json['rewardVideosWatched'] as num?)?.toInt() ??
                  d.rewardVideosWatched)
              .clamp(0, AppConfig.requiredRewardVideosToUnlock),
      freeAimSessionUsed:
          json['freeAimSessionUsed'] as bool? ?? d.freeAimSessionUsed,
    );
  }
}
