import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_theme.dart';

class QrDisplayWidget extends StatelessWidget {
  final String data;
  final String? label;
  final double size;

  const QrDisplayWidget({
    super.key,
    required this.data,
    this.label,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: QrImageView(
            data: data,
            version: QrVersions.auto,
            size: size,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: AppTheme.primaryColor,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 12),
          Text(
            label!,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              fontFamily: 'monospace',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}