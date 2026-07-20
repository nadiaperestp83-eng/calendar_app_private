import 'dart:ui';
import 'package:flutter/material.dart';

import '../models/evento.dart';
import '../theme/app_design_tokens.dart';

/// Cartão de vidro fosco (glassmorphism) usado para exibir um [Evento].
///
/// Aplica BackdropFilter com blur, uma camada semitransparente,
/// borda sutil com leve brilho e cantos bem arredondados — estética
/// "Apple-like", sem linhas de grade ou tabelas.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.evento,
    this.onTap,
    this.onLongPress,
  });

  final Evento evento;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  String _formatarHora(DateTime data) {
    final h = data.hour.toString().padLeft(2, '0');
    final m = data.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final corBase = evento.corTint != null
        ? Color(evento.corTint!)
        : Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kBorderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kBorderRadius),
                color: Colors.white.withOpacity(0.14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.28),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barra de cor lateral, discreta, sem virar "grade"
                  Container(
                    width: 4,
                    height: 46,
                    margin: const EdgeInsets.only(right: 14, top: 2),
                    decoration: BoxDecoration(
                      color: corBase.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          evento.titulo,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: Colors.white.withOpacity(0.75),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              evento.dataHoraFim != null
                                  ? '${_formatarHora(evento.dataHoraInicio)} – ${_formatarHora(evento.dataHoraFim!)}'
                                  : _formatarHora(evento.dataHoraInicio),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                        if (evento.local != null &&
                            evento.local!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.place_outlined,
                                size: 14,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  evento.local!,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
