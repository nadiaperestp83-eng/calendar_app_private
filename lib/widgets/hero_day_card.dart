import 'dart:ui';
import 'package:flutter/material.dart';

import 'landscape_painter.dart';
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
                    // 1. Base: A paisagem pintada por código
                    CustomPaint(painter: LandscapePainter(periodo: periodo)),

                    // 2. O Efeito de Vidro (Glassmorphism)
                    // Blur forte (15) cria a sensação real de profundidade
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        decoration: BoxDecoration(
                          // Reflexo sutil de luz estilo premium
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.3),
                              Colors.white.withOpacity(0.1),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 3. Gradiente para garantir legibilidade do texto na base
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.4),
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
                                color: kCorAcento.withOpacity(0.3),
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
