import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../models/correction.dart';
import '../state/providers.dart';
import '../state/session_provider.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String? conversationId; // when set, continue an existing conversation
  const ChatScreen({super.key, this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final _input = TextEditingController();
  final _scroll = ScrollController();
  String? _conversationId;
  bool _starting = true;
  bool _sending = false;
  late bool _defaultHebrew;

  @override
  void initState() {
    super.initState();
    _defaultHebrew =
        (ref.read(sessionProvider).profile?.hebrewSupportLevel ?? 'HEAVY') == 'HEAVY';
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
      if (widget.conversationId != null) {
        _conversationId = widget.conversationId;
        final res = await ref.read(apiProvider).get('/v1/conversations/$_conversationId/messages');
        final msgs = (res['messages'] as List)
            .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
            .toList();
        setState(() {
          _messages.addAll(msgs);
          _starting = false;
        });
      } else {
        final res = await ref
            .read(apiProvider)
            .post('/v1/conversations', {'scenario': 'FREE', 'mode': 'text'});
        setState(() {
          _conversationId = res['conversation']['id'] as String;
          _messages.add(const ChatMessage(
            role: 'assistant',
            content: "Hi! I'm your English tutor. Tell me about your day — in English!",
          ));
          _starting = false;
        });
      }
      _scrollToBottom();
    } catch (_) {
      setState(() => _starting = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _conversationId == null || _sending) return;
    _input.clear();
    setState(() {
      _messages.add(ChatMessage(role: 'user', content: text));
      _sending = true;
    });
    _scrollToBottom();
    try {
      final res = await ref
          .read(apiProvider)
          .post('/v1/conversations/$_conversationId/messages', {'text': text});
      final corrections = ((res['corrections'] as List?) ?? const [])
          .map((e) => Correction.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _messages.add(ChatMessage(
          role: 'assistant',
          content: res['reply'] as String? ?? '',
          corrections: corrections,
        ));
      });
    } catch (e) {
      setState(() {
        _messages.add(const ChatMessage(role: 'assistant', content: '(שגיאה בקבלת תשובה נסה שוב)'));
      });
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('שיחה עם המורה'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              icon: const Icon(Icons.translate, size: 18),
              label: Text(_defaultHebrew ? 'הסבר: עברית' : 'הסבר: EN'),
              onPressed: () => setState(() => _defaultHebrew = !_defaultHebrew),
            ),
          ),
        ],
      ),
      body: _starting
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) =>
                        MessageBubble(message: _messages[i], defaultHebrew: _defaultHebrew),
                  ),
                ),
                if (_sending) const LinearProgressIndicator(),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _input,
                            textDirection: TextDirection.ltr,
                            onSubmitted: (_) => _send(),
                            decoration: const InputDecoration(
                              hintText: 'Type in English...',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _sending ? null : _send,
                          icon: const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
