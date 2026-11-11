import 'package:flutter/material.dart';

import '../models/transaccion.dart';
import '../services/finanzas_repo.dart';
import '../utils/analisis.dart';
import '../utils/formato.dart';
import 'mascota.dart';

/// Con [inicial] abre en modo edición.
Future<void> mostrarFormularioTransaccion(
  BuildContext context,
  FinanzasRepo repo, {
  Transaccion? inicial,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 520),
    builder: (_) => _Formulario(repo: repo, inicial: inicial),
  );
}

class _Formulario extends StatefulWidget {
  const _Formulario({required this.repo, this.inicial});
  final FinanzasRepo repo;
  final Transaccion? inicial;
  @override
  State<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends State<_Formulario> {
  final _formKey = GlobalKey<FormState>();
  late final _monto = TextEditingController(
      text: widget.inicial == null
          ? ''
          : (widget.inicial!.montoCentavos / 100).toStringAsFixed(2));
  late final _descripcion =
      TextEditingController(text: widget.inicial?.descripcion ?? '');
  late TipoTransaccion _tipo = widget.inicial?.tipo ?? TipoTransaccion.gasto;
  late String _categoria = widget.inicial?.categoria ??
      (_tipo == TipoTransaccion.gasto ? categoriasGasto.first : categoriasIngreso.first);
  late String _cuentaId = widget.inicial?.cuentaId ?? cuentaEfectivo;
  late DateTime _fecha = widget.inicial?.fecha ?? DateTime.now();

  bool get _editando => widget.inicial != null;

  List<String> get _categorias {
    final base = _tipo == TipoTransaccion.gasto ? categoriasGasto : categoriasIngreso;
    return base.contains(_categoria) ? base : [...base, _categoria];
  }

  List<(String, String)> get _cuentas {
    final l = [
      (cuentaEfectivo, 'Efectivo'),
      for (final t in widget.repo.tarjetas) (t.id, t.nombre),
    ];
    if (!l.any((c) => c.$1 == _cuentaId)) {
      l.add((_cuentaId, widget.repo.nombreCuenta(_cuentaId)));
    }
    return l;
  }

  @override
  void initState() {
    super.initState();
    _monto.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _monto.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  /// Contra qué se compara el monto para la reacción de la mascota.
  int _referencia() {
    final repo = widget.repo;
    var ref = _cuentaId == cuentaEfectivo
        ? repo.balanceEfectivo
        : repo.restanteTarjeta(_cuentaId);
    final o = widget.inicial;
    if (o != null && o.tipo == TipoTransaccion.gasto && o.cuentaId == _cuentaId) {
      ref += o.montoCentavos; // al editar, el gasto original ya estaba descontado
    }
    return ref;
  }

  String _pista() {
    final repo = widget.repo;
    if (_cuentaId == cuentaEfectivo) {
      return 'Efectivo libre: ${formatoUsd(repo.balanceEfectivo - repo.ahorroTotal)}';
    }
    return 'Restante en esta tarjeta este mes: ${formatoUsd(repo.restanteTarjeta(_cuentaId))}';
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final minimo = DateTime(hoy.year - 5);
    final f = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: minimo.isBefore(_fecha) ? minimo : _fecha,
      lastDate: hoy.isAfter(_fecha) ? hoy : _fecha,
    );
    if (f != null) setState(() => _fecha = f);
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final base = widget.inicial;
    final t = Transaccion(
      id: base?.id ?? '',
      montoCentavos: parseCentavos(_monto.text)!,
      tipo: _tipo,
      categoria: _categoria,
      descripcion: _descripcion.text.trim(),
      fecha: _fecha,
      cuentaId: _tipo == TipoTransaccion.ingreso ? cuentaEfectivo : _cuentaId,
    );
    // Sin await: offline el Future no se completa, pero el stream ya refleja el cambio.
    if (base == null) {
      widget.repo.transacciones.agregar(t);
    } else {
      widget.repo.transacciones.actualizar(t);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final lectura = reaccionAlMonto(
      tipo: _tipo,
      centavos: parseCentavos(_monto.text) ?? 0,
      balance: _referencia(),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Mascota(lectura.estado, tamano: 84),
                const SizedBox(width: 12),
                Expanded(child: Text(lectura.mensaje, style: tema.textTheme.bodyLarge)),
              ]),
              const SizedBox(height: 12),
              SegmentedButton<TipoTransaccion>(
                segments: const [
                  ButtonSegment(
                      value: TipoTransaccion.gasto,
                      label: Text('Gasto'),
                      icon: Icon(Icons.arrow_upward)),
                  ButtonSegment(
                      value: TipoTransaccion.ingreso,
                      label: Text('Ingreso'),
                      icon: Icon(Icons.arrow_downward)),
                ],
                selected: {_tipo},
                onSelectionChanged: (s) => setState(() {
                  _tipo = s.first;
                  _categoria = _categorias.first;
                }),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _monto,
                autofocus: !_editando,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: tema.textTheme.headlineMedium,
                decoration: const InputDecoration(prefixText: r'$ ', hintText: '0.00'),
                validator: (v) {
                  final c = parseCentavos(v ?? '');
                  if (c == null) return 'Monto inválido';
                  if (c <= 0) return 'Debe ser mayor a 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Wrap(spacing: 8, runSpacing: 4, children: [
                for (final c in _categorias)
                  ChoiceChip(
                    label: Text(c),
                    selected: _categoria == c,
                    onSelected: (_) => setState(() => _categoria = c),
                  ),
              ]),
              if (_tipo == TipoTransaccion.gasto) ...[
                const SizedBox(height: 16),
                Text('Pagar con',
                    style: tema.textTheme.labelLarge
                        ?.copyWith(color: tema.colorScheme.outline)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 4, children: [
                  for (final (id, nombre) in _cuentas)
                    ChoiceChip(
                      avatar: Icon(
                          id == cuentaEfectivo ? Icons.payments_outlined : Icons.credit_card,
                          size: 16),
                      label: Text(nombre),
                      selected: _cuentaId == id,
                      onSelected: (_) => setState(() => _cuentaId = id),
                    ),
                ]),
                const SizedBox(height: 6),
                Text(_pista(),
                    style: tema.textTheme.bodySmall
                        ?.copyWith(color: tema.colorScheme.outline)),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _descripcion,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _elegirFecha,
                icon: const Icon(Icons.calendar_today),
                label: Text(fechaCorta(_fecha)),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _guardar,
                icon: const Icon(Icons.check),
                label: Text(_editando ? 'Guardar cambios' : 'Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}