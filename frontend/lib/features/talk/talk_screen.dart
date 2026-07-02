import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/audio_web.dart';
import '../../core/recorder_web.dart';
import '../auth/auth_controller.dart';
import '../home/home_providers.dart';

enum _TalkState { idle, recording, thinking, speaking }

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
  Timer? _recordTimeout;
  Timer? _thinkTimeout;
  bool _busy = false; // guards double-taps while starting/stopping

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
    _recordTimeout?.cancel();
    _thinkTimeout?.cancel();
    if (_state == _TalkState.recording) Recorder.stop();
    super.dispose();
  }

  Future<void> _toggleMic() async {
    if (_busy) return;
    if (_state == _TalkState.idle) {
      await _startRecording();
    } else if (_state == _TalkState.recording) {
      await _stopAndSend();
    }
  }

  Future<void> _startRecording() async {
    _busy = true;
    primeAudio(); // unlock audio within this tap so the tutor's voice can auto-play (mobile)
    setState(() {
      _userText = '';
      _tutorText = '';
      _error = null;
    });
    final ok = await Recorder.start();
    _busy = false;
    if (!ok) {
      if (mounted) {
        final err = Recorder.lastError();
        setState(() => _error = err.contains('NotAllowed') || err.contains('Denied')
            ? 'צריך לאשר הרשאת מיקרופון'
            : 'לא הצלחתי לגשת למיקרופון');
      }
      return;
    }
    if (!mounted) return;
    setState(() => _state = _TalkState.recording);
    _recordTimeout?.cancel();
    _recordTimeout = Timer(const Duration(seconds: 30), () {
      if (_state == _TalkState.recording) _stopAndSend();
    });
  }

  Future<void> _stopAndSend() async {
    _busy = true;
    _recordTimeout?.cancel();
    final audioBase64 = Recorder.stop();
    setState(() => _state = _TalkState.thinking);
    _busy = false;
    if (audioBase64.isEmpty) {
      if (mounted) setState(() => _state = _TalkState.idle);
      return;
    }
    _thinkTimeout?.cancel();
    _thinkTimeout = Timer(const Duration(seconds: 45), () {
      if (_state == _TalkState.thinking && mounted) {
        setState(() {
          _state = _TalkState.idle;
          _error = 'לקח יותר מדי זמן, נסה שוב';
        });
      }
    });
    try {
      final stt = await ref.read(apiClientProvider).post('/v1/speech/stt', {'audioBase64': audioBase64}) as Map;
      final text = stt['text']?.toString().trim() ?? '';
      if (text.isEmpty) {
        _thinkTimeout?.cancel();
        if (mounted) {
          setState(() {
            _state = _TalkState.idle;
            _error = 'לא שמעתי אותך, נסה/י לדבר קצת יותר בקול';
          });
        }
        return;
      }
      if (mounted) setState(() => _userText = text);
      await _send(text);
    } catch (_) {
      _thinkTimeout?.cancel();
      if (mounted) {
        setState(() {
          _state = _TalkState.idle;
          _error = 'משהו השתבש בתמלול, נסה שוב';
        });
      }
    }
  }

  Future<void> _send(String text) async {
    if (_convId == null) {
      _thinkTimeout?.cancel();
      setState(() => _state = _TalkState.idle);
      return;
    }
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
      case _TalkState.recording:
        return 'מקליט/ה... דבר/י באנגלית ואז הקש/י לסיום';
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
    final active = _state == _TalkState.recording || _state == _TalkState.speaking;
    final micColor = _state == _TalkState.recording ? scheme.secondary : scheme.primary;

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
            Text(_status, textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(color: scheme.onSurface.withValues(alpha: 0.7))),
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
                    _state == _TalkState.recording ? Icons.stop_rounded : Icons.mic_rounded,
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
