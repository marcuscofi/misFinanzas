import 'dart:math' as math;

import '../models/plan_ahorro.dart';
import '../models/tarjeta.dart';
import '../models/transaccion.dart';

DateTime _dia(DateTime d) => DateTime(d.year, d.month, d.day);

/// Efectivo real: ingresos − gastos hechos en efectivo (los de tarjeta no cuentan).
int calcularBalanceEfectivo(List<Transaccion> movs) => movs
    .where((t) => t.afectaEfectivo)
    .fold(0, (a, t) => a + t.centavosConSigno);

class EstadoTarjeta {
  const EstadoTarjeta(this.tarjeta, this.gastadoMes);
  final Tarjeta tarjeta;
  final int gastadoMes;

  int get limite => tarjeta.limiteMensualCentavos;
  int get restante => limite - gastadoMes;
  double get uso => limite <= 0 ? (gastadoMes > 0 ? 1 : 0) : gastadoMes / limite;
}

/// Gasto de cada tarjeta SOLO en el mes calendario actual (se reinicia el día 1).
List<EstadoTarjeta> estadoTarjetas(
    List<Transaccion> movs, List<Tarjeta> tarjetas, DateTime ahora) {
  final ini = DateTime(ahora.year, ahora.month);
  final fin = DateTime(ahora.year, ahora.month + 1);
  final porTarjeta = <String, int>{};
  for (final t in movs) {
    if (t.tipo != TipoTransaccion.gasto || t.afectaEfectivo) continue;
    if (t.fecha.isBefore(ini) || !t.fecha.isBefore(fin)) continue;
    porTarjeta[t.cuentaId] = (porTarjeta[t.cuentaId] ?? 0) + t.montoCentavos;
  }
  return [for (final c in tarjetas) EstadoTarjeta(c, porTarjeta[c.id] ?? 0)];
}

/// Lo acumulado por un plan desde [PlanAhorro.desde] hasta hoy (o hasta que se detuvo).
int ahorroPlan(PlanAhorro p, List<Transaccion> movs, DateTime ahora) {
  final fin = _dia(p.hasta ?? ahora);
  final ini = _dia(p.desde);
  if (p.regla == ReglaAhorro.porcentaje) {
    var base = 0;
    for (final t in movs) {
      if (t.tipo != TipoTransaccion.ingreso) continue;
      final d = _dia(t.fecha);
      if (d.isBefore(ini) || d.isAfter(fin)) continue;
      base += t.montoCentavos;
    }
    return (base * p.valor + 50) ~/ 100;
  }
  // Monto fijo: se aparta al inicio de cada mes, incluido el mes de creación.
  final meses = (fin.year * 12 + fin.month) - (ini.year * 12 + ini.month) + 1;
  return meses < 0 ? 0 : meses * p.valor;
}

class PresupuestoSemanal {
  const PresupuestoSemanal({
    required this.inicio,
    required this.fin,
    required this.disponible,
    required this.gastado,
    required this.asignacion,
    required this.semanasRestantes,
    required this.efectivoLibre,
    required this.tarjetasRestante,
    required this.ahorroApartado,
  });
  final DateTime inicio, fin; // lunes a domingo
  final int disponible, gastado, asignacion, semanasRestantes;
  final int efectivoLibre, tarjetasRestante, ahorroApartado;

  /// Lo que aún puedes gastar esta semana (negativo = te pasaste).
  int get quedan => asignacion - gastado;
  double get progreso => asignacion <= 0
      ? (gastado > 0 ? 1.0 : 0.0)
      : (gastado / asignacion).clamp(0.0, 1.0).toDouble();
}

PresupuestoSemanal calcularSemana({
  required List<Transaccion> movs,
  required List<Tarjeta> tarjetas, // solo activas
  required List<PlanAhorro> planes,
  required DateTime ahora,
}) {
  final hoy = _dia(ahora);
  final inicio = DateTime(hoy.year, hoy.month, hoy.day - (hoy.weekday - 1));
  final fin = DateTime(inicio.year, inicio.month, inicio.day + 6);
  final inicioMes = DateTime(hoy.year, hoy.month);
  final finMes = DateTime(hoy.year, hoy.month + 1);
  final ids = {for (final t in tarjetas) t.id};

  final efectivo = calcularBalanceEfectivo(movs);
  final ahorro = planes.fold<int>(0, (a, p) => a + ahorroPlan(p, movs, ahora));
  final tarjetasRestante = estadoTarjetas(movs, tarjetas, ahora)
      .fold<int>(0, (a, e) => a + e.restante);

  // Gasto de la semana que ya está descontado del disponible actual.
  var gastado = 0;
  for (final t in movs) {
    if (t.tipo != TipoTransaccion.gasto) continue;
    final d = _dia(t.fecha);
    if (d.isBefore(inicio) || d.isAfter(fin)) continue;
    final enMes = !d.isBefore(inicioMes) && d.isBefore(finMes);
    if (t.afectaEfectivo || (ids.contains(t.cuentaId) && enMes)) {
      gastado += t.montoCentavos;
    }
  }

  // Semana actual + lunes que aún caen dentro del mes.
  var semanas = 1;
  for (var d = DateTime(hoy.year, hoy.month, hoy.day + 1);
      d.isBefore(finMes);
      d = DateTime(d.year, d.month, d.day + 1)) {
    if (d.weekday == DateTime.monday) semanas++;
  }

  final disponible = efectivo - ahorro + tarjetasRestante;
  final asignacion = math.max(0, (disponible + gastado) ~/ semanas);

  return PresupuestoSemanal(
    inicio: inicio,
    fin: fin,
    disponible: disponible,
    gastado: gastado,
    asignacion: asignacion,
    semanasRestantes: semanas,
    efectivoLibre: efectivo - ahorro,
    tarjetasRestante: tarjetasRestante,
    ahorroApartado: ahorro,
  );
}