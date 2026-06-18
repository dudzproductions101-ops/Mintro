import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routes/auth_gate.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const ProviderScope(child: MintroApp()));
}

class MintroApp extends StatelessWidget {
  const MintroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mintro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}
