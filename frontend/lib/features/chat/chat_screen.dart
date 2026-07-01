import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_controller.dart';
import '../home/home_providers.dart';
import 'widgets/correction_card.dart';

class _Msg {
  _Msg({required this.role, required this.text, this.corrections = const [], this.newVocab = const []});
  final String role; // 'user' | 'tutor'
  final String text;
  final List corrections;
  final List newVocab;
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _messages = [];
  String? _convId;
  bool _sending = false;
  bool _starting = true;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      final res = await ref.read(apiClientProvider).post('/v1/conversations', {'scenario': 'FREE', 'mode': 'text'}) as Map;
      _convId = (res['conversation'] as Map)['id'].toString();
    } catch (_) {
      /* handled by input being disabled until a conversation exists */
    }
    if (mounted) setState(() => _starting = false);
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending || _convId == null) return;
    _input.clear();
    setState(() {
      _messages.add(_Msg(role: 'user', text: text));
      _sending = true;
    });
    _scrollToEnd();
    try {
      final res = await ref.read(apiClientProvider).post('/v1/conversations/$_convId/messages', {'text': text}) as Map;
      setState(() {
        _messages.add(_Msg(
          role: 'tutor',
          text: res['reply']?.toString() ?? '',
          corrections: (res['corrections'] as List?) ?? const [],
          newVocab: (res['newVocab'] as List?) ?? const [],
        ));
        _sending = false;
      });
    } catch (_) {
      setState(() {
        _messages.add(_Msg(role: 'tutor', text: 'אופס, משהו השתבש. נסה שוב.'));
        _sending = false;
      });
    }
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent + 240, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final companion = ref.watch(companionProvider).valueOrNull;
    final tutorName = (companion?['name']?.toString().trim().isNotEmpty ?? false) ? companion!['name'].toString() : 'Maya';

    return Scaffold(
      appBar: AppBar(title: Text(tutorName)),
      body: Column(
        children: [
          Expanded(
            child: _starting
                ? const Center(child: CircularProgressIndicator())
                : (_messages.isEmpty
                    ? _empty(theme, tutorName)
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length + (_sending ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i >= _messages.length) return _typing(theme, tutorName);
                          return _bubble(theme, _messages[i]);
                        },
                      )),
          ),
          _inputBar(theme),
        ],
      ),
    );
  }

  Widget _empty(ThemeData theme, String tutorName) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(radius: 32, backgroundColor: theme.colorScheme.primary, child: Text(tutorName.substring(0, 1), style: const TextStyle(color: Colors.white, fontSize: 26))),
              const SizedBox(height: 16),
              Text('כתוב ל-$tutorName באנגלית כדי להתחיל', textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text('אפשר פשוט "Hi, how are you?"', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
            ],
          ),
        ),
      );

  Widget _bubble(ThemeData theme, _Msg m) {
    final isUser = m.role == 'user';
    final bg = isUser ? theme.colorScheme.primary : theme.colorScheme.surface;
    final fg = isUser ? Colors.white : theme.colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.80),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(m.text, style: TextStyle(color: fg, fontSize: 16, height: 1.35)),
            ),
          ),
        ),
        if (!isUser && m.corrections.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 24),
            child: Column(children: m.corrections.map((c) => CorrectionCard(correction: c as Map)).toList()),
          ),
        if (!isUser && m.newVocab.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 24),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.end,
              children: m.newVocab.map((v) {
                final term = (v as Map)['term']?.toString() ?? '';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: theme.colorScheme.secondary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: Directionality(textDirection: TextDirection.ltr, child: Text('+ $term', style: TextStyle(color: theme.colorScheme.secondary, fontSize: 13))),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _typing(ThemeData theme, String tutorName) => Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(18)),
          child: Text('$tutorName כותב/ת...', style: theme.textTheme.bodySmall),
        ),
      );

  Widget _inputBar(ThemeData theme) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  textDirection: TextDirection.ltr,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  decoration: const InputDecoration(hintText: 'Type in English...'),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _sending ? null : _send,
                style: FilledButton.styleFrom(shape: const CircleBorder(), minimumSize: const Size(52, 52), padding: EdgeInsets.zero),
                child: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      );
}
