import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bunny_esports_flutter/data/repositories/bunny_repository.dart';
import 'package:bunny_esports_flutter/domain/models/bunny_models.dart';
import 'package:bunny_esports_flutter/main.dart';
import 'package:bunny_esports_flutter/ui/core/l10n/bunny_strings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('BunnyAppState persists sessions, sensitivity rolls, and 3-video reward unlock', () async {
    final state = BunnyAppState();
    await state.init();

    expect(state.settings.onboardingCompleted, isFalse);
    expect(state.settings.isProUnlocked, isFalse);
    expect(state.settings.rewardVideosWatched, 0);
    expect(state.sessions, isEmpty);

    await state.rollSensitivityPreset(fastDrag: true);
    expect(state.activeSensitivity.general, inInclusiveRange(150, 200));

    await state.rollSensitivityPreset(fastDrag: false);
    expect(state.activeSensitivity.general, inInclusiveRange(30, 80));

    await state.addSession(
      TrainingSession(
        id: 'test-1',
        drillType: AimDrillType.dragHeadshot,
        trainingStyle: TrainingStyle.precision,
        completedAt: DateTime.now(),
        durationSeconds: 45,
        hits: 18,
        attempts: 20,
      ),
    );
    expect(state.sessions.length, 1);
    expect(state.bestAccuracy, 90.0);
    expect(state.settings.freeAimSessionUsed, isTrue);
    expect(state.canPlayAimDrill(AimDrillType.dragHeadshot), isFalse);
    expect(state.canPlayAimDrill(AimDrillType.eyeHandCoordination), isTrue);

    // Watch 3 voluntary rewarded videos one by one
    await state.recordRewardVideoWatched();
    expect(state.settings.rewardVideosWatched, 1);
    expect(state.settings.isProUnlocked, isFalse);

    await state.recordRewardVideoWatched();
    expect(state.settings.rewardVideosWatched, 2);
    expect(state.settings.isProUnlocked, isFalse);

    await state.recordRewardVideoWatched();
    expect(state.settings.rewardVideosWatched, 3);
    expect(state.settings.isProUnlocked, isTrue);
    expect(state.canPlayAimDrill(AimDrillType.dragHeadshot), isTrue);

    final exported = state.buildJsonExport();
    expect(exported, contains('AuraBunny: Sensi & Aim Trainer'));
    expect(exported, contains('dragHeadshot'));
    expect(exported, contains('"rewardVideosWatched": 3'));

    // Review prompt eligibility respects minimum completed sessions (2+)
    expect(
      await state.reviewService.shouldPromptNow(totalCompletedSessions: 1),
      isFalse,
    );
    expect(
      await state.reviewService.shouldPromptNow(totalCompletedSessions: 2),
      isTrue,
    );
  });

  test('BunnyStrings loads English and Arabic localization keys', () async {
    await BunnyStrings.load('en');
    expect(
      BunnyStrings.t('HEADSHOT: BUNNY ESPORTS'),
      'HEADSHOT: BUNNY ESPORTS',
    );
    expect(BunnyStrings.t('%lld min', [10]), '10 min');

    await BunnyStrings.load('ar');
    expect(BunnyStrings.isRtl, isTrue);
    expect(BunnyStrings.t('Settings'), isNotEmpty);
    await BunnyStrings.load('en');
  });

  testWidgets('App renders onboarding welcome and navigates into main tabs', (
    tester,
  ) async {
    final state = BunnyAppState();
    await state.init();

    await tester.pumpWidget(BunnyEsportsApp(appState: state));
    await tester.pumpAndSettle();

    expect(find.textContaining('PRACTICE. ADAPT.'), findsOneWidget);

    await state.completeOnboarding(
      experience: ExperienceLevel.intermediate,
      focusDrill: AimDrillType.dragHeadshot,
      fingerSetup: FingerSetup.fourFinger,
      routineMinutes: 10,
      weeklyGoalDays: 5,
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);

    for (final tabIndex in [1, 2, 3, 4, 0]) {
      state.setTab(tabIndex);
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(state.selectedTabIndex, 0);
  });
}
