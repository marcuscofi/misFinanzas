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
