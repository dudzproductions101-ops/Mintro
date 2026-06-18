import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

/// Thin wrapper around the Supabase singleton. Call [initialize] once in
/// `main()` before `runApp`.
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }

  static User? get currentUser => client.auth.currentUser;
  static String? get currentUserId => currentUser?.id;
  static String? get accessToken => client.auth.currentSession?.accessToken;

  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  static Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) {
    return client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username, 'display_name': displayName},
    );
  }

  static Future<void> signOut() => client.auth.signOut();

  static Future<void> resetPasswordForEmail(String email) {
    return client.auth.resetPasswordForEmail(email);
  }
}
