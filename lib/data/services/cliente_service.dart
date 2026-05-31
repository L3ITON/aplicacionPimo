import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/cliente.dart';
import '../models/contrato.dart';

class ClienteService {
  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = const Uuid();

  Future<List<Cliente>> getClientes({String? busqueda}) async {
    final data = await _client
        .from('clientes')
        .select()
        .order('nombre');

    List<Cliente> clientes =
    (data as List).map((e) => Cliente.fromJson(e)).toList();

    if (busqueda != null && busqueda.isNotEmpty) {
      final q = busqueda.toLowerCase();
      clientes = clientes
          .where((c) =>
      c.nombreCompleto.toLowerCase().contains(q) ||
          (c.dniRuc?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    return clientes;
  }

  Future<Cliente?> getClientePorId(String id) async {
    try {
      final data = await _client
          .from('clientes')
          .select()
          .eq('id', id)
          .single();
      return Cliente.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<Cliente> crearCliente(Map<String, dynamic> payload) async {
    payload['id'] = _uuid.v4();
    final data = await _client
        .from('clientes')
        .insert(payload)
        .select()
        .single();
    return Cliente.fromJson(data);
  }

  Future<Cliente> actualizarCliente(String id, Map<String, dynamic> payload) async {
    final data = await _client
        .from('clientes')
        .update(payload)
        .eq('id', id)
        .select()
        .single();
    return Cliente.fromJson(data);
  }

  Future<List<Contrato>> getContratosDeCliente(String clienteId) async {
    final data = await _client
        .from('contratos')
        .select('*, clientes(*), usuarios(*)')
        .eq('cliente_id', clienteId)
        .order('fecha_inicio', ascending: false);
    return (data as List).map((e) => Contrato.fromJson(e)).toList();
  }
}