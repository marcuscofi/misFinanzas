import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/transacciones_service.dart';
import '../theme/paleta.dart';
import '../utils/analisis.dart';
import '../utils/formato.dart';
import '../widgets/acciones_transaccion.dart';
import '../widgets/glass_card.dart';
import '../widgets/grafica_gastos.dart';
import '../widgets/mascota.dart';
import '../widgets/movimiento_tile.dart';
import '../widgets/sync_chip.dart';

class InicioPage extends StatefulWidget {
  const InicioPage({
    super.key,
    required this.lote,
    required this.balance,
    required this.service,
    required this.onVerTodos,
  });
  final LoteTransacciones lote;
  final int balance;
  final TransaccionesService service;
  final VoidCallback onVerTodos;

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  Periodo _periodo = const Periodo.meses(1);

  static const _presets = [Periodo.dias(7), Periodo.dias(14), Periodo.meses(1)];

  Future<int?> _pedirMeses(int inicial) {
    var valor = inicial.clamp(1, 36).toInt();
    return showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('¿Cuántos meses?'),
          content: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton.filledTonal(
                onPressed: valor > 1 ? () => setS(() => valor--) : null,
                icon: const Icon(Icons.remove)),
            SizedBox(
                width: 80,
                child: Text('$valor',
                    textAlign: TextAlign.center,
                    style: Theme.of(ctx).textTheme.headlineMedium)),
            IconButton.filledTonal(
                onPressed: valor < 36 ? () => setS(() => valor++) : null,
                icon: const Icon(Icons.add)),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, valor),
                child: const Text('Aplicar')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final movs = widget.lote.items;
    final r = analizar(movs, _periodo, DateTime.now());
    final lectura = evaluarMascota(
        balance: widget.balance, r: r, hayDatos: movs.isNotEmpty);

    final izq = <Widget>[
      _cabecera(),
      const SizedBox(height: 8),
      _tarjetaMascota(lectura),
      const SizedBox(height: 12),
      _tarjetaGrafica(r),
    ];
    final der = <Widget>[
      const SizedBox(height: 8),
      Row(children: [
        Text('Últimos movimientos',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const Spacer(),
        TextButton(onPressed: widget.onVerTodos, child: const Text('Ver todos')),
      ]),
      if (movs.isEmpty)
        const Padding(
          padding: EdgeInsets.all(24),
          child: Text('Aún no hay movimientos.\nToca "Nuevo" para empezar.',
              textAlign: TextAlign.center),
        ),
      for (final t in movs.take(6))
        MovimientoTile(
          t: t,
          mostrarFecha: true,
          onEliminar: () =>
              eliminarTransaccion(context, widget.service, t, confirmar: true),
        ),
    ];

    const pad = EdgeInsets.fromLTRB(16, 8, 16, 110);
    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: LayoutBuilder(builder: (context, c) {
            if (c.maxWidth >= 900) {
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 3, child: ListView(padding: pad, children: izq)),
                Expanded(flex: 2, child: ListView(padding: pad, children: der)),
              ]);
            }
            return ListView(padding: pad, children: [...izq, ...der]);
          }),
        ),
      ),
    );
  }

  Widget _cabecera() => Row(children: [
        Expanded(
          child: Text('Mis Finanzas',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
        ),
        SyncChip(lote: widget.lote),
        IconButton(
          tooltip: 'Cerrar sesión',
          icon: const Icon(Icons.logout),
          onPressed: () => FirebaseAuth.instance.signOut(),
        ),
      ]);

  Widget _tarjetaMascota(Lectura l) {
    final tema = Theme.of(context);
    final acento = switch (l.tono) {
      Tono.positivo => Paleta.esmeralda,
      Tono.neutro => Paleta.menta,
      Tono.alerta => Paleta.gasto,
    };
    return GlassCard(
      acento: acento,
      child: Row(children: [
        Mascota(l.estado, tamano: 120),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Balance actual',
                style: tema.textTheme.labelLarge
                    ?.copyWith(color: tema.colorScheme.outline)),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(formatoUsd(widget.balance),
                  style: tema.textTheme.displaySmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 6),
            Text(l.mensaje, style: tema.textTheme.bodyMedium),
          ]),
        ),
      ]),
    );
  }

  Widget _tarjetaGrafica(ResumenPeriodo r) {
    final tema = Theme.of(context);
    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Gastos', style: tema.textTheme.titleMedium),
          const Spacer(),
          _chipVariacion(r.variacion),
        ]),
        const SizedBox(height: 4),
        Text(formatoUsd(r.gastos),
            style: tema.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        GraficaGastos(serie: r.serie, seriePrev: r.seriePrev),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(fechaMuyCorta(r.inicio), style: tema.textTheme.bodySmall),
          Text('Línea punteada: periodo anterior',
              style: tema.textTheme.bodySmall
                  ?.copyWith(color: tema.colorScheme.outline)),
          Text(fechaMuyCorta(r.hoy), style: tema.textTheme.bodySmall),
        ]),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 4, children: [
          for (final p in _presets)
            ChoiceChip(
              label: Text(p.etiqueta),
              selected: _periodo == p,
              onSelected: (_) => setState(() => _periodo = p),
            ),
          ChoiceChip(
            avatar: const Icon(Icons.tune, size: 16),
            label: Text(_periodo.meses > 1 ? _periodo.etiqueta : 'Meses…'),
            selected: _periodo.meses > 1,
            onSelected: (_) async {
              final m = await _pedirMeses(_periodo.meses > 1 ? _periodo.meses : 3);
              if (m != null) setState(() => _periodo = Periodo.meses(m));
            },
          ),
        ]),
        const Divider(height: 28, color: Colors.white12),
        Row(children: [
          Expanded(
              child: _Mini('Ingresos', formatoUsd(r.ingresos),
                  Icons.arrow_downward, Paleta.esmeralda)),
          Expanded(
              child: _Mini('Gastos', formatoUsd(r.gastos), Icons.arrow_upward,
                  Paleta.gasto)),
        ]),
      ]),
    );
  }

  Widget _chipVariacion(double? v) {
    final tema = Theme.of(context);
    if (v == null) {
      return Text('Sin periodo previo',
          style: tema.textTheme.bodySmall?.copyWith(color: tema.colorScheme.outline));
    }
    final sube = v > 0;
    final color = v == 0 ? tema.colorScheme.outline : (sube ? Paleta.gasto : Paleta.esmeralda);
    final texto = v == 0
        ? 'Sin cambios'
        : '${sube ? '+' : ''}${(v * 100).toStringAsFixed(0)} % vs. anterior';
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(v == 0 ? Icons.trending_flat : (sube ? Icons.trending_up : Icons.trending_down),
          size: 18, color: color),
      const SizedBox(width: 4),
      Text(texto,
          style: tema.textTheme.labelMedium
              ?.copyWith(color: color, fontWeight: FontWeight.w700)),
    ]);
  }
}

class _Mini extends StatelessWidget {
  const _Mini(this.etiqueta, this.valor, this.icono, this.color);
  final String etiqueta, valor;
  final IconData icono;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Row(children: [
      Icon(icono, size: 18, color: color),
      const SizedBox(width: 6),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(etiqueta,
            style: tema.textTheme.bodySmall?.copyWith(color: tema.colorScheme.outline)),
        Text(valor,
            style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
      ]),
    ]);
  }
}