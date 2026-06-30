import 'dart:typed_data';
import 'api_service.dart';
import 'audio_playback_stub.dart'
    if (dart.library.html) 'audio_playback_web.dart' as playback;

// Plays tutor speech / "say it like a native" audio via the backend TTS endpoint.
class AudioService {
  final ApiService _api;
  AudioService(this._api);

  Future<void> speak(String text, {String? voice}) async {
    final Uint8List bytes = await _api.postForBytes('/v1/speech/tts', {
      'text': text,
      if (voice != null) 'voice': voice,
    });
    playback.playBytes(bytes, 'audio/mpeg');
  }
}
