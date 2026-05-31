import 'package:flutter/material.dart';

class EstadoChip extends StatelessWidget {
  final String estado;
  final Map<String, Color>? colorMap;
  final Map<String, String>? labelMap;

  const EstadoChip({
    super.key,
    required this.estado,
    this.colorMap,
    this.labelMap,
  });

  static const _defaultColors = {
    'activo': Color(0xFF2E7D32),
    'inactivo': Color(0xFF6B7280),
    'cerrado': Color(0xFF1A3C6E),
    'vencido': Color(0xFFD32F2F),
    'disponible': Color(0xFF2E7D32),
    'agotado': Color(0xFFD32F2F),
    'mantenimiento': Color(0xFFF59E0B),
    'puntual': Color(0xFF2E7D32),
    'tardanza': Color(0xFFF59E0B),
    'falta': Color(0xFFD32F2F),
    'bueno': Color(0xFF2E7D32),
    'danado': Color(0xFFF59E0B),
    'perdido': Color(0xFFD32F2F),
    'alquiler': Color(0xFF1A3C6E),
    'venta': Color(0xFF7C3AED),
    'ambos': Color(0xFFF5A623),
  };

  @override
  Widget build(BuildContext context) {
    final colors = colorMap ?? _defaultColors;
    final color = colors[estado] ?? const Color(0xFF6B7280);
    final label = labelMap?[estado] ?? _capitalize(estado);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}