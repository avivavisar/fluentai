import 'dart:js_interop';

// Bridges to window.recStart/recStop/recError/recMime defined in web/recorder.js.
@JS('recStart')
external JSPromise<JSBoolean> _recStart();

@JS('recStop')
external JSPromise<JSString> _recStop();

@JS('recError')
external JSString _recError();

@JS('recMime')
external JSString _recMime();

/// Records the microphone (MediaRecorder) and returns base64 of a compressed audio
/// blob; the server decodes it to PCM for Azure STT. Reliable on iOS Safari.
class Recorder {
  static Future<bool> start() async {
    final ok = await _recStart().toDart;
    return ok.toDart;
  }

  static Future<String> stop() async {
    final b64 = await _recStop().toDart;
    return b64.toDart;
  }

  static String mime() => _recMime().toDart;
  static String lastError() => _recError().toDart;
}
