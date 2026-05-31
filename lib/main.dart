import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/supabase_constants.dart';
import 'core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/asistencia_screen.dart';
import 'presentation/screens/inventario_screen.dart';
import 'presentation/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
  );
  runApp(const ProviderScope(child: PimoApp()));
}

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
    GoRoute(path: '/asistencia', builder: (_, __) => const AsistenciaScreen()),
    GoRoute(path: '/inventario', builder: (_, __) => const InventarioScreen()),
  ],
);

class PimoApp extends ConsumerWidget {
  const PimoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Distribuidora Pimo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}