import 'package:flutter/foundation.dart';

/// Central app metadata & Google AdMob configuration.
///
/// iOS live AdMob App ID (`ca-app-pub-6687779687898901~2990369579`) is set in
/// `ios/Runner/Info.plist` under `GADApplicationIdentifier`.
/// Debug/profile builds automatically use Google's official test ad unit IDs
/// to avoid invalid traffic (IVT) policy violations during development.
class AppConfig {
  AppConfig._();

  static const String appName = 'AuraBunny: Sensi & Aim Trainer';
  static const String shortName = 'AuraBunny';
  static const String bundleId = 'aura.bunny';
  static const String iosAppStoreId = '6839834538';
  static const String version = '1.5';
  static const String buildNumber = '8';

  static const String developerName = 'AuraBunny Studio';
  static const String supportEmail = 'yaniamania6@icloud.com';
  static const String privacyPolicyUrl =
      'https://midwifery.site/privacy_policy.html';

  // Number of voluntary rewarded video ads required to unlock Pro drills & 5F HUD.
  static const int requiredRewardVideosToUnlock = 3;

  // Policy-compliant Interstitial frequency caps (AdMob + Apple UX).
  static const int completedSessionsPerInterstitial = 2;
  static const Duration interstitialMinInterval = Duration(minutes: 2);

  // Google Official Test Ad Unit IDs (used automatically in debug/profile builds).
  static const String _iosTestBannerId =
      'ca-app-pub-3940256099942544/2934735716';
  static const String _androidTestBannerId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _iosTestInterstitialId =
      'ca-app-pub-3940256099942544/4411468910';
  static const String _androidTestInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _iosTestRewardedId =
      'ca-app-pub-3940256099942544/1712485313';
  static const String _androidTestRewardedId =
      'ca-app-pub-3940256099942544/5224354917';

  // Live Production iOS Ad Unit IDs.
  static const String _iosProdBannerId =
      'ca-app-pub-6687779687898901/8106964885';
  static const String _iosProdInterstitialId =
      'ca-app-pub-6687779687898901/4167719879';
  static const String _iosProdRewardedId =
      'ca-app-pub-6687779687898901/2758048246';

  // Android Production Ad Unit IDs — replace when creating Android AdMob units.
  static const String _androidProdBannerId = _androidTestBannerId;
  static const String _androidProdInterstitialId = _androidTestInterstitialId;
  static const String _androidProdRewardedId = _androidTestRewardedId;

  static String get bannerAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return kReleaseMode ? _iosProdBannerId : _iosTestBannerId;
    }
    return kReleaseMode ? _androidProdBannerId : _androidTestBannerId;
  }

  static String get interstitialAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return kReleaseMode ? _iosProdInterstitialId : _iosTestInterstitialId;
    }
    return kReleaseMode
        ? _androidProdInterstitialId
        : _androidTestInterstitialId;
  }

  static String get rewardedAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return kReleaseMode ? _iosProdRewardedId : _iosTestRewardedId;
    }
    return kReleaseMode ? _androidProdRewardedId : _androidTestRewardedId;
  }
}
