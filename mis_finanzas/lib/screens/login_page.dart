import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/estado_mascota.dart';
import '../theme/paleta.dart';
import '../widgets/glass_card.dart';
import '../widgets/mascota.dart';

class _Consejo {
  const _Consejo(this.icono, this.titulo, this.texto);
  final IconData icono;
  final String titulo, texto;
}

const _consejos = [
  _Consejo(
    Icons.autorenew_rounded,
    'Automatiza tu ahorro',
    'Programa una transferencia el día que cobras: lo que no ves, no lo gastas.',
  ),
  _Consejo(
    Icons.event_repeat_rounded,
    'Revisa tu deuda semanalmente',
    'Cinco minutos por semana evitan intereses y sorpresas a fin de mes.',
  ),
  _Consejo(
    Icons.trending_down_rounded,
    'Reduce la deuda con pagos extra',
    'Un abono extra al capital recorta intereses y acorta el plazo.',
  ),
  _Consejo(
    Icons.savings_outlined,
    'Págate primero a ti',
    'Aparta tu ahorro al recibir ingresos y gasta lo que quede.',
  ),
  _Consejo(
    Icons.shield_outlined,
    'Arma tu fondo de emergencia',
    'Apunta a cubrir de 3 a 6 meses de gastos básicos.',
  ),
];

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _pageCtrl = PageController(viewportFraction: 0.94);
  Timer? _timer;
  int _pagina = 0;
  bool _cargando = false;
  bool _ocultar = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_pageCtrl.hasClients) return;
      _pageCtrl.animateToPage(
        (_pagina + 1) % _consejos.length,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageCtrl.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _mensaje(e.code));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  String _mensaje(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'Correo o contraseña incorrectos.';
      case 'invalid-email':
        return 'El correo no es válido.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento.';
      case 'network-request-failed':
        return 'Sin conexión. Revisa tu internet.';
      default:
        return 'No se pudo iniciar sesión ($code).';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          const Positioned(
            top: -120,
            right: -80,
            child: _Resplandor(Paleta.esmeralda),
          ),
          const Positioned(
            bottom: -140,
            left: -100,
            child: _Resplandor(Paleta.menta),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  shrinkWrap: true,
                  children: [
                    const Center(
                      child: Mascota(EstadoMascota.bolsa, tamano: 150),
                    ),
                    Text(
                      'Mis Finanzas',
                      textAlign: TextAlign.center,
                      style: tema.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tu dinero, bajo control.',
                      textAlign: TextAlign.center,
                      style: tema.textTheme.bodyMedium?.copyWith(
                        color: tema.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 120,
                      child: PageView.builder(
                        controller: _pageCtrl,
                        itemCount: _consejos.length,
                        onPageChanged: (i) => setState(() => _pagina = i),
                        itemBuilder: (_, i) {
                          final c = _consejos[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GlassCard(
                              acento: Paleta.menta,
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [Paleta.lima, Paleta.menta],
                                      ),
                                    ),
                                    child: Icon(c.icono, color: Colors.black),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c.titulo,
                                          style: tema.textTheme.titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          c.texto,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: tema.textTheme.bodySmall
                                              ?.copyWith(
                                                color: tema.colorScheme.outline,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _consejos.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            height: 8,
                            width: i == _pagina ? 22 : 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: i == _pagina
                                  ? Paleta.lima
                                  : Colors.white24,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Correo',
                              prefixIcon: Icon(Icons.mail_outline),
                            ),
                            validator: (v) => (v == null || !v.contains('@'))
                                ? 'Ingresa un correo válido'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _password,
                            obscureText: _ocultar,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _entrar(),
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _ocultar
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () =>
                                    setState(() => _ocultar = !_ocultar),
                              ),
                            ),
                            validator: (v) => (v == null || v.length < 6)
                                ? 'Mínimo 6 caracteres'
                                : null,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: tema.colorScheme.error),
                            ),
                          ],
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: _cargando ? null : _entrar,
                            child: _cargando
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : const Text('Entrar'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Resplandor extends StatelessWidget {
  const _Resplandor(this.color);
  final Color color;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: 340,
      height: 340,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)],
        ),
      ),
    ),
  );
}
