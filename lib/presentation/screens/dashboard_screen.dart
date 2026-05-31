import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../providers/auth_provider.dart';
import '../providers/asistencia_provider.dart';
import '../providers/inventario_provider.dart';
import '../providers/contratos_provider.dart';
import '../screens/stat_card.dart';
import '../screens/estado_chip.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final asistenciasHoy = ref.watch(asistenciasHoyProvider);
    final productosAsync = ref.watch(productosProvider);
    final contratosAsync = ref.watch(contratosProvider);
    final proxVencerAsync = ref.watch(contratosProxVencerProvider);

    final usuario = authState.value;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.person_outline, color: Colors.white, size: 20),
            ),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const _PerfilScreenPlaceholder())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(asistenciasHoyProvider);
          ref.read(productosProvider.notifier).cargar();
          ref.read(contratosProvider.notifier).cargar();
          ref.invalidate(contratosProxVencerProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Saludo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, Color(0xFF2A5298)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hola, ${usuario?.nombre ?? ''}!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppDateUtils.formatDate(DateTime.now()),
                            style: const TextStyle(color: Colors.white60, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    EstadoChip(
                      estado: usuario?.rol ?? '',
                      colorMap: const {
                        'admin': Colors.white,
                        'supervisor': Colors.white,
                        'empleado': Colors.white,
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Estadísticas
              Text('Resumen', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  asistenciasHoy.when(
                    data: (list) => StatCard(
                      titulo: 'Asistencias hoy',
                      valor: '${list.length}',
                      icono: Icons.how_to_reg_outlined,
                      color: const Color(0xFF0D7377),
                      onTap: () => context.go('/asistencia'),
                    ),
                    loading: () => const _CardShimmer(),
                    error: (_, __) => StatCard(
                      titulo: 'Asistencias hoy',
                      valor: '--',
                      icono: Icons.how_to_reg_outlined,
                    ),
                  ),
                  productosAsync.when(
                    data: (list) => StatCard(
                      titulo: 'Productos disponibles',
                      valor: '${list.where((p) => p.estado == 'disponible').length}',
                      icono: Icons.inventory_2_outlined,
                      color: const Color(0xFF5C3D99),
                      onTap: () => context.go('/inventario'),
                    ),
                    loading: () => const _CardShimmer(),
                    error: (_, __) => StatCard(
                      titulo: 'Productos',
                      valor: '--',
                      icono: Icons.inventory_2_outlined,
                    ),
                  ),
                  contratosAsync.when(
                    data: (list) => StatCard(
                      titulo: 'Contratos activos',
                      valor: '${list.where((c) => c.estado == 'activo').length}',
                      icono: Icons.description_outlined,
                      color: AppTheme.primaryColor,
                      onTap: () => context.go('/contratos'),
                    ),
                    loading: () => const _CardShimmer(),
                    error: (_, __) => StatCard(
                      titulo: 'Contratos',
                      valor: '--',
                      icono: Icons.description_outlined,
                    ),
                  ),
                  StatCard(
                    titulo: 'Reportes',
                    valor: '→',
                    icono: Icons.bar_chart_outlined,
                    color: const Color(0xFF9B2335),
                    onTap: () => context.go('/reportes'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Contratos próximos a vencer
              Text('Contratos por vencer (7 días)',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              proxVencerAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
                data: (contratos) {
                  if (contratos.isEmpty) {
                    return _EmptyCard(
                      mensaje: 'No hay contratos por vencer próximamente',
                      icono: Icons.check_circle_outline,
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: contratos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final c = contratos[i];
                      final diasRestantes = c.fechaFinEstimada
                          .difference(DateTime.now())
                          .inDays;
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFFEF3C7),
                            child: Icon(Icons.warning_amber_outlined,
                                color: Color(0xFFF59E0B)),
                          ),
                          title: Text(c.cliente?.nombreCompleto ?? 'Cliente'),
                          subtitle: Text(
                            'Vence: ${AppDateUtils.formatDate(c.fechaFinEstimada)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: diasRestantes <= 2
                                  ? AppTheme.errorColor
                                  : const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$diasRestantes d',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ),
                          onTap: () => context.go('/contratos'),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),

              // Accesos rápidos
              Text('Accesos rápidos',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.9,
                children: [
                  _AccesoRapido(
                    icono: Icons.how_to_reg,
                    label: 'Asistencia',
                    color: const Color(0xFF0D7377),
                    onTap: () => context.go('/asistencia'),
                  ),
                  _AccesoRapido(
                    icono: Icons.inventory_2,
                    label: 'Inventario',
                    color: const Color(0xFF5C3D99),
                    onTap: () => context.go('/inventario'),
                  ),
                  _AccesoRapido(
                    icono: Icons.description,
                    label: 'Contratos',
                    color: AppTheme.primaryColor,
                    onTap: () => context.go('/contratos'),
                  ),
                  _AccesoRapido(
                    icono: Icons.people,
                    label: 'Clientes',
                    color: const Color(0xFF065F46),
                    onTap: () => context.go('/clientes'),
                  ),
                  _AccesoRapido(
                    icono: Icons.bar_chart,
                    label: 'Reportes',
                    color: const Color(0xFF9B2335),
                    onTap: () => context.go('/reportes'),
                  ),
                  _AccesoRapido(
                    icono: Icons.person,
                    label: 'Perfil',
                    color: const Color(0xFF374151),
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccesoRapido extends StatelessWidget {
  final IconData icono;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AccesoRapido({
    required this.icono,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icono, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String mensaje;
  final IconData icono;

  const _EmptyCard({required this.mensaje, required this.icono});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Icon(icono, color: AppTheme.successColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
              child: Text(mensaje,
                  style: const TextStyle(color: AppTheme.textSecondary))),
        ],
      ),
    );
  }
}

class _CardShimmer extends StatelessWidget {
  const _CardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}

class _PerfilScreenPlaceholder extends StatelessWidget {
  const _PerfilScreenPlaceholder();

  @override
  Widget build(BuildContext context) {
    // Import perfil_screen in a real project
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: const Center(child: Text('Ver perfil')),
    );
  }
}