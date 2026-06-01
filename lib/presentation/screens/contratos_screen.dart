import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/contrato.dart';
import '../../../data/models/cliente.dart';
import '../../../data/models/producto.dart';
import '../../../data/services/contrato_service.dart';
import '../../../data/services/cliente_service.dart';
import '../../../data/services/inventario_service.dart';
import '../providers/contratos_provider.dart';
import '../providers/inventario_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/clientes_provider.dart';
import '../screens/estado_chip.dart';
import '../screens/inventario_screen.dart';
import '../screens/clientes_screen.dart';



class ContratosScreen extends ConsumerStatefulWidget {
  const ContratosScreen({super.key});

  @override
  ConsumerState<ContratosScreen> createState() => _ContratosScreenState();
}

class _ContratosScreenState extends ConsumerState<ContratosScreen> {
  final _busquedaCtrl = TextEditingController();
  String? _estadoFiltro;

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  void _aplicarFiltro() {
    ref.read(contratosProvider.notifier).cargar(
      estado: _estadoFiltro,
      busqueda: _busquedaCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final contratosAsync = ref.watch(contratosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contratos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: Column(
        children: [
          // Buscador y filtro
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _busquedaCtrl,
                  decoration: InputDecoration(
                    hintText: 'Buscar por cliente...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _busquedaCtrl.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _busquedaCtrl.clear();
                        _aplicarFiltro();
                      },
                    )
                        : null,
                  ),
                  onChanged: (_) => _aplicarFiltro(),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FiltroChip(
                        label: 'Todos',
                        seleccionado: _estadoFiltro == null,
                        onTap: () {
                          setState(() => _estadoFiltro = null);
                          _aplicarFiltro();
                        },
                      ),
                      _FiltroChip(
                        label: 'Activos',
                        seleccionado: _estadoFiltro == 'activo',
                        onTap: () {
                          setState(() => _estadoFiltro = 'activo');
                          _aplicarFiltro();
                        },
                      ),
                      _FiltroChip(
                        label: 'Cerrados',
                        seleccionado: _estadoFiltro == 'cerrado',
                        onTap: () {
                          setState(() => _estadoFiltro = 'cerrado');
                          _aplicarFiltro();
                        },
                      ),
                      _FiltroChip(
                        label: 'Vencidos',
                        seleccionado: _estadoFiltro == 'vencido',
                        onTap: () {
                          setState(() => _estadoFiltro = 'vencido');
                          _aplicarFiltro();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Lista
          Expanded(
            child: contratosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: const TextStyle(color: AppTheme.errorColor))),
              data: (contratos) {
                if (contratos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.description_outlined,
                            size: 64, color: AppTheme.textSecondary),
                        const SizedBox(height: 16),
                        const Text('No se encontraron contratos'),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => _aplicarFiltro(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: contratos.length,
                    itemBuilder: (context, i) {
                      return _ContratoCard(
                        contrato: contratos[i],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                DetalleContratoScreen(contrato: contratos[i]),
                          ),
                        ).then((_) => _aplicarFiltro()),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CrearContratoScreen()),
        ).then((_) => _aplicarFiltro()),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Contrato'),
      ),
    );
  }
}

class _FiltroChip extends StatelessWidget {
  final String label;
  final bool seleccionado;
  final VoidCallback onTap;

