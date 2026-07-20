import 'dart:ui';
import 'package:flutter/material.dart';

import 'landscape_painter.dart';
import 'texture_painters.dart';
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
    final periodo = periodoAtual(DateTime.now());

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
                    // Paisagem original mantida
                    CustomPaint(painter: LandscapePainter(periodo: periodo)),

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

                    Opacity(
                      opacity: 0.05,
                      child: CustomPaint(painter: NoiseOverlayPainter()),
                    ),

                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                      child: Container(color: Colors.black.withOpacity(0.05)),
                    ),

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

                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(kBorderRadius),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),

                    // Conteúdo textual inalterado
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
                                color: kCorAcento.withOpacity(0.28),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: kCorAcento.withOpacity(0.4)),
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
                            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14, fontWeight: FontWeight.w300, letterSpacing: 0.4, shadows: const [Shadow(color: Colors.black45, blurRadius: 8)]),
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
