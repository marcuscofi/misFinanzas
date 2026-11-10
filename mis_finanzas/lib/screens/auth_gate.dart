import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'dashboard_page.dart';
import 'login_page.dart';

/// Decide qué pantalla mostrar según el estado de la sesión.
/// En web, Firebase Auth conserva la sesión (persistencia local) por defecto.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snapshot.data;
        if (user == null) return const LoginPage();
        // La key fuerza a recrear el dashboard si cambia el usuario.
        return DashboardPage(key: ValueKey(user.uid), user: user);
      },
    );
  }
}