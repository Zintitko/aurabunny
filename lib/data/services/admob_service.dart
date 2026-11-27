import 'dart:async';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/app_config.dart';

enum RewardAdLoadState { idle, loading, ready, showing, unavailable }

/// Google AdMob service wired for Apple App Store & AdMob Policy compliance:
/// - Requests iOS ATT permission cleanly after first frame (falls back to
///   non-personalized ads if denied)
/// - Requests GDPR/UMP consent before initializing MobileAds
/// - Strictly opt-in Rewarded Ads with persistent credit & anti-IVT cooldown
/// - Frequency-capped Interstitial Ads shown ONLY at natural post-drill breaks
///   (never on cold launch, never mid-drill, never on every tab switch)
class AdMobService extends ChangeNotifier {
  AdMobService({required this.onRewardVideoCompleted});

  final Future<void> Function() onRewardVideoCompleted;

  bool _initialized = false;
  bool get initialized => _initialized;

  bool _nonPersonalizedAds = true;
  bool get nonPersonalizedAds => _nonPersonalizedAds;

  bool _privacyOptionsRequired = false;
  bool get privacyOptionsRequired => _privacyOptionsRequired;

  // Rewarded ad state
  RewardedAd? _rewardedAd;
  RewardAdLoadState _rewardState = RewardAdLoadState.idle;
  RewardAdLoadState get rewardState => _rewardState;

  String? _statusMessage;
  String? get statusMessage => _statusMessage;

  // Interstitial ad state & frequency cap
  InterstitialAd? _interstitialAd;
  bool _interstitialLoading = false;
  bool _interstitialShowing = false;
  int _completedActivitiesSinceInterstitial = 0;
  DateTime? _lastInterstitialShownAt;

  // Short anti-IVT pacing cooldown (3 seconds) after finishing a rewarded video
  DateTime? _cooldownUntil;
  Timer? _cooldownTimer;

  bool get isInCooldown {
    final until = _cooldownUntil;
    if (until == null) return false;
    return DateTime.now().isBefore(until);
  }

  int get cooldownSecondsRemaining {
    final until = _cooldownUntil;
    if (until == null) return 0;
    final diff = until.difference(DateTime.now()).inSeconds + 1;
    return diff.clamp(0, 10);
  }

  bool get isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  AdRequest buildAdRequest() =>
      AdRequest(nonPersonalizedAds: _nonPersonalizedAds);

