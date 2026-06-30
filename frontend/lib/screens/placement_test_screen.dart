import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/placement_question.dart';
import '../state/providers.dart';
import '../state/session_provider.dart';
import 'placement_result_screen.dart';

class PlacementTestScreen extends ConsumerStatefulWidget {
  const PlacementTestScreen({super.key});

  @override
  ConsumerState<PlacementTestScreen> createState() => _PlacementTestScreenState();
}

class _PlacementTestScreenState extends ConsumerState<PlacementTestScreen> {
  List<PlacementQuestion> _questions = [];
  String _writingPrompt = '';
  String _writingPromptHe = '';
  final Map<String, String> _answers = {};
  final _writing = TextEditingController();
  bool _loading = true;
  bool _submitting = false;
  String? _error;

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
      final res = await ref.read(apiProvider).get('/v1/placement/questions');
      setState(() {
        _questions = (res['questions'] as List)
            .map((e) => PlacementQuestion.fromJson(e as Map<String, dynamic>))
            .toList();
        _writingPrompt = res['writingPrompt'] as String? ?? '';
        _writingPromptHe = res['writingPromptHe'] as String? ?? '';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'טעינת המבחן נכשלה';
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final answers = _answers.entries.map((e) => {'id': e.key, 'answer': e.value}).toList();
      final res = await ref.read(apiProvider).post('/v1/placement/submit', {
        'answers': answers,
        'writingSample': _writing.text.trim(),
      });
      await ref.read(apiProvider).patch('/v1/profile', {'onboardingComplete': true});
      await ref.read(sessionProvider.notifier).refreshProfile();
      if (!mounted) return;
      final result = res['result'] as Map<String, dynamic>;
      final review = ((res['review'] as List?) ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => PlacementResultScreen(
            cefrLevel: result['cefrLevel'].toString(),
            rationale: result['rationale']?.toString() ?? '',
            review: review,
          ),
        ),
        (r) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('שליחת המבחן נכשלה')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(body: Center(child: Text(_error!)));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('מבחן רמה')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('בחר את התשובה הנכונה לכל משפט',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('מתחת לכל משפט יש תרגום לעברית', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          ..._questions.map(_buildQuestion),
          const SizedBox(height: 16),
          Text(_writingPrompt,
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          if (_writingPromptHe.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(_writingPromptHe,
                  textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.grey)),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _writing,
            maxLines: 4,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Write your answer in English...',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('סיים ובדוק רמה'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildQuestion(PlacementQuestion q) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q.prompt,
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            if (q.promptHe.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(q.promptHe,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            ...q.options.map((opt) {
              final selected = _answers[q.id] == opt;
              return ListTile(
                dense: true,
                leading: Icon(
                    selected ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                title: Text(opt, textDirection: TextDirection.ltr),
                onTap: () => setState(() => _answers[q.id] = opt),
              );
            }),
          ],
        ),
      ),
    );
  }
}
