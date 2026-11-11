import 'package:flutter/material.dart';

import '../models/transaccion.dart';
import '../services/transacciones_service.dart';
import '../utils/formato.dart';

Future<void> mostrarFormularioTransaccion(
  BuildContext context,
  TransaccionesService service,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _FormularioTransaccion(service: service),
  );
}

class _FormularioTransaccion extends StatefulWidget {
  const _FormularioTransaccion({required this.service});
  final TransaccionesService service;

  @override
  State<_FormularioTransaccion> createState() => _FormularioTransaccionState();
}

class _FormularioTransaccionState extends State<_FormularioTransaccion> {
  final _formKey = GlobalKey<FormState>();
  final _monto = TextEditingController();
  final _descripcion = TextEditingController();

  TipoTransaccion _tipo = TipoTransaccion.gasto;
  String _categoria = categoriasGasto.first;
  DateTime _fecha = DateTime.now();

  List<String> get _categorias => _tipo == TipoTransaccion.gasto
      ? categoriasGasto
      : categoriasIngreso;

  @override
  void dispose() {
    _monto.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final f = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(hoy.year - 5),
      lastDate: hoy,
    );
    if (f != null) setState(() => _fecha = f);
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final centavos = parseCentavos(_monto.text)!;

    // Sin await: offline el Future no se completa hasta sincronizar,
    // pero el stream ya muestra el movimiento localmente.
    widget.service.agregar(Transaccion(
      montoCentavos: centavos,
      tipo: _tipo,
      categoria: _categoria,
      descripcion: _descripcion.text.trim(),
      fecha: _fecha,
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: Theme.of(context).textTheme.headlineMedium,
                decoration: const InputDecoration(
                  prefixText: r'$ ',
                  hintText: '0.00',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final c = parseCentavos(v ?? '');
                  if (c == null) return 'Monto inválido';
                  if (c <= 0) return 'Debe ser mayor a 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final c in _categorias)
                    ChoiceChip(
                      label: Text(c),
                      selected: _categoria == c,
                      onSelected: (_) => setState(() => _categoria = c),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descripcion,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  border: OutlineInputBorder(),
                ),
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
                label: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}