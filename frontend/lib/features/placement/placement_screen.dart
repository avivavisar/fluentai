import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_controller.dart';
import '../profile/profile_providers.dart';

class PlacementScreen extends ConsumerStatefulWidget {
  const PlacementScreen({super.key});
  @override
  ConsumerState<PlacementScreen> createState() => _PlacementScreenState();
}

class _PlacementScreenState extends ConsumerState<PlacementScreen> {
  List<dynamic> _questions = [];
  String _writingPromptHe = '';
  final Map<String, String> _answers = {};
  final _writing = TextEditingController();
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _writing.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await ref.read(apiClientProvider).get('/v1/placement/questions') as Map;
      setState(() {
        _questions = data['questions'] as List;
        _writingPromptHe = (data['writingPromptHe'] ?? '').toString();
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'טעינת המבחן נכשלה';
        _loading = false;
      });
    }
  }

  bool get _allAnswered => _answers.length == _questions.length && _questions.isNotEmpty;

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final res = await ref.read(apiClientProvider).post('/v1/placement/submit', {
        'answers': _answers.entries.map((e) => {'id': e.key, 'answer': e.value}).toList(),
        'writingSample': _writing.text,
      }) as Map;
      setState(() {
        _result = (res['result'] as Map).cast<String, dynamic>();
        _submitting = false;
      });
    } catch (_) {
      setState(() {
        _error = 'שליחת המבחן נכשלה, נסה שוב';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_result != null) return _ResultView(result: _result!);

    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('מבחן רמה')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: [
                  Text('ענה על מה שאתה יכול — זה עוזר לי למצוא את הרמה שלך',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                  const SizedBox(height: 16),
                  for (var qi = 0; qi < _questions.length; qi++) _questionCard(theme, qi),
                  _writingCard(theme),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: FilledButton(
                onPressed: (_allAnswered && !_submitting) ? _submit : null,
                child: _submitting
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : Text(_allAnswered ? 'סיים ובדוק רמה' : 'ענה על כל השאלות (${_answers.length}/${_questions.length})'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _questionCard(ThemeData theme, int qi) {
    final q = _questions[qi] as Map;
    final id = q['id'].toString();
    final options = (q['options'] as List).cast<String>();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${qi + 1}. ${q['prompt']}', style: theme.textTheme.titleMedium),
          Text(q['promptHe'].toString(), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 12),
          ...options.map((opt) {
            final sel = _answers[id] == opt;
            final primary = theme.colorScheme.primary;
            return GestureDetector(
              onTap: () => setState(() => _answers[id] = opt),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: sel ? primary.withValues(alpha: 0.08) : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: sel ? primary : theme.colorScheme.outlineVariant, width: sel ? 2 : 1),
                ),
                child: Row(
                  children: [
                    Icon(sel ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                        size: 20, color: sel ? primary : theme.colorScheme.outline),
                    const SizedBox(width: 10),
                    Expanded(child: Text(opt, textDirection: TextDirection.ltr, textAlign: TextAlign.left)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _writingCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('כתיבה קצרה', style: theme.textTheme.titleMedium),
          Text(_writingPromptHe, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 12),
          TextField(
            controller: _writing,
            maxLines: 4,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(hintText: 'Write here in English...'),
          ),
        ],
      ),
    );
  }
}

class _ResultView extends ConsumerWidget {
  const _ResultView({required this.result});
  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cefr = result['cefrLevel']?.toString() ?? 'A2';
    final rationale = result['rationale']?.toString() ?? '';
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Icon(Icons.emoji_events_rounded, size: 56, color: theme.colorScheme.secondary),
              const SizedBox(height: 16),
              Text('הרמה שלך', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(20)),
                child: Text(cefr, style: const TextStyle(color: Colors.white, fontSize: 40)),
              ),
              const SizedBox(height: 20),
              Text(rationale, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => ref.invalidate(profileProvider),
                  child: const Text('בוא נתחיל ללמוד'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
