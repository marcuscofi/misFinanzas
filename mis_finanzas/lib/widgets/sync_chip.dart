import 'package:flutter/material.dart';
import '../services/transacciones_service.dart';
import '../theme/paleta.dart';

class SyncChip extends StatelessWidget {
  const SyncChip({super.key, required this.lote});
  final LoteTransacciones lote;

  @override
  Widget build(BuildContext context) {
    IconData icono;
    String texto;
    Color color;
    if (lote.pendientes) {
      icono = Icons.cloud_upload_outlined;
      texto = 'Sincronizando…';
      color = Colors.amber;
    } else if (lote.desdeCache) {
      icono = Icons.cloud_off_outlined;
      texto = 'Sin conexión';
      color = Colors.orangeAccent;
    } else {
      icono = Icons.cloud_done_outlined;
      texto = 'Sincronizado';
      color = Paleta.esmeralda;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icono, size: 14, color: color),
        const SizedBox(width: 6),
        Text(texto,
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}