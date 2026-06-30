import 'correction.dart';

class ChatMessage {
  final String role; // 'user' | 'assistant'
  final String content;
  final List<Correction> corrections;

  const ChatMessage({
    required this.role,
    required this.content,
    this.corrections = const [],
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        role: ((j['role'] as String?) ?? 'assistant').toLowerCase(),
        content: (j['content'] as String?) ?? '',
        corrections: ((j['corrections'] as List?) ?? const [])
            .map((e) => Correction.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
