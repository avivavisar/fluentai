class Correction {
  final String type;
  final String original;
  final String suggestion;
  final String explanationEn;
  final String explanationHe;
  final String severity;

  const Correction({
    required this.type,
    required this.original,
    required this.suggestion,
    required this.explanationEn,
    required this.explanationHe,
    required this.severity,
  });

  factory Correction.fromJson(Map<String, dynamic> j) => Correction(
        type: (j['type'] as String?) ?? 'GRAMMAR',
        original: (j['original'] as String?) ?? '',
        suggestion: (j['suggestion'] as String?) ?? '',
        explanationEn: (j['explanationEn'] ?? j['explanation_en'] ?? '') as String,
        explanationHe: (j['explanationHe'] ?? j['explanation_he'] ?? '') as String,
        severity: (j['severity'] as String?) ?? 'LOW',
      );
}
