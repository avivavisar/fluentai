import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_controller.dart';
import '../profile/profile_providers.dart';

const _goals = <({String value, String label, IconData icon})>[
  (value: 'TRAVEL', label: 'טיולים בחו״ל', icon: Icons.flight_takeoff_rounded),
  (value: 'BUSINESS', label: 'עבודה ועסקים', icon: Icons.work_outline_rounded),
  (value: 'EXAM', label: 'מבחן או לימודים', icon: Icons.school_outlined),
  (value: 'CASUAL', label: 'שיחה כללית', icon: Icons.chat_bubble_outline_rounded),
];

const _interestOptions = <({String value, String label})>[
  (value: 'technology', label: 'טכנולוגיה'),
  (value: 'startups', label: 'סטארטאפים'),
  (value: 'sports', label: 'ספורט'),
  (value: 'travel', label: 'נסיעות'),
  (value: 'music', label: 'מוזיקה'),
  (value: 'food', label: 'אוכל'),
  (value: 'movies', label: 'סרטים וסדרות'),
  (value: 'news', label: 'חדשות'),
  (value: 'gaming', label: 'גיימינג'),
  (value: 'business', label: 'עסקים'),
];

const _support = <({String value, String label, String desc})>[
  (value: 'HEAVY', label: 'הרבה עברית', desc: 'הסברים נשענים על עברית — מצוין למתחילים'),
  (value: 'LIGHT', label: 'קצת עברית', desc: 'אנגלית קודם, ועברית כעזר קצר'),
  (value: 'NONE', label: 'באנגלית בלבד', desc: 'שקיעה מלאה, בלי עברית'),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  String? _goal;
  final Set<String> _interests = {};
  String _supportLevel = 'HEAVY';
  bool _saving = false;
  String? _error;

  bool get _canProceed {
    if (_step == 1) return _goal != null;
    return true;
  }

  Future<void> _next() async {
    if (_step < 3) {
      setState(() => _step++);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(apiClientProvider).post('/v1/profile/onboarding', {
        'goal': _goal,
        'interests': _interests.toList(),
        'hebrewSupportLevel': _supportLevel,
      });
      ref.invalidate(profileProvider); // Gate advances to the placement test.
    } catch (_) {
      setState(() {
        _error = 'שמירה נכשלה, נסה שוב';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  if (_step > 0)
                    IconButton(
                      onPressed: _saving ? null : () => setState(() => _step--),
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                  Expanded(child: _Dots(count: 4, current: _step)),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: _buildStep(theme),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: FilledButton(
                onPressed: (_canProceed && !_saving) ? _next : null,
                child: _saving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : Text(_step < 3 ? 'המשך' : 'סיום'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(ThemeData theme) {
    switch (_step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: theme.colorScheme.primary,
                child: const Text('מ', style: TextStyle(color: Colors.white, fontSize: 30)),
              ),
            ),
            const SizedBox(height: 20),
            Text('היי, אני מאיה', textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'המורה הפרטית שלך לאנגלית\nשלוש שאלות קצרות ומתחילים ללמוד',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
          ],
        );
      case 1:
        return _StepLayout(
          title: 'מה המטרה שלך?',
          subtitle: 'כדי שאתאים לך את השיעורים',
          child: Column(
            children: _goals
                .map((g) => _OptionTile(
                      label: g.label,
                      icon: g.icon,
                      selected: _goal == g.value,
                      onTap: () => setState(() => _goal = g.value),
                    ))
                .toList(),
          ),
        );
      case 2:
        return _StepLayout(
          title: 'מה מעניין אותך?',
          subtitle: 'כדי שהשיחות יהיו רלוונטיות (אפשר לבחור כמה)',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _interestOptions.map((i) {
              final sel = _interests.contains(i.value);
              return FilterChip(
                label: Text(i.label),
                selected: sel,
                onSelected: (_) => setState(() => sel ? _interests.remove(i.value) : _interests.add(i.value)),
                showCheckmark: false,
              );
            }).toList(),
          ),
        );
      default:
        return _StepLayout(
          title: 'כמה עברית שאעזור בה?',
          subtitle: 'תמיד אפשר לשנות בהמשך',
          child: Column(
            children: _support
                .map((s) => _OptionTile(
                      label: s.label,
                      description: s.desc,
                      selected: _supportLevel == s.value,
                      onTap: () => setState(() => _supportLevel = s.value),
                    ))
                .toList(),
          ),
        );
    }
  }
}

class _StepLayout extends StatelessWidget {
  const _StepLayout({required this.title, required this.subtitle, required this.child});
  final String title;
  final String subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
        const SizedBox(height: 20),
        child,
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.label, required this.selected, required this.onTap, this.icon, this.description});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? primary.withValues(alpha: 0.08) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? primary : theme.colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: selected ? primary : theme.colorScheme.onSurface),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.titleMedium?.copyWith(color: selected ? primary : theme.colorScheme.onSurface)),
                  if (description != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(description!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                    ),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle_rounded, color: primary, size: 22),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current});
  final int count;
  final int current;
  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final on = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: on ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: on ? primary : primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
