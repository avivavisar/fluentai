import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_controller.dart';

/// Calls the backend to prove the auth chain (Supabase token -> our API).
final meProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final data = await api.get('/v1/me');
  return (data as Map).cast<String, dynamic>();
});

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  static const _tabs = [_HomeTab(), _PlaceholderTab(icon: Icons.mic_none_rounded, title: 'שיחה'), _PlaceholderTab(icon: Icons.menu_book_rounded, title: 'מילים'), _PlaceholderTab(icon: Icons.insights_rounded, title: 'התקדמות')];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'בית'),
          NavigationDestination(icon: Icon(Icons.mic_none_outlined), selectedIcon: Icon(Icons.mic_rounded), label: 'שיחה'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book_rounded), label: 'מילים'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights_rounded), label: 'התקדמות'),
        ],
      ),
    );
  }
}

class _HomeTab extends ConsumerWidget {
  const _HomeTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final me = ref.watch(meProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('FluentAI'),
        actions: [
          IconButton(
            tooltip: 'התנתקות',
            onPressed: () => ref.read(authControllerProvider).signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: Center(
        child: me.when(
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(24),
            child: Text('שגיאה בחיבור לשרת:\n$e', textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.error)),
          ),
          data: (user) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 48),
                const SizedBox(height: 16),
                Text('מחובר בהצלחה', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('${user['email']}', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text('כאן ייבנה מסך הבית עם מאיה (M1.9)', textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.icon, required this.title});
  final IconData icon;
  final String title;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('בקרוב', style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
