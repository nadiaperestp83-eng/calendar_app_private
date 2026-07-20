import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Pinta um LinearGradient manualmente via [Paint].
///
/// Nota técnica: `Paint` não tem uma propriedade de instância `dither`
/// na API pública do Flutter (isso nunca saiu de uma PR experimental
/// de 2019). O dithering de gradientes hoje é controlado pela flag
/// estática `Paint.enableDithering`, que desde as versões recentes do
/// engine (Impeller) já vem `true` por padrão — ou seja, o gradiente
/// abaixo já é renderizado sem banding, sem precisar configurar nada
/// manualmente. Mantemos o CustomPainter mesmo assim, só pra ter
/// controle total do desenho (paisagem + camadas por cima).
class DitheredGradientPainter extends CustomPainter {
  DitheredGradientPainter({required this.gradient});

  final LinearGradient gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..isAntiAlias = true;
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant DitheredGradientPainter oldDelegate) =>
      oldDelegate.gradient != gradient;
}

/// Textura de ruído (grain) sutil, gerada proceduralmente — sem
/// nenhuma imagem/asset externo. Pontos minúsculos com opacidade
/// levemente variável, espalhados de forma determinística (seed fixo)
/// pra não "piscar" a cada rebuild.
class NoiseOverlayPainter extends CustomPainter {
  NoiseOverlayPainter({this.densidade = 900, this.seed = 7});

  final int densidade;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    final paint = Paint()..color = Colors.white;

    for (var i = 0; i < densidade; i++) {
      final ponto = Offset(
        rnd.nextDouble() * size.width,
        rnd.nextDouble() * size.height,
      );
      final raio = rnd.nextDouble() * 0.7 + 0.2;
      paint.color = Colors.white.withOpacity(rnd.nextDouble() * 0.5 + 0.2);
      canvas.drawCircle(ponto, raio, paint);
    }
  }

  @override
  bool shouldRepaint(covariant NoiseOverlayPainter oldDelegate) => false;
}
