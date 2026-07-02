import 'dart:js_interop';

// Bridges to window.recStart/recStop/recError defined in web/recorder.js.
@JS('recStart')
external JSPromise<JSBoolean> _recStart();

@JS('recStop')
external JSString _recStop();

@JS('recError')
external JSString _recError();

/// Records the microphone as base64 16 kHz mono PCM for server-side (Azure) transcription.
class Recorder {
  static Future<bool> start() async {
    final ok = await _recStart().toDart;
    return ok.toDart;
  }

  static String stop() => _recStop().toDart;
  static String lastError() => _recError().toDart;
}
