import 'package:flutter/material.dart';

import '../models/plan_ahorro.dart';
import '../services/planes_service.dart';
import '../utils/formato.dart';

Future<void> mostrarFormularioPlan(
  BuildContext context,
  PlanesService svc, {
  PlanAhorro? inicial,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 520),
    builder: (_) => _FormPlan(svc: svc, inicial: inicial),
  );
}

class _FormPlan extends StatefulWidget {
  const _FormPlan({required this.svc, this.inicial});
  final PlanesService svc;
  final PlanAhorro? inicial;
  @override
  State<_FormPlan> createState() => _FormPlanState();
}

class _FormPlanState extends State<_FormPlan> {
  final _formKey = GlobalKey<FormState>();
  late ReglaAhorro _regla = widget.inicial?.regla ?? ReglaAhorro.porcentaje;
  late final _nombre = TextEditingController(
    text: widget.inicial?.nombre ?? '',
  );
  late final _valor = TextEditingController(text: _valorInicial());
  late final _objetivo = TextEditingController(
    text: widget.inicial?.objetivoCentavos == null
        ? ''
        : (widget.inicial!.objetivoCentavos! / 100).toStringAsFixed(2),
  );

  bool get _editando => widget.inicial != null;

  String _valorInicial() {
    final p = widget.inicial;
    if (p == null) return '';
    return p.regla == ReglaAhorro.porcentaje
        ? '${p.valor}'
        : (p.valor / 100).toStringAsFixed(2);
  }

  @override
  void dispose() {
    _nombre.dispose();
    _valor.dispose();
    _objetivo.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final base = widget.inicial;
    final ahora = DateTime.now();
    final valor = _editando
        ? base!.valor
        : (_regla == ReglaAhorro.porcentaje
              ? int.parse(_valor.text.trim())
              : parseCentavos(_valor.text)!);
    widget.svc.guardar(
      PlanAhorro(
        id: base?.id ?? '',
        nombre: _nombre.text.trim(),
        regla: _regla,
        valor: valor,
        objetivoCentavos: _objetivo.text.trim().isEmpty
            ? null
            : parseCentavos(_objetivo.text),
        desde: base?.desde ?? DateTime(ahora.year, ahora.month, 1),
        hasta: base?.hasta,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final porcentaje = _regla == ReglaAhorro.porcentaje;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _editando ? 'Editar plan' : 'Nuevo plan de ahorro',
                style: tema.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombre,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej. Viaje, Emergencias',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ponle un nombre'
                    : (v.trim().length > 60 ? 'Máximo 60 caracteres' : null),
              ),
              const SizedBox(height: 16),
              SegmentedButton<ReglaAhorro>(
                segments: const [
                  ButtonSegment(
                    value: ReglaAhorro.porcentaje,
                    label: Text('% de ingresos'),
                    icon: Icon(Icons.percent),
                  ),
                  ButtonSegment(
                    value: ReglaAhorro.montoFijo,
                    label: Text('Monto fijo'),
                    icon: Icon(Icons.attach_money),
                  ),
                ],
                selected: {_regla},
                onSelectionChanged: _editando
                    ? null
                    : (s) => setState(() {
                        _regla = s.first;
                        _valor.clear();
                      }),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _valor,
                enabled: !_editando,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: porcentaje
                      ? 'Porcentaje de cada ingreso'
                      : 'Monto por mes',
                  prefixText: porcentaje ? null : r'$ ',
                  suffixText: porcentaje ? '%' : null,
                  helperText: _editando
                      ? 'La regla no se edita. Detén el plan y crea otro para cambiarla.'
                      : (porcentaje
                            ? 'Se aparta de cada ingreso desde el 1 de este mes.'
                            : 'Se aparta al inicio de cada mes, incluido este.'),
                  helperMaxLines: 2,
                ),
                validator: (v) {
                  if (_editando) return null;
                  if (porcentaje) {
                    final n = int.tryParse((v ?? '').trim());
                    if (n == null || n < 1 || n > 100) return 'Entre 1 y 100';
                    return null;
                  }
                  final c = parseCentavos(v ?? '');
                  if (c == null) return 'Monto inválido';
                  if (c <= 0) return 'Debe ser mayor a 0';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _objetivo,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Meta total (opcional)',
                  prefixText: r'$ ',
                  helperText:
                      'Para ver tu progreso, ej. \$1,200 para un viaje.',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final c = parseCentavos(v);
                  return (c == null || c <= 0) ? 'Monto inválido' : null;
                },
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _guardar,
                icon: const Icon(Icons.check),
                label: Text(_editando ? 'Guardar cambios' : 'Crear plan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
