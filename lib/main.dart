import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_config.dart';
import 'data/repositories/bunny_repository.dart';
import 'ui/bunny_main_shell.dart';
import 'ui/core/l10n/bunny_strings.dart';
import 'ui/core/theme/bunny_theme.dart';
import 'ui/features/onboarding/views/onboarding_flow.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
  final appState = BunnyAppState();
  await appState.init();
  runApp(BunnyEsportsApp(appState: appState));

  // Initialize ATT + UMP consent + Google Mobile Ads AFTER first frame renders
  // so Apple's ATT dialog displays cleanly over active UI (Guideline 5.1.2).
  WidgetsBinding.instance.addPostFrameCallback((_) {
    appState.adMobService.initialize();
  });
}

class BunnyEsportsApp extends StatelessWidget {
  const BunnyEsportsApp({super.key, required this.appState});

  final BunnyAppState appState;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return MaterialApp(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: BunnyTheme.buildDarkTheme(),
          locale: BunnyStrings.currentLocale,
          supportedLocales: BunnyStrings.supportedLanguages
              .map((l) => Locale(l.code))
              .toList(),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: appState.settings.onboardingCompleted
              ? BunnyMainShell(state: appState)
              : OnboardingFlow(state: appState),
        );
      },
    );
  }
}
