import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/services/asistencia_service.dart';
import '../../../data/services/inventario_service.dart';
import '../../../data/services/contrato_service.dart';
import '../providers/auth_provider.dart';
import '../providers/asistencia_provider.dart';

import '../screens/estado_chip.dart';
import '../providers/inventario_provider.dart';
import '../providers/contratos_provider.dart';

class ReportesScreen extends ConsumerStatefulWidget {
  const ReportesScreen({super.key});

  @override
  ConsumerState<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends ConsumerState<ReportesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usuario = ref.watch(authNotifierProvider).value;

    if (usuario?.rol != 'admin') {
      return Scaffold(
        appBar: AppBar(title: const Text('Reportes')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outlined, size: 64, color: AppTheme.textSecondary),
              SizedBox(height: 16),
              Text('Solo administradores pueden ver reportes'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentColor,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Asistencia'),
            Tab(text: 'Stock bajo'),
            Tab(text: 'Contratos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _TabReporteAsistencia(),
          _TabReporteStock(),
          _TabReporteContratos(),
        ],
      ),
    );
  }
}

// ─── Tab Asistencia ───────────────────────────────────────────────────────────

class _TabReporteAsistencia extends ConsumerStatefulWidget {
  const _TabReporteAsistencia();

  @override
  ConsumerState<_TabReporteAsistencia> createState() =>
      _TabReporteAsistenciaState();
}

