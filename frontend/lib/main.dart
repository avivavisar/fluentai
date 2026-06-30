import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_localizations.dart';
import 'theme.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const ProviderScope(child: FluentAIApp()));
}

class FluentAIApp extends StatelessWidget {
  const FluentAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx)!.appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Hebrew by default (RTL). A language switcher is added in Increment 1.
      locale: const Locale('he'),
      home: const SplashScreen(),
    );
  }
}
