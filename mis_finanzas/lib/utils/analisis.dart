import '../models/estado_mascota.dart';
import '../models/transaccion.dart';

DateTime _restarMeses(DateTime d, int m) {
  final total = d.year * 12 + (d.month - 1) - m;
  final y = total ~/ 12;
  final mes = total % 12 + 1;
  final ultimo = DateTime(y, mes + 1, 0).day;
  return DateTime(y, mes, d.day > ultimo ? ultimo : d.day);
}

int _dias(DateTime a, DateTime b) => DateTime.utc(
  b.year,
  b.month,
  b.day,
).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

/// Ventana de tiempo: N días o N meses hacia atrás desde hoy.
class Periodo {
  const Periodo.dias(this.dias) : meses = 0;
  const Periodo.meses(this.meses) : dias = 0;
  final int dias;
  final int meses;

  String get etiqueta {
    if (meses > 0) return meses == 1 ? '1 mes' : '$meses meses';
    return dias == 7 ? '1 sem' : (dias == 14 ? '2 sem' : '$dias días');
  }

  DateTime inicio(DateTime hoy) {
    if (meses > 0) {
      final r = _restarMeses(hoy, meses);
      return DateTime(r.year, r.month, r.day + 1);
    }
    return DateTime(hoy.year, hoy.month, hoy.day - (dias - 1));
  }

  DateTime inicioAnterior(DateTime inicio) => meses > 0
      ? _restarMeses(inicio, meses)
      : DateTime(inicio.year, inicio.month, inicio.day - dias);

  @override
  bool operator ==(Object other) =>
      other is Periodo && other.dias == dias && other.meses == meses;
  @override
  int get hashCode => Object.hash(dias, meses);
}

class ResumenPeriodo {
  const ResumenPeriodo({
    required this.inicio,
    required this.hoy,
    required this.gastos,
    required this.ingresos,
    required this.gastosPrevios,
    required this.serie,
    required this.seriePrev,
  });
  final DateTime inicio, hoy;
  final int gastos, ingresos, gastosPrevios;
  final List<int> serie, seriePrev;

  /// +0.25 = los gastos subieron 25 % frente al periodo anterior.
  double? get variacion =>
      gastosPrevios == 0 ? null : (gastos - gastosPrevios) / gastosPrevios;
}

ResumenPeriodo analizar(List<Transaccion> movs, Periodo p, DateTime ahora) {
  final hoy = DateTime(ahora.year, ahora.month, ahora.day);
  final finExcl = DateTime(hoy.year, hoy.month, hoy.day + 1);
  final inicio = p.inicio(hoy);
  final inicioPrev = p.inicioAnterior(inicio);
  final totalDias = _dias(inicio, finExcl);
  final bucket = totalDias <= 31 ? 1 : 7;
  final n = (totalDias / bucket).ceil();

  final serie = List<int>.filled(n, 0);
  final prev = List<int>.filled(n, 0);
  var gastos = 0, ingresos = 0, gastosPrev = 0;

  for (final t in movs) {
    final dia = DateTime(t.fecha.year, t.fecha.month, t.fecha.day);
    final enActual = !dia.isBefore(inicio) && dia.isBefore(finExcl);
    final enPrev = !dia.isBefore(inicioPrev) && dia.isBefore(inicio);
    if (enActual) {
      if (t.tipo == TipoTransaccion.gasto) {
        gastos += t.montoCentavos;
        serie[_dias(inicio, dia) ~/ bucket] += t.montoCentavos;
      } else {
        ingresos += t.montoCentavos;
      }
    } else if (enPrev && t.tipo == TipoTransaccion.gasto) {
      gastosPrev += t.montoCentavos;
      final i = _dias(inicioPrev, dia) ~/ bucket;
      if (i < n) prev[i] += t.montoCentavos;
    }
  }

  return ResumenPeriodo(
    inicio: inicio,
    hoy: hoy,
    gastos: gastos,
    ingresos: ingresos,
    gastosPrevios: gastosPrev,
    serie: serie,
    seriePrev: prev,
  );
}

