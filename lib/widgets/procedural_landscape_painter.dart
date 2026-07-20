import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../shaders/landscape_params.dart';

/// `CustomPainter` que desenha a paisagem procedural usando o
/// `dart:ui.FragmentShader` compilado a partir de `landscape.frag`.
///
/// Não usa `flutter_shaders`/`AnimatedSampler` de propósito: essa API serve
/// para capturar um widget/imagem filho como `sampler2D` de entrada do
/// shader, e esta cena não usa nenhum `sampler2D` — é 100% matemática. O
/// `CustomPainter` nativo entrega exatamente o mesmo resultado (um
/// `Canvas.drawRect` com `Paint()..shader = shader`) sem adicionar
/// dependência nenhuma.
class ProceduralLandscapePainter extends CustomPainter {
  ProceduralLandscapePainter({
    required this.shader,
    required this.params,
    this.time = 0.0,
  }) : super(repaint: null);

  /// Instância já criada via `program.fragmentShader()`. O ideal é manter
  /// UMA instância viva por widget (ver `ProceduralLandscape` abaixo) e só
  /// atualizar os uniforms a cada repaint — criar uma instância nova por
  /// frame tem custo desnecessário.
  final ui.FragmentShader shader;

  final LandscapeParams params;

  /// Segundos desde o início da animação — usado só para o brilho sutil
  /// das estrelas / god-rays. Pode ficar fixo (0.0) se preferir uma cena
  /// totalmente estática (mais barato ainda).
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    _setUniforms(size);
    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  /// Envia todos os uniforms para o shader, NA MESMA ORDEM em que foram
  /// declarados em `landscape.frag`. Um `vec2`/`vec3` consome 2/3 chamadas
  /// consecutivas de `setFloat`.
  void _setUniforms(Size size) {
    var i = 0;
    void f(double v) => shader.setFloat(i++, v);

    // uSize
    f(size.width);
    f(size.height);

    // uTime
    f(time);

    // uSeed
    f(params.seed);

    // uScenario
    f(params.scenario.uniformValue);

    // uSunDir
    f(params.sunDir.dx);
    f(params.sunDir.dy);

    // uSkyTop / uSkyBottom
    _setColor(f, params.skyTop);
    _setColor(f, params.skyBottom);

    // uGrassColor / uRockColor
    _setColor(f, params.grassColor);
    _setColor(f, params.rockColor);

    // uHazeColor
    _setColor(f, params.hazeColor);

    // uSunColor
    _setColor(f, params.sunColor);

    // uIsNight
    f(params.isNight ? 1.0 : 0.0);
  }

  static void _setColor(void Function(double) f, Color c) {
    f(c.red / 255.0);
    f(c.green / 255.0);
    f(c.blue / 255.0);
  }

  @override
  bool shouldRepaint(covariant ProceduralLandscapePainter oldDelegate) {
    return oldDelegate.params != params ||
        oldDelegate.time != time ||
        oldDelegate.shader != shader;
  }
}
