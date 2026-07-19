import 'dart:ui';
import 'package:flutter/material.dart';

import '../services/isar_service.dart';

/// Seletor de data sutil, aberto como um bottom sheet de vidro.
/// Não é uma grade de calendário tradicional: é uma lista horizontal
/// de dias do mês, rolável, com destaque leve para o dia selecionado
/// e um indicador (ponto) nos dias que possuem eventos.
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
    final diasNoMes =
        DateTime(_mesVisivel.year, _mesVisivel.month + 1, 0).day;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(32),
            ),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 18),
              Row(
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
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _mudarMes(1),
                    icon: const Icon(Icons.chevron_right,
                        color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: diasNoMes,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
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

                    return GestureDetector(
                      onTap: () {
                        widget.onDataSelecionada(dia);
                        Navigator.of(context).pop();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: selecionado
                              ? Colors.white.withOpacity(0.9)
                              : Colors.white.withOpacity(0.08),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _diaSemanaAbrev(dia.weekday),
                              style: TextStyle(
                                fontSize: 11,
                                color: selecionado
                                    ? Colors.black54
                                    : Colors.white54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${dia.day}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: selecionado
                                    ? Colors.black87
                                    : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (temEvento)
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: selecionado
                                      ? Colors.black45
                                      : Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _diaSemanaAbrev(int weekday) {
    const dias = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    return dias[weekday - 1];
  }
}
