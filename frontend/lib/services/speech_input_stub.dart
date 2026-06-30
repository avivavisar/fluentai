// Non-web fallback for speech-to-text (mobile native STT to be added later).
class SpeechInput {
  bool get supported => false;

  void start({
    required void Function(String text, bool isFinal) onResult,
    void Function()? onEnd,
    void Function(String error)? onError,
  }) {
    onError?.call('not_supported');
  }

  void stop() {}
}
