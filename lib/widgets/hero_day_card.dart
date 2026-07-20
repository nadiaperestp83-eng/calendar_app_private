import 'dart:ui';
import 'package:flutter/material.dart';

import 'landscape_painter.dart';
import '../theme/app_design_tokens.dart';

/// Card "Hero" do dia atual — fica no topo da HomeScreen.
///
/// Fundo: paisagem 100% gerada por código (LandscapePainter), variando
/// pela hora do dia. Por cima, um gradiente interno INVERTIDO em
/// relação ao fundo do Scaffold (que vai de azul-noturno no topo para
/// roxo-noturno na base) — aqui o card vai do roxo mais claro no topo
/// para o azul mais profundo na base, criando a ilusão óptica de uma
/// "janela" para um espaço mais profundo, em vez de um elemento colado
/// por cima do fundo.
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
        // BoxShadow leve para dar profundidade ao card sobre o gradiente.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kBorderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 12),
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
                // relação ao fundo do Scaffold (kGradienteTopo/Base).
                DecoratedBox(
                  decoration: BoxDecoration(
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
                            // Acento índigo só aqui, no badge de destaque.
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
