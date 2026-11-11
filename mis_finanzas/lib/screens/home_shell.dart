import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/transacciones_service.dart';
import '../theme/paleta.dart';
import '../widgets/formulario_transaccion.dart';
import 'inicio_page.dart';
import 'movimientos_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.user});
  final User user;
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final TransaccionesService _service =
      TransaccionesService(widget.user.uid);
  late final Stream<LoteTransacciones> _stream = _service.observar();
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LoteTransacciones>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(body: Center(child: Text('Error: ${snap.error}')));
        }
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final lote = snap.data!;
        final balance = lote.items.fold<int>(0, (a, t) => a + t.centavosConSigno);

        final cuerpo = IndexedStack(index: _tab, children: [
          InicioPage(
            lote: lote,
            balance: balance,
            service: _service,
            onVerTodos: () => setState(() => _tab = 1),
          ),
          MovimientosPage(lote: lote, service: _service),
        ]);

        final fab = FloatingActionButton.extended(
          backgroundColor: Paleta.lima,
          foregroundColor: Colors.black,
          onPressed: () => mostrarFormularioTransaccion(context, _service,
              balanceCentavos: balance),
          icon: const Icon(Icons.add),
          label: const Text('Nuevo'),
        );

        return LayoutBuilder(builder: (context, c) {
          if (c.maxWidth >= 840) {
            return Scaffold(
              floatingActionButton: fab,
              body: Row(children: [
                NavigationRail(
                  selectedIndex: _tab,
                  onDestinationSelected: (i) => setState(() => _tab = i),
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                        icon: Icon(Icons.home_outlined),
                        selectedIcon: Icon(Icons.home_rounded),
                        label: Text('Inicio')),
                    NavigationRailDestination(
                        icon: Icon(Icons.receipt_long_outlined),
                        selectedIcon: Icon(Icons.receipt_long),
                        label: Text('Movimientos')),
                  ],
                ),
                const VerticalDivider(width: 1, color: Colors.white10),
                Expanded(child: cuerpo),
              ]),
            );
          }
          return Scaffold(
            floatingActionButton: fab,
            body: cuerpo,
            bottomNavigationBar: NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Inicio'),
                NavigationDestination(
                    icon: Icon(Icons.receipt_long_outlined),
                    selectedIcon: Icon(Icons.receipt_long),
                    label: 'Movimientos'),
              ],
            ),
          );
        });
      },
    );
  }
}