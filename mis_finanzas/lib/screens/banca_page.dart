import 'package:flutter/material.dart';

import '../models/cuenta_bancaria.dart';
import '../models/tarjeta.dart';
import '../services/finanzas_repo.dart';
import '../theme/paleta.dart';
import '../utils/formato.dart';
import '../utils/presupuesto.dart';
import '../widgets/cuenta_form.dart';
import '../widgets/glass_card.dart';
import '../widgets/tarjeta_form.dart';

Color colorBanco(String banco) {
  const c = [
    Paleta.esmeralda,
    Paleta.menta,
    Paleta.lima,
    Color(0xFF5BC0FF),
    Color(0xFFB388FF),
    Color(0xFFFFB74D),
  ];
  final i = bancos.indexOf(banco);
  return c[(i < 0 ? 0 : i) % c.length];
}

class BancaPage extends StatelessWidget {
  const BancaPage({super.key, required this.repo});
  final FinanzasRepo repo;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final estados = repo.estadosTarjetas;
    final cuentas = repo.cuentas;
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
              Text(
                'Banca',
                style: tema.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                acento: Paleta.esmeralda,
                child: Row(
                  children: [
                    const _Avatar(
                      icono: Icons.account_balance_wallet_outlined,
                      color: Paleta.esmeralda,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Líquido total',
                            style: tema.textTheme.titleMedium,
                          ),
                          Text(
                            'Efectivo + cuentas y débito',
                            style: tema.textTheme.bodySmall?.copyWith(
                              color: tema.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatoUsd(repo.liquidoTotal),
                      style: tema.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _SeccionTitulo(
                icono: Icons.payments_outlined,
                titulo: 'Efectivo Libre',
              ),
              const SizedBox(height: 10),
              GlassCard(
                acento: Paleta.lima,
                child: Row(
                  children: [
                    const _Avatar(
                      icono: Icons.payments_outlined,
                      color: Paleta.lima,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Efectivo', style: tema.textTheme.titleMedium),
                          Text(
                            'No se reinicia cada mes',
                            style: tema.textTheme.bodySmall?.copyWith(
                              color: tema.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatoUsd(libre),
                          style: tema.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: libre < 0 ? Paleta.gasto : null,
                          ),
                        ),
                        Text(
                          'balance ${formatoUsd(repo.balanceEfectivo)}',
                          style: tema.textTheme.bodySmall?.copyWith(
                            color: tema.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SeccionTitulo(
                icono: Icons.account_balance_outlined,
                titulo: 'Cuentas y Débito',
                accion: TextButton.icon(
                  onPressed: () =>
                      mostrarFormularioCuenta(context, repo.cuentasSvc),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar'),
                ),
              ),
              const SizedBox(height: 10),
              if (cuentas.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Agrega una cuenta bancaria o tarjeta de débito para seguir su saldo acumulado.',
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final c in cuentas) ...[
                _CuentaCard(
                  cuenta: c,
                  saldo: repo.saldoCuenta(c.id),
                  onTap: () => mostrarFormularioCuenta(
                    context,
                    repo.cuentasSvc,
                    inicial: c,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 12),
              _SeccionTitulo(
                icono: Icons.credit_card_outlined,
                titulo: 'Tarjetas de Crédito',
                accion: TextButton.icon(
                  onPressed: () =>
                      mostrarFormularioTarjeta(context, repo.tarjetasSvc),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar'),
                ),
              ),
              const SizedBox(height: 10),
              if (estados.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Agrega tu primera tarjeta para llevar el presupuesto mensual de cada una.',
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final e in estados) ...[
                _TarjetaCreditoCard(
                  e: e,
                  renueva: renueva,
                  onTap: () => mostrarFormularioTarjeta(
                    context,
                    repo.tarjetasSvc,
                    inicial: e.tarjeta,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (repo.cuentasArchivadas.isNotEmpty ||
                  repo.archivadas.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Archivadas',
                  style: tema.textTheme.labelLarge?.copyWith(
                    color: tema.colorScheme.outline,
                  ),
                ),
                for (final c in repo.cuentasArchivadas)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(c.nombre),
                    subtitle: const Text('Cuenta archivada'),
                    trailing: TextButton(
                      onPressed: () =>
                          repo.cuentasSvc.archivar(c.id, activa: true),
                      child: const Text('Reactivar'),
                    ),
                  ),
                for (final t in repo.archivadas)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.nombre),
                    subtitle: const Text('Tarjeta archivada'),
                    trailing: TextButton(
                      onPressed: () =>
                          repo.tarjetasSvc.archivar(t.id, activa: true),
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

class _SeccionTitulo extends StatelessWidget {
  const _SeccionTitulo({
    required this.icono,
    required this.titulo,
    this.accion,
  });
  final IconData icono;
  final String titulo;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Row(
      children: [
        Icon(icono, size: 20, color: Paleta.esmeralda),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            titulo,
            style: tema.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ?accion,
      ],
    );
  }
}

class _CuentaCard extends StatelessWidget {
  const _CuentaCard({
    required this.cuenta,
    required this.saldo,
    required this.onTap,
  });
  final CuentaBancaria cuenta;
  final int saldo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final color = colorBanco(cuenta.banco);
    return GlassCard(
      acento: color,
      onTap: onTap,
      child: Row(
        children: [
          _Avatar(
            texto: cuenta.bancoCorto.characters.first.toUpperCase(),
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cuenta.nombre, style: tema.textTheme.titleMedium),
                Text(
                  '${cuenta.tipoEtiqueta} · saldo acumulado',
                  style: tema.textTheme.bodySmall?.copyWith(
                    color: tema.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatoUsd(saldo),
                style: tema.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: saldo < 0 ? Paleta.gasto : null,
                ),
              ),
              Text(
                'disponible',
                style: tema.textTheme.bodySmall?.copyWith(
                  color: tema.colorScheme.outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TarjetaCreditoCard extends StatelessWidget {
  const _TarjetaCreditoCard({
    required this.e,
    required this.renueva,
    required this.onTap,
  });
  final EstadoTarjeta e;
  final DateTime renueva;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final c = e.tarjeta;
    final color = colorBanco(c.banco);
    final barra = e.uso > 1
        ? Paleta.gasto
        : (e.uso > 0.8 ? Colors.amber : color);
    return GlassCard(
      acento: color,
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              _Avatar(
                texto: c.bancoCorto.characters.first.toUpperCase(),
                color: color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.nombre, style: tema.textTheme.titleMedium),
                    Text(
                      'Se renueva el ${fechaMuyCorta(renueva)}',
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: tema.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatoUsd(e.restante),
                    style: tema.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: e.restante < 0 ? Paleta.gasto : null,
                    ),
                  ),
                  Text(
                    'restante',
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: tema.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: e.uso.clamp(0.0, 1.0).toDouble(),
              minHeight: 8,
              color: barra,
              backgroundColor: Colors.white10,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gastado ${formatoUsd(e.gastadoMes)}',
                style: tema.textTheme.bodySmall,
              ),
              Text(
                'Presupuesto ${formatoUsd(e.limite)}',
                style: tema.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
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
        : Text(
            texto ?? '',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
  );
}
