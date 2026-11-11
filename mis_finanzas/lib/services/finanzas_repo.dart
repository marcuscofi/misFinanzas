import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/cuenta_bancaria.dart';
import '../models/plan_ahorro.dart';
import '../models/tarjeta.dart';
import '../models/transaccion.dart';
import '../utils/presupuesto.dart';
import 'cuentas_service.dart';
import 'planes_service.dart';
import 'tarjetas_service.dart';
import 'transacciones_service.dart';

class FinanzasRepo extends ChangeNotifier {
  FinanzasRepo(String uid)
      : transacciones = TransaccionesService(uid),
        tarjetasSvc = TarjetasService(uid),
        cuentasSvc = CuentasBancariasService(uid),
        planesSvc = PlanesService(uid) {
    _subs = [
      transacciones.observar().listen((v) {
        _lote = v;
        notifyListeners();
      }, onError: _fallo),
      tarjetasSvc.observar().listen((v) {
        _tarjetas = v;
        notifyListeners();
      }, onError: _fallo),
      cuentasSvc.snapshots().listen((v) {
        _cuentas = v;
        notifyListeners();
      }, onError: _fallo),
      planesSvc.observar().listen((v) {
        _planes = v;
        notifyListeners();
      }, onError: _fallo),
    ];
  }

  final TransaccionesService transacciones;
  final TarjetasService tarjetasSvc;
  final CuentasBancariasService cuentasSvc;
  final PlanesService planesSvc;
  late final List<StreamSubscription<dynamic>> _subs;

  LoteTransacciones? _lote;
  List<Tarjeta>? _tarjetas;
  List<CuentaBancaria>? _cuentas;
  List<PlanAhorro>? _planes;
  Object? error;

  void _fallo(Object e) {
    error = e;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  bool get listo =>
      _lote != null && _tarjetas != null && _cuentas != null && _planes != null;
  LoteTransacciones get lote => _lote!;
  List<PlanAhorro> get planes => _planes!;
  List<Tarjeta> get tarjetas => _tarjetas!.where((t) => t.activa).toList();
  List<Tarjeta> get archivadas => _tarjetas!.where((t) => !t.activa).toList();
  List<CuentaBancaria> get cuentas =>
      _cuentas!.where((c) => c.activa).toList();
  List<CuentaBancaria> get cuentasArchivadas =>
      _cuentas!.where((c) => !c.activa).toList();

  // ---- Derivados (datos chicos: se recalculan al leerlos) ----
  int get balanceEfectivo => calcularBalanceEfectivo(lote.items);
  int saldoCuenta(String id) => calcularSaldoCuenta(lote.items, id);
  int get saldoCuentas => cuentas.fold(0, (a, c) => a + saldoCuenta(c.id));
  int get liquidoTotal => calcularLiquidoTotal(lote.items, cuentas);
  List<EstadoTarjeta> get estadosTarjetas =>
      estadoTarjetas(lote.items, tarjetas, DateTime.now());
  int restanteTarjeta(String id) =>
      estadosTarjetas.where((e) => e.tarjeta.id == id).map((e) => e.restante).firstOrNull ?? 0;
  int ahorroDe(PlanAhorro p) => ahorroPlan(p, lote.items, DateTime.now());
  int get ahorroTotal => planes.fold(0, (a, p) => a + ahorroDe(p));
  PresupuestoSemanal get semana => calcularSemana(
      movs: lote.items,
      tarjetas: tarjetas,
      planes: planes,
      ahora: DateTime.now(),
      cuentasBancarias: cuentas);

  bool esCuentaBancaria(String id) => _cuentas!.any((c) => c.id == id);
  bool esTarjetaCredito(String id) => _tarjetas!.any((t) => t.id == id);

  String nombreCuenta(String id) {
    if (id == cuentaEfectivo) return 'Efectivo';
    final tarjeta = _tarjetas!.where((t) => t.id == id).firstOrNull;
    if (tarjeta != null) return tarjeta.nombre;
    final cuenta = _cuentas!.where((c) => c.id == id).firstOrNull;
    if (cuenta != null) {
      final alias = cuenta.alias.trim();
      return alias.isEmpty ? cuenta.banco : '${cuenta.banco} · $alias';
    }
    return 'Cuenta eliminada';
  }
}