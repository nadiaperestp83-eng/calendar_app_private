import 'dart:ui';
import 'package:flutter/material.dart';

import 'landscape_painter.dart';
import 'texture_painters.dart';
import '../theme/app_design_tokens.dart';

/// Card "Hero" do dia atual — fica no topo da HomeScreen.
///
/// Fundo: paisagem 100% gerada por código (LandscapePainter), variando
/// pela hora do dia. Por cima, um gradiente "janela" pintado manualmente
/// com dither (sem banding) + uma camada de ruído sutil (textura fosca),
/// dando um acabamento de altíssima qualidade em vez de "código liso".
class HeroDayCard extends StatelessWidget {
  const HeroDayCard({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.quantidadeEventos,
  });

  final String titulo;
  final String subtitulo;
  final int quantidadeEventos;

  @override
  Widget build(BuildContext context) {
    final periodo = periodoAtual(DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kBorderRadius),
          // Sombra realista: blur alto, sem espalhamento (spread 0),
          // preta a 30% — o card parece flutuar sobre o degradê de fundo.
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kBorderRadius),
          child: SizedBox(
            height: 220,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Paisagem gerada via CustomPainter — sem asset.
                CustomPaint(painter: LandscapePainter(periodo: periodo)),

                // Efeito "janela": gradiente interno invertido em
                // relação ao fundo do Scaffold, agora pintado com
                // dither: true (elimina banding de cor).
                CustomPaint(
                  painter: DitheredGradientPainter(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        kGradienteBase.withOpacity(0.28),
                        kGradienteTopo.withOpacity(0.42),
                      ],
                    ),
                  ),
                ),

                // Textura de ruído (grain) sutil — acabamento "fosco",
                // remove o aspecto artificial de gradiente liso demais.
                Opacity(
                  opacity: 0.05,
                  child: CustomPaint(painter: NoiseOverlayPainter()),
                ),

                // Véu de vidro fosco bem sutil sobre a paisagem
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: Container(color: Colors.black.withOpacity(0.05)),
                ),

                // Gradiente escuro na base, para o texto ficar legível
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.55),
                      ],
                      stops: const [0.45, 1.0],
                    ),
                  ),
                ),

                // Borda interna muito fina, quase branca, 10% —
                // "vidro esculpido no degradê", não colado por cima.
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kBorderRadius),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),

                // Conteúdo textual
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (quantidadeEventos > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: kCorAcento.withOpacity(0.28),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: kCorAcento.withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            quantidadeEventos == 1
                                ? '1 compromisso'
                                : '$quantidadeEventos compromissos',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      Text(
                        titulo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                          shadows: [
                            Shadow(color: Colors.black45, blurRadius: 12),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitulo,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 0.4,
                          shadows: const [
                            Shadow(color: Colors.black45, blurRadius: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
