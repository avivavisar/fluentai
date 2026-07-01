import 'package:flutter/material.dart';

/// A gentle correction: original → suggestion, with an English explanation and
/// an on-demand Hebrew translation (never red-pen).
class CorrectionCard extends StatefulWidget {
  const CorrectionCard({super.key, required this.correction});
  final Map correction;
  @override
  State<CorrectionCard> createState() => _CorrectionCardState();
}

class _CorrectionCardState extends State<CorrectionCard> {
  bool _he = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = widget.correction;
    final original = c['original']?.toString() ?? '';
    final suggestion = c['suggestion']?.toString() ?? '';
    final expEn = c['explanation_en']?.toString() ?? '';
    final expHe = c['explanation_he']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(original, style: TextStyle(decoration: TextDecoration.lineThrough, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.arrow_forward_rounded, size: 16)),
                Text(suggestion, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(_he ? expHe : expEn, style: theme.textTheme.bodyMedium),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _he = !_he),
              icon: const Icon(Icons.translate_rounded, size: 16),
              label: Text(_he ? 'English' : 'תרגום'),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ),
        ],
      ),
    );
  }
}
