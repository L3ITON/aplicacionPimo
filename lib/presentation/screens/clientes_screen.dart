import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/cliente.dart';
import '../providers/clientes_provider.dart';
import '../providers/contratos_provider.dart';
import '../screens/estado_chip.dart';


class ClientesScreen extends ConsumerStatefulWidget {
  const ClientesScreen({super.key});

  @override
  ConsumerState<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends ConsumerState<ClientesScreen> {
  final _busquedaCtrl = TextEditingController();

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientesAsync = ref.watch(clientesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _busquedaCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o DNI/RUC...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _busquedaCtrl.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _busquedaCtrl.clear();
                    ref
                        .read(clientesProvider.notifier)
                        .cargar();
                  },
                )
                    : null,
              ),
              onChanged: (v) {
                ref.read(clientesProvider.notifier).cargar(busqueda: v);
              },
            ),
          ),
          Expanded(
            child: clientesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: const TextStyle(color: AppTheme.errorColor))),
              data: (clientes) {
                if (clientes.isEmpty) {
                  return const Center(
                      child: Text('No se encontraron clientes'));
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.read(clientesProvider.notifier).cargar(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: clientes.length,
                    itemBuilder: (context, i) {
                      final c = clientes[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryColor,
                            child: Text(
                              c.nombre.isNotEmpty
                                  ? c.nombre[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(c.nombreCompleto,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (c.dniRuc != null)
                                Text(c.dniRuc!,
                                    style: const TextStyle(fontSize: 12)),
                              if (c.telefono != null)
                                Text(c.telefono!,
                                    style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          trailing:
                          const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DetalleClienteScreen(cliente: c),
                            ),
                          ).then((_) => ref
                              .read(clientesProvider.notifier)
                              .cargar()),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (_) => const FormularioClienteScreen()),
          );
          if (result == true) {
            ref.read(clientesProvider.notifier).cargar();
          }
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

// ─── Detalle Cliente ──────────────────────────────────────────────────────────

class DetalleClienteScreen extends ConsumerWidget {
  final Cliente cliente;

  const DetalleClienteScreen({super.key, required this.cliente});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(cliente.nombreCompleto),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      FormularioClienteScreen(cliente: cliente)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Center(
              child: CircleAvatar(
                radius: 42,
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  cliente.nombre.isNotEmpty
                      ? cliente.nombre[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                cliente.nombreCompleto,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 24),

            // Info
            _InfoSection(titulo: 'Datos personales', filas: [
              _InfoFila('DNI / RUC', cliente.dniRuc ?? '-'),
              _InfoFila('Teléfono', cliente.telefono ?? '-'),
              _InfoFila('Email', cliente.email ?? '-'),
              _InfoFila('Dirección', cliente.direccion ?? '-'),
            ]),
            const SizedBox(height: 20),

            // Contratos del cliente
            const Text('Historial de contratos',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor)),
            const SizedBox(height: 10),
            _HistorialContratos(clienteId: cliente.id),
          ],
        ),
      ),
    );
  }
}

class _HistorialContratos extends ConsumerStatefulWidget {
  final String clienteId;

  const _HistorialContratos({required this.clienteId});

  @override
  ConsumerState<_HistorialContratos> createState() =>
      _HistorialContratosState();
}

class _HistorialContratosState extends ConsumerState<_HistorialContratos> {
  List<dynamic>? _contratos;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final service = ref.read(clienteServiceProvider);
      final lista = await service.getContratosDeCliente(widget.clienteId);
      setState(() {
        _contratos = lista;
        _cargando = false;
      });
    } catch (_) {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_contratos == null || _contratos!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Center(
          child: Text('Sin contratos registrados',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
      );
    }

    return Column(
      children: _contratos!.map((c) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppDateUtils.formatDate(c.fechaInicio)} → ${AppDateUtils.formatDate(c.fechaFinEstimada)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Text('S/ ${c.montoTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.primaryColor)),
                  ],
                ),
              ),
              EstadoChip(estado: c.estado),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String titulo;
  final List<Widget> filas;

  const _InfoSection({required this.titulo, required this.filas});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(children: filas),
        ),
      ],
    );
  }
}

class _InfoFila extends StatelessWidget {
  final String label;
  final String valor;

  const _InfoFila(this.label, this.valor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary)),
          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.end,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Formulario Cliente ───────────────────────────────────────────────────────

class FormularioClienteScreen extends ConsumerStatefulWidget {
  final Cliente? cliente;

  const FormularioClienteScreen({super.key, this.cliente});

  @override
  ConsumerState<FormularioClienteScreen> createState() =>
      _FormularioClienteScreenState();
}

class _FormularioClienteScreenState
    extends ConsumerState<FormularioClienteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _dniRucCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  bool _cargando = false;

  bool get esEdicion => widget.cliente != null;

  @override
  void initState() {
    super.initState();
    if (esEdicion) {
      final c = widget.cliente!;
      _nombreCtrl.text = c.nombre;
      _apellidoCtrl.text = c.apellido;
      _dniRucCtrl.text = c.dniRuc ?? '';
      _telefonoCtrl.text = c.telefono ?? '';
      _emailCtrl.text = c.email ?? '';
      _direccionCtrl.text = c.direccion ?? '';
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _dniRucCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);

    final payload = {
      'nombre': _nombreCtrl.text.trim(),
      'apellido': _apellidoCtrl.text.trim(),
      'dni_ruc': _dniRucCtrl.text.trim(),
      'telefono': _telefonoCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'direccion': _direccionCtrl.text.trim(),
    };

    try {
      final service = ref.read(clienteServiceProvider);
      Cliente resultado;
      if (esEdicion) {
        resultado =
        await service.actualizarCliente(widget.cliente!.id, payload);
      } else {
        resultado = await service.crearCliente(payload);
      }
      ref.read(clientesProvider.notifier).cargar();
      if (mounted) {
        if (esEdicion) {
          Navigator.pop(context, true);
        } else {
          // Devolver el cliente creado para usarlo en selector
          Navigator.pop(context, resultado);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
            Text(esEdicion ? 'Cliente actualizado' : 'Cliente creado'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(esEdicion ? 'Editar Cliente' : 'Nuevo Cliente'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nombreCtrl,
                    decoration:
                    const InputDecoration(labelText: 'Nombre *'),
                    validator: (v) =>
                    v == null || v.isEmpty ? 'Campo requerido' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _apellidoCtrl,
                    decoration:
                    const InputDecoration(labelText: 'Apellido *'),
                    validator: (v) =>
                    v == null || v.isEmpty ? 'Campo requerido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dniRucCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'DNI / RUC'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefonoCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Teléfono'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration:
              const InputDecoration(labelText: 'Correo electrónico'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _direccionCtrl,
              decoration: const InputDecoration(labelText: 'Dirección'),
              maxLines: 2,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _cargando ? null : _guardar,
                child: _cargando
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
                    : Text(esEdicion ? 'Actualizar' : 'Crear Cliente'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}