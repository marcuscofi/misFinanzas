import 'package:flutter/material.dart';
import '../models/transaccion.dart';
import '../services/transacciones_service.dart';
import '../utils/analisis.dart';
import '../utils/formato.dart';
import 'mascota.dart';

Future<void> mostrarFormularioTransaccion(
  BuildContext context,
  TransaccionesService service, {
  required int balanceCentavos,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 520),
    builder: (_) => _Formulario(service: service, balance: balanceCentavos),
  );
}

class _Formulario extends StatefulWidget {
  const _Formulario({required this.service, required this.balance});
  final TransaccionesService service;
  final int balance;

  @override
  State<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends State<_Formulario> {
  final _formKey = GlobalKey<FormState>();
  final _monto = TextEditingController();
  final _descripcion = TextEditingController();
  TipoTransaccion _tipo = TipoTransaccion.gasto;
  String _categoria = categoriasGasto.first;
  DateTime _fecha = DateTime.now();

  List<String> get _categorias =>
      _tipo == TipoTransaccion.gasto ? categoriasGasto : categoriasIngreso;

  @override
  void initState() {
    super.initState();
    _monto.addListener(() => setState(() {})); // la mascota reacciona al escribir
  }

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
    widget.service.agregar(Transaccion(
      montoCentavos: parseCentavos(_monto.text)!,
      tipo: _tipo,
      categoria: _categoria,
      descripcion: _descripcion.text.trim(),
      fecha: _fecha,
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final lectura = reaccionAlMonto(
      tipo: _tipo,
      centavos: parseCentavos(_monto.text) ?? 0,
      balance: widget.balance,
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
                Expanded(
                    child: Text(lectura.mensaje, style: tema.textTheme.bodyLarge)),
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
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _descripcion,
                textCapitalization: TextCapitalization.sentences,
                decoration:
                    const InputDecoration(labelText: 'Descripción (opcional)'),
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