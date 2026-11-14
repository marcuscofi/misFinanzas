import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/paleta.dart';

class GraficaGastos extends StatelessWidget {
  const GraficaGastos({
    super.key,
    required this.serie,
    required this.seriePrev,
    this.alto = 170,
  });
  final List<int> serie, seriePrev;
  final double alto;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: alto,
    width: double.infinity,
    child: CustomPaint(painter: _Painter(serie, seriePrev)),
  );
}

class _Painter extends CustomPainter {
  _Painter(this.serie, this.prev);
  final List<int> serie, prev;

  @override
  void paint(Canvas canvas, Size size) {
    if (serie.isEmpty) return;
    final w = size.width, h = size.height;
    const pad = 14.0;
    final maxV = [...serie, ...prev, 1].reduce(math.max);

    Offset punto(List<int> s, int i) {
      final x = s.length == 1 ? w / 2 : w * i / (s.length - 1);
      final y = h - pad - (s[i] / maxV) * (h - pad * 2);
      return Offset(x, y);
    }

    Path trazo(List<int> s) {
      final p = Path();
      var a = punto(s, 0);
      p.moveTo(a.dx, a.dy);
      for (var i = 1; i < s.length; i++) {
        final b = punto(s, i);
        final mx = (a.dx + b.dx) / 2;
        p.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
        a = b;
      }
      return p;
    }

    final grilla = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = pad + (h - pad * 2) * i / 3;
      canvas.drawLine(Offset(0, y), Offset(w, y), grilla);
    }

    // Periodo anterior (punteado)
    if (prev.length > 1 && prev.any((v) => v > 0)) {
      final pp = Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      for (final m in trazo(prev).computeMetrics()) {
        for (var d = 0.0; d < m.length; d += 11) {
          canvas.drawPath(m.extractPath(d, d + 5), pp);
        }
      }
    }

    final rect = Rect.fromLTWH(0, 0, w, h);
    final ultimo = punto(serie, serie.length - 1);

    if (serie.length > 1) {
      final linea = trazo(serie);
      final area = Path.from(linea)
        ..lineTo(ultimo.dx, h)
        ..lineTo(punto(serie, 0).dx, h)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Paleta.menta.withValues(alpha: 0.35),
              Paleta.menta.withValues(alpha: 0),
            ],
          ).createShader(rect),
      );
      canvas.drawPath(
        linea,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..shader = const LinearGradient(
            colors: [Paleta.lima, Paleta.esmeralda, Paleta.menta],
          ).createShader(rect),
      );
    }

    canvas.drawCircle(
      ultimo,
      10,
      Paint()..color = Paleta.esmeralda.withValues(alpha: 0.25),
    );
    canvas.drawCircle(ultimo, 5, Paint()..color = Paleta.esmeralda);
  }

  @override
  bool shouldRepaint(_Painter o) =>
      !listEquals(o.serie, serie) || !listEquals(o.prev, prev);
}
