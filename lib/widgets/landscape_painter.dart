import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Períodos do dia usados para escolher a paleta da paisagem.
enum PeriodoDoDia { madrugada, manha, tarde, entardecer, noite }

PeriodoDoDia periodoAtual(DateTime agora) {
  final h = agora.hour;
  if (h >= 5 && h < 8) return PeriodoDoDia.madrugada;
  if (h >= 8 && h < 12) return PeriodoDoDia.manha;
  if (h >= 12 && h < 17) return PeriodoDoDia.tarde;
  if (h >= 17 && h < 20) return PeriodoDoDia.entardecer;
  return PeriodoDoDia.noite;
}

/// Desenha uma paisagem estilizada (céu + sol/lua + montanhas em camadas)
class LandscapePainter extends CustomPainter {
  LandscapePainter({required this.periodo});

  final PeriodoDoDia periodo;

  List<Color> get _corCeu {
    switch (periodo) {
      case PeriodoDoDia.madrugada:
        return const [Color(0xFF1E2140), Color(0xFFD67A4D)];
      case PeriodoDoDia.manha:
        return const [Color(0xFF3B82F6), Color(0xFF7DD3FC)];
      case PeriodoDoDia.tarde:
        return const [Color(0xFF0284C7), Color(0xFF38BDF8)];
      case PeriodoDoDia.entardecer:
        return const [Color(0xFFF97316), Color(0xFFFDBA74)];
      case PeriodoDoDia.noite:
        return const [Color(0xFF0F172A), Color(0xFF1E293B)];
    }
  }

  bool get _ehNoite =>
      periodo == PeriodoDoDia.noite || periodo == PeriodoDoDia.madrugada;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1) Céu com gradiente diagonal para dar profundidade
    final ceuPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: _corCeu,
      ).createShader(rect);
    canvas.drawRect(rect, ceuPaint);

    // 2) Sol ou lua
    final astroCentro = Offset(size.width * 0.78, size.height * 0.28);
    final astroRaio = size.height * 0.16;
    
    if (_ehNoite) {
      // Lua
      canvas.drawCircle(astroCentro, astroRaio, Paint()..color = Colors.white.withOpacity(0.95));
      // Estrelas
      final rnd = math.Random(periodo.index);
      for (var i = 0; i < 15; i++) {
        canvas.drawCircle(
          Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height * 0.5),
          rnd.nextDouble() * 1.5,
          Paint()..color = Colors.white.withOpacity(0.7),
        );
      }
    } else {
      // Sol com brilho mais intenso
      canvas.drawCircle(
        astroCentro,
        astroRaio,
        Paint()
          ..color = Colors.white.withOpacity(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25),
      );
      canvas.drawCircle(astroCentro, astroRaio * 0.65, Paint()..color = Colors.white.withOpacity(0.95));
    }

    // 3) Montanhas com opacidade crescente (camada da frente mais escura)
    _desenharCamadaMontanha(canvas, size, alturaBase: 0.65, variacao: 0.08, cor: _corCeu.last.withOpacity(0.4), seed: 1);
    _desenharCamadaMontanha(canvas, size, alturaBase: 0.78, variacao: 0.10, cor: _corCeu.last.withOpacity(0.7), seed: 2);
    _desenharCamadaMontanha(canvas, size, alturaBase: 0.90, variacao: 0.07, cor: _corCeu.last.withOpacity(1.0), seed: 3);
  }

  void _desenharCamadaMontanha(Canvas canvas, Size size, {required double alturaBase, required double variacao, required Color cor, required int seed}) {
    final rnd = math.Random(seed * 17 + periodo.index);
    final path = Path()..moveTo(0, size.height);
    double x = 0;
    final passo = size.width / 5;
    path.lineTo(0, size.height * alturaBase);
    while (x < size.width) {
      final y = size.height * (alturaBase - rnd.nextDouble() * variacao);
      path.quadraticBezierTo(x + passo / 2, y, math.min(x + passo, size.width), size.height * alturaBase);
      x += passo;
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, Paint()..color = cor);
  }

  @override
  bool shouldRepaint(covariant LandscapePainter oldDelegate) => oldDelegate.periodo != periodo;
}
