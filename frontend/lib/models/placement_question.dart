class PlacementQuestion {
  final String id;
  final String level;
  final String prompt;
  final String promptHe;
  final List<String> options;

  const PlacementQuestion({
    required this.id,
    required this.level,
    required this.prompt,
    required this.promptHe,
    required this.options,
  });

  factory PlacementQuestion.fromJson(Map<String, dynamic> j) => PlacementQuestion(
        id: j['id'] as String,
        level: (j['level'] as String?) ?? '',
        prompt: (j['prompt'] as String?) ?? '',
        promptHe: (j['promptHe'] as String?) ?? '',
        options:
            (j['options'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      );
}
