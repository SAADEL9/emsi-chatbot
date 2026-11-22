import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SessionInfo {
  const SessionInfo({
    required this.id,
    required this.email,
    required this.accessToken,
  });

  final String id;
  final String email;
  final String accessToken;
}

class AuthController extends ChangeNotifier {
  AuthController({this.session});

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  SessionInfo? session;
  StreamSubscription<AuthState>? _authSubscription;
  bool get isSignedIn => session != null;

  static AuthController signedInForTest({
    String id = 'test-user',
    String email = 'demo@emsi.ma',
  }) => AuthController(
    session: SessionInfo(id: id, email: email, accessToken: 'test-token'),
  );

  Future<void> init() async {
    if (!isConfigured) return;
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
    _sync(Supabase.instance.client.auth.currentSession);
    await _authSubscription?.cancel();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      _sync(data.session);
    });
  }

  void _sync(Session? next) {
    final user = next?.user;
    session = user == null
        ? null
        : SessionInfo(
            id: user.id,
            email: user.email ?? '',
            accessToken: next!.accessToken,
          );
    notifyListeners();
  }

  Future<String?> signIn(String email, String password) async {
    _ensureConfigured();
    await Supabase.instance.client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    return null;
  }

  Future<String?> signUp(String email, String password) async {
    _ensureConfigured();
    final result = await Supabase.instance.client.auth.signUp(
      email: email.trim(),
      password: password,
    );
    if (result.session == null) {
      return 'Compte créé. Confirmez votre e-mail, puis reconnectez-vous.';
    }
    return null;
  }

  Future<void> resetPassword(String email) async {
    _ensureConfigured();
    await Supabase.instance.client.auth.resetPasswordForEmail(email.trim());
  }

  Future<void> signOut() async {
    if (!isConfigured) {
      session = null;
      notifyListeners();
      return;
    }
    await Supabase.instance.client.auth.signOut();
  }

  void _ensureConfigured() {
    if (!isConfigured) {
      throw StateError(
        'Ajoutez SUPABASE_URL et SUPABASE_ANON_KEY (voir le README).',
      );
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
