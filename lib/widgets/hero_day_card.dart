import 'dart:ui';
import 'package:flutter/material.dart';

import '../shaders/landscape_params.dart';
import 'procedural_landscape.dart';
import '../theme/app_design_tokens.dart';

class HeroDayCard extends StatefulWidget {
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
  State<HeroDayCard> createState() => _HeroDayCardState();
}

class _HeroDayCardState extends State<HeroDayCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 15.0, end: 22.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A seed muda uma vez por dia (fica estável entre rebuilds do mesmo
    // dia) e já decide, de forma determinística, tanto o tipo de cenário
    // (montanhas / colinas com vegetação / formas orgânicas) quanto os
    // detalhes finos do terreno. A paleta muda com o período do dia.
    final params = LandscapeParams.fromDate(DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kBorderRadius),
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
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // 1. Base: paisagem 100% procedural via Fragment Shader
                    //    (dart:ui.FragmentProgram — sem imagens/texturas)
                    ProceduralLandscape(params: params),

                    // 2. O Efeito de Vidro (Glassmorphism) ajustado para sigma 5
                    // Agora o desfoque é leve, preservando o sol e montanhas
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        decoration: BoxDecoration(
                          // Reflexo de luz suave
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.25),
                              Colors.white.withOpacity(0.05),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 3. Gradiente para garantir legibilidade do texto
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),

                    // 4. Borda de vidro esculpido
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(kBorderRadius),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                    ),

                    // 5. Conteúdo textual
                    Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (widget.quantidadeEventos > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: kCorAcento.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: kCorAcento.withOpacity(0.5)),
                              ),
                              child: Text(
                                widget.quantidadeEventos == 1 ? '1 compromisso' : '${widget.quantidadeEventos} compromissos',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.2),
                              ),
                            ),
                          const SizedBox(height: 10),
                          Text(
                            widget.titulo,
                            style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold, letterSpacing: 0.4, shadows: [Shadow(color: Colors.black45, blurRadius: 12)]),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.subtitulo,
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w300, letterSpacing: 0.4, shadows: const [Shadow(color: Colors.black45, blurRadius: 8)]),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
