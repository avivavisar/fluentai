import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gotrue/gotrue.dart';
import '../../core/api_client.dart';
import '../../core/auth_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

/// Emits on every auth change (sign-in/out, token refresh).
final authStateChangesProvider = StreamProvider<AuthState>(
  (ref) => AuthClient.instance.client.onAuthStateChange,
);

final authControllerProvider = Provider<AuthController>((ref) => AuthController());

class AuthController {
  GoTrueClient get _auth => AuthClient.instance.client;

  Session? get session => _auth.currentSession;
  User? get user => _auth.currentUser;

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithPassword(email: email.trim(), password: password);
  }

  Future<void> signUp(String email, String password) async {
    await _auth.signUp(email: email.trim(), password: password);
  }

  // Social login uses a redirect flow we'll wire with provider config later.
  Future<void> signInWithGoogle() async => throw UnimplementedError();
  Future<void> signInWithApple() async => throw UnimplementedError();

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
