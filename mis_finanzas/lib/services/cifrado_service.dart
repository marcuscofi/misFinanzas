import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class CifradoService {
  static const _prefijo = 'e2ee:v1:';
  static const _largoIv = 12;
  static const _llaveEntorno = String.fromEnvironment('E2EE_KEY');

  static String _llave = _llaveEntorno;

  static void configurarLlave(String llave) {
    _llave = llave;
  }

  static bool get configurado => _llave.trim().isNotEmpty;

  static void validarConfiguracion() {
    if (!configurado) {
      throw StateError(
        'Falta la variable de entorno E2EE_KEY. '
        'Compila con --dart-define-from-file=env.json',
      );
    }
  }

  static String cifrar(String texto) {
    if (texto.isEmpty) return texto;
    validarConfiguracion();
    final iv = enc.IV.fromSecureRandom(_largoIv);
    final cifrado = _crypter().encrypt(texto, iv: iv);
    return '$_prefijo${base64Encode([...iv.bytes, ...cifrado.bytes])}';
  }

  static String descifrar(String texto) {
    if (!texto.startsWith(_prefijo)) return texto;
    if (!configurado) return texto;
    try {
      final bytes = base64Decode(texto.substring(_prefijo.length));
      if (bytes.length <= _largoIv) return texto;
      final iv = enc.IV(bytes.sublist(0, _largoIv));
      final cuerpo = enc.Encrypted(Uint8List.fromList(bytes.sublist(_largoIv)));
      return _crypter().decrypt(cuerpo, iv: iv);
    } catch (_) {
      return texto;
    }
  }

  static enc.Encrypter _crypter() {
    final digest = sha256.convert(utf8.encode(_llave));
    final key = enc.Key(Uint8List.fromList(digest.bytes));
    return enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
  }
}
