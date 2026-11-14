import 'package:flutter/material.dart';

import '../models/estado_mascota.dart';
import '../models/plan_ahorro.dart';
import '../services/finanzas_repo.dart';
import '../theme/paleta.dart';
import '../utils/formato.dart';
import '../widgets/glass_card.dart';
import '../widgets/mascota.dart';
import '../widgets/plan_form.dart';

Future<bool> _confirmar(
  BuildContext context,
  String titulo,
  String texto,
  String boton,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: Text(texto),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(boton),
        ),
      ],
    ),
  );
  return ok == true;
}

class AhorroPage extends StatelessWidget {
  const AhorroPage({super.key, required this.repo});
  final FinanzasRepo repo;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final total = repo.ahorroTotal;
    final planes = repo.planes;

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ahorro',
                      style: tema.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        mostrarFormularioPlan(context, repo.planesSvc),
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo plan'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GlassCard(
                acento: Paleta.lima,
                child: Row(
                  children: [
                    Mascota(
                      total > 0
                          ? EstadoMascota.hucha
                          : EstadoMascota.escritorio,
                      tamano: 110,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total ahorrado',
                            style: tema.textTheme.labelLarge?.copyWith(
                              color: tema.colorScheme.outline,
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              formatoUsd(total),
                              style: tema.textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Está apartado: no cuenta en lo que puedes gastar.',
                            style: tema.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (planes.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Aún no tienes planes. Crea uno y el cerdito empieza a apartar por ti.',
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final p in planes) ...[
                _PlanCard(
                  p: p,
                  acumulado: repo.ahorroDe(p),
                  onEditar: () => mostrarFormularioPlan(
                    context,
                    repo.planesSvc,
                    inicial: p,
                  ),
                  onDetener: () async {
                    if (await _confirmar(
                      context,
                      '¿Detener "${p.nombre}"?',
                      'Dejará de acumular. Lo ahorrado hasta hoy se conserva.',
                      'Detener',
                    )) {
                      repo.planesSvc.detener(p.id);
                    }
                  },
                  onEliminar: () async {
                    if (await _confirmar(
                      context,
                      '¿Eliminar "${p.nombre}"?',
                      'Se liberarán ${formatoUsd(repo.ahorroDe(p))} y volverán a tu dinero disponible.',
                      'Eliminar',
                    )) {
                      repo.planesSvc.eliminar(p.id);
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.p,
    required this.acumulado,
    required this.onEditar,
    required this.onDetener,
    required this.onEliminar,
  });
  final PlanAhorro p;
  final int acumulado;
  final VoidCallback onEditar, onDetener, onEliminar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final regla = p.regla == ReglaAhorro.porcentaje
        ? '${p.valor} % de tus ingresos'
        : '${formatoUsd(p.valor)} al mes';
    final obj = p.objetivoCentavos;
    final progreso = obj == null || obj <= 0
        ? 0.0
        : (acumulado / obj).clamp(0.0, 1.0).toDouble();

    return GlassCard(
      acento: p.activo ? Paleta.lima : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.nombre,
                      style: tema.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$regla · desde ${fechaMuyCorta(p.desde)}',
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: tema.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              if (!p.activo)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Detenido', style: tema.textTheme.labelSmall),
                ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') onEditar();
                  if (v == 'stop') onDetener();
                  if (v == 'del') onEliminar();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Editar nombre y meta'),
                  ),
                  if (p.activo)
                    const PopupMenuItem(
                      value: 'stop',
                      child: Text('Detener plan'),
                    ),
                  const PopupMenuItem(value: 'del', child: Text('Eliminar')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatoUsd(acumulado),
            style: tema.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: Paleta.lima,
            ),
          ),
          if (obj != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progreso,
                minHeight: 8,
                color: Paleta.lima,
                backgroundColor: Colors.white10,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  acumulado >= obj
                      ? '¡Meta alcanzada! 🎉'
                      : '${(progreso * 100).round()} %',
                  style: tema.textTheme.bodySmall,
                ),
                Text(
                  'Meta ${formatoUsd(obj)}',
                  style: tema.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
