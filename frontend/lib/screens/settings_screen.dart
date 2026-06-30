import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/providers.dart';
import '../state/session_provider.dart';
import 'login_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _supportLabels = {'NONE': 'ללא', 'LIGHT': 'מעט', 'HEAVY': 'הרבה'};
  bool _saving = false;

  Future<void> _setSupport(String level) async {
    setState(() => _saving = true);
    try {
      await ref.read(apiProvider).patch('/v1/profile', {'hebrewSupportLevel': level});
      await ref.read(sessionProvider.notifier).refreshProfile();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(sessionProvider).profile;
    final support = profile?.hebrewSupportLevel ?? 'HEAVY';
    return Scaffold(
      appBar: AppBar(title: const Text('הגדרות')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(title: const Text('אימייל'), subtitle: Text(profile?.displayName ?? '')),
          const Divider(),
          const Text('רמת תמיכה בעברית', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: _supportLabels.entries
                .map((e) => ButtonSegment(value: e.key, label: Text(e.value)))
                .toList(),
            selected: {support},
            onSelectionChanged: _saving ? null : (s) => _setSupport(s.first),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('התנתק'),
            onPressed: () async {
              await ref.read(sessionProvider.notifier).logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (r) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
