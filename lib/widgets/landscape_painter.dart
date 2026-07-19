import 'dart:math' as math;
import 'package:flutter/material.dart';

/// PerÃ­odos do dia usados para escolher a paleta da paisagem.
enum PeriodoDoDia { madrugada, manha, tarde, entardecer, noite }

PeriodoDoDia periodoAtual(DateTime agora) {
  final h = agora.hour;
  if (h >= 5 && h < 8) return PeriodoDoDia.madrugada;
  if (h >= 8 && h < 12) return PeriodoDoDia.manha;
  if (h >= 12 && h < 17) return PeriodoDoDia.tarde;
  if (h >= 17 && h < 20) return PeriodoDoDia.entardecer;
  return PeriodoDoDia.noite;
}

/// Desenha uma paisagem estilizada (cÃ©u + sol/lua + montanhas em camadas)
/// inteiramente via cÃ³digo â€” sem nenhuma imagem/asset externo.
class LandscapePainter extends CustomPainter {
  LandscapePainter({required this.periodo});

  final PeriodoDoDia periodo;

  List<Color> get _corCeu {
    switch (periodo) {
      case PeriodoDoDia.madrugada:
        return const [Color(0xFF2B2E4A), Color(0xFFE8A87C)];
      case PeriodoDoDia.manha:
        return const [Color(0xFF6DA9E4), Color(0xFFBFE3F0)];
      case PeriodoDoDia.tarde:
        return const [Color(0xFF3E8FDE), Color(0xFF8FCBEA)];
      case PeriodoDoDia.entardecer:
        return const [Color(0xFFFF7E5F), Color(0xFFFEB47B)];
      case PeriodoDoDia.noite:
        return const [Color(0xFF0F1030), Color(0xFF2B2E5C)];
    }
  }

  bool get _ehNoite =>
      periodo == PeriodoDoDia.noite || periodo == PeriodoDoDia.madrugada;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1) CÃ©u em gradiente
    final ceuPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: _corCeu,
      ).createShader(rect);
    canvas.drawRect(rect, ceuPaint);

    // 2) Sol ou lua
    final astroCentro = Offset(size.width * 0.78, size.height * 0.28);
    final astroRaio = size.height * 0.16;
    if (_ehNoite) {
      canvas.drawCircle(
        astroCentro,
        astroRaio,
        Paint()..color = Colors.white.withOpacity(0.9),
      );
      // pequenas estrelas
      final rnd = math.Random(periodo.index);
      for (var i = 0; i < 18; i++) {
        final p = Offset(
          rnd.nextDouble() * size.width,
          rnd.nextDouble() * size.height * 0.6,
        );
        canvas.drawCircle(
          p,
          rnd.nextDouble() * 1.2 + 0.3,
          Paint()..color = Colors.white.withOpacity(0.6),
        );
      }
    } else {
      canvas.drawCircle(
        astroCentro,
        astroRaio,
        Paint()
          ..color = Colors.white.withOpacity(0.85)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
      canvas.drawCircle(
        astroCentro,
        astroRaio * 0.7,
        Paint()..color = Colors.white,
      );
    }

    // 3) Montanhas em 3 camadas (paralaxe visual simples)
    _desenharCamadaMontanha(
      canvas, size,
      alturaBase: 0.62, variacao: 0.10,
      cor: _corCeu.last.withOpacity(0.55),
      seed: 1,
    );
    _desenharCamadaMontanha(
      canvas, size,
      alturaBase: 0.74, variacao: 0.12,
      cor: _corCeu.last.withOpacity(0.8),
      seed: 2,
    );
    _desenharCamadaMontanha(
      canvas, size,
      alturaBase: 0.86, variacao: 0.09,
      cor: (_ehNoite ? const Color(0xFF15162E) : const Color(0xFF1B2A38)),
      seed: 3,
    );
  }

  void _desenharCamadaMontanha(
    Canvas canvas,
    Size size, {
    required double alturaBase,
    required double variacao,
    required Color cor,
    required int seed,
  }) {
    final rnd = math.Random(seed * 17 + periodo.index);
    final path = Path()..moveTo(0, size.height);
    double x = 0;
    final passo = size.width / 6;
    path.lineTo(0, size.height * alturaBase);
    while (x < size.width) {
      final y = size.height * (alturaBase - rnd.nextDouble() * variacao);
      final xCtrl = x + passo / 2;
      final xFim = math.min(x + passo, size.width);
      path.quadraticBezierTo(xCtrl, y, xFim, size.height * alturaBase);
      x += passo;
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, Paint()..color = cor);
  }

  @override
  bool shouldRepaint(covariant LandscapePainter oldDelegate) =>
      oldDelegate.periodo != periodo;
}
