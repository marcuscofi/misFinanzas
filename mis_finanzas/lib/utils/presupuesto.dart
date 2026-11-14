// lib/utils/presupuesto.dart
import 'dart:math' as math;

import '../models/cuenta_bancaria.dart';
import '../models/plan_ahorro.dart';
import '../models/tarjeta.dart';
import '../models/transaccion.dart';

DateTime _dia(DateTime d) => DateTime(d.year, d.month, d.day);

int calcularBalanceEfectivo(List<Transaccion> movs) => movs
    .where((t) => t.afectaEfectivo)
    .fold(0, (a, t) => a + t.centavosConSigno);

int calcularSaldoCuenta(List<Transaccion> movs, String cuentaId) => movs
    .where((t) => t.cuentaId == cuentaId)
    .fold(0, (a, t) => a + t.centavosConSigno);

int calcularLiquidoTotal(
  List<Transaccion> movs,
  List<CuentaBancaria> cuentas,
) =>
    calcularBalanceEfectivo(movs) +
    cuentas.fold(0, (a, c) => a + calcularSaldoCuenta(movs, c.id));

class EstadoTarjeta {
  const EstadoTarjeta(this.tarjeta, this.gastadoMes);
  final Tarjeta tarjeta;
  final int gastadoMes;

  int get limite => tarjeta.limiteMensualCentavos;
  int get restante => limite - gastadoMes;
  double get uso =>
      limite <= 0 ? (gastadoMes > 0 ? 1 : 0) : gastadoMes / limite;
}

List<EstadoTarjeta> estadoTarjetas(
  List<Transaccion> movs,
  List<Tarjeta> tarjetas,
  DateTime ahora,
) {
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
  final meses = (fin.year * 12 + fin.month) - (ini.year * 12 + ini.month) + 1;
  return meses < 0 ? 0 : meses * p.valor;
}

class PresupuestoSemanal {
  const PresupuestoSemanal({
    required this.inicio,
    required this.fin,
    required this.disponible,
    required this.gastado,
    required this.asignacionOptimista,
    required this.asignacionPesimista,
    required this.semanasRestantesEnteras,
    required this.semanasExactas,
    required this.diasRestantesEnMes,
    required this.efectivoLibre,
    required this.cuentasRestante,
    required this.tarjetasRestante,
    required this.ahorroApartado,
  });
  final DateTime inicio, fin;
  final int disponible, gastado;
  final int asignacionOptimista, asignacionPesimista;
  final int semanasRestantesEnteras, diasRestantesEnMes;
  final double semanasExactas;
  final int efectivoLibre, cuentasRestante, tarjetasRestante, ahorroApartado;

  int get quedanOptimista => asignacionOptimista - gastado;
  int get quedanPesimista => asignacionPesimista - gastado;

  // El monto principal para gastar usa el escenario OPTIMISTA
  int get quedan => quedanOptimista;
  int get asignacion => asignacionOptimista;
  int get semanasRestantes => semanasRestantesEnteras;

  double get progreso => asignacionOptimista <= 0
      ? (gastado > 0 ? 1.0 : 0.0)
      : (gastado / asignacionOptimista).clamp(0.0, 1.0).toDouble();
}

PresupuestoSemanal calcularSemana({
  required List<Transaccion> movs,
  required List<Tarjeta> tarjetas,
  required List<PlanAhorro> planes,
  required DateTime ahora,
  List<CuentaBancaria> cuentasBancarias = const [],
}) {
  final hoy = _dia(ahora);
  final inicio = DateTime(hoy.year, hoy.month, hoy.day - (hoy.weekday - 1));
  final fin = DateTime(inicio.year, inicio.month, inicio.day + 6);
  final inicioMes = DateTime(hoy.year, hoy.month);
  final finMes = DateTime(hoy.year, hoy.month + 1);
  
  final ultimoDiaMes = DateTime(hoy.year, hoy.month + 1, 0).day;
  final diasRestantesEnMes = math.max(0, ultimoDiaMes - hoy.day);
  final semanasRestantesEnteras = math.max(1, (diasRestantesEnMes / 7).floor());
  final semanasExactas = math.max(1.0, diasRestantesEnMes / 7.0);
  final idsTarjetas = {for (final t in tarjetas) t.id};
  final idsCuentas = {for (final c in cuentasBancarias) c.id};

  final efectivo = calcularBalanceEfectivo(movs);
  final cuentasSaldo = cuentasBancarias.fold<int>(
    0,
    (a, c) => a + calcularSaldoCuenta(movs, c.id),
  );
  final ahorro = planes.fold<int>(0, (a, p) => a + ahorroPlan(p, movs, ahora));
  final tarjetasRestante = estadoTarjetas(
    movs,
    tarjetas,
    ahora,
  ).fold<int>(0, (a, e) => a + e.restante);

  var gastado = 0;
  for (final t in movs) {
    if (t.tipo != TipoTransaccion.gasto) continue;
    final d = _dia(t.fecha);
    if (d.isBefore(inicio) || d.isAfter(fin)) continue;
    final enMes = !d.isBefore(inicioMes) && d.isBefore(finMes);
    if (t.afectaEfectivo ||
        idsCuentas.contains(t.cuentaId) ||
        (idsTarjetas.contains(t.cuentaId) && enMes)) {
      gastado += t.montoCentavos;
    }
  }

  // CORRECCIÓN: El disponible real excluye las líneas de crédito (tarjetasRestante)
  // para evitar inflar artificialmente el dinero de bolsillo con deuda.
  final disponible = efectivo + cuentasSaldo - ahorro;
  final baseSemanal = math.max(0, disponible + gastado);
  
  final asignacionOptimista = baseSemanal ~/ semanasRestantesEnteras;
  final asignacionPesimista = (baseSemanal / semanasExactas).floor();

  return PresupuestoSemanal(
    inicio: inicio,
    fin: fin,
    disponible: disponible,
    gastado: gastado,
    asignacionOptimista: asignacionOptimista,
    asignacionPesimista: asignacionPesimista,
    semanasRestantesEnteras: semanasRestantesEnteras,
    semanasExactas: semanasExactas,
    diasRestantesEnMes: diasRestantesEnMes,
    efectivoLibre: efectivo - ahorro,
    cuentasRestante: cuentasSaldo,
    tarjetasRestante: tarjetasRestante,
    ahorroApartado: ahorro,
  );
}