import 'package:flutter/material.dart';

import '../models/cuenta_bancaria.dart';
import '../models/tarjeta.dart';
import '../services/cuentas_service.dart';

Future<void> mostrarFormularioCuenta(
  BuildContext context,
  CuentasBancariasService svc, {
  CuentaBancaria? inicial,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 520),
    builder: (_) => _FormCuenta(svc: svc, inicial: inicial),
  );
}

class _FormCuenta extends StatefulWidget {
  const _FormCuenta({required this.svc, this.inicial});
  final CuentasBancariasService svc;
  final CuentaBancaria? inicial;
  @override
  State<_FormCuenta> createState() => _FormCuentaState();
}

class _FormCuentaState extends State<_FormCuenta> {
  final _formKey = GlobalKey<FormState>();
  late String _banco = widget.inicial?.banco ?? bancos.first;
  late final _alias = TextEditingController(text: widget.inicial?.alias ?? '');
  late TipoCuentaBancaria _tipo =
      widget.inicial?.tipo ?? TipoCuentaBancaria.cuenta;

  @override
  void dispose() {
    _alias.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final base = widget.inicial;
    widget.svc.guardar(
      CuentaBancaria(
        id: base?.id ?? '',
        banco: _banco,
        alias: _alias.text.trim(),
        tipo: _tipo,
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
                editando ? 'Editar cuenta' : 'Nueva cuenta',
                style: tema.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              SegmentedButton<TipoCuentaBancaria>(
                segments: const [
                  ButtonSegment(
                    value: TipoCuentaBancaria.cuenta,
                    label: Text('Cuenta'),
                    icon: Icon(Icons.account_balance_outlined),
                  ),
                  ButtonSegment(
                    value: TipoCuentaBancaria.debito,
                    label: Text('Débito'),
                    icon: Icon(Icons.credit_card_outlined),
                  ),
                ],
                selected: {_tipo},
                onSelectionChanged: (s) => setState(() => _tipo = s.first),
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
                  hintText: 'Ej. Cuenta de nómina',
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _guardar,
                icon: const Icon(Icons.check),
                label: Text(editando ? 'Guardar cambios' : 'Agregar cuenta'),
              ),
              if (editando)
                TextButton.icon(
                  onPressed: () {
                    widget.svc.archivar(widget.inicial!.id, activa: false);
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.archive_outlined),
                  label: const Text('Archivar cuenta'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
