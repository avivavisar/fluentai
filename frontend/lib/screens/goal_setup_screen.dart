import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/providers.dart';
import '../state/session_provider.dart';
import 'placement_test_screen.dart';

class GoalSetupScreen extends ConsumerStatefulWidget {
  const GoalSetupScreen({super.key});

  @override
  ConsumerState<GoalSetupScreen> createState() => _GoalSetupScreenState();
}

class _GoalSetupScreenState extends ConsumerState<GoalSetupScreen> {
  String _goal = 'CASUAL';
  String _support = 'HEAVY';
  final Set<String> _interests = {};
  bool _saving = false;

  static const _goals = {
    'TRAVEL': 'טיולים',
    'BUSINESS': 'עסקים וקריירה',
    'EXAM': 'מבחן',
    'CASUAL': 'כללי',
  };

  static const _interestOptions = {
    'movies': 'סרטים',
    'music': 'מוזיקה',
    'travel': 'טיולים',
    'technology': 'טכנולוגיה',
    'sports': 'ספורט',
    'business': 'עסקים',
    'news': 'חדשות',
    'gaming': 'גיימינג',
  };

  static const _supportLabels = {'NONE': 'ללא', 'LIGHT': 'מעט', 'HEAVY': 'הרבה'};

  Future<void> _continue() async {
    setState(() => _saving = true);
    try {
      await ref.read(apiProvider).patch('/v1/profile', {
        'goal': _goal,
        'interests': _interests.toList(),
        'hebrewSupportLevel': _support,
      });
      await ref.read(sessionProvider.notifier).refreshProfile();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PlacementTestScreen()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('שמירה נכשלה')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('בוא נכיר אותך')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('מה המטרה שלך', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _goals.entries
                .map((e) => ChoiceChip(
                      label: Text(e.value),
                      selected: _goal == e.key,
                      onSelected: (_) => setState(() => _goal = e.key),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
          Text('תחומי עניין', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _interestOptions.entries
                .map((e) => FilterChip(
                      label: Text(e.value),
                      selected: _interests.contains(e.key),
                      onSelected: (sel) => setState(() {
                        if (sel) {
                          _interests.add(e.key);
                        } else {
                          _interests.remove(e.key);
                        }
                      }),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
          Text('כמה תמיכה בעברית תרצה', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: _supportLabels.entries
                .map((e) => ButtonSegment(value: e.key, label: Text(e.value)))
                .toList(),
            selected: {_support},
            onSelectionChanged: (s) => setState(() => _support = s.first),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _saving ? null : _continue,
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('המשך למבחן רמה'),
          ),
        ],
      ),
    );
  }
}
