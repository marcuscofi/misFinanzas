import 'package:flutter/material.dart';

import '../models/tarjeta.dart';
import '../services/tarjetas_service.dart';
import '../utils/formato.dart';

Future<void> mostrarFormularioTarjeta(
  BuildContext context,
  TarjetasService svc, {
  Tarjeta? inicial,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 520),
    builder: (_) => _FormTarjeta(svc: svc, inicial: inicial),
  );
}

class _FormTarjeta extends StatefulWidget {
  const _FormTarjeta({required this.svc, this.inicial});
  final TarjetasService svc;
  final Tarjeta? inicial;
  @override
  State<_FormTarjeta> createState() => _FormTarjetaState();
}

class _FormTarjetaState extends State<_FormTarjeta> {
  final _formKey = GlobalKey<FormState>();
  late String _banco = widget.inicial?.banco ?? bancos.first;
  late final _alias = TextEditingController(text: widget.inicial?.alias ?? '');
  late final _limite = TextEditingController(
    text: widget.inicial == null
        ? ''
        : (widget.inicial!.limiteMensualCentavos / 100).toStringAsFixed(2),
  );

  @override
  void dispose() {
    _alias.dispose();
    _limite.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final base = widget.inicial;
    widget.svc.guardar(
      Tarjeta(
        id: base?.id ?? '',
        banco: _banco,
        alias: _alias.text.trim(),
        limiteMensualCentavos: parseCentavos(_limite.text)!,
        activa: base?.activa ?? true,
        creada: base?.creada ?? DateTime.now(),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final editando = widget.inicial != null;
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
                editando ? 'Editar tarjeta' : 'Nueva tarjeta',
                style: tema.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final b in bancos)
                    ChoiceChip(
                      label: Text(b),
                      selected: _banco == b,
                      onSelected: (_) => setState(() => _banco = b),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _alias,
                textCapitalization: TextCapitalization.words,
                maxLength: 60,
                decoration: const InputDecoration(
                  labelText: 'Alias (opcional)',
                  hintText: 'Ej. Visa Oro',
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _limite,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Presupuesto mensual',
                  prefixText: r'$ ',
                  helperText: 'Se renueva solo el día 1 de cada mes.',
                ),
                validator: (v) {
                  final c = parseCentavos(v ?? '');
                  if (c == null) return 'Monto inválido';
                  if (c <= 0) return 'Debe ser mayor a 0';
                  if (c > 1000000000) return 'Monto demasiado alto';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _guardar,
                icon: const Icon(Icons.check),
                label: Text(editando ? 'Guardar cambios' : 'Agregar tarjeta'),
              ),
              if (editando)
                TextButton.icon(
                  onPressed: () {
                    widget.svc.archivar(widget.inicial!.id, activa: false);
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.archive_outlined),
                  label: const Text('Archivar tarjeta'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
