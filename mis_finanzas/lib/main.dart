import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'dart:ui' show PointerDeviceKind;

import 'config/firebase_config.dart';
import 'screens/auth_gate.dart';
import 'services/cifrado_service.dart';
import 'theme/tema.dart';

class _ScrollWeb extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    FirebaseConfig.validar();
    CifradoService.validarConfiguracion();

    await Firebase.initializeApp(options: FirebaseConfig.options);

    // Debe ejecutarse antes de cualquier otra operación con Firestore.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    await initializeDateFormatting('es');

    runApp(const MyApp());
  } catch (error) {
    runApp(_ErrorArranqueApp(error: '$error'));
  }
}

/// Evita la pantalla negra cuando falta configuración en el despliegue.
class _ErrorArranqueApp extends StatelessWidget {
  const _ErrorArranqueApp({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mis Finanzas',
      debugShowCheckedModeBanner: false,
      theme: construirTema(),
      themeMode: ThemeMode.dark,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.settings_suggest, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'No se pudo iniciar Mis Finanzas',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Text(error, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                const Text(
                  'Revisa las variables de entorno del despliegue '
                  '(FIREBASE_* y E2EE_KEY).',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mis Finanzas',
      debugShowCheckedModeBanner: false,
      scrollBehavior: _ScrollWeb(),
      theme: construirTema(),
      themeMode: ThemeMode.dark,
      home: const AuthGate(),
    );
  }
}
