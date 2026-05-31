import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color? color;
  final VoidCallback? onTap;
  final String? subtitulo;

  const StatCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icono,
    this.color,
    this.onTap,
    this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? AppTheme.primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icono, color: Colors.white, size: 20),
                ),
                if (onTap != null)
                  const Icon(Icons.arrow_forward_ios,
                      color: Colors.white54, size: 14),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              valor,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              titulo,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            if (subtitulo != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitulo!,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}