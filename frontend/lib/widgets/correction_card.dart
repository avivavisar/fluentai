import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/correction.dart';
import '../state/providers.dart';

class CorrectionCard extends ConsumerStatefulWidget {
  final Correction correction;
  final bool defaultHebrew;
  const CorrectionCard({super.key, required this.correction, required this.defaultHebrew});

  @override
  ConsumerState<CorrectionCard> createState() => _CorrectionCardState();
}

class _CorrectionCardState extends ConsumerState<CorrectionCard> {
  late bool _showHebrew;
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    _showHebrew = widget.defaultHebrew;
  }

  @override
  void didUpdateWidget(covariant CorrectionCard old) {
    super.didUpdateWidget(old);
    if (old.defaultHebrew != widget.defaultHebrew) {
      setState(() => _showHebrew = widget.defaultHebrew);
    }
  }

  Future<void> _sayLikeNative() async {
    if (_speaking) return;
    setState(() => _speaking = true);
    try {
      await ref.read(audioServiceProvider).speak(widget.correction.suggestion);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('השמעה נכשלה')));
      }
    } finally {
      if (mounted) setState(() => _speaking = false);
    }
  }

  Color _severityColor() {
    switch (widget.correction.severity) {
      case 'HIGH':
        return Colors.red.shade400;
      case 'MEDIUM':
        return Colors.orange.shade400;
      default:
        return Colors.blue.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.correction;
    final explanation = _showHebrew ? c.explanationHe : c.explanationEn;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: _severityColor(), shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(c.type, style: Theme.of(context).textTheme.labelSmall),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _showHebrew = !_showHebrew),
                  child: Text(_showHebrew ? 'EN' : 'עברית'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  c.original,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.arrow_forward, size: 16),
                ),
                Text(
                  c.suggestion,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(explanation, textDirection: _showHebrew ? TextDirection.rtl : TextDirection.ltr),
            const SizedBox(height: 6),
            InkWell(
              onTap: _sayLikeNative,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _speaking
                      ? const SizedBox(
                          height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.record_voice_over, size: 18, color: scheme.primary),
                  const SizedBox(width: 4),
                  Text('say it like a native',
                      style: TextStyle(color: scheme.primary, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
