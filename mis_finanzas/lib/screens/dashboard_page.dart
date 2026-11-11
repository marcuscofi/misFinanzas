import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/transaccion.dart';
import '../services/transacciones_service.dart';
import '../utils/formato.dart';
import '../widgets/formulario_transaccion.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.user});
  final User user;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final TransaccionesService _service =
      TransaccionesService(widget.user.uid);
  late final Stream<List<Transaccion>> _stream = _service.observar();

  static const _iconos = <String, IconData>{
    'Comida': Icons.restaurant,
    'Transporte': Icons.directions_bus,
    'Hogar': Icons.home,
    'Salud': Icons.favorite,
    'Ocio': Icons.sports_esports,
    'Servicios': Icons.receipt_long,
    'Salario': Icons.payments,
    'Extra': Icons.add_card,
  };

  void _eliminar(Transaccion t) {
    _service.eliminar(t.id); // sin await: el stream refleja el cambio al instante
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: const Text('Movimiento eliminado'),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () => _service.agregar(t),
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => mostrarFormularioTransaccion(context, _service),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      body: StreamBuilder<List<Transaccion>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final lista = snapshot.data!;
          return CustomScrollView(
            slivers: [
              SliverAppBar.large(
                title: const Text('Mis Finanzas'),
                actions: [
                  IconButton(
                    tooltip: 'Cerrar sesión',
                    icon: const Icon(Icons.logout),
                    onPressed: () => FirebaseAuth.instance.signOut(),
                  ),
                ],
              ),
              SliverToBoxAdapter(child: _ResumenCard(movimientos: lista)),
              if (lista.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text('Aún no hay movimientos.\nToca "Nuevo" para empezar.',
                        textAlign: TextAlign.center),
                  ),
                )
              else
                ..._buildLista(lista),
              // Espacio para que el FAB no tape el último ítem.
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildLista(List<Transaccion> lista) {
    // Aplana en: encabezado de día, movimientos, encabezado, movimientos...
    final items = <Object>[];
    DateTime? diaActual;
    for (final t in lista) {
      final dia = DateTime(t.fecha.year, t.fecha.month, t.fecha.day);
      if (diaActual != dia) {
        diaActual = dia;
        items.add(dia);
      }
      items.add(t);
    }

    final tema = Theme.of(context);
    return [
      SliverList.builder(
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          if (item is DateTime) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(fechaLarga(item),
                  style: tema.textTheme.labelLarge
                      ?.copyWith(color: tema.colorScheme.outline)),
            );
          }
          final t = item as Transaccion;
          final esIngreso = t.tipo == TipoTransaccion.ingreso;
          final color = esIngreso ? Colors.green.shade600 : tema.colorScheme.error;
          return Dismissible(
            key: ValueKey(t.id),
            direction: DismissDirection.endToStart,
            background: Container(
              color: tema.colorScheme.errorContainer,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              child: Icon(Icons.delete_outline,
                  color: tema.colorScheme.onErrorContainer),
            ),
            onDismissed: (_) => _eliminar(t),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: tema.colorScheme.secondaryContainer,
                child: Icon(_iconos[t.categoria] ?? Icons.category,
                    color: tema.colorScheme.onSecondaryContainer),
              ),
              title: Text(t.descripcion.isEmpty ? t.categoria : t.descripcion),
              subtitle: Text(t.categoria),
              trailing: Text(
                '${esIngreso ? '+' : '-'}${formatoUsd(t.montoCentavos)}',
                style: tema.textTheme.titleMedium
                    ?.copyWith(color: color, fontWeight: FontWeight.w600),
              ),
            ),
          );
        },
      ),
    ];
  }
}

class _ResumenCard extends StatelessWidget {
  const _ResumenCard({required this.movimientos});
  final List<Transaccion> movimientos;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final ahora = DateTime.now();

    var balance = 0;
    var ingresosMes = 0;
    var gastosMes = 0;
    for (final t in movimientos) {
      balance += t.centavosConSigno;
      if (t.fecha.year == ahora.year && t.fecha.month == ahora.month) {
        if (t.tipo == TipoTransaccion.ingreso) {
          ingresosMes += t.montoCentavos;
        } else {
          gastosMes += t.montoCentavos;
        }
      }
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: tema.colorScheme.primaryContainer,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Balance actual',
                style: tema.textTheme.labelLarge
                    ?.copyWith(color: tema.colorScheme.onPrimaryContainer)),
            const SizedBox(height: 4),
            Text(
              formatoUsd(balance),
              style: tema.textTheme.displaySmall?.copyWith(
                  color: tema.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _Mini(
                        etiqueta: 'Ingresos del mes',
                        valor: formatoUsd(ingresosMes),
                        icono: Icons.arrow_downward,
                        color: Colors.green.shade700)),
                Expanded(
                    child: _Mini(
                        etiqueta: 'Gastos del mes',
                        valor: formatoUsd(gastosMes),
                        icono: Icons.arrow_upward,
                        color: tema.colorScheme.error)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({
    required this.etiqueta,
    required this.valor,
    required this.icono,
    required this.color,
  });
  final String etiqueta, valor;
  final IconData icono;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Row(
      children: [
        Icon(icono, size: 18, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(etiqueta,
                  style: tema.textTheme.bodySmall
                      ?.copyWith(color: tema.colorScheme.onPrimaryContainer)),
              Text(valor,
                  style: tema.textTheme.titleSmall?.copyWith(
                      color: tema.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}