import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/auth/login_screen.dart';
import '../services/supabase_service.dart';
import 'root_shell.dart';

/// Listens to Supabase auth state and shows [LoginScreen] or [RootShell]
/// accordingly. Wrapping the whole app in this means no manual navigation
/// is needed on sign-in/sign-out — the stream rebuild handles it.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: SupabaseService.authStateChanges,
      builder: (context, snapshot) {
        final session = SupabaseService.client.auth.currentSession;
        return session != null ? const RootShell() : const LoginScreen();
      },
    );
  }
}
