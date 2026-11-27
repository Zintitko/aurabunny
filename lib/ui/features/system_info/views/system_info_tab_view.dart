import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../data/repositories/bunny_repository.dart';
import '../../../core/l10n/bunny_strings.dart';
import '../../../core/theme/bunny_theme.dart';
import '../../../core/widgets/bunny_components.dart';
import '../../settings/views/settings_screen.dart';

class SystemInfoTabView extends StatefulWidget {
  const SystemInfoTabView({
    super.key,
    required this.state,
    this.isActive = true,
  });

  final BunnyAppState state;
  final bool isActive;

  @override
  State<SystemInfoTabView> createState() => _SystemInfoTabViewState();
}

class _SystemInfoTabViewState extends State<SystemInfoTabView>
    with SingleTickerProviderStateMixin {
  Ticker? _fpsTicker;
  int _frameCount = 0;
  Duration _lastSample = Duration.zero;
  double _measuredHz = 60.0;

  String _deviceClass = '--';
  String _osVersion = '--';
  int _cpuCores = 0;
  int? _batteryLevel;
  String _chargeState = '--';
  String _networkPath = '--';
  String _ipRoutes = '--';

  bool _tlsRunning = false;
  int? _tlsDnsMs;
  int? _tlsConnectMs;
  int? _tlsTotalMs;
  String? _tlsError;

  @override
  void initState() {
    super.initState();
    _syncDisplayLinkMonitor();
    _loadDeviceTelemetry();
  }

  @override
  void didUpdateWidget(covariant SystemInfoTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _syncDisplayLinkMonitor();
      if (widget.isActive) {
        _loadDeviceTelemetry();
      }
    }
  }

  @override
  void dispose() {
    _fpsTicker?.dispose();
    super.dispose();
  }

  void _syncDisplayLinkMonitor() {
    if (widget.isActive) {
      if (_fpsTicker == null) {
        _fpsTicker = createTicker((elapsed) {
          _frameCount++;
          final diff = elapsed - _lastSample;
          if (diff.inMilliseconds >= 500) {
            final hz = (_frameCount * 1000.0) / diff.inMilliseconds;
            _frameCount = 0;
            _lastSample = elapsed;
            if (mounted) {
              setState(() => _measuredHz = hz.clamp(15, 240));
            }
          }
        })..start();
      } else if (!_fpsTicker!.isActive) {
        _frameCount = 0;
        _lastSample = Duration.zero;
        _fpsTicker!.start();
      }
    } else {
      _fpsTicker?.stop();
    }
  }

  Future<void> _loadDeviceTelemetry() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceClass = 'Mobile';
    String osVer = defaultTargetPlatform.name;

    try {
      if (!kIsWeb && Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        deviceClass = '${info.name} (${info.utsname.machine})';
        osVer = '${info.systemName} ${info.systemVersion}';
      } else if (!kIsWeb && Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        deviceClass = '${info.manufacturer} ${info.model}';
        osVer = 'Android ${info.version.release} (SDK ${info.version.sdkInt})';
      } else if (!kIsWeb && Platform.isMacOS) {
        final info = await deviceInfo.macOsInfo;
        deviceClass = info.model;
        osVer = 'macOS ${info.osRelease}';
      }
    } catch (_) {}

    int cores = 0;
    try {
      if (!kIsWeb) cores = Platform.numberOfProcessors;
    } catch (_) {}

    int? batteryLvl;
    String chargeStr = BunnyStrings.t('Unknown');
    try {
      final battery = Battery();
      batteryLvl = await battery.batteryLevel;
      final state = await battery.batteryState;
      chargeStr = switch (state) {
        BatteryState.charging => BunnyStrings.t('Charging'),
        BatteryState.full => BunnyStrings.t('Fully charged'),
        BatteryState.discharging => BunnyStrings.t('On battery'),
        _ => BunnyStrings.t('Unknown'),
      };
    } catch (_) {}

    String netPath = BunnyStrings.t('Offline');
    try {
      final results = await Connectivity().checkConnectivity();
      if (results.contains(ConnectivityResult.wifi)) {
        netPath = BunnyStrings.t('Wi‑Fi');
      } else if (results.contains(ConnectivityResult.mobile)) {
        netPath = BunnyStrings.t('Cellular');
      } else if (results.contains(ConnectivityResult.ethernet)) {
        netPath = BunnyStrings.t('Ethernet');
      } else if (results.contains(ConnectivityResult.none)) {
        netPath = BunnyStrings.t('Offline');
      } else {
        netPath = BunnyStrings.t('Other');
      }
    } catch (_) {}

    String ipRouteLabel = BunnyStrings.t('Unavailable');
    try {
      if (!kIsWeb) {
        final interfaces = await NetworkInterface.list();
        bool hasV4 = false;
        bool hasV6 = false;
        for (final iface in interfaces) {
          for (final addr in iface.addresses) {
            if (addr.type == InternetAddressType.IPv4) hasV4 = true;
            if (addr.type == InternetAddressType.IPv6) hasV6 = true;
          }
        }
        if (hasV4 && hasV6) {
          ipRouteLabel = BunnyStrings.t('IPv4 + IPv6');
        } else if (hasV4) {
          ipRouteLabel = BunnyStrings.t('IPv4');
        } else if (hasV6) {
          ipRouteLabel = BunnyStrings.t('IPv6');
        }
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _deviceClass = deviceClass;
      _osVersion = osVer;
      _cpuCores = cores;
      _batteryLevel = batteryLvl;
      _chargeState = chargeStr;
      _networkPath = netPath;
      _ipRoutes = ipRouteLabel;
    });
  }

  Future<void> _runTlsEstimate() async {
    if (_tlsRunning) return;
    widget.state.triggerSelectionHaptic();
    setState(() {
      _tlsRunning = true;
      _tlsError = null;
      _tlsDnsMs = null;
      _tlsConnectMs = null;
      _tlsTotalMs = null;
    });

    try {
      final totalWatch = Stopwatch()..start();
      final dnsWatch = Stopwatch()..start();
      final addresses = await InternetAddress.lookup('www.apple.com')
          .timeout(const Duration(seconds: 5));
      dnsWatch.stop();

      if (addresses.isEmpty) {
        throw const SocketException('No route');
      }

      final tlsWatch = Stopwatch()..start();
      final socket = await SecureSocket.connect(
        'www.apple.com',
        443,
        timeout: const Duration(seconds: 6),
      );
      tlsWatch.stop();
      totalWatch.stop();
      await socket.close();

      if (!mounted) return;
      setState(() {
        _tlsDnsMs = dnsWatch.elapsedMilliseconds;
        _tlsConnectMs = tlsWatch.elapsedMilliseconds;
        _tlsTotalMs = totalWatch.elapsedMilliseconds;
        _tlsRunning = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _tlsError = BunnyStrings.t('TLS estimate unavailable');
        _tlsRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final widthPx = (mq.size.width * mq.devicePixelRatio).round();
    final heightPx = (mq.size.height * mq.devicePixelRatio).round();
    final readingsAvailable = [
      _deviceClass != '--',
      _osVersion != '--',
      _cpuCores > 0,
      _batteryLevel != null,
      _chargeState != '--',
      _networkPath != '--',
      _ipRoutes != '--',
      true, // display resolution
      true, // point scale
      true, // display-link Hz
      _tlsTotalMs != null,
    ].where((b) => b).length;

    return Scaffold(
      backgroundColor: BunnyColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BunnyPillBadge(
                        label: BunnyStrings.t('LIVE READINGS'),
                        color: BunnyColors.cyan,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        BunnyStrings.t('System Info'),
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _loadDeviceTelemetry,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Refresh',
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SettingsScreen(state: widget.state),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: BunnyStrings.t('Settings'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'See live display-link rate, battery, device, display, and network readings, plus an optional www.apple.com TLS connection estimate—not in-game FPS or ping.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontSize: 12.5),
            ),
            const SizedBox(height: 16),

            // Live Display-Link Rate + Quick Snapshot Row
            Row(
              children: [
                Expanded(
                  child: BunnyStatTile(
                    label: BunnyStrings.t('DISPLAY-LINK RATE'),
                    value: BunnyStrings.t('%lld Hz', [_measuredHz.round()]),
                    accentColor: BunnyColors.cyan,
                    subtitle: BunnyStrings.t('MEASURED'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: BunnyStatTile(
                    label: BunnyStrings.t('BATTERY'),
                    value: _batteryLevel != null ? '$_batteryLevel%' : '--',
                    accentColor: BunnyColors.emerald,
                    subtitle: _chargeState,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: BunnyStatTile(
                    label: BunnyStrings.t('READINGS'),
                    value: '$readingsAvailable / 11',
                    accentColor: BunnyColors.electricBlueBright,
                    subtitle: BunnyStrings.t('ON-DEVICE'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Optional Apple TLS Connection Estimate
            BunnySectionHeader(
              title: BunnyStrings.t('OPTIONAL TLS ESTIMATE'),
              accentColor: BunnyColors.electricBlue,
              trailing: BunnyPillBadge(
                label: BunnyStrings.t('OPTIONAL'),
                color: BunnyColors.electricBlue,
              ),
            ),
            const SizedBox(height: 10),
            BunnyCard(
              accentColor: BunnyColors.electricBlue,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    BunnyStrings.t('www.apple.com TLS connection estimate'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    BunnyStrings.t(
                      'Makes one TLS connection to www.apple.com. Apple and network providers receive normal connection metadata. Bunny does not save the result.',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontSize: 12),
                  ),
                  if (_tlsTotalMs != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: BunnyStatTile(
                            label: BunnyStrings.t('DNS step'),
                            value: '${_tlsDnsMs ?? 0} ms',
                            accentColor: BunnyColors.cyan,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: BunnyStatTile(
                            label: BunnyStrings.t('Connection setup'),
                            value: '${_tlsConnectMs ?? 0} ms',
                            accentColor: BunnyColors.electricBlueBright,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: BunnyStatTile(
                            label: BunnyStrings.t('TLS ESTIMATE'),
                            value: '${_tlsTotalMs ?? 0} ms',
                            accentColor: BunnyColors.emerald,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_tlsError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _tlsError!,
                      style: const TextStyle(
                        color: BunnyColors.crimson,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  BunnyPrimaryButton(
                    label: _tlsRunning
                        ? BunnyStrings.t('TEST IN PROGRESS')
                        : BunnyStrings.t('RUN TLS ESTIMATE'),
                    icon: Icons.network_check_rounded,
                    compact: true,
                    onPressed: _tlsRunning ? null : _runTlsEstimate,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Hardware & Display Details
            BunnySectionHeader(
              title: BunnyStrings.t('DEVICE DETAILS'),
              accentColor: BunnyColors.cyan,
            ),
            const SizedBox(height: 10),
            BunnyCard(
              child: Column(
                children: [
                  _infoRow(BunnyStrings.t('Device class'), _deviceClass),
                  _infoRow(BunnyStrings.t('Operating system'), _osVersion),
                  _infoRow(
                    BunnyStrings.t('CPU cores'),
                    _cpuCores > 0
                        ? '$_cpuCores'
                        : BunnyStrings.t('Unavailable'),
                  ),
                  _infoRow(
                    BunnyStrings.t('Resolution'),
                    BunnyStrings.t('%lld × %lld px', [widthPx, heightPx]),
                  ),
                  _infoRow(
                    BunnyStrings.t('Point scale'),
                    '${mq.devicePixelRatio.toStringAsFixed(1)}×',
                  ),
                  _infoRow(BunnyStrings.t('NETWORK PATH'), _networkPath),
                  _infoRow(
                    BunnyStrings.t('IP routes'),
                    _ipRoutes,
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Disclaimer
            const Text(
              'Display-link rate, battery, device, network-path, and TLS connection readings are informational snapshots from system APIs. They are not diagnostic, benchmark, in-game FPS, or in-game ping results. Take reasonable breaks, use your device safely, and stop if practice causes discomfort.',
              style: TextStyle(
                fontSize: 11,
                color: BunnyColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: BunnyColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: BunnyColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(),
      ],
    );
  }
}
