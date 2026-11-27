import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_config.dart';

/// Apple App Store Policy-Compliant Rating & Review Service (Guideline 1.1.7 / 5.6.1).
///
/// - Automatic in-app prompts strictly use Apple's native SKStoreReviewController
///   via `InAppReview.instance.requestReview()` — NO custom pre-prompt / review
///   gating, NEVER shown on cold launch or mid-drill.
/// - Triggered only after a positive completion milestone (2+ completed drills)
///   with a 60-day local cooldown (in addition to Apple's OS-level 3/year cap).
/// - Manual "Write a Review" button in Settings calls `openStoreListing` with
///   iOS App Store ID `6839834538` so the button always works reliably.
class ReviewService {
  static const String _lastPromptKey = 'aurabunny_last_review_prompt_ms_v1';
  static const int minCompletedSessionsForPrompt = 2;
  static const Duration localCooldown = Duration(days: 60);

  bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.macOS);

  Future<bool> shouldPromptNow({
    required int totalCompletedSessions,
    DateTime? now,
  }) async {
    if (totalCompletedSessions < minCompletedSessionsForPrompt) {
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(_lastPromptKey);
    if (lastMs == null) return true;
    final lastPrompt = DateTime.fromMillisecondsSinceEpoch(lastMs);
    final current = now ?? DateTime.now();
    return current.difference(lastPrompt) >= localCooldown;
  }

  /// Requests the native OS rating dialog (SKStoreReviewController on iOS) if
  /// the user has completed enough sessions and is outside the cooldown window.
  Future<bool> maybeRequestInAppReview({
    required int totalCompletedSessions,
  }) async {
    final eligible = await shouldPromptNow(
      totalCompletedSessions: totalCompletedSessions,
    );
    if (!eligible || !_isSupportedPlatform) return false;

    try {
      final inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(
          _lastPromptKey,
          DateTime.now().millisecondsSinceEpoch,
        );
        await inAppReview.requestReview();
        return true;
      }
    } catch (_) {
      // Never disrupt UX if StoreKit / Play In-App Review is unavailable.
    }
    return false;
  }

  /// Opens the App Store / Play Store listing directly for the manual
  /// "Write a Review" button in Settings (per Apple HIG, buttons should open
  /// the store listing rather than calling `requestReview()`).
  Future<void> openWriteReviewPage() async {
    if (!_isSupportedPlatform) return;
    try {
      await InAppReview.instance.openStoreListing(
        appStoreId: AppConfig.iosAppStoreId,
      );
    } catch (_) {}
  }

  Future<void> clearReviewHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastPromptKey);
  }
}
