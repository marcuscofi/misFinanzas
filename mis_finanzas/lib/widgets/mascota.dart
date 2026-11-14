import 'package:flutter/material.dart';

import '../models/estado_mascota.dart';
import '../theme/paleta.dart';

class Mascota extends StatelessWidget {
  const Mascota(this.estado, {super.key, this.tamano = 140});
  final EstadoMascota estado;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.85, end: 1.0).animate(anim),
          child: child,
        ),
      ),
      child: Image.asset(
        estado.asset,
        key: ValueKey(estado),
        width: tamano,
        height: tamano,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => SizedBox(
          width: tamano,
          height: tamano,
          child: Icon(
            Icons.savings_rounded,
            size: tamano * 0.6,
            color: Paleta.esmeralda,
          ),
        ),
      ),
    );
  }
}
