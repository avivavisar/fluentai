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
  String _writingPrompt = '';
  String _writingPromptHe = '';
  final Map<String, String> _answers = {};
  final Set<String> _translated = {};
  bool _writingTranslated = false;
  final _writing = TextEditingController();
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  Map<String, dynamic>? _result;
  List<dynamic>? _review;

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
        _writingPrompt = (data['writingPrompt'] ?? '').toString();
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
        _review = res['review'] as List?;
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
    if (_result != null) return _ResultView(result: _result!, review: _review ?? const []);

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
                  Text('השלם את המילה החסרה בכל משפט — ענה על מה שאתה יכול',
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
                    : Text(_allAnswered ? 'סיים ובדוק' : 'ענה על כל השאלות (${_answers.length}/${_questions.length})'),
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
    final showHe = _translated.contains(id);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('שאלה ${qi + 1}', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => showHe ? _translated.remove(id) : _translated.add(id)),
                icon: const Icon(Icons.translate_rounded, size: 18),
                label: Text(showHe ? 'הסתר' : 'תרגום'),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(q['prompt'].toString(),
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 19), textAlign: TextAlign.left),
            ),
          ),
          if (showHe)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(q['promptHe'].toString(),
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            ),
          const SizedBox(height: 14),
          ...options.map((opt) => _optionTile(theme, id, opt)),
        ],
      ),
    );
  }

  Widget _optionTile(ThemeData theme, String id, String opt) {
    final sel = _answers[id] == opt;
    final primary = theme.colorScheme.primary;
    return GestureDetector(
      onTap: () => setState(() => _answers[id] = opt),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: sel ? primary.withValues(alpha: 0.08) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: sel ? primary : theme.colorScheme.outlineVariant, width: sel ? 2 : 1),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              Icon(sel ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                  size: 20, color: sel ? primary : theme.colorScheme.outline),
              const SizedBox(width: 10),
              Expanded(child: Text(opt, style: const TextStyle(fontSize: 16))),
            ],
          ),
        ),
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
          Row(
            children: [
              Text('כתיבה קצרה', style: theme.textTheme.titleMedium),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => _writingTranslated = !_writingTranslated),
                icon: const Icon(Icons.translate_rounded, size: 18),
                label: Text(_writingTranslated ? 'הסתר' : 'תרגום'),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(_writingPrompt, textAlign: TextAlign.left, style: theme.textTheme.bodyLarge),
            ),
          ),
          if (_writingTranslated)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_writingPromptHe,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            ),
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
  const _ResultView({required this.result, required this.review});
  final Map<String, dynamic> result;
  final List<dynamic> review;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cefr = result['cefrLevel']?.toString() ?? 'A2';
    final rationale = result['rationale']?.toString() ?? '';
    final correct = review.where((r) => (r as Map)['isCorrect'] == true).length;

    return Scaffold(
      appBar: AppBar(title: const Text('הסקירה שלך')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: [
                  Text('ענית נכון על $correct מתוך ${review.length}', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('בוא נראה איפה דייקת ואיפה כדאי ללמוד',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                  const SizedBox(height: 16),
                  if ((result['writingFeedback']?.toString() ?? '').isNotEmpty) ...[
                    _feedbackCard(theme, result['writingFeedback'].toString()),
                    const SizedBox(height: 16),
                  ],
                  ...review.map((r) => _reviewCard(theme, r as Map)),
                  const SizedBox(height: 8),
                  _levelCard(theme, cefr, rationale),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => ref.invalidate(profileProvider),
                  child: const Text('בוא נתחיל ללמוד'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _feedbackCard(ThemeData theme, String feedback) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.primary,
            child: const Text('מ', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('מאיה על הכתיבה שלך', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(feedback, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewCard(ThemeData theme, Map r) {
    final ok = r['isCorrect'] == true;
    final good = Colors.green.shade600;
    final bad = theme.colorScheme.error;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: (ok ? good : bad).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ok ? Icons.check_circle_rounded : Icons.cancel_rounded, color: ok ? good : bad, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(r['prompt'].toString(), textAlign: TextAlign.left, style: theme.textTheme.titleSmall),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _answerRow(theme, 'התשובה שלך', r['chosen'].toString(), ok ? good : bad),
          if (!ok) _answerRow(theme, 'התשובה הנכונה', r['correct'].toString(), good),
          if (!ok && r['explanationHe'] != null) ...[
            const SizedBox(height: 6),
            Text(r['explanationHe'].toString(),
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.75))),
          ],
        ],
      ),
    );
  }

  Widget _answerRow(ThemeData theme, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Text('$label: ', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          Expanded(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(value, textAlign: TextAlign.left, style: theme.textTheme.bodyMedium?.copyWith(color: color)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _levelCard(ThemeData theme, String cefr, String rationale) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Text('הרמה שלך', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(16)),
            child: Text(cefr, style: const TextStyle(color: Colors.white, fontSize: 34)),
          ),
          if (rationale.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(rationale, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.75))),
          ],
        ],
      ),
    );
  }
}
