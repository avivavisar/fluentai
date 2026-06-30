// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

// Plays audio bytes in the browser via a Blob URL — no plugin, no native assets.
void playBytes(Uint8List bytes, String mimeType) {
  final blob = html.Blob(<dynamic>[bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final audio = html.AudioElement(url)..autoplay = true;
  audio.onEnded.listen((_) => html.Url.revokeObjectUrl(url));
  audio.play();
}
