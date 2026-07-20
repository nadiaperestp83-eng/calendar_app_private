import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../shaders/landscape_params.dart';
import '../shaders/landscape_shader_controller.dart';
import 'procedural_landscape_painter.dart';
import 'package:flutter/scheduler.dart'; // <--- ESTA LINHA É A QUE FALTA

/// Widget "pronto para usar": carrega `landscape.frag`, mantém uma única
/// instância de [ui.FragmentShader] viva (evita recompilar/realocar a cada
/// rebuild) e desenha a paisagem via [ProceduralLandscapePainter].
///
/// Uso (substitui `CustomPaint(painter: LandscapePainter(periodo: periodo))`):
/// ```dart
/// ProceduralLandscape(
///   params: LandscapeParams.fromDate(DateTime.now()),
/// )
/// ```
class ProceduralLandscape extends StatefulWidget {
  const ProceduralLandscape({
    super.key,
    required this.params,
    this.animate = true,
  });

  final LandscapeParams params;

  /// Se `true`, mantém um `Ticker` leve rodando só para o brilho sutil das
  /// estrelas/god-rays (não afeta a geometria do terreno, que é estática).
  /// Desligue para economizar bateria se a animação não for essencial.
  final bool animate;

  @override
  State<ProceduralLandscape> createState() => _ProceduralLandscapeState();
}

class _ProceduralLandscapeState extends State<ProceduralLandscape>
    with SingleTickerProviderStateMixin {
  ui.FragmentShader? _shader;
  Ticker? _ticker;
  double _time = 0.0;

  @override
  void initState() {
    super.initState();
    _loadShader();
    if (widget.animate) {
      _ticker = createTicker((elapsed) {
        setState(() => _time = elapsed.inMilliseconds / 1000.0);
      })..start();
    }
  }

  Future<void> _loadShader() async {
    final program = await LandscapeShaderController.program();
    if (!mounted) return;
    setState(() => _shader = program.fragmentShader());
  }

  @override
  void dispose() {
    _ticker?.dispose();
    // FragmentShader não expõe dispose() na API pública estável — o GC do
    // engine cuida da liberação quando a última referência Dart some.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shader = _shader;
    if (shader == null) {
      // Primeiro frame antes do shader compilar (raríssimo se você chamar
      // LandscapeShaderController.preload() no boot do app) — usa um
      // gradiente estático simples como placeholder, sem imagens.
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [widget.params.skyTop, widget.params.skyBottom],
          ),
        ),
      );
    }

    return CustomPaint(
      painter: ProceduralLandscapePainter(
        shader: shader,
        params: widget.params,
        time: _time,
      ),
      size: Size.infinite,
    );
  }
}
