import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/finanzas_repo.dart';
import '../theme/paleta.dart';
import '../widgets/formulario_transaccion.dart';
import 'ahorro_page.dart';
import 'inicio_page.dart';
import 'movimientos_page.dart';
import 'banca_page.dart';

const _destinos = [
  (icono: Icons.home_outlined, activo: Icons.home_rounded, texto: 'Inicio'),
  (
    icono: Icons.receipt_long_outlined,
    activo: Icons.receipt_long,
    texto: 'Movimientos',
  ),
  (
    icono: Icons.account_balance_wallet_outlined,
    activo: Icons.account_balance_wallet,
    texto: 'Banca',
  ),
  (icono: Icons.savings_outlined, activo: Icons.savings, texto: 'Ahorro'),
];

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.user});
  final User user;
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final FinanzasRepo _repo = FinanzasRepo(widget.user.uid);
  int _tab = 0;

  @override
  void dispose() {
    _repo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _repo,
      builder: (context, _) {
        if (_repo.error != null) {
          return Scaffold(body: Center(child: Text('Error: ${_repo.error}')));
        }
        if (!_repo.listo) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final cuerpo = IndexedStack(
          index: _tab,
          children: [
            InicioPage(repo: _repo, onVerTodos: () => setState(() => _tab = 1)),
            MovimientosPage(repo: _repo),
            BancaPage(repo: _repo),
            AhorroPage(repo: _repo),
          ],
        );

        // El botón "Nuevo" solo en Inicio y Movimientos.
        final fab = _tab <= 1
            ? FloatingActionButton.extended(
                backgroundColor: Paleta.lima,
                foregroundColor: Colors.black,
                onPressed: () => mostrarFormularioTransaccion(context, _repo),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo'),
              )
            : null;

        return LayoutBuilder(
          builder: (context, c) {
            if (c.maxWidth >= 840) {
              return Scaffold(
                floatingActionButton: fab,
                body: Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _tab,
                      onDestinationSelected: (i) => setState(() => _tab = i),
                      labelType: NavigationRailLabelType.all,
                      destinations: [
                        for (final d in _destinos)
                          NavigationRailDestination(
                            icon: Icon(d.icono),
                            selectedIcon: Icon(d.activo),
                            label: Text(d.texto),
                          ),
                      ],
                    ),
                    const VerticalDivider(width: 1, color: Colors.white10),
                    Expanded(child: cuerpo),
                  ],
                ),
              );
            }
            return Scaffold(
              floatingActionButton: fab,
              body: cuerpo,
              bottomNavigationBar: NavigationBar(
                selectedIndex: _tab,
                onDestinationSelected: (i) => setState(() => _tab = i),
                destinations: [
                  for (final d in _destinos)
                    NavigationDestination(
                      icon: Icon(d.icono),
                      selectedIcon: Icon(d.activo),
                      label: d.texto,
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
