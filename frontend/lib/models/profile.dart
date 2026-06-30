class Profile {
  final String? displayName;
  final String? cefrLevel;
  final String goal;
  final List<String> interests;
  final String hebrewSupportLevel;
  final bool voiceEnabled;
  final bool onboardingComplete;

  const Profile({
    this.displayName,
    this.cefrLevel,
    required this.goal,
    required this.interests,
    required this.hebrewSupportLevel,
    required this.voiceEnabled,
    required this.onboardingComplete,
  });

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        displayName: j['displayName'] as String?,
        cefrLevel: j['cefrLevel'] as String?,
        goal: (j['goal'] as String?) ?? 'CASUAL',
        interests:
            (j['interests'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        hebrewSupportLevel: (j['hebrewSupportLevel'] as String?) ?? 'HEAVY',
        voiceEnabled: (j['voiceEnabled'] as bool?) ?? true,
        onboardingComplete: (j['onboardingComplete'] as bool?) ?? false,
      );
}
