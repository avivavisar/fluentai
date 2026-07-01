import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_controller.dart';

/// Dashboard stats for the home screen (CEFR, streak, words, conversations).
final progressProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final data = await api.get('/v1/progress');
  return (data as Map).cast<String, dynamic>();
});
