import 'package:flutter/material.dart';

import '../models/transaccion.dart';
import '../services/transacciones_service.dart';
import '../services/finanzas_repo.dart';
import '../utils/formato.dart';
import '../widgets/acciones_transaccion.dart';
import '../widgets/mascota.dart';
import '../widgets/formulario_transaccion.dart';
import '../models/estado_mascota.dart';
import '../widgets/movimiento_tile.dart';
import '../widgets/sync_chip.dart';

class MovimientosPage extends StatefulWidget {
  const MovimientosPage({super.key, required this.repo});
  final FinanzasRepo repo;
  @override
  State<MovimientosPage> createState() => _MovimientosPageState();
}

class _MovimientosPageState extends State<MovimientosPage> {
  int _filtro = 0; // 0 todos, 1 gastos, 2 ingresos

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final lista = widget.repo.lote.items.where((t) {
      if (_filtro == 1) return t.tipo == TipoTransaccion.gasto;
      if (_filtro == 2) return t.tipo == TipoTransaccion.ingreso;
      return true;
    }).toList();

    final items = <Object>[];
    DateTime? diaActual;
    for (final t in lista) {
      final d = DateTime(t.fecha.year, t.fecha.month, t.fecha.day);
      if (diaActual != d) {
        diaActual = d;
        items.add(d);
      }
      items.add(t);
    }

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Movimientos',
                              style: tema.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          SyncChip(lote: widget.repo.lote),
                          if (modoPruebas)
                            PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'gen') {
                                  widget.repo.transacciones.generarPrueba(50);
                                }
                                if (v == 'del') {
                                  widget.repo.transacciones.borrarPrueba();
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'gen',
                                  child: Text('Generar 50 de prueba'),
                                ),
                                PopupMenuItem(
                                  value: 'del',
                                  child: Text('Borrar los de prueba'),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 0, label: Text('Todos')),
                          ButtonSegment(value: 1, label: Text('Gastos')),
                          ButtonSegment(value: 2, label: Text('Ingresos')),
                        ],
                        selected: {_filtro},
                        onSelectionChanged: (s) =>
                            setState(() => _filtro = s.first),
                      ),
                    ],
                  ),
                ),
              ),
              if (lista.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Mascota(EstadoMascota.escritorio, tamano: 140),
                        SizedBox(height: 8),
                        Text('Nada por aquí todavía.'),
                      ],
                    ),
                  ),
                )
              else
                SliverList.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    if (item is DateTime) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                        child: Text(
                          fechaLarga(item),
                          style: tema.textTheme.labelLarge?.copyWith(
                            color: tema.colorScheme.outline,
                          ),
                        ),
                      );
                    }
                    final t = item as Transaccion;
                    return Dismissible(
                      key: ValueKey(t.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: tema.colorScheme.error.withValues(alpha: 0.25),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        child: Icon(
                          Icons.delete_outline,
                          color: tema.colorScheme.error,
                        ),
                      ),
                      onDismissed: (_) => eliminarTransaccion(
                        context,
                        widget.repo.transacciones,
                        t,
                        confirmar: false,
                      ),
                      child: MovimientoTile(
                        t: t,
                        cuenta: t.cuentaId == cuentaEfectivo
                            ? null
                            : widget.repo.nombreCuenta(t.cuentaId),
                        onTap: () => mostrarFormularioTransaccion(
                          context,
                          widget.repo,
                          inicial: t,
                        ),
                        onEliminar: () => eliminarTransaccion(
                          context,
                          widget.repo.transacciones,
                          t,
                          confirmar: true,
                        ),
                      ),
                    );
                  },
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
        ),
      ),
    );
  }
}
