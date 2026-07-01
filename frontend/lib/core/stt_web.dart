import 'dart:convert';
import 'dart:js_interop';

// Bridges to window.sttStart/sttStop/sttPoll defined in web/stt.js.
@JS('sttStart')
external void _sttStart(JSString lang);

@JS('sttStop')
external void _sttStop();

@JS('sttPoll')
external JSString _sttPoll();

class SttState {
  SttState(this.status, this.transcript, this.error);
  final String status; // idle | listening | final | ended | error
  final String transcript;
  final String error;
}

/// Browser speech-to-text (Chrome/Edge), polled for progress.
class Stt {
  static void start([String lang = 'en-US']) => _sttStart(lang.toJS);
  static void stop() => _sttStop();

  static SttState poll() {
    final m = jsonDecode(_sttPoll().toDart) as Map<String, dynamic>;
    return SttState(
      m['status']?.toString() ?? 'idle',
      m['transcript']?.toString() ?? '',
      m['error']?.toString() ?? '',
    );
  }
}
