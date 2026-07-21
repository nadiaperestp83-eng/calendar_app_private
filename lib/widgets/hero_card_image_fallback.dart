import 'package:flutter/material.dart';
import 'package:nature_daily/nature_daily.dart';

import '../shaders/landscape_params.dart';

/// Motor do `nature_daily` compartilhado por todos os `HeroCardImageFallback`
/// da árvore de widgets — evita recriar a lista de ecossistemas (mesma
/// instância imutável, `List.unmodifiable` já dentro do próprio pacote) a
/// cada rebuild do Hero Card.
final NatureDailyEngine _engine = NatureDailyEngine(ecossistemasData);

/// Fundo do Hero Card.
///
/// MUDANÇA DE PRIORIDADE (a pedido explícito): antes este widget mostrava
/// o shader procedural por padrão e só caía pra imagem do `nature_daily`
/// se o shader falhasse ou demorasse. Isso foi invertido — o shader ficou
/// feio/indesejado como fundo, então agora a imagem do `nature_daily` é
/// SEMPRE a imagem principal, sem espera de timeout nem crossfade com
/// shader.
///
/// Por isso também removi o tratamento pesado de blur/dessaturação que
/// fazia sentido pra disfarçar uma FOTO REALISTA como se fosse "extensão
/// abstrata do shader" (aquele era o objetivo com o Pixabay). Agora que a
/// imagem é o conteúdo principal — não mais um substituto discreto — ela
/// é exibida limpa, só com um gradiente sutil embaixo pra garantir
/// contraste de texto (título/data do card por cima).
///
/// Mantive o nome da classe (`HeroCardImageFallback`) só para não precisar
/// mexer no import do `hero_day_card.dart` de novo — mas ela não é mais um
/// "fallback" condicional, é o fundo padrão.
class HeroCardImageFallback extends StatelessWidget {
  const HeroCardImageFallback({
    super.key,
    required this.params,
    this.overlayOpacityTop = 0.10,
    this.overlayOpacityBottom = 0.45,
  });

  final LandscapeParams params;

  /// Opacidade do gradiente escuro no topo do card (baixa — só o
  /// suficiente pra não "estourar" o relógio/status bar do device, que
  /// fica sobreposto ao card em alguns layouts).
  final double overlayOpacityTop;

  /// Opacidade do gradiente escuro embaixo — mais forte, garante que o
  /// texto ("Hoje", "20 de julho de 2026") continue legível em cima de
  /// qualquer imagem, clara ou escura.
  final double overlayOpacityBottom;

  Ecossistema get _item => _engine.getConteudoDeHoje();

  @override
  Widget build(BuildContext context) {
    final item = _item;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          item.assetPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Asset ausente/corrompido no pacote — cai pro gradiente do
            // shader como último recurso, só pra não deixar o card em
            // branco.
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [params.skyTop, params.skyBottom],
                ),
              ),
            );
          },
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
