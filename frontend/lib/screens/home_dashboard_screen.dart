import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/progress.dart';
import '../state/providers.dart';
import '../state/session_provider.dart';
import '../theme.dart';
import 'talk_screen.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';

class HomeDashboardScreen extends ConsumerStatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  ConsumerState<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  Progress? _progress;
  List<Map<String, dynamic>> _conversations = [];
  bool _loading = true;

  static const _scenarios = [
    {'key': 'FREE', 'label': 'שיחה חופשית', 'icon': Icons.chat_bubble_outline},
    {'key': 'TRAVEL', 'label': 'טיולים', 'icon': Icons.flight_takeoff},
    {'key': 'BUSINESS', 'label': 'עסקים', 'icon': Icons.work_outline},
    {'key': 'INTERVIEW', 'label': 'ראיון עבודה', 'icon': Icons.record_voice_over},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final progressRes = await ref.read(apiProvider).get('/v1/progress');
      final convRes = await ref.read(apiProvider).get('/v1/conversations');
      setState(() {
        _progress = Progress.fromJson(progressRes as Map<String, dynamic>);
        _conversations =
            ((convRes['conversations'] as List?) ?? const []).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _openTalk({String scenario = 'FREE', String? conversationId}) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TalkScreen(scenario: scenario, conversationId: conversationId),
    ));
    _load();
  }

  Future<void> _openTextChat({String? conversationId}) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChatScreen(conversationId: conversationId),
    ));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final profile = ref.watch(sessionProvider).profile;
    final name = profile?.displayName ?? '';
    final cefr = _progress?.cefrLevel ?? profile?.cefrLevel ?? '-';

    return Scaffold(
      appBar: AppBar(
        title: const Text('FluentAI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              _load();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('שלום $name 👋', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text('רמה $cefr', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  _talkHero(scheme),
                  const SizedBox(height: 16),
                  Text('תרחישים', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _scenarioTiles(scheme),
                  const SizedBox(height: 16),
                  _statsRow(),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.keyboard),
                    label: const Text('צ׳אט בטקסט'),
                    onPressed: () => _openTextChat(),
                  ),
                  const SizedBox(height: 20),
                  if (_conversations.isNotEmpty) ...[
                    Text('השיחות שלי', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ..._conversations.map(_conversationTile),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _talkHero(ColorScheme scheme) {
    return GestureDetector(
      onTap: () => _openTalk(),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [scheme.primary, scheme.tertiary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(color: seedColor.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              child: const Icon(Icons.mic, color: Colors.white, size: 34),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('דבר עם המורה',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('שיחה קולית באנגלית עם פידבק מיידי',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _scenarioTiles(ColorScheme scheme) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: _scenarios.map((s) {
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openTalk(scenario: s['key'] as String),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(s['icon'] as IconData, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(s['label'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _statsRow() {
    Widget chip(IconData icon, String value, String label) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        );
    return Row(
      children: [
        chip(Icons.bolt, '${_progress?.xp ?? 0}', 'XP'),
        const SizedBox(width: 10),
        chip(Icons.local_fire_department, '${_progress?.streak ?? 0}', 'רצף'),
        const SizedBox(width: 10),
        chip(Icons.menu_book, '${_progress?.wordsLearned ?? 0}', 'מילים'),
      ],
    );
  }

  Widget _conversationTile(Map<String, dynamic> c) {
    final last = (c['lastMessage'] as String?)?.trim();
    final count = c['messageCount'] ?? 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.forum_outlined),
        title: Text(
          (last == null || last.isEmpty) ? 'שיחה' : last,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textDirection: TextDirection.ltr,
        ),
        subtitle: Text('$count הודעות'),
        trailing: const Icon(Icons.chevron_left),
        onTap: () => _openTalk(conversationId: c['id'] as String),
      ),
    );
  }
}
