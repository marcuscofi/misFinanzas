import 'package:flutter/material.dart';
import '../theme/paleta.dart';
import '../utils/formato.dart';
import '../utils/presupuesto.dart';
import 'glass_card.dart';

class SemanaCard extends StatelessWidget {
  const SemanaCard({super.key, required this.s});
  final PresupuestoSemanal s;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    if (s.asignacion == 0 && s.gastado == 0) {
      return const GlassCard(
        child: Row(children: [
          Icon(Icons.event_available_outlined),
          SizedBox(width: 12),
          Expanded(
            child: Text(
                'Registra un ingreso o una tarjeta para calcular cuánto puedes gastar esta semana.'),
          ),
        ]),
      );
    }
    final exceso = s.quedan < 0;
    final color =
        exceso ? Paleta.gasto : (s.progreso > 0.8 ? Colors.amber : Paleta.esmeralda);

    return GlassCard(
      acento: color,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Esta semana', style: tema.textTheme.titleMedium),
          const Spacer(),
          Text('${fechaMuyCorta(s.inicio)} – ${fechaMuyCorta(s.fin)}',
              style: tema.textTheme.bodySmall
                  ?.copyWith(color: tema.colorScheme.outline)),
        ]),
        const SizedBox(height: 8),
        Text(exceso ? 'Te pasaste por' : 'Aún puedes gastar',
            style: tema.textTheme.bodySmall
                ?.copyWith(color: tema.colorScheme.outline)),
        Text(formatoUsd(exceso ? -s.quedan : s.quedan),
            style: tema.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: exceso ? Paleta.gasto : null)),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
              value: s.progreso,
              minHeight: 10,
              color: color,
              backgroundColor: Colors.white10),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Gastado ${formatoUsd(s.gastado)}', style: tema.textTheme.bodySmall),
          Text('de ${formatoUsd(s.asignacion)}', style: tema.textTheme.bodySmall),
        ]),
        const Divider(height: 24, color: Colors.white12),
        Wrap(spacing: 20, runSpacing: 8, children: [
          _Dato('Efectivo libre', formatoUsd(s.efectivoLibre)),
          _Dato('Cuentas y débito', formatoUsd(s.cuentasRestante)),
          _Dato('Tarjetas (mes)', formatoUsd(s.tarjetasRestante)),
          _Dato('Ahorro apartado', formatoUsd(s.ahorroApartado)),
        ]),
        const SizedBox(height: 8),
        Text(
          s.semanasRestantes == 1
              ? 'Se reparte para la última semana del mes.'
              : 'Se reparte para las otras ${s.semanasRestantes} semanas restantes.',
          style: tema.textTheme.bodySmall?.copyWith(color: tema.colorScheme.outline),
        ),
      ]),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato(this.etiqueta, this.valor);
  final String etiqueta, valor;
  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(etiqueta,
          style: tema.textTheme.bodySmall?.copyWith(color: tema.colorScheme.outline)),
      Text(valor,
          style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
    ]);
  }
}