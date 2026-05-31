import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/producto.dart';
import '../../../data/models/categoria.dart';
import '../providers/inventario_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/qr_scanner_widget.dart';
import '../screens/qr_display_widget.dart';
import '../screens/estado_chip.dart';

class InventarioScreen extends ConsumerStatefulWidget {
  const InventarioScreen({super.key});

  @override
  ConsumerState<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends ConsumerState<InventarioScreen> {
  final _busquedaCtrl = TextEditingController();
  String? _categoriaFiltro;
  String? _estadoFiltro;

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  void _aplicarFiltro() {
    ref.read(productosProvider.notifier).cargar(
      categoriaId: _categoriaFiltro,
      estado: _estadoFiltro,
      busqueda: _busquedaCtrl.text,
    );
  }

  Future<void> _escanearYBuscar() async {
    final codigo = await abrirEscaner(context, titulo: 'Buscar Producto');
    if (codigo == null || !mounted) return;

    final producto =
    await ref.read(inventarioServiceProvider).getProductoPorQr(codigo);
    if (!mounted) return;

    if (producto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Producto no encontrado con ese QR'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } else {
      _mostrarDetalleProducto(producto);
    }
  }

  void _mostrarDetalleProducto(Producto producto) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalleProductoScreen(producto: producto),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productosAsync = ref.watch(productosProvider);
    final categoriasAsync = ref.watch(categoriasProvider);
    final usuario = ref.watch(authNotifierProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _escanearYBuscar,
            tooltip: 'Buscar por QR',
          ),
        ],
      ),
      body: Column(
        children: [
          // Buscador y filtros
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _busquedaCtrl,
                  decoration: InputDecoration(
                    hintText: 'Buscar producto...',
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
                Row(
                  children: [
                    Expanded(
                      child: categoriasAsync.when(
                        data: (cats) => DropdownButtonFormField<String>(
                          value: _categoriaFiltro,
                          isDense: true,
                          decoration: const InputDecoration(
                              labelText: 'Categoría', isDense: true),
                          items: [
                            const DropdownMenuItem(
                                value: null, child: Text('Todas')),
                            ...cats.map((c) => DropdownMenuItem(
                                value: c.id, child: Text(c.nombre))),
                          ],
                          onChanged: (v) {
                            setState(() => _categoriaFiltro = v);
                            _aplicarFiltro();
                          },
                        ),
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _estadoFiltro,
                        isDense: true,
                        decoration: const InputDecoration(
                            labelText: 'Estado', isDense: true),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Todos')),
                          DropdownMenuItem(
                              value: 'disponible', child: Text('Disponible')),
                          DropdownMenuItem(
                              value: 'agotado', child: Text('Agotado')),
                          DropdownMenuItem(
                              value: 'mantenimiento',
                              child: Text('Mantenimiento')),
                        ],
                        onChanged: (v) {
                          setState(() => _estadoFiltro = v);
                          _aplicarFiltro();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Lista
          Expanded(
            child: productosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: const TextStyle(color: AppTheme.errorColor))),
              data: (productos) {
                if (productos.isEmpty) {
                  return const Center(
                      child: Text('No se encontraron productos'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: productos.length,
                  itemBuilder: (context, i) {
                    final p = productos[i];
                    return _ProductoCard(
                      producto: p,
                      onTap: () => _mostrarDetalleProducto(p),
                    );
                  },
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
              builder: (_) => const FormularioProductoScreen(),
            ),
          );
          if (result == true) _aplicarFiltro();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ProductoCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback onTap;

  const _ProductoCard({required this.producto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Ícono/imagen
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: producto.imagenUrl != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(producto.imagenUrl!,
                      fit: BoxFit.cover),
                )
                    : const Icon(Icons.inventory_2_outlined,
                    color: AppTheme.primaryColor, size: 28),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      producto.categoria?.nombre ?? 'Sin categoría',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _StockIndicator(producto: producto),
                        const SizedBox(width: 8),
                        EstadoChip(estado: producto.tipo),
                      ],
                    ),
                  ],
                ),
              ),
              // Precio y estado
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  EstadoChip(estado: producto.estado),
                  const SizedBox(height: 4),
                  if (producto.precioAlquilerDia != null)
                    Text(
                      'S/ ${producto.precioAlquilerDia!.toStringAsFixed(2)}/día',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary),
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

class _StockIndicator extends StatelessWidget {
  final Producto producto;

  const _StockIndicator({required this.producto});

  @override
  Widget build(BuildContext context) {
    final color = producto.stockBajo
        ? AppTheme.errorColor
        : AppTheme.successColor;
    return Row(
      children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 4),
        Text(
          '${producto.stockDisponible}/${producto.stockTotal}',
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
    );
  }
}

// ─── Pantalla de Detalle ──────────────────────────────────────────────────────

class DetalleProductoScreen extends ConsumerWidget {
  final Producto producto;

  const DetalleProductoScreen({super.key, required this.producto});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(producto.nombre),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      FormularioProductoScreen(producto: producto),
                ),
              );
              if (result == true && context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // QR
            Center(
              child: QrDisplayWidget(
                data: producto.codigoQr,
                label: producto.codigoQr,
              ),
            ),
            const SizedBox(height: 24),
            // Info
            _InfoSection(titulo: 'Información general', items: [
              _InfoRow('Nombre', producto.nombre),
              _InfoRow('Descripción', producto.descripcion ?? 'Sin descripción'),
              _InfoRow('Categoría', producto.categoria?.nombre ?? 'Sin categoría'),
              _InfoRow('Tipo', producto.tipo),
              _InfoRow('Estado', producto.estado),
            ]),
            const SizedBox(height: 16),
            _InfoSection(titulo: 'Stock', items: [
              _InfoRow('Stock total', '${producto.stockTotal}'),
              _InfoRow('Disponible', '${producto.stockDisponible}'),
              _InfoRow('Porcentaje',
                  '${(producto.porcentajeStock * 100).toStringAsFixed(0)}%'),
            ]),
            const SizedBox(height: 16),
            _InfoSection(titulo: 'Precios', items: [
              if (producto.precioAlquilerDia != null)
                _InfoRow('Alquiler/día',
                    'S/ ${producto.precioAlquilerDia!.toStringAsFixed(2)}'),
              if (producto.precioVenta != null)
                _InfoRow(
                    'Venta', 'S/ ${producto.precioVenta!.toStringAsFixed(2)}'),
            ]),
            const SizedBox(height: 24),
            // Botón movimiento
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Registrar movimiento'),
                onPressed: () => _mostrarDialogoMovimiento(context, ref),
              ),
            ),
            const SizedBox(height: 12),
            // Historial movimientos
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.history),
                label: const Text('Ver historial de movimientos'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        HistorialMovimientosScreen(productoId: producto.id),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoMovimiento(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MovimientoSheet(productoId: producto.id),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String titulo;
  final List<Widget> items;

  const _InfoSection({required this.titulo, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor)),
        const SizedBox(height: 8),
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String valor;

  const _InfoRow(this.label, this.valor);

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
          Text(valor,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─── Modal Movimiento ─────────────────────────────────────────────────────────

class _MovimientoSheet extends ConsumerStatefulWidget {
  final String productoId;

  const _MovimientoSheet({required this.productoId});

  @override
  ConsumerState<_MovimientoSheet> createState() => _MovimientoSheetState();
}

class _MovimientoSheetState extends ConsumerState<_MovimientoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadCtrl = TextEditingController();
  final _motivoCtrl = TextEditingController();
  String _tipo = 'entrada';
  bool _cargando = false;

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _motivoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      final usuario = ref.read(authNotifierProvider).value;
      await ref.read(inventarioServiceProvider).registrarMovimiento(
        productoId: widget.productoId,
        usuarioId: usuario!.id,
        tipoMovimiento: _tipo,
        cantidad: int.parse(_cantidadCtrl.text),
        motivo: _motivoCtrl.text.isNotEmpty ? _motivoCtrl.text : null,
      );
      ref.read(productosProvider.notifier).cargar();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Movimiento registrado'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Registrar Movimiento',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _tipo,
              decoration: const InputDecoration(labelText: 'Tipo de movimiento'),
              items: const [
                DropdownMenuItem(value: 'entrada', child: Text('Entrada')),
                DropdownMenuItem(value: 'salida', child: Text('Salida')),
                DropdownMenuItem(value: 'ajuste', child: Text('Ajuste')),
              ],
              onChanged: (v) => setState(() => _tipo = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cantidadCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cantidad'),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Campo requerido';
                if (int.tryParse(v) == null || int.parse(v) <= 0) {
                  return 'Ingresa un número válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _motivoCtrl,
              decoration:
              const InputDecoration(labelText: 'Motivo (opcional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _cargando ? null : _guardar,
                child: _cargando
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
                    : const Text('Registrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Historial Movimientos ────────────────────────────────────────────────────

class HistorialMovimientosScreen extends ConsumerStatefulWidget {
  final String productoId;

  const HistorialMovimientosScreen({super.key, required this.productoId});

  @override
  ConsumerState<HistorialMovimientosScreen> createState() =>
      _HistorialMovimientosScreenState();
}

class _HistorialMovimientosScreenState
    extends ConsumerState<HistorialMovimientosScreen> {
  @override
  void initState() {
    super.initState();
    ref
        .read(movimientosProvider.notifier)
        .cargar(productoId: widget.productoId);
  }

  @override
  Widget build(BuildContext context) {
    final movimientosAsync = ref.watch(movimientosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Movimientos')),
      body: movimientosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (lista) {
          if (lista.isEmpty) {
            return const Center(child: Text('Sin movimientos registrados'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: lista.length,
            itemBuilder: (context, i) {
              final m = lista[i];
              final color = m.tipoMovimiento == 'entrada'
                  ? AppTheme.successColor
                  : m.tipoMovimiento == 'salida'
                  ? AppTheme.errorColor
                  : AppTheme.accentColor;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.15),
                    child: Icon(
                      m.tipoMovimiento == 'entrada'
                          ? Icons.arrow_downward
                          : m.tipoMovimiento == 'salida'
                          ? Icons.arrow_upward
                          : Icons.tune,
                      color: color,
                      size: 18,
                    ),
                  ),
                  title: Text(
                      '${_capitalize(m.tipoMovimiento)}: ${m.cantidad} unidades'),
                  subtitle: Text(
                    '${m.motivo ?? 'Sin motivo'}\n${m.usuario?.nombreCompleto ?? ''}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Text(
                    '${m.fecha.day}/${m.fecha.month}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _capitalize(String s) =>
      s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s;
}

// ─── Formulario Producto ──────────────────────────────────────────────────────

class FormularioProductoScreen extends ConsumerStatefulWidget {
  final Producto? producto;

  const FormularioProductoScreen({super.key, this.producto});

  @override
  ConsumerState<FormularioProductoScreen> createState() =>
      _FormularioProductoScreenState();
}

class _FormularioProductoScreenState
    extends ConsumerState<FormularioProductoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _stockTotalCtrl = TextEditingController();
  final _stockDisponibleCtrl = TextEditingController();
  final _precioAlquilerCtrl = TextEditingController();
  final _precioVentaCtrl = TextEditingController();
  String _tipo = 'alquiler';
  String _estado = 'disponible';
  String? _categoriaId;
  bool _cargando = false;

  bool get esEdicion => widget.producto != null;

  @override
  void initState() {
    super.initState();
    if (esEdicion) {
      final p = widget.producto!;
      _nombreCtrl.text = p.nombre;
      _descripcionCtrl.text = p.descripcion ?? '';
      _stockTotalCtrl.text = p.stockTotal.toString();
      _stockDisponibleCtrl.text = p.stockDisponible.toString();
      _precioAlquilerCtrl.text = p.precioAlquilerDia?.toString() ?? '';
      _precioVentaCtrl.text = p.precioVenta?.toString() ?? '';
      _tipo = p.tipo;
      _estado = p.estado;
      _categoriaId = p.categoriaId;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _stockTotalCtrl.dispose();
    _stockDisponibleCtrl.dispose();
    _precioAlquilerCtrl.dispose();
    _precioVentaCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);

    final payload = {
      'categoria_id': _categoriaId,
      'nombre': _nombreCtrl.text.trim(),
      'descripcion': _descripcionCtrl.text.trim(),
      'tipo': _tipo,
      'stock_total': int.parse(_stockTotalCtrl.text),
      'stock_disponible': int.parse(_stockDisponibleCtrl.text),
      'precio_alquiler_dia': _precioAlquilerCtrl.text.isNotEmpty
          ? double.parse(_precioAlquilerCtrl.text)
          : null,
      'precio_venta': _precioVentaCtrl.text.isNotEmpty
          ? double.parse(_precioVentaCtrl.text)
          : null,
      'estado': _estado,
    };

    try {
      final service = ref.read(inventarioServiceProvider);
      if (esEdicion) {
        await service.actualizarProducto(widget.producto!.id, payload);
      } else {
        await service.crearProducto(payload);
      }
      ref.read(productosProvider.notifier).cargar();
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                esEdicion ? 'Producto actualizado' : 'Producto creado'),
            backgroundColor: AppTheme.successColor,
          ),
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
    final categoriasAsync = ref.watch(categoriasProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(esEdicion ? 'Editar Producto' : 'Nuevo Producto'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre *'),
              validator: (v) =>
              v == null || v.isEmpty ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descripcionCtrl,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            categoriasAsync.when(
              data: (cats) => DropdownButtonFormField<String>(
                value: _categoriaId,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('Sin categoría')),
                  ...cats.map((c) => DropdownMenuItem(
                      value: c.id, child: Text(c.nombre))),
                ],
                onChanged: (v) => setState(() => _categoriaId = v),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _tipo,
              decoration: const InputDecoration(labelText: 'Tipo *'),
              items: const [
                DropdownMenuItem(value: 'alquiler', child: Text('Alquiler')),
                DropdownMenuItem(value: 'venta', child: Text('Venta')),
                DropdownMenuItem(value: 'ambos', child: Text('Ambos')),
              ],
              onChanged: (v) => setState(() => _tipo = v!),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stockTotalCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Stock total *'),
                    validator: (v) =>
                    v == null || v.isEmpty ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _stockDisponibleCtrl,
                    keyboardType: TextInputType.number,
                    decoration:
                    const InputDecoration(labelText: 'Stock disponible *'),
                    validator: (v) =>
                    v == null || v.isEmpty ? 'Requerido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _precioAlquilerCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Precio alquiler/día', prefixText: 'S/ '),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _precioVentaCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Precio venta', prefixText: 'S/ '),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _estado,
              decoration: const InputDecoration(labelText: 'Estado *'),
              items: const [
                DropdownMenuItem(
                    value: 'disponible', child: Text('Disponible')),
                DropdownMenuItem(value: 'agotado', child: Text('Agotado')),
                DropdownMenuItem(
                    value: 'mantenimiento', child: Text('Mantenimiento')),
              ],
              onChanged: (v) => setState(() => _estado = v!),
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
                    : Text(esEdicion ? 'Actualizar' : 'Crear Producto'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}