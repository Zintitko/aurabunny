import 'package:flutter/material.dart';

import '../../../data/repositories/bunny_repository.dart';
import 'core/l10n/bunny_strings.dart';
import 'core/theme/bunny_theme.dart';
import 'features/aim/views/aim_tab_view.dart';
import 'features/home/views/home_view.dart';
import 'features/hud/views/hud_tab_view.dart';
import 'features/sensitivity/views/sensitivity_tab_view.dart';
import 'features/system_info/views/system_info_tab_view.dart';

class BunnyMainShell extends StatelessWidget {
  const BunnyMainShell({super.key, required this.state});

  final BunnyAppState state;

  @override
  Widget build(BuildContext context) {
    final index = state.selectedTabIndex;
    final activeAccent = switch (index) {
      0 => BunnyColors.electricBlue,
      1 => BunnyColors.crimson,
      2 => BunnyColors.gold,
      3 => BunnyColors.violetBright,
      _ => BunnyColors.cyan,
    };

    return Scaffold(
      backgroundColor: BunnyColors.bg,
      body: IndexedStack(
        index: index,
        children: [
          HomeView(state: state),
          AimTabView(state: state),
          HudTabView(state: state),
          SensitivityTabView(state: state),
          SystemInfoTabView(state: state, isActive: index == 4),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: BunnyColors.bgElevated,
          border: Border(
            top: BorderSide(color: BunnyColors.borderSubtle, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            height: 66,
            backgroundColor: Colors.transparent,
            indicatorColor: activeAccent.withValues(alpha: 0.18),
            selectedIndex: index,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: state.setTab,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(
                  Icons.home_rounded,
                  color: BunnyColors.electricBlue,
                ),
                label: BunnyStrings.t('Home'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.gps_fixed_outlined),
                selectedIcon: const Icon(
                  Icons.gps_fixed_rounded,
                  color: BunnyColors.crimson,
                ),
                label: BunnyStrings.t('Aim'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.gamepad_outlined),
                selectedIcon: const Icon(
                  Icons.gamepad_rounded,
                  color: BunnyColors.gold,
                ),
                label: BunnyStrings.t('HUD'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.tune_outlined),
                selectedIcon: const Icon(
                  Icons.tune_rounded,
                  color: BunnyColors.violetBright,
                ),
                label: BunnyStrings.t('SENS'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.memory_outlined),
                selectedIcon: const Icon(
                  Icons.memory_rounded,
                  color: BunnyColors.cyan,
                ),
                label: BunnyStrings.t('SYS'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
