import 'dart:convert';
import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Play MP3 bytes in the browser via a data URL (web target). Calls [onEnded] when done.
void playAudioBytes(Uint8List bytes, {void Function()? onEnded}) {
  final b64 = base64Encode(bytes);
  final audio = web.document.createElement('audio') as web.HTMLAudioElement;
  audio.src = 'data:audio/mpeg;base64,$b64';
  if (onEnded != null) {
    audio.addEventListener('ended', ((web.Event _) => onEnded()).toJS);
  }
  audio.play();
}
