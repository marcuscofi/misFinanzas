import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// Importaremos las opciones generadas automáticamente o las pasaremos por parámetros

void main() async {
  // Asegura que los bindings de Flutter estén listos
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa Firebase para Web/Móvil
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAYtRAd7VgUM0L2RryxP68twNXtzMVcc0s",
      authDomain: "misgastos-1291c.firebaseapp.com",
      databaseURL: "https://misgastos-1291c-default-rtdb.firebaseio.com",
      projectId: "misgastos-1291c",
      storageBucket: "misgastos-1291c.firebasestorage.app",
      messagingSenderId: "70807927015",
      appId: "1:70807927015:web:1069556e1e09de5bc50a42",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mis Finanzas',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const Scaffold(
        body: Center(
          child: Text('¡Firebase conectado en Flutter con éxito!'),
        ),
      ),
    );
  }
}
