import 'package:flutter/material.dart';
import '../models/transaccion.dart';
import '../services/transacciones_service.dart';
import '../utils/formato.dart';

/// [confirmar] = true para el botón de la papelera; el deslizar ya es intencional
/// y se cubre con "Deshacer".
Future<void> eliminarTransaccion(
  BuildContext context,
  TransaccionesService service,
  Transaccion t, {
  required bool confirmar,
}) async {
  if (confirmar) {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar movimiento?'),
        content: Text(
            '${t.descripcion.isEmpty ? t.categoria : t.descripcion} · ${formatoUsd(t.montoCentavos)}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
  }
  service.eliminar(t.id); // sin await: funciona igual offline
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
      content: const Text('Movimiento eliminado'),
      action: SnackBarAction(
          label: 'Deshacer', onPressed: () => service.agregar(t)),
    ));
}