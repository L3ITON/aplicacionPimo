import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/usuario.dart';
import '../../data/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final usuarioActualProvider = FutureProvider<Usuario?>((ref) async {
  final service = ref.read(authServiceProvider);
  return await service.getUsuarioActual();
});

class AuthNotifier extends StateNotifier<AsyncValue<Usuario?>> {
  final AuthService _service;

  AuthNotifier(this._service) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() async {
    try {
      final usuario = await _service.getUsuarioActual();
      state = AsyncValue.data(usuario);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final usuario = await _service.signIn(email: email, password: password);
      state = AsyncValue.data(usuario);
      return usuario != null;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
    state = const AsyncValue.data(null);
  }

  Future<void> refreshUsuario() async {
    final usuario = await _service.getUsuarioActual();
    state = AsyncValue.data(usuario);
  }
}

final authNotifierProvider =
StateNotifierProvider<AuthNotifier, AsyncValue<Usuario?>>((ref) {
  final service = ref.read(authServiceProvider);
  return AuthNotifier(service);
});