class _TabReporteAsistenciaState
    extends ConsumerState<_TabReporteAsistencia> {
  String? _empleadoId;
  int _mes = DateTime.now().month;
  int _anio = DateTime.now().year;
  List<dynamic>? _datos;
  bool _cargando = false;

  Future<void> _cargar() async {
    if (_empleadoId == null) return;
    setState(() => _cargando = true);
    try {
      final service = ref.read(asistenciaServiceProvider);
      final data = await service.getResumenMensual(
          empleadoId: _empleadoId!, year: _anio, month: _mes);
      setState(() => _datos = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor));
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final empleados = ref.watch(empleadosProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Asistencia mensual por empleado',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),

          empleados.when(
            data: (lista) => DropdownButtonFormField<String>(
              value: _empleadoId,
              decoration:
              const InputDecoration(labelText: 'Empleado'),
              items: lista
                  .map((e) => DropdownMenuItem(
                  value: e.id, child: Text(e.nombreCompleto)))
                  .toList(),
              onChanged: (v) {
                setState(() => _empleadoId = v);
                _cargar();
              },
            ),
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 12),

          Row(children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _mes,
                decoration: const InputDecoration(labelText: 'Mes'),
                items: List.generate(
                    12,
                        (i) => DropdownMenuItem(
                        value: i + 1, child: Text(_nombreMes(i + 1)))),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _mes = v);
                    _cargar();
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: _anio.toString(),
                decoration: const InputDecoration(labelText: 'Año'),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  final a = int.tryParse(v);
                  if (a != null && a > 2020) {
                    setState(() => _anio = a);
                    _cargar();
                  }
                },
              ),
            ),
          ]),
          const SizedBox(height: 20),

          if (_cargando)
            const Center(child: CircularProgressIndicator())
          else if (_datos == null)
            const Center(
                child: Text('Selecciona un empleado',
                    style: TextStyle(color: AppTheme.textSecondary)))
          else if (_datos!.isEmpty)
              const Center(child: Text('Sin registros en este período'))
            else ...[
                // Resumen estadístico
                _TarjetaResumen(datos: _datos!),
                const SizedBox(height: 16),

                // Tabla
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    children: [
                      // Cabecera
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius:
                          BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        child: const Row(
                          children: [
                            Expanded(
                                child: Text('Fecha',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600))),
                            Text('Entrada',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                            SizedBox(width: 16),
                            Text('Estado',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      ..._datos!.asMap().entries.map((entry) {
                        final i = entry.key;
                        final a = entry.value;
                        final bgColor = i.isEven
                            ? Colors.white
                            : const Color(0xFFF9FAFB);
                        return Container(
                          color: bgColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                  child: Text(
                                    AppDateUtils.formatDate(
                                        DateTime.parse(a.fecha.toString())),
                                    style: const TextStyle(fontSize: 13),
                                  )),
                              Text(
                                a.horaEntrada != null
                                    ? AppDateUtils.formatOnlyTime(a.horaEntrada!)
                                    : '--',
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(width: 16),
                              EstadoChip(estado: a.estado),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
        ],
      ),
    );
  }

  String _nombreMes(int mes) {
    const nombres = [
      '',
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return nombres[mes];
  }
}

class _TarjetaResumen extends StatelessWidget {
  final List datos;

  const _TarjetaResumen({required this.datos});

  @override
  Widget build(BuildContext context) {
    final puntuales = datos.where((a) => a.estado == 'puntual').length;
    final tardanzas = datos.where((a) => a.estado == 'tardanza').length;
    final faltas = datos.where((a) => a.estado == 'falta').length;
    final total = datos.length;
    final pct = total > 0
        ? ((puntuales / total) * 100).toStringAsFixed(0)
        : '0';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppTheme.primaryColor, Color(0xFF2A5298)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text('Resumen del mes',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatCircle(valor: '$total', label: 'Total', color: Colors.white),
              _StatCircle(
                  valor: '$puntuales',
                  label: 'Puntuales',
                  color: const Color(0xFF86EFAC)),
              _StatCircle(
                  valor: '$tardanzas',
                  label: 'Tardanzas',
                  color: const Color(0xFFFBBF24)),
              _StatCircle(
                  valor: '$faltas',
                  label: 'Faltas',
                  color: const Color(0xFFFCA5A5)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Puntualidad: $pct%',
            style: const TextStyle(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _StatCircle extends StatelessWidget {
  final String valor;
  final String label;
  final Color color;

  const _StatCircle(
      {required this.valor, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(valor,
            style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

// ─── Tab Stock Bajo ───────────────────────────────────────────────────────────

class _TabReporteStock extends ConsumerStatefulWidget {
  const _TabReporteStock();

  @override
  ConsumerState<_TabReporteStock> createState() => _TabReporteStockState();
}

class _TabReporteStockState extends ConsumerState<_TabReporteStock> {
  List<dynamic>? _productos;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final service = ref.read(inventarioServiceProvider);
      final data = await service.getProductosStockBajo();
      setState(() => _productos = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor));
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _cargar,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Productos con stock bajo',
                    style: Theme.of(context).textTheme.titleLarge),
                Text(
                  _productos != null ? '${_productos!.length} items' : '',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Productos con menos del 20% de stock disponible',
              style: TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),

            if (_cargando)
              const Center(child: CircularProgressIndicator())
            else if (_productos == null || _productos!.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: AppTheme.successColor, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '¡Excelente! Todos los productos tienen stock suficiente.',
                        style: TextStyle(color: AppTheme.successColor),
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._productos!.map((p) {
                final pct =
                (p.porcentajeStock * 100).toStringAsFixed(0);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFFCA5A5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(p.nombre,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$pct% stock',
                              style: const TextStyle(
                                color: AppTheme.errorColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: p.porcentajeStock.clamp(0.0, 1.0),
                          backgroundColor: const Color(0xFFFEE2E2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.errorColor),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${p.stockDisponible} disponibles de ${p.stockTotal} total',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

// ─── Tab Contratos ────────────────────────────────────────────────────────────

class _TabReporteContratos extends ConsumerStatefulWidget {
  const _TabReporteContratos();

  @override
  ConsumerState<_TabReporteContratos> createState() =>
      _TabReporteContratosState();
}

class _TabReporteContratosState
    extends ConsumerState<_TabReporteContratos> {
  List<dynamic>? _vencidos;
  List<dynamic>? _proxVencer;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final service = ref.read(contratoServiceProvider);
      final vencidos = await service.getContratosVencidos();
      final proxVencer = await service.getContratosProxAVencer();
      setState(() {
        _vencidos = vencidos;
        _proxVencer = proxVencer;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor));
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _cargar,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vencidos
            _SeccionContratos(
              titulo: 'Contratos vencidos',
              subtitulo: 'Contratos activos con fecha de fin ya pasada',
              contratos: _vencidos ?? [],
              colorBorde: AppTheme.errorColor,
              colorFondo: const Color(0xFFFEF2F2),
            ),
            const SizedBox(height: 20),

            // Por vencer
            _SeccionContratos(
              titulo: 'Por vencer (próximos 7 días)',
              subtitulo: 'Contratos que vencen esta semana',
              contratos: _proxVencer ?? [],
              colorBorde: const Color(0xFFF59E0B),
              colorFondo: const Color(0xFFFFFBEB),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeccionContratos extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final List contratos;
  final Color colorBorde;
  final Color colorFondo;

  const _SeccionContratos({
    required this.titulo,
    required this.subtitulo,
    required this.contratos,
    required this.colorBorde,
    required this.colorFondo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: colorBorde,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontSize: 16)),
                Text(subtitulo,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorBorde.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${contratos.length}',
                style: TextStyle(
                    color: colorBorde, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (contratos.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorFondo,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colorBorde.withOpacity(0.3)),
            ),
            child: const Center(
                child: Text('Sin contratos en esta categoría',
                    style: TextStyle(color: AppTheme.textSecondary))),
          )
        else
          ...contratos.map((c) {
            final dias = c.fechaFinEstimada
                .difference(DateTime.now())
                .inDays;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorFondo,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorBorde.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.cliente?.nombreCompleto ?? 'Cliente',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Venció: ${AppDateUtils.formatDate(c.fechaFinEstimada)}',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        Text(
                          'S/ ${c.montoTotal.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 13, color: colorBorde),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      EstadoChip(estado: c.estado),
                      const SizedBox(height: 4),
                      Text(
                        dias < 0
                            ? '${dias.abs()} días atrás'
                            : 'En $dias días',
                        style: TextStyle(
                            fontSize: 11, color: colorBorde),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}