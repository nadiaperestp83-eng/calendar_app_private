import 'dart:ui';
import 'package:flutter/material.dart';

import '../services/isar_service.dart';
import '../theme/app_design_tokens.dart';

/// Seletor de data sutil, aberto como um DraggableScrollableSheet de
/// vidro. Não é uma grade de calendário tradicional: é uma lista
/// horizontal de dias do mês, rolável (ListView.builder), com destaque
/// "glass" (borda + brilho suave) para o dia selecionado — sem
/// preenchimento sólido chamativo.
class DateSelectorSheet extends StatefulWidget {
  const DateSelectorSheet({
    super.key,
    required this.dataSelecionada,
    required this.onDataSelecionada,
  });

  final DateTime dataSelecionada;
  final ValueChanged<DateTime> onDataSelecionada;

  static Future<void> show(
    BuildContext context, {
    required DateTime dataSelecionada,
    required ValueChanged<DateTime> onDataSelecionada,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DateSelectorSheet(
        dataSelecionada: dataSelecionada,
        onDataSelecionada: onDataSelecionada,
      ),
    );
  }

  @override
  State<DateSelectorSheet> createState() => _DateSelectorSheetState();
}

class _DateSelectorSheetState extends State<DateSelectorSheet> {
  late DateTime _mesVisivel = DateTime(
    widget.dataSelecionada.year,
    widget.dataSelecionada.month,
  );
  Set<DateTime> _diasComEvento = {};

  static const _meses = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];

  @override
  void initState() {
    super.initState();
    _carregarIndicadores();
  }

  Future<void> _carregarIndicadores() async {
    final dias = await IsarService.instance.getDiasComEventos(_mesVisivel);
    if (mounted) setState(() => _diasComEvento = dias);
  }

  void _mudarMes(int delta) {
    setState(() {
      _mesVisivel = DateTime(_mesVisivel.year, _mesVisivel.month + delta);
    });
    _carregarIndicadores();
  }

  @override
  Widget build(BuildContext context) {
    // DraggableScrollableSheet permite ao usuário arrastar para ver mais
    // do mês sem perder o contexto do dia focado, mantendo a filosofia
    // "não é uma grade fixa que toma o foco visual".
    return DraggableScrollableSheet(
      initialChildSize: 0.42,
      minChildSize: 0.30,
      maxChildSize: 0.75,
      expand: false,
      builder: (context, scrollController) {
        final diasNoMes =
            DateTime(_mesVisivel.year, _mesVisivel.month + 1, 0).day;

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(kBorderRadius),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(kBorderRadius),
                ),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 14),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => _mudarMes(-1),
                          icon: const Icon(Icons.chevron_left,
                              color: Colors.white70),
                        ),
                        Text(
                          '${_meses[_mesVisivel.month - 1]} ${_mesVisivel.year}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _mudarMes(1),
                          icon: const Icon(Icons.chevron_right,
                              color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      itemCount: diasNoMes,
                      itemBuilder: (context, index) {
                        final dia = DateTime(
                          _mesVisivel.year,
                          _mesVisivel.month,
                          index + 1,
                        );
                        final selecionado = dia.year ==
                                widget.dataSelecionada.year &&
                            dia.month == widget.dataSelecionada.month &&
                            dia.day == widget.dataSelecionada.day;
                        final temEvento = _diasComEvento.any(
                          (d) => d.day == dia.day && d.month == dia.month,
                        );

                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () {
                              widget.onDataSelecionada(dia);
                              Navigator.of(context).pop();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 58,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                // Feedback "glass": sem preenchimento
                                // sólido — só borda + brilho suave.
                                color: Colors.white.withOpacity(
                                  selecionado ? 0.10 : 0.04,
                                ),
                                border: Border.all(
                                  color: Colors.white.withOpacity(
                                    selecionado ? 0.55 : 0.08,
                                  ),
                                  width: selecionado ? 1.4 : 1,
                                ),
                                boxShadow: selecionado
                                    ? [
                                        BoxShadow(
                                          color:
                                              Colors.white.withOpacity(0.18),
                                          blurRadius: 14,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _diaSemanaAbrev(dia.weekday),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: 0.3,
                                      color: selecionado
                                          ? Colors.white70
                                          : Colors.white38,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${dia.day}',
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: selecionado
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (temEvento)
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white
                                            .withOpacity(selecionado ? 0.9 : 0.5),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _diaSemanaAbrev(int weekday) {
    const dias = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    return dias[weekday - 1];
  }
}
