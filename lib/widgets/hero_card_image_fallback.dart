import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:nature_daily/nature_daily.dart';

import '../shaders/landscape_params.dart';
import '../shaders/landscape_shader_controller.dart';
import 'procedural_landscape.dart';

/// Motor do `nature_daily` compartilhado por todos os `HeroCardImageFallback`
/// da árvore de widgets — evita recriar a lista de ecossistemas (mesma
/// instância imutável, `List.unmodifiable` já dentro do próprio pacote) a
/// cada rebuild do Hero Card.
final NatureDailyEngine _engine = NatureDailyEngine(ecossistemasData);

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
/// 2. Se o shader não estiver pronto depois de [shaderTimeout], troca para
///    o conteúdo do dia do `nature_daily` (imagem local `.webp` já tratada
///    com blur + saturação reduzida + gradiente `skyTop`/`skyBottom`). Como
///    é um asset embutido no pacote — sem rede — isso é praticamente
///    instantâneo; o timeout aqui serve só pra não trocar de visual antes
///    da hora em devices onde o shader compila rápido.
/// 3. Se/quando o shader terminar de compilar, faz um crossfade suave de
///    volta pra ele, que é sempre a experiência "premium" pretendida.
/// 4. Se o shader falhar (asset ausente, erro de compilação GLSL etc),
///    fica definitivamente no conteúdo do `nature_daily`.
///
/// NOTA DE DESIGN: o `nature_daily` é um pacote de conteúdo educativo
/// "cíclico e determinístico por dia" (`getConteudoDeHoje()`), não uma
/// busca por cenário como era o Pixabay. Por isso este widget NÃO tenta
/// casar `params.scenario` com a `categoria` do ecossistema — todo mundo
/// vê a mesma "surpresa educativa do dia", independente da paisagem do
/// shader. Se você quiser filtrar por categoria (ex: `scenario ==
/// montanhas` → só itens de categoria 'Tundra'), me diga o mapeamento que
/// eu ajusto o `_escolherItem()` abaixo.
class HeroCardImageFallback extends StatefulWidget {
  const HeroCardImageFallback({
    super.key,
    required this.params,
    this.shaderTimeout = const Duration(milliseconds: 600),
    this.blurSigma = 18.0,
    this.saturation = 0.35,
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

  @override
  State<HeroCardImageFallback> createState() => _HeroCardImageFallbackState();
}

enum _EstadoVisual { aguardandoShader, mostrandoFallback, mostrandoShader }

class _HeroCardImageFallbackState extends State<HeroCardImageFallback> {
  ui.FragmentShader? _shader;
  bool _shaderFalhou = false;
  Timer? _timeoutTimer;

  _EstadoVisual get _estado {
    if (_shader != null) return _EstadoVisual.mostrandoShader;
    if (_shaderFalhou || (_timeoutTimer != null && !_timeoutTimer!.isActive)) {
      return _EstadoVisual.mostrandoFallback;
    }
    return _EstadoVisual.aguardandoShader;
  }

  @override
  void initState() {
    super.initState();
    _carregarShader();
    _timeoutTimer = Timer(widget.shaderTimeout, () {
      if (mounted && _shader == null) setState(() {});
    });
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
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  Ecossistema _escolherItem() => _engine.getConteudoDeHoje();

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
        return _ImagemTratada(
          key: const ValueKey('fallback-image'),
          ecossistema: _escolherItem(),
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

/// Aplica o tratamento visual pedido sobre a imagem do `nature_daily`:
/// blur -> dessaturação -> gradiente com as cores do shader por cima,
/// pra ela se misturar com o resto do app em vez de parecer uma foto
/// realista solta no meio da UI.
class _ImagemTratada extends StatelessWidget {
  const _ImagemTratada({
    super.key,
    required this.ecossistema,
    required this.params,
    required this.blurSigma,
    required this.saturation,
  });

  final Ecossistema ecossistema;
  final LandscapeParams params;
  final double blurSigma;
  final double saturation;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1) Imagem base (asset local .webp do pacote), desfocada e
        // dessaturada.
        ColorFiltered(
          colorFilter: matrizDeSaturacao(saturation),
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
              sigmaX: blurSigma,
              sigmaY: blurSigma,
              tileMode: TileMode.decal,
            ),
            child: Image.asset(
              ecossistema.assetPath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Asset ausente/corrompido no pacote — cai pro
                // placeholder de gradiente puro.
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
