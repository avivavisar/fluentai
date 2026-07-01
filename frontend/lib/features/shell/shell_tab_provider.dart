import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Currently selected bottom-nav tab (0=home, 1=chat, 2=words, 3=progress).
/// Shared so the home "Talk to your tutor" CTA can jump to the chat tab.
final shellTabProvider = StateProvider<int>((ref) => 0);
