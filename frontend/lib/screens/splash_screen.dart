import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/session_provider.dart';
import 'login_screen.dart';
import 'goal_setup_screen.dart';
import 'home_dashboard_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await ref.read(sessionProvider.notifier).bootstrap();
    if (!mounted) return;
    final s = ref.read(sessionProvider);
    Widget next;
    if (!s.isLoggedIn) {
      next = const LoginScreen();
    } else if (s.profile?.cefrLevel == null) {
      next = const GoalSetupScreen();
    } else {
      next = const HomeDashboardScreen();
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => next));
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
