import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../state/providers.dart';
import 'correction_card.dart';

class MessageBubble extends ConsumerStatefulWidget {
  final ChatMessage message;
  final bool defaultHebrew;
  const MessageBubble({super.key, required this.message, required this.defaultHebrew});

  @override
  ConsumerState<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends ConsumerState<MessageBubble> {
  String? _translation;
  bool _translating = false;
  bool _speaking = false;

  Future<void> _speak() async {
    if (_speaking) return;
    setState(() => _speaking = true);
    try {
      await ref.read(audioServiceProvider).speak(widget.message.content);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('השמעה נכשלה')));
      }
    } finally {
      if (mounted) setState(() => _speaking = false);
    }
  }

  Future<void> _toggleTranslate() async {
    if (_translating) return;
    if (_translation != null) {
      setState(() => _translation = null);
      return;
    }
    setState(() => _translating = true);
    try {
      final res = await ref
          .read(apiProvider)
          .post('/v1/translate', {'text': widget.message.content});
      setState(() => _translation = res['hebrew'] as String?);
    } catch (_) {
      setState(() => _translation = '(תרגום נכשל)');
    } finally {
      if (mounted) setState(() => _translating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.role == 'user';
    final scheme = Theme.of(context).colorScheme;
    final bubbleColor = isUser ? scheme.primaryContainer : scheme.surfaceContainerHighest;

    final bubble = Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
      decoration: BoxDecoration(color: bubbleColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message.content, textDirection: TextDirection.ltr, textAlign: TextAlign.left),
          if (!isUser) ...[
            const Divider(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: _speak,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _speaking
                          ? const SizedBox(
                              height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.volume_up, size: 18, color: scheme.primary),
                      const SizedBox(width: 4),
                      Text('השמע', style: TextStyle(color: scheme.primary, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: _toggleTranslate,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _translating
                          ? const SizedBox(
                              height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.translate, size: 18, color: scheme.primary),
                      const SizedBox(width: 4),
                      Text(_translation == null ? 'תרגם' : 'הסתר',
                          style: TextStyle(color: scheme.primary, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            if (_translation != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(_translation!, textDirection: TextDirection.rtl),
              ),
          ],
        ],
      ),
    );

    return Column(
      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(alignment: isUser ? Alignment.centerRight : Alignment.centerLeft, child: bubble),
        if (widget.message.corrections.isNotEmpty)
          ...widget.message.corrections.map(
            (c) => CorrectionCard(correction: c, defaultHebrew: widget.defaultHebrew),
          ),
      ],
    );
  }
}
