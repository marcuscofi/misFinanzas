import 'package:intl/intl.dart';

final _usd = NumberFormat.currency(locale: 'en_US', symbol: r'$');

/// Formatea centavos como USD: 1250 -> $12.50, -500 -> -$5.00
String formatoUsd(int centavos) => _usd.format(centavos / 100);

final _fechaLarga = DateFormat("EEEE d 'de' MMMM", 'es');
final _fechaCorta = DateFormat('d MMM yyyy', 'es');
final _fechaMuyCorta = DateFormat('d MMM', 'es');

String fechaLarga(DateTime d) {
  final s = _fechaLarga.format(d);
  return s[0].toUpperCase() + s.substring(1);
}

String fechaCorta(DateTime d) => _fechaCorta.format(d);

String fechaMuyCorta(DateTime d) => _fechaMuyCorta.format(d);

/// Convierte "12.5" o "12,50" a centavos. Devuelve null si no es válido.
int? parseCentavos(String texto) {
  final limpio = texto.trim().replaceAll(',', '.');
  if (!RegExp(r'^\d+(\.\d{0,2})?$').hasMatch(limpio)) return null;
  final valor = double.tryParse(limpio);
  if (valor == null) return null;
  return (valor * 100).round();
}