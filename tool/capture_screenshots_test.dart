import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bunny_esports_flutter/data/repositories/bunny_repository.dart';
import 'package:bunny_esports_flutter/domain/models/bunny_models.dart';
import 'package:bunny_esports_flutter/ui/bunny_main_shell.dart';
import 'package:bunny_esports_flutter/ui/core/l10n/bunny_strings.dart';
import 'package:bunny_esports_flutter/ui/core/theme/bunny_theme.dart';
import 'package:bunny_esports_flutter/ui/features/aim/views/aim_trainer_screen.dart';

Future<void> _loadRealFonts() async {
  // Load bundled Poppins font so text renders identically to real iOS devices.
  final poppinsLoader = FontLoader('Poppins');
  final poppinsBytes = await File('assets/fonts/Poppins-Regular.ttf').readAsBytes();
  poppinsLoader.addFont(Future.value(ByteData.view(poppinsBytes.buffer)));
  await poppinsLoader.load();

  // Load MaterialIcons font from Flutter SDK so all icons render crisply.
  final flutterBin = Platform.environment['FLUTTER_ROOT'] ?? '';
  final candidates = <String>[
    if (flutterBin.isNotEmpty)
      '$flutterBin/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    '/Users/macbookpro/development/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    '/opt/homebrew/share/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    '/usr/local/share/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ];

  // Also search via `which flutter`
  try {
    final res = Process.runSync('which', ['flutter']);
    if (res.exitCode == 0) {
      final path = (res.stdout as String).trim();
      final resolved = File(path).resolveSymbolicLinksSync();
      final root = Directory(resolved).parent.parent.path;
      candidates.insert(
        0,
        '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      );
    }
  } catch (_) {}

  for (final path in candidates) {
    final file = File(path);
    if (file.existsSync()) {
      final iconLoader = FontLoader('MaterialIcons');
      final bytes = await file.readAsBytes();
      iconLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
      await iconLoader.load();
      break;
    }
  }
}

Future<BunnyAppState> _buildPopulatedState() async {
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({});
  final state = BunnyAppState();
  await state.init();
  await BunnyStrings.load('en');

  await state.completeOnboarding(
    experience: ExperienceLevel.experienced,
    focusDrill: AimDrillType.dragHeadshot,
    fingerSetup: FingerSetup.fiveFinger,
    routineMinutes: 10,
    weeklyGoalDays: 5,
  );
  // Unlock Pro (3/3 videos) so 5-Finger Claw HUD & Pro drills showcase cleanly
  await state.recordRewardVideoWatched();
  await state.recordRewardVideoWatched();
  await state.recordRewardVideoWatched();

  await state.updateHudConfig(
    state.hudConfig.copyWith(
      fingerSetup: FingerSetup.fiveFinger,
      spacing: FiveFingerSpacing.balanced,
      controls: HudConfiguration.presetControls(
        FingerSetup.fiveFinger,
        FiveFingerSpacing.balanced,
      ),
    ),
  );

  await state.updateActiveSensitivity(
    SensitivityProfile(
      id: 'tourney-pro',
      name: 'Fast Drag Pro',
      general: 172,
      redDot: 158,
      scope2x: 136,
      scope4x: 118,
      sniperScope: 84,
      freeLook: 160,
      updatedAt: DateTime.now(),
    ),
  );

  final now = DateTime.now();
  final sampleAccuracies = [
    (14, 20), // 70%
    (15, 20), // 75%
    (16, 20), // 80%
    (17, 20), // 85%
    (18, 20), // 90%
    (19, 20), // 95%
  ];
  for (int i = 0; i < sampleAccuracies.length; i++) {
    final pair = sampleAccuracies[i];
    await state.addSession(
      TrainingSession(
        id: 'demo-$i',
        drillType: i.isEven
            ? AimDrillType.dragHeadshot
            : AimDrillType.eyeHandCoordination,
        trainingStyle: TrainingStyle.rapidDrag,
        completedAt: now.subtract(Duration(hours: (5 - i) * 3)),
        durationSeconds: 45,
        hits: pair.$1,
        attempts: pair.$2,
        avgResponseMs: 265 - i * 12,
        bestResponseMs: 210 - i * 8,
      ),
    );
  }
  return state;
}

Future<void> _captureWidget(
  WidgetTester tester, {
  required Widget child,
  required Size logicalSize,
  required double pixelRatio,
  required String outPath,
}) async {
  tester.view.physicalSize = Size(
    logicalSize.width * pixelRatio,
    logicalSize.height * pixelRatio,
  );
  tester.view.devicePixelRatio = pixelRatio;

  final boundaryKey = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: BunnyTheme.buildDarkTheme(),
      home: RepaintBoundary(
        key: boundaryKey,
        child: MediaQuery(
          data: MediaQueryData(
            size: logicalSize,
            devicePixelRatio: pixelRatio,
            padding: const EdgeInsets.only(top: 48, bottom: 24),
          ),
          child: child,
        ),
      ),
    ),
  );

  await tester.runAsync(() async {
    final ctx = boundaryKey.currentContext!;
    for (final img in [
      'assets/images/AppIcon.png',
      'assets/images/BunnyHero.png',
      'assets/images/AimTrainingHero.png',
      'assets/images/HUDYellowBanner.png',
      'assets/images/SensitivityBanner.png',
      'assets/images/OnboardingHero.png',
    ]) {
      await precacheImage(AssetImage(img), ctx);
    }
  });

  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump(const Duration(milliseconds: 200));

  await tester.runAsync(() async {
    final boundary =
        boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final outFile = File(outPath);
    outFile.parent.createSync(recursive: true);
    await outFile.writeAsBytes(byteData!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Capture live UI screens for iPhone and iPad', (tester) async {
    await tester.runAsync(_loadRealFonts);
    final state = await tester.runAsync(_buildPopulatedState);
    final appState = state!;

    const outDir = 'build/raw_screenshots';

    // 1. iPhone logical 393x852 @ 3x (1179x2556)
    const phoneSize = Size(393, 852);
    const phoneRatio = 3.0;

    appState.setTab(0);
    await _captureWidget(
      tester,
      child: BunnyMainShell(state: appState),
      logicalSize: phoneSize,
      pixelRatio: phoneRatio,
      outPath: '$outDir/iphone_01_home.png',
    );

    appState.setTab(1);
    await _captureWidget(
      tester,
      child: BunnyMainShell(state: appState),
      logicalSize: phoneSize,
      pixelRatio: phoneRatio,
      outPath: '$outDir/iphone_02_aim.png',
    );

    await _captureWidget(
      tester,
      child: AimTrainerScreen(
        state: appState,
        drillType: AimDrillType.dragHeadshot,
        trainingStyle: TrainingStyle.rapidDrag,
        durationSeconds: 45,
      ),
      logicalSize: phoneSize,
      pixelRatio: phoneRatio,
      outPath: '$outDir/iphone_03_drag_arena.png',
    );

    appState.setTab(2);
    await _captureWidget(
      tester,
      child: BunnyMainShell(state: appState),
      logicalSize: phoneSize,
      pixelRatio: phoneRatio,
      outPath: '$outDir/iphone_04_hud.png',
    );

    appState.setTab(3);
    await _captureWidget(
      tester,
      child: BunnyMainShell(state: appState),
      logicalSize: phoneSize,
      pixelRatio: phoneRatio,
      outPath: '$outDir/iphone_05_sens.png',
    );

    appState.setTab(4);
    await _captureWidget(
      tester,
      child: BunnyMainShell(state: appState),
      logicalSize: phoneSize,
      pixelRatio: phoneRatio,
      outPath: '$outDir/iphone_06_sys.png',
    );

    // 2. iPad 12.9" logical 768x1024 @ 2x (1536x2048 crisp tablet proportions)
    const padSize = Size(768, 1024);
    const padRatio = 2.0;

    appState.setTab(0);
    await _captureWidget(
      tester,
      child: BunnyMainShell(state: appState),
      logicalSize: padSize,
      pixelRatio: padRatio,
      outPath: '$outDir/ipad_01_home.png',
    );

    appState.setTab(1);
    await _captureWidget(
      tester,
      child: BunnyMainShell(state: appState),
      logicalSize: padSize,
      pixelRatio: padRatio,
      outPath: '$outDir/ipad_02_aim.png',
    );

    await _captureWidget(
      tester,
      child: AimTrainerScreen(
        state: appState,
        drillType: AimDrillType.dragHeadshot,
        trainingStyle: TrainingStyle.rapidDrag,
        durationSeconds: 45,
      ),
      logicalSize: padSize,
      pixelRatio: padRatio,
      outPath: '$outDir/ipad_03_drag_arena.png',
    );

    appState.setTab(2);
    await _captureWidget(
      tester,
      child: BunnyMainShell(state: appState),
      logicalSize: padSize,
      pixelRatio: padRatio,
      outPath: '$outDir/ipad_04_hud.png',
    );

    appState.setTab(3);
    await _captureWidget(
      tester,
      child: BunnyMainShell(state: appState),
      logicalSize: padSize,
      pixelRatio: padRatio,
      outPath: '$outDir/ipad_05_sens.png',
    );

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