enum Tono { positivo, neutro, alerta }

class Lectura {
  const Lectura(this.estado, this.mensaje, this.tono);
  final EstadoMascota estado;
  final String mensaje;
  final Tono tono;
}

/// Qué cara pone el cerdito según el periodo seleccionado.
Lectura evaluarMascota({
  required int balance,
  required ResumenPeriodo r,
  required bool hayDatos,
}) {
  if (!hayDatos) {
    return const Lectura(
      EstadoMascota.escritorio,
      'Registra tu primer movimiento y arrancamos.',
      Tono.neutro,
    );
  }
  if (balance < 0) {
    return const Lectura(
      EstadoMascota.panico,
      'Tu balance está en negativo. ¡Hay que frenar!',
      Tono.alerta,
    );
  }
  final v = r.variacion;
  if (r.ingresos > 0 && r.gastos > r.ingresos) {
    return const Lectura(
      EstadoMascota.sudando,
      'Gastaste más de lo que ingresó en este periodo.',
      Tono.alerta,
    );
  }
  if (v != null && v > 0.25) {
    return Lectura(
      EstadoMascota.preocupado,
      'Tus gastos subieron ${(v * 100).round()} % frente al periodo anterior.',
      Tono.alerta,
    );
  }
  if (r.ingresos > 0) {
    final tasa = (r.ingresos - r.gastos) / r.ingresos;
    if (tasa >= 0.5) {
      return const Lectura(
        EstadoMascota.celebra,
        'Ahorras más de la mitad de lo que ganas. ¡Brutal!',
        Tono.positivo,
      );
    }
    if (tasa >= 0.3) {
      return const Lectura(
        EstadoMascota.meta,
        'Vas rumbo a tu meta de ahorro.',
        Tono.positivo,
      );
    }
  }
  if (v != null && v <= -0.10) {
    return Lectura(
      EstadoMascota.ahorro,
      'Tus gastos bajaron ${(-v * 100).round()} %. Buen control.',
      Tono.positivo,
    );
  }
  if (r.ingresos > r.gastos) {
    return const Lectura(
      EstadoMascota.hucha,
      'Tus ingresos van por encima de tus gastos.',
      Tono.positivo,
    );
  }
  return const Lectura(
    EstadoMascota.escritorio,
    'Todo bajo control. Sigo supervisando.',
    Tono.neutro,
  );
}

/// Reacción en vivo mientras se escribe el monto en el formulario.
Lectura reaccionAlMonto({
  required TipoTransaccion tipo,
  required int centavos,
  required int balance,
}) {
  if (tipo == TipoTransaccion.ingreso) {
    if (centavos > 0 && balance > 0 && centavos >= balance * 0.5) {
      return const Lectura(
        EstadoMascota.celebra,
        '¡Entrada grande!',
        Tono.positivo,
      );
    }
    return const Lectura(
      EstadoMascota.bolsa,
      'Entra dinero. ¡Buen movimiento!',
      Tono.positivo,
    );
  }
  if (centavos == 0) {
    return const Lectura(
      EstadoMascota.escritorio,
      'Anota el gasto, yo superviso.',
      Tono.neutro,
    );
  }
  if (balance <= 0 || centavos > balance) {
    return const Lectura(
      EstadoMascota.panico,
      '¡Eso supera tu balance!',
      Tono.alerta,
    );
  }
  if (centavos >= balance * 0.3) {
    return const Lectura(
      EstadoMascota.sudando,
      'Salida fuerte… ¿seguro?',
      Tono.alerta,
    );
  }
  if (centavos >= balance * 0.1) {
    return const Lectura(
      EstadoMascota.preocupado,
      'Es un gasto considerable.',
      Tono.alerta,
    );
  }
  return const Lectura(
    EstadoMascota.escritorio,
    'Gasto controlado.',
    Tono.neutro,
  );
}
