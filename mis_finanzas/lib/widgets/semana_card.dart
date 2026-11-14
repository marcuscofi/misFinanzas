// lib/widgets/semana_card.dart
import 'package:flutter/material.dart';

import '../theme/paleta.dart';
import '../utils/formato.dart';
import '../utils/presupuesto.dart';
import 'glass_card.dart';

String _semanasTexto(double semanas) {
  final texto = semanas.toStringAsFixed(1);
  return texto.endsWith('.0') ? texto.substring(0, texto.length - 2) : texto;
}

class SemanaCard extends StatelessWidget {
  const SemanaCard({super.key, required this.s});
  final PresupuestoSemanal s;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    if (s.asignacionOptimista == 0 &&
        s.asignacionPesimista == 0 &&
        s.gastado == 0) {
      return const GlassCard(
        child: Row(
          children: [
            Icon(Icons.event_available_outlined),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Registra un ingreso o una tarjeta para calcular cuánto puedes gastar esta semana.',
              ),
            ),
          ],
        ),
      );
    }
    final exceso = s.quedanOptimista < 0;
    final color = exceso
        ? Paleta.gasto
        : (s.progreso > 0.8 ? Colors.amber : Paleta.esmeralda);
    final semanas = _semanasTexto(s.semanasExactas);

    return GlassCard(
      acento: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Esta semana', style: tema.textTheme.titleMedium),
              const Spacer(),
              Text(
                '${fechaMuyCorta(s.inicio)} – ${fechaMuyCorta(s.fin)}',
                style: tema.textTheme.bodySmall?.copyWith(
                  color: tema.colorScheme.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            exceso ? 'Te pasaste por' : 'Aún puedes gastar',
            style: tema.textTheme.bodySmall?.copyWith(
              color: tema.colorScheme.outline,
            ),
          ),
          Text(
            formatoUsd(exceso ? -s.quedanOptimista : s.quedanOptimista),
            style: tema.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: exceso ? Paleta.gasto : null,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: s.progreso,
              minHeight: 10,
              color: color,
              backgroundColor: Colors.white10,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gastado ${formatoUsd(s.gastado)}',
                style: tema.textTheme.bodySmall,
              ),
              Text(
                'de ${formatoUsd(s.asignacionOptimista)}',
                style: tema.textTheme.bodySmall,
              ),
            ],
          ),
          const Divider(height: 24, color: Colors.white12),
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              _Dato('Efectivo libre', formatoUsd(s.efectivoLibre)),
              _Dato('Cuentas y débito', formatoUsd(s.cuentasRestante)),
              _Dato('Tarjetas (mes)', formatoUsd(s.tarjetasRestante)),
              _Dato('Ahorro apartado', formatoUsd(s.ahorroApartado)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Quedan ${s.diasRestantesEnMes} días en el mes: '
            '${s.semanasRestantesEnteras} ${s.semanasRestantesEnteras == 1 ? 'semana completa' : 'semanas completas'} '
            '($semanas ${semanas == '1' ? 'semana exacta' : 'semanas exactas'}).',
            style: tema.textTheme.bodySmall?.copyWith(
              color: tema.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _Escenario(
                  titulo: 'Optimista (Principal)',
                  detalle:
                      'Solo ${s.semanasRestantesEnteras} ${s.semanasRestantesEnteras == 1 ? 'semana' : 'semanas'}',
                  asignacion: s.asignacionOptimista,
                  quedan: s.quedanOptimista,
                  color: color,
                  destacado: true,
                ),
                const Divider(height: 18, color: Colors.white12),
                _Escenario(
                  titulo: 'Conservador / Pesimista',
                  detalle: 'Cubre los $semanas sem. exactas',
                  asignacion: s.asignacionPesimista,
                  quedan: s.quedanPesimista,
                  color: Paleta.menta,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Escenario extends StatelessWidget {
  const _Escenario({
    required this.titulo,
    required this.detalle,
    required this.asignacion,
    required this.quedan,
    required this.color,
    this.destacado = false,
  });

  final String titulo;
  final String detalle;
  final int asignacion;
  final int quedan;
  final Color color;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final deficit = quedan < 0;
    return Row(
      children: [
        Icon(
          destacado ? Icons.speed : Icons.shield_outlined,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: tema.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                detalle,
                style: tema.textTheme.bodySmall?.copyWith(
                  color: tema.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${formatoUsd(asignacion)} / sem',
              style: tema.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              deficit
                  ? 'Déficit ${formatoUsd(-quedan)}'
                  : 'Quedan ${formatoUsd(quedan)}',
              style: tema.textTheme.bodySmall?.copyWith(
                color: deficit ? Paleta.gasto : tema.colorScheme.outline,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato(this.etiqueta, this.valor);
  final String etiqueta, valor;
  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: tema.textTheme.bodySmall?.copyWith(
            color: tema.colorScheme.outline,
          ),
        ),
        Text(
          valor,
          style: tema.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}