  const _FiltroChip({
    required this.label,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: seleccionado ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: seleccionado ? AppTheme.primaryColor : AppTheme.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: seleccionado ? Colors.white : AppTheme.textSecondary,
            fontSize: 13,
            fontWeight:
            seleccionado ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ContratoCard extends StatelessWidget {
  final Contrato contrato;
  final VoidCallback onTap;

  const _ContratoCard({required this.contrato, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final diasRestantes =
        contrato.fechaFinEstimada.difference(DateTime.now()).inDays;
    final proxAVencer = contrato.proxAVencer;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: proxAVencer
            ? const BorderSide(color: Color(0xFFF59E0B), width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      contrato.cliente?.nombreCompleto ?? 'Cliente',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  EstadoChip(estado: contrato.estado),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${AppDateUtils.formatDate(contrato.fechaInicio)} → ${AppDateUtils.formatDate(contrato.fechaFinEstimada)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'S/ ${contrato.montoTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  if (proxAVencer)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        diasRestantes == 0
                            ? 'Vence hoy'
                            : 'Vence en $diasRestantes días',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFB45309),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Detalle Contrato ─────────────────────────────────────────────────────────

class DetalleContratoScreen extends ConsumerStatefulWidget {
  final Contrato contrato;

  const DetalleContratoScreen({super.key, required this.contrato});

  @override
  ConsumerState<DetalleContratoScreen> createState() =>
      _DetalleContratoScreenState();
}

class _DetalleContratoScreenState
    extends ConsumerState<DetalleContratoScreen> {
  bool _cargando = false;

  Future<void> _cerrarContrato() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar contrato'),
        content: const Text(
            '¿Confirmas el cierre de este contrato? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cerrar contrato')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _cargando = true);
    try {
      await ref
          .read(contratoServiceProvider)
          .cerrarContrato(widget.contrato.id);
      ref.read(contratosProvider.notifier).cargar();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Contrato cerrado'),
              backgroundColor: AppTheme.successColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.contrato;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Contrato'),
        actions: [
          if (c.estado == 'activo')
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'cerrar') _cerrarContrato();
                if (v == 'devolucion') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RegistrarDevolucionScreen(contrato: c),
                    ),
                  );
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'devolucion',
                    child: Text('Registrar devolución')),
                const PopupMenuItem(
                    value: 'cerrar', child: Text('Cerrar contrato')),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estado banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Estado del contrato',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary)),
                      const SizedBox(height: 4),
                      EstadoChip(estado: c.estado),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Monto total',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary)),
                      Text(
                        'S/ ${c.montoTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Cliente
            _Seccion(titulo: 'Cliente', items: [
              _Fila('Nombre', c.cliente?.nombreCompleto ?? 'Sin nombre'),
              _Fila('DNI/RUC', c.cliente?.dniRuc ?? '-'),
              _Fila('Teléfono', c.cliente?.telefono ?? '-'),
            ]),
            const SizedBox(height: 12),

            // Fechas
            _Seccion(titulo: 'Fechas', items: [
              _Fila('Inicio', AppDateUtils.formatDate(c.fechaInicio)),
              _Fila('Fin estimado',
                  AppDateUtils.formatDate(c.fechaFinEstimada)),
              if (c.fechaFinReal != null)
                _Fila('Fin real', AppDateUtils.formatDate(c.fechaFinReal!)),
            ]),
            const SizedBox(height: 12),

            // Financiero
            _Seccion(titulo: 'Detalle financiero', items: [
              _Fila(
                  'Monto total', 'S/ ${c.montoTotal.toStringAsFixed(2)}'),
              if (c.depositoGarantia != null)
                _Fila('Depósito garantía',
                    'S/ ${c.depositoGarantia!.toStringAsFixed(2)}'),
            ]),
            const SizedBox(height: 12),

            // Productos
            if (c.detalles != null && c.detalles!.isNotEmpty) ...[
              const Text('Productos contratados',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor)),
              const SizedBox(height: 8),
              ...c.detalles!.map((d) => _ProductoDetalleCard(detalle: d)),
              const SizedBox(height: 12),
            ],

            // Observaciones
            if (c.observaciones != null && c.observaciones!.isNotEmpty) ...[
              _Seccion(titulo: 'Observaciones', items: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Text(c.observaciones!,
                      style: const TextStyle(
                          color: AppTheme.textSecondary)),
                ),
              ]),
            ],

            const SizedBox(height: 24),
            if (c.estado == 'activo') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.assignment_return_outlined),
                  label: const Text('Registrar devolución'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RegistrarDevolucionScreen(contrato: c),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.close),
                  label: const Text('Cerrar contrato'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                    side: const BorderSide(color: AppTheme.errorColor),
                  ),
                  onPressed: _cargando ? null : _cerrarContrato,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  final String titulo;
  final List<Widget> items;

  const _Seccion({required this.titulo, required this.items});

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
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  final String label;
  final String valor;

  const _Fila(this.label, this.valor);

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
            child: Text(valor,
                textAlign: TextAlign.end,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _ProductoDetalleCard extends StatelessWidget {
  final detalle;

  const _ProductoDetalleCard({required this.detalle});

  @override
  Widget build(BuildContext context) {
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
          const Icon(Icons.inventory_2_outlined,
              color: AppTheme.primaryColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detalle.producto?.nombre ?? 'Producto',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Cant: ${detalle.cantidad}  ·  S/ ${detalle.precioUnitarioDia.toStringAsFixed(2)}/día',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            'S/ ${detalle.subtotal.toStringAsFixed(2)}',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }
}

// ─── Crear Contrato ───────────────────────────────────────────────────────────

class CrearContratoScreen extends ConsumerStatefulWidget {
  const CrearContratoScreen({super.key});

  @override
  ConsumerState<CrearContratoScreen> createState() =>
      _CrearContratoScreenState();
}

class _CrearContratoScreenState extends ConsumerState<CrearContratoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _observacionCtrl = TextEditingController();
  final _depositoCtrl = TextEditingController();

  Cliente? _clienteSeleccionado;
  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaFin = DateTime.now().add(const Duration(days: 7));
  final List<_ItemContrato> _items = [];
  bool _cargando = false;

  @override
  void dispose() {
    _observacionCtrl.dispose();
    _depositoCtrl.dispose();
    super.dispose();
  }

  int get _diasContrato =>
      _fechaFin.difference(_fechaInicio).inDays.clamp(1, 9999);

  double get _montoTotal => _items.fold(
      0,
          (sum, item) =>
      sum + (item.cantidad * (item.producto.precioAlquilerDia ?? 0) * _diasContrato));

  Future<void> _seleccionarCliente() async {
    final cliente = await Navigator.push<Cliente>(
      context,
      MaterialPageRoute(builder: (_) => const _SelectorClienteScreen()),
    );
    if (cliente != null) setState(() => _clienteSeleccionado = cliente);
  }

  Future<void> _agregarProducto() async {
    final item = await Navigator.push<_ItemContrato>(
      context,
      MaterialPageRoute(builder: (_) => const _SelectorProductoScreen()),
    );
    if (item != null) {
      setState(() {
        final existente =
        _items.indexWhere((i) => i.producto.id == item.producto.id);
        if (existente >= 0) {
          _items[existente] = _ItemContrato(
            producto: item.producto,
            cantidad: _items[existente].cantidad + item.cantidad,
          );
        } else {
          _items.add(item);
        }
      });
    }
  }

  Future<void> _seleccionarFecha(bool esInicio) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: esInicio ? _fechaInicio : _fechaFin,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('es'),
    );
    if (picked != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio = picked;
          if (_fechaFin.isBefore(_fechaInicio)) {
            _fechaFin = _fechaInicio.add(const Duration(days: 1));
          }
        } else {
          _fechaFin = picked;
        }
      });
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_clienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Selecciona un cliente'),
            backgroundColor: AppTheme.errorColor),
      );
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Agrega al menos un producto'),
            backgroundColor: AppTheme.errorColor),
      );
      return;
    }

    setState(() => _cargando = true);
    try {
      final usuario = ref.read(authNotifierProvider).value;
      final detalles = _items
          .map((i) => {
        'producto_id': i.producto.id,
        'cantidad': i.cantidad,
        'precio_unitario_dia': i.producto.precioAlquilerDia ?? 0,
        'subtotal': i.cantidad *
            (i.producto.precioAlquilerDia ?? 0) *
            _diasContrato,
      })
          .toList();

      await ref.read(contratoServiceProvider).crearContrato(
        clienteId: _clienteSeleccionado!.id,
        usuarioId: usuario!.id,
        fechaInicio: _fechaInicio,
        fechaFinEstimada: _fechaFin,
        montoTotal: _montoTotal,
        depositoGarantia: _depositoCtrl.text.isNotEmpty
            ? double.tryParse(_depositoCtrl.text)
            : null,
        observaciones: _observacionCtrl.text.isNotEmpty
            ? _observacionCtrl.text
            : null,
        detalles: detalles,
      );

      ref.read(contratosProvider.notifier).cargar();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Contrato creado exitosamente'),
              backgroundColor: AppTheme.successColor),
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
      appBar: AppBar(title: const Text('Nuevo Contrato')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Cliente
            const Text('Cliente',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _seleccionarCliente,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_outlined,
                        color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _clienteSeleccionado?.nombreCompleto ??
                            'Seleccionar cliente',
                        style: TextStyle(
                          color: _clienteSeleccionado != null
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppTheme.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Fechas
            const Text('Período de alquiler',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _FechaPicker(
                    label: 'Fecha inicio',
                    fecha: _fechaInicio,
                    onTap: () => _seleccionarFecha(true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _FechaPicker(
                    label: 'Fecha fin',
                    fecha: _fechaFin,
                    onTap: () => _seleccionarFecha(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Duración: $_diasContrato día(s)',
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),

            // Productos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Productos',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor)),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar'),
                  onPressed: _agregarProducto,
                ),
              ],
            ),
            if (_items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                    child: Text('Sin productos agregados',
                        style: TextStyle(color: AppTheme.textSecondary))),
              )
            else
              ...List.generate(_items.length, (i) {
                final item = _items[i];
                final subtotal = item.cantidad *
                    (item.producto.precioAlquilerDia ?? 0) *
                    _diasContrato;
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
                            Text(item.producto.nombre,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text(
                              '${item.cantidad} u × S/ ${item.producto.precioAlquilerDia?.toStringAsFixed(2)}/día × $_diasContrato días',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'S/ ${subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppTheme.errorColor, size: 20),
                        onPressed: () =>
                            setState(() => _items.removeAt(i)),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('MONTO TOTAL',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor)),
                  Text(
                    'S/ ${_montoTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Depósito y observaciones
            TextFormField(
              controller: _depositoCtrl,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Depósito de garantía (opcional)',
                  prefixText: 'S/ '),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _observacionCtrl,
              decoration:
              const InputDecoration(labelText: 'Observaciones (opcional)'),
              maxLines: 3,
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
                    : const Text('Crear Contrato'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FechaPicker extends StatelessWidget {
  final String label;
  final DateTime fecha;
  final VoidCallback onTap;

  const _FechaPicker({
    required this.label,
    required this.fecha,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 14, color: AppTheme.primaryColor),
                const SizedBox(width: 6),
                Text(AppDateUtils.formatDate(fecha),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Selector Cliente ─────────────────────────────────────────────────────────

class _SelectorClienteScreen extends ConsumerStatefulWidget {
  const _SelectorClienteScreen();

  @override
  ConsumerState<_SelectorClienteScreen> createState() =>
      _SelectorClienteScreenState();
}

class _SelectorClienteScreenState
    extends ConsumerState<_SelectorClienteScreen> {
  final _busquedaCtrl = TextEditingController();
  List<Cliente> _clientes = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final service = ref.read(clienteServiceProvider);
      final lista = await service.getClientes();
      setState(() {
        _clientes = lista;
        _cargando = false;
      });
    } catch (_) {
      setState(() => _cargando = false);
    }
  }

  List<Cliente> get _filtrados {
    final q = _busquedaCtrl.text.toLowerCase();
    if (q.isEmpty) return _clientes;
    return _clientes
        .where((c) =>
    c.nombreCompleto.toLowerCase().contains(q) ||
        (c.dniRuc?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar Cliente')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _busquedaCtrl,
              decoration: const InputDecoration(
                hintText: 'Buscar cliente...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: _filtrados.length,
              itemBuilder: (context, i) {
                final c = _filtrados[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(c.nombre[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(c.nombreCompleto),
                  subtitle: Text(c.dniRuc ?? ''),
                  onTap: () => Navigator.pop(context, c),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final nuevoCliente = await Navigator.push<Cliente>(
            context,
            MaterialPageRoute(
                builder: (_) => const FormularioClienteScreen()),
          );
          if (nuevoCliente != null && context.mounted) {
            Navigator.pop(context, nuevoCliente);
          }
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

// ─── Selector Producto ────────────────────────────────────────────────────────

class _SelectorProductoScreen extends ConsumerStatefulWidget {
  const _SelectorProductoScreen();

  @override
  ConsumerState<_SelectorProductoScreen> createState() =>
      _SelectorProductoScreenState();
}

class _SelectorProductoScreenState
    extends ConsumerState<_SelectorProductoScreen> {
  final _busquedaCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController(text: '1');
  List<Producto> _productos = [];
  bool _cargando = true;
  Producto? _seleccionado;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final service = ref.read(inventarioServiceProvider);
      final lista = await service.getProductos();
      setState(() {
        _productos = lista
            .where((p) =>
        (p.tipo == 'alquiler' || p.tipo == 'ambos') &&
            p.stockDisponible > 0)
            .toList();
        _cargando = false;
      });
    } catch (_) {
      setState(() => _cargando = false);
    }
  }

  List<Producto> get _filtrados {
    final q = _busquedaCtrl.text.toLowerCase();
    if (q.isEmpty) return _productos;
    return _productos
        .where((p) => p.nombre.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Producto')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _busquedaCtrl,
              decoration: const InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (_seleccionado != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_seleccionado!.nombre,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        Text(
                            'Disponible: ${_seleccionado!.stockDisponible}',
                            style:
                            const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: _cantidadCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Cant.', isDense: true),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final cant =
                          int.tryParse(_cantidadCtrl.text) ?? 1;
                      if (cant <= 0 ||
                          cant > _seleccionado!.stockDisponible) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Cantidad inválida (máx ${_seleccionado!.stockDisponible})'),
                            backgroundColor: AppTheme.errorColor,
                          ),
                        );
                        return;
                      }
                      Navigator.pop(
                          context,
                          _ItemContrato(
                              producto: _seleccionado!,
                              cantidad: cant));
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: _filtrados.length,
              itemBuilder: (context, i) {
                final p = _filtrados[i];
                final esSel = _seleccionado?.id == p.id;
                return ListTile(
                  selected: esSel,
                  selectedTileColor:
                  AppTheme.primaryColor.withOpacity(0.05),
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: Text(p.nombre),
                  subtitle: Text(
                    'Stock: ${p.stockDisponible}  ·  S/ ${p.precioAlquilerDia?.toStringAsFixed(2)}/día',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () => setState(() => _seleccionado = p),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemContrato {
  final Producto producto;
  final int cantidad;

  _ItemContrato({required this.producto, required this.cantidad});
}

// ─── Registrar Devolución ─────────────────────────────────────────────────────

class RegistrarDevolucionScreen extends ConsumerStatefulWidget {
  final Contrato contrato;

  const RegistrarDevolucionScreen({super.key, required this.contrato});

  @override
  ConsumerState<RegistrarDevolucionScreen> createState() =>
      _RegistrarDevolucionScreenState();
}

class _RegistrarDevolucionScreenState
    extends ConsumerState<RegistrarDevolucionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cargoExtraCtrl = TextEditingController();
  final _observacionCtrl = TextEditingController();
  String _estadoProducto = 'bueno';
  bool _cargando = false;

  @override
  void dispose() {
    _cargoExtraCtrl.dispose();
    _observacionCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);

    try {
      final usuario = ref.read(authNotifierProvider).value;

      // Obtener empleado_id del usuario actual
      // Como fallback usamos el usuario_id del contrato
      final productosDevueltos = widget.contrato.detalles
          ?.map((d) => {
        'producto_id': d.productoId,
        'cantidad': d.cantidad,
      })
          .toList() ??
          [];

      await ref.read(contratoServiceProvider).registrarDevolucion(
        contratoId: widget.contrato.id,
        empleadoId: widget.contrato.usuarioId,
        estadoProducto: _estadoProducto,
        cargoExtra: _cargoExtraCtrl.text.isNotEmpty
            ? double.tryParse(_cargoExtraCtrl.text)
            : null,
        observacion: _observacionCtrl.text.isNotEmpty
            ? _observacionCtrl.text
            : null,
        productosDevueltos: productosDevueltos,
      );

      ref.read(contratosProvider.notifier).cargar();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Devolución registrada'),
              backgroundColor: AppTheme.successColor),
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
      appBar: AppBar(title: const Text('Registrar Devolución')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Resumen contrato
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.contrato.cliente?.nombreCompleto ?? 'Cliente',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Contrato: S/ ${widget.contrato.montoTotal.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text('Estado de los equipos devueltos',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor)),
            const SizedBox(height: 10),

            ...[
              ('bueno', 'Buen estado', Icons.check_circle_outline,
              AppTheme.successColor),
              ('danado', 'Con daños', Icons.warning_amber_outlined,
              const Color(0xFFF59E0B)),
              ('perdido', 'Perdido', Icons.cancel_outlined,
              AppTheme.errorColor),
            ].map((opt) {
              final (val, label, icon, color) = opt;
              return GestureDetector(
                onTap: () => setState(() => _estadoProducto = val),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _estadoProducto == val
                        ? color.withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _estadoProducto == val ? color : AppTheme.borderColor,
                      width: _estadoProducto == val ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: color),
                      const SizedBox(width: 12),
                      Text(label,
                          style: TextStyle(
                              fontWeight: FontWeight.w600, color: color)),
                      const Spacer(),
                      if (_estadoProducto == val)
                        Icon(Icons.check_circle, color: color, size: 20),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            if (_estadoProducto != 'bueno') ...[
              TextFormField(
                controller: _cargoExtraCtrl,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Cargo extra',
                  prefixText: 'S/ ',
                ),
              ),
              const SizedBox(height: 12),
            ],

            TextFormField(
              controller: _observacionCtrl,
              decoration: const InputDecoration(
                labelText: 'Observaciones',
              ),
              maxLines: 3,
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
                    : const Text('Confirmar Devolución'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

