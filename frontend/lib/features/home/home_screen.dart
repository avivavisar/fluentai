import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_controller.dart';
import '../profile/profile_providers.dart';
import '../shell/shell_tab_provider.dart';
import 'home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'בוקר טוב';
    if (h < 18) return 'צהריים טובים';
    return 'ערב טוב';
  }

  String _name(WidgetRef ref) {
    final p = ref.watch(profileProvider).valueOrNull;
    final display = p?['displayName'];
    if (display is String && display.trim().isNotEmpty) return display;
    final email = ref.read(authControllerProvider).user?.email ?? '';
    final prefix = email.split('@').first;
    return prefix.isEmpty ? 'לומד/ת' : prefix;
  }

  void _soon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('בקרוב — אנחנו בונים את זה עכשיו'), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final progress = ref.watch(progressProvider).valueOrNull;
    final cefr = progress?['cefrLevel']?.toString() ?? '—';
    final words = (progress?['wordsLearned'] ?? 0).toString();
    final convos = (progress?['conversationsCount'] ?? 0).toString();
    final streak = (progress?['streak'] ?? 0).toString();
    final companion = ref.watch(companionProvider).valueOrNull;
    final tutorName = (companion?['name']?.toString().trim().isNotEmpty ?? false) ? companion!['name'].toString() : 'Maya';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(progressProvider);
            ref.invalidate(profileProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_greeting(), style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurface.withValues(alpha: 0.5))),
                        Text(_name(ref), style: theme.textTheme.headlineSmall),
                      ],
                    ),
                  ),
                  _StreakPill(days: streak),
                  IconButton(
                    tooltip: 'התנתקות',
                    onPressed: () => ref.read(authControllerProvider).signOut(),
                    icon: const Icon(Icons.logout_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _MayaBubble(
                avatarText: tutorName.substring(0, 1),
                text: '$tutorName: טוב לראות אותך, ${_name(ref)}! מוכנים לשיעור קצר היום?',
              ),
              const SizedBox(height: 18),
              _TalkCta(onTap: () => ref.read(shellTabProvider.notifier).state = 1),
              const SizedBox(height: 22),
              Text('המשימה של היום', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              _TaskTile(icon: Icons.edit_rounded, title: 'תרגול זמן עבר', minutes: '5 דק׳', onTap: () => _soon(context)),
              _TaskTile(icon: Icons.menu_book_rounded, title: '5 מילים לחזרה', minutes: '3 דק׳', onTap: () => _soon(context)),
              _TaskTile(icon: Icons.local_cafe_rounded, title: 'סיטואציה: בבית קפה', minutes: '7 דק׳', onTap: () => _soon(context)),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(child: _StatCard(label: 'רמה', value: cefr)),
                  const SizedBox(width: 10),
                  Expanded(child: _StatCard(label: 'מילים', value: words)),
                  const SizedBox(width: 10),
                  Expanded(child: _StatCard(label: 'שיחות', value: convos)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.days});
  final String days;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: theme.colorScheme.secondary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded, size: 18, color: theme.colorScheme.secondary),
          const SizedBox(width: 4),
          Text('$days ימים', style: theme.textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _MayaBubble extends StatelessWidget {
  const _MayaBubble({required this.text, required this.avatarText});
  final String text;
  final String avatarText;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(radius: 20, backgroundColor: theme.colorScheme.primary, child: Text(avatarText, style: const TextStyle(color: Colors.white, fontSize: 16))),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(18)),
            child: Text(text, style: theme.textTheme.bodyLarge?.copyWith(height: 1.4)),
          ),
        ),
      ],
    );
  }
}

class _TalkCta extends StatelessWidget {
  const _TalkCta({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(22)),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
              child: const Icon(Icons.mic_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('דבר עם המורה', style: TextStyle(color: Colors.white, fontSize: 18)),
                  SizedBox(height: 2),
                  Text('שיחה קולית · 5 דקות', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28),
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.icon, required this.title, required this.minutes, required this.onTap});
  final IconData icon;
  final String title;
  final String minutes;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
            Text(minutes, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
            const SizedBox(width: 4),
            Icon(Icons.chevron_left_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.headlineSmall),
        ],
      ),
    );
  }
}
