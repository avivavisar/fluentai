import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../profile/profile_providers.dart';
import '../onboarding/onboarding_screen.dart';
import '../placement/placement_screen.dart';
import '../shell/app_shell.dart';

/// Decides where a signed-in user lands: onboarding → placement → the app.
class GateScreen extends ConsumerWidget {
  const GateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    return profile.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('שגיאה בחיבור לשרת', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                FilledButton(onPressed: () => ref.invalidate(profileProvider), child: const Text('נסה שוב')),
              ],
            ),
          ),
        ),
      ),
      data: (p) {
        if (p['onboardingComplete'] != true) return const OnboardingScreen();
        if (p['cefrLevel'] == null) return const PlacementScreen();
        return const AppShell();
      },
    );
  }
}
