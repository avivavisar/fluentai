import 'dart:js_interop';

// Bridges to window.sttStart/sttStop defined in web/stt.js (browser Web Speech API).
@JS('sttStart')
external void _sttStart(JSString lang, JSFunction onFinal, JSFunction onEnd, JSFunction onError);

@JS('sttStop')
external void _sttStop();

/// Browser speech-to-text (Chrome/Edge). Recognizes one English utterance.
class Stt {
  static void start({
    required void Function(String transcript) onFinal,
    required void Function() onEnd,
    required void Function(String error) onError,
  }) {
    _sttStart(
      'en-US'.toJS,
      ((JSString t) => onFinal(t.toDart)).toJS,
      (() => onEnd()).toJS,
      ((JSString e) => onError(e.toDart)).toJS,
    );
  }

  static void stop() => _sttStop();
}
