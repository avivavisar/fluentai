import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/audio_web.dart';
import '../../core/stt_web.dart';
import '../auth/auth_controller.dart';
import '../home/home_providers.dart';

enum _TalkState { idle, listening, thinking, speaking }

class TalkScreen extends ConsumerStatefulWidget {
  const TalkScreen({super.key});
  @override
  ConsumerState<TalkScreen> createState() => _TalkScreenState();
}

class _TalkScreenState extends ConsumerState<TalkScreen> with SingleTickerProviderStateMixin {
  _TalkState _state = _TalkState.idle;
  String? _convId;
  String _userText = '';
  String _tutorText = '';
  String? _error;
  late final AnimationController _pulse;
  Timer? _pollTimer;
  Timer? _listenTimeout;
  Timer? _thinkTimeout;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
    _startConversation();
  }

  Future<void> _startConversation() async {
    try {
      final res = await ref.read(apiClientProvider).post('/v1/conversations', {'scenario': 'FREE', 'mode': 'voice'}) as Map;
      _convId = (res['conversation'] as Map)['id'].toString();
    } catch (_) {
      if (mounted) setState(() => _error = 'לא הצלחתי להתחבר לשרת');
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _pollTimer?.cancel();
    _listenTimeout?.cancel();
    _thinkTimeout?.cancel();
    Stt.stop();
    super.dispose();
  }

  void _toggleMic() {
    if (_state == _TalkState.idle) {
      _beginListening();
    } else if (_state == _TalkState.listening) {
      Stt.stop(); // final/ended will be picked up by the poll loop
    }
  }

  void _beginListening() {
    setState(() {
      _state = _TalkState.listening;
      _userText = '';
      _tutorText = '';
      _error = null;
    });
    Stt.start();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 250), (_) => _pollStt());
    _listenTimeout?.cancel();
    _listenTimeout = Timer(const Duration(seconds: 15), () {
      if (_state == _TalkState.listening) Stt.stop();
    });
  }

  void _pollStt() {
    final s = Stt.poll();
    if (s.transcript.isNotEmpty && s.transcript != _userText) {
      setState(() => _userText = s.transcript); // live interim transcript
    }
    switch (s.status) {
      case 'final':
        _stopListening();
        if (s.transcript.trim().isNotEmpty) {
          _send(s.transcript.trim());
        } else {
          setState(() => _state = _TalkState.idle);
        }
        break;
      case 'ended':
        _stopListening();
        setState(() => _state = _TalkState.idle);
        break;
      case 'error':
        _stopListening();
        setState(() {
          _state = _TalkState.idle;
          _error = s.error == 'unsupported'
              ? 'זיהוי דיבור נתמך ב-Chrome או Edge — פתח שם'
              : (s.error == 'not-allowed' ? 'צריך לאשר הרשאת מיקרופון' : 'לא שמעתי, נסה שוב');
        });
        break;
    }
  }

  void _stopListening() {
    _pollTimer?.cancel();
    _listenTimeout?.cancel();
  }

  Future<void> _send(String text) async {
    if (_convId == null) {
      setState(() => _state = _TalkState.idle);
      return;
    }
    setState(() {
      _userText = text;
      _state = _TalkState.thinking;
    });
    _thinkTimeout?.cancel();
    _thinkTimeout = Timer(const Duration(seconds: 40), () {
      if (_state == _TalkState.thinking && mounted) {
        setState(() {
          _state = _TalkState.idle;
          _error = 'לקח יותר מדי זמן, נסה שוב';
        });
      }
    });
    try {
      final res = await ref.read(apiClientProvider).post('/v1/conversations/$_convId/messages', {'text': text}) as Map;
      _thinkTimeout?.cancel();
      final reply = res['reply']?.toString() ?? '';
      if (!mounted) return;
      setState(() {
        _tutorText = reply;
        _state = _TalkState.speaking;
      });
      final bytes = await ref.read(apiClientProvider).postBytes('/v1/speech/tts', {'text': reply});
      playAudioBytes(bytes, onEnded: () {
        if (mounted) setState(() => _state = _TalkState.idle);
      });
    } catch (_) {
      _thinkTimeout?.cancel();
      if (mounted) {
        setState(() {
          _state = _TalkState.idle;
          _error = 'משהו השתבש, נסה שוב';
        });
      }
    }
  }

  String get _status {
    switch (_state) {
      case _TalkState.listening:
        return 'מקשיב/ה לך... דבר/י באנגלית';
      case _TalkState.thinking:
        return 'חושב/ת...';
      case _TalkState.speaking:
        return 'מדבר/ת...';
      case _TalkState.idle:
        return 'הקש/י על המיקרופון ודבר/י';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final companion = ref.watch(companionProvider).valueOrNull;
    final tutorName = (companion?['name']?.toString().trim().isNotEmpty ?? false) ? companion!['name'].toString() : 'Maya';
    final active = _state == _TalkState.listening || _state == _TalkState.speaking;
    final micColor = _state == _TalkState.listening ? scheme.secondary : scheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(tutorName),
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).maybePop()),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) {
                final scale = active ? (1 + _pulse.value * 0.12) : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                    child: _state == _TalkState.thinking
                        ? const Center(child: SizedBox(width: 34, height: 34, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)))
                        : Center(child: Text(tutorName.substring(0, 1), style: const TextStyle(color: Colors.white, fontSize: 56))),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
            Text(_status, style: theme.textTheme.titleMedium?.copyWith(color: scheme.onSurface.withValues(alpha: 0.7))),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: scheme.error)),
            ],
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    if (_userText.isNotEmpty) _line(theme, 'אתה', _userText, scheme.onSurface.withValues(alpha: 0.6)),
                    if (_tutorText.isNotEmpty) _line(theme, tutorName, _tutorText, scheme.onSurface),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 28, top: 8),
              child: GestureDetector(
                onTap: _toggleMic,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(color: micColor, shape: BoxShape.circle),
                  child: Icon(
                    _state == _TalkState.listening ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(ThemeData theme, String who, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(who, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: 2),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(text, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge?.copyWith(color: color, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
