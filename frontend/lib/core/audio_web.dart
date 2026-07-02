import 'dart:convert';
import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

// Tiny silent WAV to "unlock" audio on the first user gesture (mobile/iOS autoplay policy).
const _silentWav =
    'data:audio/wav;base64,UklGRiQAAABXQVZFZm10IBAAAAABAAEAgD4AAAB9AAACABAAZGF0YQAAAAA=';

// Single reusable element: once it has played within a user gesture, later plays are allowed.
web.HTMLAudioElement? _player;
web.HTMLAudioElement _ensure() =>
    _player ??= (web.document.createElement('audio') as web.HTMLAudioElement);

/// Call inside a user gesture (e.g. the mic tap) so later programmatic playback works on mobile.
void primeAudio() {
  final a = _ensure();
  a.src = _silentWav;
  a.play();
}

/// Play MP3 bytes, reusing the primed element so mobile autoplay policies don't block it.
void playAudioBytes(Uint8List bytes, {void Function()? onEnded}) {
  final a = _ensure();
  a.onended = onEnded == null ? null : ((web.Event _) => onEnded()).toJS;
  a.src = 'data:audio/mpeg;base64,${base64Encode(bytes)}';
  a.play();
}
