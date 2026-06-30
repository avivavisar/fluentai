import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_controller.dart';

/// The current user's profile (drives the onboarding → placement → app gate).
final profileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final data = await api.get('/v1/profile');
  return (data as Map).cast<String, dynamic>();
});
