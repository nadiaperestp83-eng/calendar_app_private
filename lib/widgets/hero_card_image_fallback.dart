import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:nature_daily/nature_daily.dart';

import '../shaders/landscape_params.dart';

/// Cache do motor do `nature_daily` — a descoberta dos assets via
/// `AssetManifest` é assíncrona e não muda durante a vida do app, então
/// fazemos isso uma vez só e reaproveitamos em todos os
/// `HeroCardImageFallback` da árvore de widgets.
Future<NatureDailyEngine>? _engineFuture;

Future<NatureDailyEngine> _obterEngine() {
  return _engineFuture ??= carregarEcossistemasDosAssets(
    // IMPORTANTE: quando um pacote declara `assets:` no PRÓPRIO
    // pubspec.yaml, o Flutter bundla esses arquivos sob o prefixo
    // `packages/<nome_do_pacote>/...` no AssetManifest do APP que
    // consome o pacote (é o mesmo prefixo que o parâmetro `package:`
    // do `Image.asset()` adiciona por baixo dos panos). O default
    // 'assets/images/' do `carregarEcossistemasDosAssets()` funciona
    // perfeitamente quando chamado de DENTRO do próprio nature_daily
    // (seu app de exemplo/teste), mas aqui — sendo chamado do
    // `calendar_app_private`, que só CONSOME o pacote — precisa do
    // prefixo completo, senão a busca no manifest não acha nada e a
    // lista volta vazia.
    pastaAssets: 'packages/nature_daily/assets/images/',
  ).then((ecossistemas) => NatureDailyEngine(ecossistemas));
}

/// Fundo do Hero Card: imagem do dia gerada pelo `nature_daily`, com os
/// nomes de arquivo descobertos automaticamente via `AssetManifest`
/// (não mais hardcoded) — usa o motor `NatureAssetLoader` do próprio
/// pacote, exatamente como ele foi projetado pra ser usado.
///
/// A imagem é sempre o conteúdo principal do card (sem espera de shader,
/// sem crossfade condicional) e é exibida limpa — só um gradiente escuro
/// sutil embaixo garante que o texto ("Hoje", data) continue legível.
class HeroCardImageFallback extends StatefulWidget {
  const HeroCardImageFallback({
    super.key,
    required this.params,
    this.overlayOpacityTop = 0.10,
    this.overlayOpacityBottom = 0.45,
  });

  final LandscapeParams params;
  final double overlayOpacityTop;
  final double overlayOpacityBottom;

  @override
  State<HeroCardImageFallback> createState() => _HeroCardImageFallbackState();
}

class _HeroCardImageFallbackState extends State<HeroCardImageFallback> {
  late final Future<NatureDailyEngine> _future = _obterEngine();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NatureDailyEngine>(
      future: _future,
      builder: (context, snapshot) {
        final engine = snapshot.data;
        // Ainda carregando o manifest, deu erro, ou a pasta de assets
        // veio vazia (NatureDailyEngine exige lista não-vazia) — mostra
        // o gradiente do shader como placeholder nesses três casos.
        if (engine == null || snapshot.hasError || engine.totalItens == 0) {
          return _GradientePlaceholder(params: widget.params);
        }
        return _ImagemDoDia(item: engine.getConteudoDeHoje(), params: widget.params, overlayOpacityTop: widget.overlayOpacityTop, overlayOpacityBottom: widget.overlayOpacityBottom);
      },
    );
  }
}

/// Brilho ambiente: a MESMA imagem do dia (via engine em cache — garantido
/// ser idêntica à do `HeroCardImageFallback` nítido), só que borrada e
/// ampliada, pensada para ficar ATRÁS e SEM clipe, vazando pelas bordas do
/// card — efeito "auréola" comum em capas de álbum (Spotify/Apple Music),
/// em vez de borrar a própria foto nítida.
class HeroCardAmbientGlow extends StatefulWidget {
  const HeroCardAmbientGlow({
    super.key,
    required this.params,
    this.blurSigma = 40.0,
    this.scale = 1.25,
  });

  final LandscapeParams params;
  final double blurSigma;
  final double scale;

  @override
  State<HeroCardAmbientGlow> createState() => _HeroCardAmbientGlowState();
}

class _HeroCardAmbientGlowState extends State<HeroCardAmbientGlow> {
  late final Future<NatureDailyEngine> _future = _obterEngine();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NatureDailyEngine>(
      future: _future,
      builder: (context, snapshot) {
        final engine = snapshot.data;
        if (engine == null || snapshot.hasError || engine.totalItens == 0) {
          return _GradientePlaceholder(params: widget.params);
        }
        final item = engine.getConteudoDeHoje();
        return ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: widget.blurSigma,
            sigmaY: widget.blurSigma,
            tileMode: TileMode.decal,
          ),
          child: Transform.scale(
            scale: widget.scale,
            child: Image.asset(
              item.assetPath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _GradientePlaceholder(params: widget.params),
            ),
          ),
        );
      },
    );
  }
}

class _GradientePlaceholder extends StatelessWidget {
  const _GradientePlaceholder({required this.params});
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

class _ImagemDoDia extends StatelessWidget {
  const _ImagemDoDia({
    required this.item,
    required this.params,
    required this.overlayOpacityTop,
    required this.overlayOpacityBottom,
  });

  final Ecossistema item;
  final LandscapeParams params;
  final double overlayOpacityTop;
  final double overlayOpacityBottom;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          // `item.assetPath` já vem com o prefixo completo
          // `packages/nature_daily/assets/images/...` direto do
          // AssetManifest — por isso NÃO passamos o parâmetro
          // `package:` aqui (dobraria o prefixo e quebraria de novo).
          item.assetPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _GradientePlaceholder(params: params),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(overlayOpacityTop),
                Colors.black.withOpacity(overlayOpacityBottom),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
