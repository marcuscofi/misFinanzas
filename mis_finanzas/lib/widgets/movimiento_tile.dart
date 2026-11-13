import 'package:flutter/material.dart';

import '../models/transaccion.dart';
import '../theme/paleta.dart';
import '../utils/formato.dart';

const _iconos = <String, IconData>{
  'Comida': Icons.restaurant,
  'Transporte': Icons.directions_bus,
  'Hogar': Icons.home,
  'Salud': Icons.favorite,
  'Ocio': Icons.sports_esports,
  'Servicios': Icons.receipt_long,
  'Salario': Icons.payments,
  'Extra': Icons.add_card,
};

class MovimientoTile extends StatelessWidget {
  const MovimientoTile({
    super.key,
    required this.t,
    required this.onEliminar,
    this.mostrarFecha = false,
    this.cuenta,
    this.onTap,
  });
  final Transaccion t;
  final VoidCallback onEliminar;
  final bool mostrarFecha;
  final String? cuenta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final ingreso = t.tipo == TipoTransaccion.ingreso;
    final color = ingreso ? Paleta.esmeralda : Paleta.gasto;
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 12, right: 4),
      onTap: onTap,
      subtitle: Text(
        [
          t.categoria,
          ?cuenta,
          if (mostrarFecha) fechaCorta(t.fecha),
        ].join(' · '),
      ),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(_iconos[t.categoria] ?? Icons.category, color: color),
      ),
      title: Text(
        t.descripcion.isEmpty ? t.categoria : t.descripcion,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${ingreso ? '+' : '-'}${formatoUsd(t.montoCentavos)}',
            style: tema.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            tooltip: 'Eliminar',
            icon: const Icon(Icons.delete_outline, size: 20),
            color: tema.colorScheme.outline,
            onPressed: onEliminar,
          ),
        ],
      ),
    );
  }
}
