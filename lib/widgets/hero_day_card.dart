import 'dart:ui';
import 'package:flutter/material.dart';

import 'landscape_painter.dart';

/// Card "Hero" do dia atual — fica no topo da HomeScreen.
/// Fundo: paisagem 100% gerada por código (LandscapePainter), variando
/// pela hora do dia. Por cima, um leve véu de vidro fosco + gradiente
/// escuro na base para garantir legibilidade do texto.
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: SizedBox(
          height: 220,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Paisagem gerada via CustomPainter — sem asset.
              CustomPaint(painter: LandscapePainter(periodo: periodo)),

              // Véu de vidro fosco bem sutil sobre a paisagem
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: Container(color: Colors.black.withOpacity(0.06)),
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

              // Borda sutil de vidro
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
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
                          color: Colors.white.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          quantidadeEventos == 1
                              ? '1 compromisso'
                              : '$quantidadeEventos compromissos',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(color: Colors.black45, blurRadius: 12),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
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
    );
  }
}
