import 'dart:convert';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

/// Play MP3 bytes in the browser via a data URL (web target).
void playAudioBytes(Uint8List bytes) {
  final b64 = base64Encode(bytes);
  final audio = web.document.createElement('audio') as web.HTMLAudioElement;
  audio.src = 'data:audio/mpeg;base64,$b64';
  audio.play();
}
