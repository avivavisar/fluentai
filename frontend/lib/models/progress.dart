class Progress {
  final String? cefrLevel;
  final double cefrConfidence;
  final int xp;
  final int level;
  final int streak;
  final int wordsLearned;
  final int conversationsCount;

  const Progress({
    this.cefrLevel,
    required this.cefrConfidence,
    required this.xp,
    required this.level,
    required this.streak,
    required this.wordsLearned,
    required this.conversationsCount,
  });

  factory Progress.fromJson(Map<String, dynamic> j) => Progress(
        cefrLevel: j['cefrLevel'] as String?,
        cefrConfidence: (j['cefrConfidence'] as num?)?.toDouble() ?? 0,
        xp: (j['xp'] as num?)?.toInt() ?? 0,
        level: (j['level'] as num?)?.toInt() ?? 1,
        streak: (j['streak'] as num?)?.toInt() ?? 0,
        wordsLearned: (j['wordsLearned'] as num?)?.toInt() ?? 0,
        conversationsCount: (j['conversationsCount'] as num?)?.toInt() ?? 0,
      );
}
