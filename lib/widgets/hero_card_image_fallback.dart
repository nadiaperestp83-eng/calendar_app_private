import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../services/pixabay_service.dart';
import '../shaders/landscape_params.dart';
import '../shaders/landscape_shader_controller.dart';
import 'procedural_landscape.dart';

/// Decide, para cada [LandscapeScenario] + período (dia/noite), qual
/// termo de busca no Pixabay melhor combina com o que o shader
/// desenharia — mantendo o clima minimalista/abstrato do app (nada de
/// fotos de pessoas, texto, logos etc, por isso o "minimalist"/
/// "abstract" em quase todas as queries).
String queryParaCenario(LandscapeParams params) {
  String base;
  switch (params.scenario) {
    case LandscapeScenario.montanhas:
      base = 'mountain landscape minimalist';
      break;
    case LandscapeScenario.colinasComVegetacao:
      base = 'green hills landscape minimalist';
      break;
    case LandscapeScenario.formasOrganicas:
      base = 'abstract hills landscape';
      break;
  }
  return params.isNight ? '$base night' : '$base sunlight';
}

/// Matriz de saturação para [ColorFilter.matrix].
///
/// `saturation == 1.0` não altera a imagem; `0.0` é preto e branco.
/// Valores baixos (ex: 0.25–0.4) são o que dá a sensação de "extensão
/// abstrata do shader" pedida — a foto perde realismo e vira quase uma
/// textura de cor.
ColorFilter matrizDeSaturacao(double saturation) {
  final double s = saturation.clamp(0.0, 1.0);
  final double inv = 1 - s;
  final double r = 0.213 * inv;
  final double g = 0.715 * inv;
  final double b = 0.072 * inv;
  return ColorFilter.matrix(<double>[
    r + s, g, b, 0, 0,
    r, g + s, b, 0, 0,
    r, g, b + s, 0, 0,
    0, 0, 0, 1, 0,
  ]);
}

/// Widget "drop-in" para substituir o `ProceduralLandscape` dentro do
/// `HeroDayCard`. Ele:
///
/// 1. Começa a compilar o shader normalmente (via
///    `LandscapeShaderController`).
/// 2. Se o shader não estiver pronto depois de [shaderTimeout], inicia
///    em paralelo a busca/download de uma imagem no Pixabay coerente
///    com [params] e a exibe já tratada (blur + saturação reduzida +
///    gradiente com as cores `skyTop`/`skyBottom` do shader).
/// 3. Se/quando o shader terminar de compilar (mesmo que a imagem já
///    esteja na tela), faz um crossfade suave de volta para o shader,
///    que é sempre a experiência "premium" pretendida.
/// 4. Se o shader falhar (asset ausente, erro de compilação GLSL
///    etc), fica definitivamente na imagem tratada.
///
/// Uso: troque, em `hero_day_card.dart`,
/// `ProceduralLandscape(params: params)` por
/// `HeroCardImageFallback(params: params)`.
class HeroCardImageFallback extends StatefulWidget {
  const HeroCardImageFallback({
    super.key,
    required this.params,
    this.shaderTimeout = const Duration(milliseconds: 600),
    this.blurSigma = 18.0,
    this.saturation = 0.35,
    this.query,
  });

  final LandscapeParams params;

  /// Quanto tempo esperar o shader compilar antes de acionar o
  /// fallback. 600ms é folgado o suficiente para não "piscar" fallback
  /// em devices rápidos, mas curto o bastante para não deixar o
  /// usuário olhando pro placeholder cinza do `ProceduralLandscape`.
  final Duration shaderTimeout;

  /// Intensidade do desfoque (sigma do `ImageFilter.blur`).
  final double blurSigma;

  /// 0.0 = preto e branco, 1.0 = cores originais da foto. O default
  /// (0.35) é propositalmente baixo para a foto não competir
  /// visualmente com o resto do app.
  final double saturation;

  /// Override manual da busca — se `null`, é derivada automaticamente
  /// de `params.scenario` + `params.isNight` via [queryParaCenario].
  final String? query;

  @override
  State<HeroCardImageFallback> createState() => _HeroCardImageFallbackState();
}

enum _EstadoVisual { aguardandoShader, mostrandoFallback, mostrandoShader }

class _HeroCardImageFallbackState extends State<HeroCardImageFallback> {
  ui.FragmentShader? _shader;
  PixabayImage? _imagemFallback;
  bool _shaderFalhou = false;
  bool _fallbackDisparado = false;
  Timer? _timeoutTimer;

