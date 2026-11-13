import 'package:firebase_core/firebase_core.dart';

/// Los valores se inyectan en compilación con --dart-define.
/// Nunca se escriben en el código.
class FirebaseConfig {
  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const _senderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const _storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );

  static const options = FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: _senderId,
    projectId: _projectId,
    authDomain: _authDomain,
    storageBucket: _storageBucket,
  );

  /// Falla con un mensaje claro si falta alguna variable.
  static void validar() {
    const requeridas = {
      'FIREBASE_API_KEY': _apiKey,
      'FIREBASE_APP_ID': _appId,
      'FIREBASE_MESSAGING_SENDER_ID': _senderId,
      'FIREBASE_PROJECT_ID': _projectId,
      'FIREBASE_AUTH_DOMAIN': _authDomain,
      'FIREBASE_STORAGE_BUCKET': _storageBucket,
    };
    final faltan = requeridas.entries
        .where((e) => e.value.isEmpty)
        .map((e) => e.key);
    if (faltan.isNotEmpty) {
      throw StateError(
        'Faltan variables de entorno: ${faltan.join(', ')}. '
        'Compila con --dart-define-from-file=env.json',
      );
    }
  }
}
