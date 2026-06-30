// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

// Browser-based speech-to-text using the Web Speech API (Chrome/Edge).
class SpeechInput {
  html.SpeechRecognition? _rec;

  bool get supported => html.SpeechRecognition.supported;

  void start({
    required void Function(String text, bool isFinal) onResult,
    void Function()? onEnd,
    void Function(String error)? onError,
  }) {
    if (!html.SpeechRecognition.supported) {
      onError?.call('not_supported');
      return;
    }
    final rec = html.SpeechRecognition();
    _rec = rec;
    rec.lang = 'en-US';
    rec.interimResults = true;
    rec.continuous = false;

    rec.onResult.listen((ev) {
      final results = ev.results;
      if (results == null) return;
      final sb = StringBuffer();
      var isFinal = false;
      for (final res in results) {
        final alt = res.item(0);
        sb.write(alt.transcript);
        if (res.isFinal == true) isFinal = true;
      }
      onResult(sb.toString(), isFinal);
    });
    rec.onError.listen((_) => onError?.call('error'));
    rec.onEnd.listen((_) => onEnd?.call());
    rec.start();
  }

  void stop() {
    try {
      _rec?.stop();
    } catch (_) {}
  }
}
