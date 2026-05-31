import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/services/asistencia_service.dart';
import '../providers/asistencia_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/qr_scanner_widget.dart';
import '../screens/estado_chip.dart';

class AsistenciaScreen extends ConsumerStatefulWidget {
  const AsistenciaScreen({super.key});

  @override
  ConsumerState<AsistenciaScreen> createState() => _AsistenciaScreenState();
}

class _AsistenciaScreenState extends ConsumerState<AsistenciaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _escaneando = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    ref.read(asistenciaHistorialProvider.notifier).cargar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _escanearQr() async {
    if (_escaneando) return;
    setState(() => _escaneando = true);

    final codigo = await abrirEscaner(context, titulo: 'Escanear Empleado');
    setState(() => _escaneando = false);

    if (codigo == null || !mounted) return;

    try {
      final service = ref.read(asistenciaServiceProvider);
      final empleado = await service.getEmpleadoPorId(codigo);

      if (!mounted) return;

      if (empleado == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Empleado no encontrado con ese QR'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      final resultado = await service.registrarPorQr(codigo);

      if (!mounted) return;

      final accion = resultado['accion'];
      String mensaje;
      Color color;

      if (accion == 'entrada') {
        mensaje =
        '✓ Entrada registrada para ${empleado.nombreCompleto} (${resultado['estado']})';
        color = AppTheme.successColor;
      } else if (accion == 'salida') {
        mensaje = '✓ Salida registrada para ${empleado.nombreCompleto}';
        color = AppTheme.primaryColor;
      } else {
        mensaje = '${empleado.nombreCompleto} ya tiene entrada y salida hoy';
        color = AppTheme.accentColor;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje), backgroundColor: color),
      );
      ref.invalidate(asistenciasHoyProvider);
      ref.read(asistenciaHistorialProvider.notifier).cargar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = ref.watch(authNotifierProvider).value;
    final esAdmin = usuario?.rol == 'admin' || usuario?.rol == 'supervisor';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistencia'),
        leading: esAdmin
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        )
            : null,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentColor,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Hoy'),
            Tab(text: 'Historial'),
            Tab(text: 'Mensual'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TabHoy(onEscanear: _escanearQr),
          const _TabHistorial(),
          const _TabMensual(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _escanearQr,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Escanear QR'),
        backgroundColor: AppTheme.accentColor,
      ),
    );
  }
}

class _TabHoy extends ConsumerWidget {
  final VoidCallback onEscanear;

  const _TabHoy({required this.onEscanear});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asistenciasHoy = ref.watch(asistenciasHoyProvider);

    return asistenciasHoy.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error al cargar: $e',
            style: const TextStyle(color: AppTheme.errorColor)),
      ),
      data: (lista) {
        if (lista.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.how_to_reg_outlined,
                    size: 64, color: AppTheme.textSecondary),
                const SizedBox(height: 16),
                const Text('Sin asistencias registradas hoy'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onEscanear,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Escanear QR'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: lista.length,
          itemBuilder: (context, i) {
            final a = lista[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    a.empleado?.nombreCompleto.isNotEmpty == true
                        ? a.empleado!.nombreCompleto[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(a.empleado?.nombreCompleto ?? 'Empleado'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (a.horaEntrada != null)
                      Text(
                          'Entrada: ${AppDateUtils.formatOnlyTime(a.horaEntrada!)}',
                          style: const TextStyle(fontSize: 12)),
                    if (a.horaSalida != null)
                      Text('Salida: ${AppDateUtils.formatOnlyTime(a.horaSalida!)}',
                          style: const TextStyle(fontSize: 12)),
                  ],
                ),
                trailing: EstadoChip(estado: a.estado),
              ),
            );
          },
        );
      },
    );
  }
}

class _TabHistorial extends ConsumerStatefulWidget {
  const _TabHistorial();

  @override
  ConsumerState<_TabHistorial> createState() => _TabHistorialState();
}

class _TabHistorialState extends ConsumerState<_TabHistorial> {
  String? _empleadoSeleccionado;
  DateTime? _desde;
  DateTime? _hasta;

