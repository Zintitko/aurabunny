import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/bunny_models.dart';

class LocalStorageService {
  static const _settingsKey = 'bunny_app_settings_v1';
  static const _sessionsKey = 'bunny_training_sessions_v1';
  static const _activeSensKey = 'bunny_active_sensitivity_v1';
  static const _savedSensKey = 'bunny_saved_sensitivities_v1';
  static const _hudKey = 'bunny_hud_config_v1';

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey);
    if (raw == null) return AppSettings.defaults();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return AppSettings.defaults();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  Future<List<TrainingSession>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionsKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => TrainingSession.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSessions(List<TrainingSession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _sessionsKey,
      jsonEncode(sessions.map((s) => s.toJson()).toList()),
    );
  }

  Future<SensitivityProfile> loadActiveSensitivity() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_activeSensKey);
    if (raw == null) return SensitivityProfile.defaultBalanced();
    try {
      return SensitivityProfile.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return SensitivityProfile.defaultBalanced();
    }
  }

  Future<void> saveActiveSensitivity(SensitivityProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeSensKey, jsonEncode(profile.toJson()));
  }

  Future<List<SensitivityProfile>> loadSavedSensitivities() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_savedSensKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => SensitivityProfile.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSavedSensitivities(List<SensitivityProfile> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _savedSensKey,
      jsonEncode(profiles.map((p) => p.toJson()).toList()),
    );
  }

  Future<HudConfiguration> loadHudConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_hudKey);
    if (raw == null) return HudConfiguration.defaults();
    try {
      return HudConfiguration.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return HudConfiguration.defaults();
    }
  }

  Future<void> saveHudConfig(HudConfiguration config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hudKey, jsonEncode(config.toJson()));
  }

  Future<void> deleteAllLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_settingsKey);
    await prefs.remove(_sessionsKey);
    await prefs.remove(_activeSensKey);
    await prefs.remove(_savedSensKey);
    await prefs.remove(_hudKey);
  }
}
