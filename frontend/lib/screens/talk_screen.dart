import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/correction.dart';
import '../state/providers.dart';
import '../services/speech_input.dart';

enum TalkState { idle, listening, thinking, speaking }

class TalkScreen extends ConsumerStatefulWidget {
  final String scenario;
  final String? conversationId;
  const TalkScreen({super.key, this.scenario = 'FREE', this.conversationId});

  @override
  ConsumerState<TalkScreen> createState() => _TalkScreenState();
}

class _TalkScreenState extends ConsumerState<TalkScreen>
    with SingleTickerProviderStateMixin {
  final SpeechInput _speech = SpeechInput();
  late final AnimationController _pulse;
  String? _conversationId;
  TalkState _state = TalkState.idle;
  String _transcript = '';
  String _tutorText = '';
  List<Correction> _corrections = [];
  Map<String, dynamic>? _coaching;
  String _status = 'הקש על המיקרופון כדי לדבר';
  bool _starting = true;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _start();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      if (widget.conversationId != null) {
        _conversationId = widget.conversationId;
      } else {
        final res = await ref.read(apiProvider).post(
          '/v1/conversations',
          {'scenario': widget.scenario, 'mode': 'voice'},
        );
        _conversationId = res['conversation']['id'] as String;
      }
      _tutorText = "Hi! I'm your English tutor. Tap the mic and tell me about your day.";
      setState(() => _starting = false);
      await _speakTutor(_tutorText);
    } catch (_) {
      setState(() => _starting = false);
    }
  }

  void _toggleMic() {
    if (_state == TalkState.listening) {
      _speech.stop();
      return;
    }
    if (!_speech.supported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('זיהוי דיבור נתמך ב-Chrome או Edge')),
      );
      return;
    }
    setState(() {
      _state = TalkState.listening;
      _transcript = '';
      _corrections = [];
      _coaching = null;
      _status = 'מקשיב... דבר באנגלית';
    });
    _speech.start(
      onResult: (text, isFinal) {
        setState(() => _transcript = text);
        if (isFinal) _onFinal(text);
      },
      onError: (_) => setState(() {
        _state = TalkState.idle;
        _status = 'לא נשמע ברור נסה שוב';
      }),
      onEnd: () {
        if (_state == TalkState.listening && _transcript.trim().isEmpty) {
          setState(() {
            _state = TalkState.idle;
            _status = 'הקש על המיקרופון כדי לדבר';
          });
        }
      },
    );
  }

  Future<void> _onFinal(String text) async {
    if (text.trim().isEmpty || _conversationId == null) return;
    _speech.stop();
    setState(() {
      _state = TalkState.thinking;
      _status = 'המורה חושב...';
    });
    try {
      final res = await ref.read(apiProvider).post(
        '/v1/conversations/$_conversationId/messages',
        {'text': text},
      );
      final corrections = ((res['corrections'] as List?) ?? const [])
          .map((e) => Correction.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _tutorText = res['reply'] as String? ?? '';
        _corrections = corrections;
        _coaching = res['coaching'] as Map<String, dynamic>?;
      });
      await _speakTutor(_tutorText);
    } catch (_) {
      setState(() {
        _state = TalkState.idle;
        _status = 'שגיאה נסה שוב';
      });
    }
  }

  Future<void> _speakTutor(String text) async {
    setState(() {
      _state = TalkState.speaking;
      _status = 'המורה מדבר...';
    });
    try {
      await ref.read(audioServiceProvider).speak(text);
    } catch (_) {}
    if (mounted) {
      setState(() {
        _state = TalkState.idle;
        _status = 'הקש על המיקרופון כדי לדבר';
      });
    }
  }

  Future<void> _sayNative(String phrase) async {
    try {
      await ref.read(audioServiceProvider).speak(phrase);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = _state == TalkState.listening || _state == TalkState.speaking;
    final busy = _state == TalkState.thinking || _state == TalkState.speaking;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [scheme.primaryContainer, scheme.surface],
          ),
        ),
        child: SafeArea(
          child: _starting
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const Spacer(),
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, __) {
                        final scale = active ? 1.0 + _pulse.value * 0.12 : 1.0;
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 168,
                            height: 168,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [scheme.primary, scheme.tertiary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: scheme.primary.withValues(alpha: 0.45),
                                  blurRadius: 44,
                                  spreadRadius: 6,
                                ),
                              ],
                            ),
                            child: Icon(
                              _state == TalkState.speaking
                                  ? Icons.graphic_eq
                                  : (_state == TalkState.listening
                                      ? Icons.hearing
                                      : Icons.school),
                              color: Colors.white,
                              size: 68,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(_status, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Text(
                        _state == TalkState.listening && _transcript.isNotEmpty
                            ? _transcript
                            : _tutorText,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.ltr,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_corrections.isNotEmpty) _feedbackStrip(scheme),
                    if (_coaching != null) _coachingStrip(scheme),
                    const Spacer(),
                    GestureDetector(
                      onTap: busy ? null : _toggleMic,
                      child: Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _state == TalkState.listening
                              ? Colors.redAccent
                              : (busy ? Colors.grey : scheme.primary),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 14),
                          ],
                        ),
                        child: Icon(
                          _state == TalkState.listening ? Icons.stop : Icons.mic,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _coachingStrip(ColorScheme scheme) {
    final fluency = _coaching?['fluency_he']?.toString() ?? '';
    final tone = _coaching?['tone_he']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (fluency.isNotEmpty)
            Row(children: [
              const Icon(Icons.speed, size: 16),
              const SizedBox(width: 6),
              Expanded(child: Text('שטף: $fluency', textAlign: TextAlign.right)),
            ]),
          if (tone.isNotEmpty) const SizedBox(height: 4),
          if (tone.isNotEmpty)
            Row(children: [
              const Icon(Icons.emoji_emotions_outlined, size: 16),
              const SizedBox(width: 6),
              Expanded(child: Text('טון: $tone', textAlign: TextAlign.right)),
            ]),
        ],
      ),
    );
  }

  Widget _feedbackStrip(ColorScheme scheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _corrections.take(2).map((c) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.tips_and_updates, size: 18, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${c.original}  →  ${c.suggestion}',
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.record_voice_over, size: 20, color: scheme.primary),
                  onPressed: () => _sayNative(c.suggestion),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
