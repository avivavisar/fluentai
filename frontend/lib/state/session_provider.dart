import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile.dart';
import 'providers.dart';

class Session {
  final String? token;
  final Profile? profile;
  final bool loading;
  const Session({this.token, this.profile, this.loading = false});

  bool get isLoggedIn => token != null;

  Session copyWith({String? token, Profile? profile, bool? loading}) => Session(
        token: token ?? this.token,
        profile: profile ?? this.profile,
        loading: loading ?? this.loading,
      );
}

class SessionNotifier extends StateNotifier<Session> {
  final Ref ref;
  SessionNotifier(this.ref) : super(const Session());

  Future<void> bootstrap() async {
    final token = await ref.read(storageProvider).readToken();
    if (token == null) {
      state = const Session();
      return;
    }
    try {
      final res = await ref.read(apiProvider).get('/v1/profile');
      state = Session(
        token: token,
        profile: Profile.fromJson(res['profile'] as Map<String, dynamic>),
      );
    } catch (_) {
      await ref.read(storageProvider).clear();
      state = const Session();
    }
  }

  Future<void> signup(String email, String password, String displayName) async {
    final res = await ref.read(apiProvider).post(
      '/v1/auth/signup',
      {'email': email, 'password': password, 'displayName': displayName},
      auth: false,
    );
    await ref.read(storageProvider).saveToken(res['token'] as String);
    final profileJson = (res['user']?['profile']) as Map<String, dynamic>?;
    state = Session(
      token: res['token'] as String,
      profile: profileJson != null ? Profile.fromJson(profileJson) : null,
    );
  }

  Future<void> login(String email, String password) async {
    final res = await ref.read(apiProvider).post(
      '/v1/auth/login',
      {'email': email, 'password': password},
      auth: false,
    );
    await ref.read(storageProvider).saveToken(res['token'] as String);
    final profileJson = (res['user']?['profile']) as Map<String, dynamic>?;
    state = Session(
      token: res['token'] as String,
      profile: profileJson != null ? Profile.fromJson(profileJson) : null,
    );
  }

  Future<void> refreshProfile() async {
    if (state.token == null) return;
    final res = await ref.read(apiProvider).get('/v1/profile');
    state = state.copyWith(
      profile: Profile.fromJson(res['profile'] as Map<String, dynamic>),
    );
  }

  void setProfile(Profile p) => state = state.copyWith(profile: p);

  Future<void> logout() async {
    await ref.read(storageProvider).clear();
    state = const Session();
  }
}

final sessionProvider =
    StateNotifierProvider<SessionNotifier, Session>((ref) => SessionNotifier(ref));