  _EstadoVisual get _estado {
    if (_shader != null) return _EstadoVisual.mostrandoShader;
    if (_imagemFallback != null || _shaderFalhou) {
      return _EstadoVisual.mostrandoFallback;
    }
    return _EstadoVisual.aguardandoShader;
  }

  @override
  void initState() {
    super.initState();
    _carregarShader();
    _timeoutTimer = Timer(widget.shaderTimeout, _dispararFallbackSeNecessario);
  }

  Future<void> _carregarShader() async {
    try {
      final program = await LandscapeShaderController.program();
      if (!mounted) return;
      setState(() => _shader = program.fragmentShader());
    } catch (_) {
      // Falha de compilação do GLSL, asset faltando, etc — trata como
      // "shader indisponível" e força o fallback imediatamente, sem
      // esperar o timeout.
      if (!mounted) return;
      setState(() => _shaderFalhou = true);
      _dispararFallbackSeNecessario();
    }
  }

  Future<void> _dispararFallbackSeNecessario() async {
    if (_fallbackDisparado || _shader != null || !mounted) return;
    _fallbackDisparado = true;

    final query = widget.query ?? queryParaCenario(widget.params);
    try {
      final imagem = await PixabayService.searchFirst(query);
      if (!mounted || _shader != null) return; // shader chegou primeiro
      setState(() => _imagemFallback = imagem);
    } on PixabayException {
      // Sem chave configurada, sem internet, sem resultados etc — não
      // há o que fazer além de deixar o placeholder simples do
      // `ProceduralLandscape` (gradiente `skyTop`/`skyBottom`) até o
      // shader compilar. Não propaga a exceção pra não derrubar o
      // Hero Card por causa de uma imagem decorativa.
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        fit: StackFit.expand,
        children: [...previousChildren, if (currentChild != null) currentChild],
      ),
      child: _construirConteudo(),
    );
  }

  Widget _construirConteudo() {
    switch (_estado) {
      case _EstadoVisual.mostrandoShader:
        return ProceduralLandscape(
          key: const ValueKey('shader'),
          params: widget.params,
        );
      case _EstadoVisual.mostrandoFallback:
        if (_imagemFallback == null) {
          // Shader falhou mas a imagem ainda não chegou: gradiente
          // simples enquanto isso, igual ao placeholder original.
          return _GradientePlaceholder(
            key: const ValueKey('placeholder'),
            params: widget.params,
          );
        }
        return _ImagemTratada(
          key: const ValueKey('fallback-image'),
          imagem: _imagemFallback!,
          params: widget.params,
          blurSigma: widget.blurSigma,
          saturation: widget.saturation,
        );
      case _EstadoVisual.aguardandoShader:
        return _GradientePlaceholder(
          key: const ValueKey('placeholder'),
          params: widget.params,
        );
    }
  }
}

class _GradientePlaceholder extends StatelessWidget {
  const _GradientePlaceholder({super.key, required this.params});
  final LandscapeParams params;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [params.skyTop, params.skyBottom],
        ),
      ),
    );
  }
}

/// Aplica o tratamento visual pedido sobre a imagem do Pixabay:
/// blur -> dessaturação -> gradiente com as cores do shader por cima,
/// pra ela se misturar com o resto do app em vez de parecer uma foto
/// realista solta no meio da UI.
class _ImagemTratada extends StatelessWidget {
  const _ImagemTratada({
    super.key,
    required this.imagem,
    required this.params,
    required this.blurSigma,
    required this.saturation,
  });

  final PixabayImage imagem;
  final LandscapeParams params;
  final double blurSigma;
  final double saturation;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1) Imagem base, desfocada e dessaturada.
        ColorFiltered(
          colorFilter: matrizDeSaturacao(saturation),
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
              sigmaX: blurSigma,
              sigmaY: blurSigma,
              tileMode: TileMode.decal,
            ),
            child: Image.network(
              imagem.webformatUrl,
              fit: BoxFit.cover,
              // Evita "pop-in" abrupto: a imagem some suavemente do
              // cinza pro conteúdo carregado.
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) return child;
                return AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  child: child,
                );
              },
              errorBuilder: (context, error, stackTrace) {
                // Download falhou depois de já termos passado pela
                // busca (ex: CDN fora do ar) — cai pro placeholder.
                return _GradientePlaceholder(params: params);
              },
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return _GradientePlaceholder(params: params);
              },
            ),
          ),
        ),

        // 2) Gradiente com as cores do shader por cima — é o que faz
        // a foto "combinar" com skyTop/skyBottom em vez de destoar.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                params.skyTop.withOpacity(0.55),
                params.skyBottom.withOpacity(0.65),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
