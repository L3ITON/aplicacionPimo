import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  bool get isLoggedIn => currentUser != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<Usuario?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      print('LOGIN OK');
      print(response.user?.id);

      if (response.user == null) return null;

      return await getUsuarioActual();
    } catch (e) {
      print('ERROR LOGIN: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<Usuario?> getUsuarioActual() async {
    final user = currentUser;
    if (user == null) return null;

    final data = await _client
        .from('usuarios')
        .select()
        .eq('id', user.id)
        .single();

    return Usuario.fromJson(data);
  }

  Future<void> updatePerfil({
    required String nombre,
    required String apellido,
    required String telefono,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('No hay sesión activa');

    await _client.from('usuarios').update({
      'nombre': nombre,
      'apellido': apellido,
      'telefono': telefono,
    }).eq('id', user.id);
  }
}