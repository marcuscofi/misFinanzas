import 'package:flutter/material.dart';

import '../models/tarjeta.dart';
import '../services/finanzas_repo.dart';
import '../theme/paleta.dart';
import '../utils/formato.dart';
import '../utils/presupuesto.dart';
import '../widgets/glass_card.dart';
import '../widgets/tarjeta_form.dart';

Color colorTarjeta(String banco) {
  const c = [
    Paleta.esmeralda, Paleta.menta, Paleta.lima,
    Color(0xFF5BC0FF), Color(0xFFB388FF), Color(0xFFFFB74D),
  ];
  final i = bancos.indexOf(banco);
  return c[(i < 0 ? 0 : i) % c.length];
}

class TarjetasPage extends StatelessWidget {
  const TarjetasPage({super.key, required this.repo});
  final FinanzasRepo repo;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final estados = repo.estadosTarjetas;
    final ahora = DateTime.now();
    final renueva = DateTime(ahora.year, ahora.month + 1, 1);
    final libre = repo.balanceEfectivo - repo.ahorroTotal;

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            children: [
              Row(children: [
                Expanded(
                  child: Text('Tarjetas',
                      style: tema.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ),
                OutlinedButton.icon(
                  onPressed: () => mostrarFormularioTarjeta(context, repo.tarjetasSvc),
                  icon: const Icon(Icons.add_card),
                  label: const Text('Agregar'),
                ),
              ]),
              const SizedBox(height: 12),
              GlassCard(
                acento: Paleta.esmeralda,
                child: Row(children: [
                  const _Avatar(icono: Icons.payments_outlined, color: Paleta.esmeralda),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Efectivo', style: tema.textTheme.titleMedium),
                      Text('No se reinicia cada mes',
                          style: tema.textTheme.bodySmall
                              ?.copyWith(color: tema.colorScheme.outline)),
                    ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(formatoUsd(repo.balanceEfectivo),
                        style: tema.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    Text('libre de ahorro: ${formatoUsd(libre)}',
                        style: tema.textTheme.bodySmall
                            ?.copyWith(color: tema.colorScheme.outline)),
                  ]),
                ]),
              ),
              const SizedBox(height: 12),
              if (estados.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Agrega tu primera tarjeta para llevar el presupuesto mensual de cada una.',
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final e in estados) ...[
                _TarjetaCard(
                  e: e,
                  renueva: renueva,
                  onTap: () => mostrarFormularioTarjeta(context, repo.tarjetasSvc,
                      inicial: e.tarjeta),
                ),
                const SizedBox(height: 12),
              ],
              if (repo.archivadas.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Archivadas',
                    style: tema.textTheme.labelLarge
                        ?.copyWith(color: tema.colorScheme.outline)),
                for (final t in repo.archivadas)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.nombre),
                    trailing: TextButton(
                      onPressed: () => repo.tarjetasSvc.archivar(t.id, activa: true),
                      child: const Text('Reactivar'),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaCard extends StatelessWidget {
  const _TarjetaCard({required this.e, required this.renueva, required this.onTap});
  final EstadoTarjeta e;
  final DateTime renueva;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final c = e.tarjeta;
    final color = colorTarjeta(c.banco);
    final barra = e.uso > 1 ? Paleta.gasto : (e.uso > 0.8 ? Colors.amber : color);
    return GlassCard(
      acento: color,
      onTap: onTap,
      child: Column(children: [
        Row(children: [
          _Avatar(texto: c.bancoCorto.characters.first.toUpperCase(), color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.nombre, style: tema.textTheme.titleMedium),
              Text('Se renueva el ${fechaMuyCorta(renueva)}',
                  style: tema.textTheme.bodySmall
                      ?.copyWith(color: tema.colorScheme.outline)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(formatoUsd(e.restante),
                style: tema.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: e.restante < 0 ? Paleta.gasto : null)),
            Text('restante',
                style: tema.textTheme.bodySmall
                    ?.copyWith(color: tema.colorScheme.outline)),
          ]),
        ]),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
              value: e.uso.clamp(0.0, 1.0).toDouble(),
              minHeight: 8,
              color: barra,
              backgroundColor: Colors.white10),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Gastado ${formatoUsd(e.gastadoMes)}', style: tema.textTheme.bodySmall),
          Text('Presupuesto ${formatoUsd(e.limite)}', style: tema.textTheme.bodySmall),
        ]),
      ]),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.icono, this.texto, required this.color});
  final IconData? icono;
  final String? texto;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        alignment: Alignment.center,
        child: icono != null
            ? Icon(icono, color: color)
            : Text(texto ?? '',
                style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18)),
      );
}