  /// Initializes ATT, UMP consent, Google Mobile Ads SDK, and preloads ads.
  Future<void> initialize() async {
    if (_initialized) return;
    if (!isSupportedPlatform) {
      _rewardState = RewardAdLoadState.unavailable;
      notifyListeners();
      return;
    }

    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final status =
            await AppTrackingTransparency.trackingAuthorizationStatus;
        if (status == TrackingStatus.notDetermined) {
          final result =
              await AppTrackingTransparency.requestTrackingAuthorization();
          _nonPersonalizedAds = result != TrackingStatus.authorized;
        } else {
          _nonPersonalizedAds = status != TrackingStatus.authorized;
        }
      } else {
        _nonPersonalizedAds = false;
      }
    } catch (_) {
      _nonPersonalizedAds = true;
    }

    try {
      final completer = Completer<void>();
      final params = ConsentRequestParameters();
      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          try {
            ConsentForm.loadAndShowConsentFormIfRequired((FormError? _) async {
              await _refreshPrivacyOptionsFlag();
              if (!completer.isCompleted) completer.complete();
            });
          } catch (_) {
            if (!completer.isCompleted) completer.complete();
          }
        },
        (FormError _) {
          if (!completer.isCompleted) completer.complete();
        },
      );
      await completer.future.timeout(
        const Duration(seconds: 6),
        onTimeout: () {},
      );
    } catch (_) {
      // Proceed gracefully if UMP cannot reach network.
    }

    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      await Future.wait([loadRewardedAd(), loadInterstitialAd()]);
    } catch (_) {
      _rewardState = RewardAdLoadState.unavailable;
      notifyListeners();
    }
  }

  Future<void> _refreshPrivacyOptionsFlag() async {
    try {
      final status = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      _privacyOptionsRequired =
          status == PrivacyOptionsRequirementStatus.required;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> showPrivacyOptionsForm() async {
    if (!isSupportedPlatform) return;
    try {
      ConsentForm.showPrivacyOptionsForm((FormError? _) {
        _refreshPrivacyOptionsFlag();
      });
    } catch (_) {}
  }

  // -------------------------
  // INTERSTITIAL ADS
  // -------------------------

  Future<void> loadInterstitialAd() async {
    if (!isSupportedPlatform ||
        _interstitialLoading ||
        _interstitialAd != null) {
      return;
    }
    _interstitialLoading = true;
    try {
      await InterstitialAd.load(
        adUnitId: AppConfig.interstitialAdUnitId,
        request: buildAdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            _interstitialAd = ad;
            _interstitialLoading = false;
          },
          onAdFailedToLoad: (LoadAdError _) {
            _interstitialAd = null;
            _interstitialLoading = false;
          },
        ),
      );
    } catch (_) {
      _interstitialAd = null;
      _interstitialLoading = false;
    }
  }

  bool _isInterstitialIntervalElapsed() {
    final last = _lastInterstitialShownAt;
    if (last == null) return true;
    return DateTime.now().difference(last) >= AppConfig.interstitialMinInterval;
  }

  /// Call ONLY at a natural post-session break (e.g., exiting or replaying
  /// after a completed Aim Drill or HUD Playground).
  /// Respects session-count & time frequency caps and never blocks navigation.
  Future<void> recordCompletedActivityAndMaybeShowInterstitial() async {
    if (!isSupportedPlatform || !_initialized) return;
    if (_interstitialShowing || _rewardState == RewardAdLoadState.showing) {
      return;
    }

    _completedActivitiesSinceInterstitial++;
    final meetsCountCap =
        _completedActivitiesSinceInterstitial >=
        AppConfig.completedSessionsPerInterstitial;
    if (!meetsCountCap || !_isInterstitialIntervalElapsed()) {
      if (_interstitialAd == null) {
        loadInterstitialAd();
      }
      return;
    }

    final ad = _interstitialAd;
    if (ad == null) {
      loadInterstitialAd();
      return;
    }

    final completer = Completer<void>();
    _interstitialShowing = true;
    _interstitialAd = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        _completedActivitiesSinceInterstitial = 0;
        _lastInterstitialShownAt = DateTime.now();
      },
      onAdDismissedFullScreenContent: (InterstitialAd dismissedAd) {
        dismissedAd.dispose();
        _interstitialShowing = false;
        loadInterstitialAd();
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd failedAd, AdError _) {
        failedAd.dispose();
        _interstitialShowing = false;
        loadInterstitialAd();
        if (!completer.isCompleted) completer.complete();
      },
    );

    try {
      await ad.show();
    } catch (_) {
      _interstitialShowing = false;
      if (!completer.isCompleted) completer.complete();
    }

    await completer.future;
  }

  // -------------------------
  // REWARDED VIDEO ADS
  // -------------------------

  Future<void> loadRewardedAd() async {
    if (!isSupportedPlatform) {
      _rewardState = RewardAdLoadState.unavailable;
      notifyListeners();
      return;
    }
    if (_rewardState == RewardAdLoadState.loading ||
        _rewardState == RewardAdLoadState.showing) {
      return;
    }

    _rewardedAd?.dispose();
    _rewardedAd = null;
    _rewardState = RewardAdLoadState.loading;
    _statusMessage = null;
    notifyListeners();

    try {
      await RewardedAd.load(
        adUnitId: AppConfig.rewardedAdUnitId,
        request: buildAdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            _rewardedAd = ad;
            _rewardState = RewardAdLoadState.ready;
            _statusMessage = null;
            notifyListeners();
          },
          onAdFailedToLoad: (LoadAdError error) {
            _rewardedAd = null;
            _rewardState = RewardAdLoadState.unavailable;
            _statusMessage = 'Video ad could not be loaded right now. Check your connection and try again.';
            notifyListeners();
          },
        ),
      );
    } catch (_) {
      _rewardState = RewardAdLoadState.unavailable;
      _statusMessage = 'Video ad could not be loaded right now. Check your connection and try again.';
      notifyListeners();
    }
  }

  /// Shows a single voluntary rewarded video ad. Never auto-chains the next ad.
  Future<bool> showRewardedAd() async {
    if (!isSupportedPlatform || isInCooldown) return false;
    final ad = _rewardedAd;
    if (ad == null) {
      await loadRewardedAd();
      return false;
    }

    final completer = Completer<bool>();
    bool rewardEarned = false;

    _rewardState = RewardAdLoadState.showing;
    _statusMessage = null;
    notifyListeners();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd dismissedAd) {
        dismissedAd.dispose();
        _rewardedAd = null;
        _rewardState = RewardAdLoadState.idle;
        if (rewardEarned) {
          _startCooldown();
        } else {
          _statusMessage = 'Watch the full video to earn progress toward unlocking Pro features.';
        }
        notifyListeners();
        loadRewardedAd();
        if (!completer.isCompleted) completer.complete(rewardEarned);
      },
      onAdFailedToShowFullScreenContent: (RewardedAd failedAd, AdError err) {
        failedAd.dispose();
        _rewardedAd = null;
        _rewardState = RewardAdLoadState.unavailable;
        _statusMessage = 'Ad could not be shown. Please try again.';
        notifyListeners();
        loadRewardedAd();
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (AdWithoutView adView, RewardItem reward) async {
          rewardEarned = true;
          await onRewardVideoCompleted();
        },
      );
    } catch (_) {
      _rewardState = RewardAdLoadState.unavailable;
      notifyListeners();
      if (!completer.isCompleted) completer.complete(false);
    }

    return completer.future;
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _cooldownUntil = DateTime.now().add(const Duration(seconds: 3));
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isInCooldown) {
        timer.cancel();
        _cooldownUntil = null;
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }
}