  @override
  Widget build(BuildContext context) {
    final historial = ref.watch(asistenciaHistorialProvider);
    final empleados = ref.watch(empleadosProvider);

    return Column(
      children: [
        // Filtros
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: empleados.when(
                  data: (lista) => DropdownButtonFormField<String>(
                    value: _empleadoSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Empleado',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos')),
                      ...lista.map((e) => DropdownMenuItem(
                        value: e.id,
                        child: Text(e.nombreCompleto,
                            overflow: TextOverflow.ellipsis),
                      )),
                    ],
                    onChanged: (v) {
                      setState(() => _empleadoSeleccionado = v);
                      ref
                          .read(asistenciaHistorialProvider.notifier)
                          .cargar(empleadoId: v, desde: _desde, hasta: _hasta);
                    },
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox(),
                ),
              ),
            ],
          ),
        ),
        // Lista
        Expanded(
          child: historial.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (lista) {
              if (lista.isEmpty) {
                return const Center(
                    child: Text('Sin registros en este período'));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: lista.length,
                itemBuilder: (context, i) {
                  final a = lista[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      dense: true,
                      title: Text(a.empleado?.nombreCompleto ?? 'Empleado'),
                      subtitle: Text(AppDateUtils.formatDate(a.fecha)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (a.horaEntrada != null)
                            Text(AppDateUtils.formatOnlyTime(a.horaEntrada!),
                                style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          EstadoChip(estado: a.estado),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TabMensual extends ConsumerStatefulWidget {
  const _TabMensual();

  @override
  ConsumerState<_TabMensual> createState() => _TabMensualState();
}

class _TabMensualState extends ConsumerState<_TabMensual> {
  String? _empleadoId;
  int _mes = DateTime.now().month;
  int _anio = DateTime.now().year;
  List<dynamic>? _resumen;
  bool _cargando = false;

  Future<void> _cargarResumen() async {
    if (_empleadoId == null) return;
    setState(() => _cargando = true);
    try {
      final service = ref.read(asistenciaServiceProvider);
      final data = await service.getResumenMensual(
        empleadoId: _empleadoId!,
        year: _anio,
        month: _mes,
      );
      setState(() => _resumen = data);
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
        children: [
          empleados.when(
            data: (lista) => DropdownButtonFormField<String>(
              value: _empleadoId,
              decoration: const InputDecoration(labelText: 'Seleccionar empleado'),
              items: lista
                  .map((e) => DropdownMenuItem(
                value: e.id,
                child: Text(e.nombreCompleto),
              ))
                  .toList(),
              onChanged: (v) {
                setState(() => _empleadoId = v);
                _cargarResumen();
              },
            ),
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _mes,
                  decoration: const InputDecoration(labelText: 'Mes'),
                  items: List.generate(
                      12,
                          (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text(_nombreMes(i + 1)))),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _mes = v);
                      _cargarResumen();
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
                      _cargarResumen();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_cargando) const CircularProgressIndicator(),
          if (_resumen != null && !_cargando) ...[
            _ResumenStats(resumen: _resumen!),
            const SizedBox(height: 12),
            ..._resumen!.map((a) {
              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  dense: true,
                  title: Text(AppDateUtils.formatDate(
                      DateTime.parse(a.fecha.toString()))),
                  trailing: EstadoChip(estado: a.estado),
                ),
              );
            }),
          ],
          if (_empleadoId == null && !_cargando)
            const Center(
                child: Text('Selecciona un empleado para ver el resumen')),
        ],
      ),
    );
  }

  String _nombreMes(int mes) {
    const nombres = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return nombres[mes];
  }
}

class _ResumenStats extends StatelessWidget {
  final List resumen;

  const _ResumenStats({required this.resumen});

  @override
  Widget build(BuildContext context) {
    final puntuales = resumen.where((a) => a.estado == 'puntual').length;
    final tardanzas = resumen.where((a) => a.estado == 'tardanza').length;
    final faltas = resumen.where((a) => a.estado == 'falta').length;

    return Row(
      children: [
        Expanded(
            child: _MiniStat(
                label: 'Puntuales', valor: '$puntuales', color: AppTheme.successColor)),
        Expanded(
            child: _MiniStat(
                label: 'Tardanzas', valor: '$tardanzas', color: AppTheme.accentColor)),
        Expanded(
            child: _MiniStat(
                label: 'Faltas', valor: '$faltas', color: AppTheme.errorColor)),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String valor;
  final Color color;

  const _MiniStat({required this.label, required this.valor, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(valor,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}