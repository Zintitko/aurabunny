import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../core/app_config.dart';
import '../../../data/services/admob_service.dart';

/// Policy-compliant Banner Ad wrapper for non-gameplay dashboard surfaces.
/// Never placed inside active Aim drills or HUD playgrounds to avoid accidental
/// taps (Google AdMob Placement Policy).
class BunnyBannerAd extends StatefulWidget {
  const BunnyBannerAd({super.key, required this.adMobService});

  final AdMobService adMobService;

  @override
  State<BunnyBannerAd> createState() => _BunnyBannerAdState();
}

class _BunnyBannerAdState extends State<BunnyBannerAd> {
  BannerAd? _banner;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _maybeLoad();
    widget.adMobService.addListener(_onServiceChanged);
  }

  @override
  void dispose() {
    widget.adMobService.removeListener(_onServiceChanged);
    _banner?.dispose();
    super.dispose();
  }

  void _onServiceChanged() {
    if (!_loaded && widget.adMobService.initialized && _banner == null) {
      _maybeLoad();
    }
  }

  void _maybeLoad() {
    if (!widget.adMobService.isSupportedPlatform ||
        !widget.adMobService.initialized) {
      return;
    }
    final banner = BannerAd(
      size: AdSize.banner,
      adUnitId: AppConfig.bannerAdUnitId,
      request: widget.adMobService.buildAdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          _banner = null;
        },
      ),
    );
    _banner = banner;
    banner.load();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;
    if (!_loaded || banner == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Center(
        child: SizedBox(
          width: banner.size.width.toDouble(),
          height: banner.size.height.toDouble(),
          child: AdWidget(ad: banner),
        ),
      ),
    );
  }
}
