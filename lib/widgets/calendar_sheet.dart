import 'dart:ui';
import 'package:flutter/material.dart';

import '../services/isar_service.dart';
import '../theme/app_design_tokens.dart';

/// Sheet do calendário, fixo e sempre visível na base da tela
/// (estilo Google Maps) — não é mais um modal.
///
/// Dois estados, com transição suave (crossfade) entre eles:
/// - Recolhido (extent perto de kSheetMinExtent): seletor rápido
///   horizontal, compacto, mostrando ~7-10 dias de uma vez.
/// - Expandido (extent >= kSheetMidExtent): VisaoMesLista, uma lista
///   vertical fluida com todos os dias do mês, sem grade.
///
/// Usa `snap: true` + `snapSizes` para um snap inteligente (baseado em
/// posição E velocidade do gesto, comportamento nativo do
/// DraggableScrollableSheet do Flutter).
class CalendarSheet extends StatefulWidget {
  const CalendarSheet({
    super.key,
    required this.dataSelecionada,
    required this.onDataSelecionada,
  });

  final DateTime dataSelecionada;
  final ValueChanged<DateTime> onDataSelecionada;

  @override
  State<CalendarSheet> createState() => _CalendarSheetState();
}

class _CalendarSheetState extends State<CalendarSheet> {
  final _sheetController = DraggableScrollableController();

  late DateTime _mesVisivel = DateTime(
    widget.dataSelecionada.year,
    widget.dataSelecionada.month,
  );
  Set<DateTime> _diasComEvento = {};
  double _extent = kSheetMinExtent;

  static const _meses = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];
  static const _diasSemanaAbrev = [
    'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom',
  ];

  bool get _expandido => _extent >= kSheetMidExtent;

  @override
  void initState() {
    super.initState();
    _sheetController.addListener(_onExtentChanged);
    _carregarIndicadores();
  }

  @override
  void dispose() {
    _sheetController.removeListener(_onExtentChanged);
    _sheetController.dispose();
    super.dispose();
  }

  void _onExtentChanged() {
    if (!_sheetController.isAttached) return;
    final novoExtent = _sheetController.size;
    // Só refaz o build quando cruza o limiar recolhido/expandido ou
    // quando a diferença é perceptível — evita rebuilds excessivos
    // durante o arraste.
    if ((novoExtent - _extent).abs() > 0.01) {
      setState(() => _extent = novoExtent);
    }
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

  void _selecionarData(DateTime dia) {
    widget.onDataSelecionada(dia);
    // Depois de escolher um dia na lista do mês (estado expandido),
    // recolhe o sheet suavemente pra voltar o foco pro Card "Hoje".
    if (_sheetController.isAttached) {
      _sheetController.animateTo(
        kSheetMinExtent,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: kSheetMinExtent,
      minChildSize: kSheetMinExtent,
      maxChildSize: kSheetMaxExtent,
      snap: true,
      snapSizes: const [kSheetMinExtent, kSheetMidExtent, kSheetMaxExtent],
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(kBorderRadius),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: kSheetBlurSigma,
              sigmaY: kSheetBlurSigma,
            ),
            child: Container(
              decoration: BoxDecoration(
                // Opacidade baixa — o degradê de fundo continua
                // visível de forma difusa através do blur intenso.
                color: Colors.white.withOpacity(kGlassOpacityMax),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(kBorderRadius),
                ),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      child: _expandido
                          ? _buildVisaoMesLista(scrollController)
                          : _buildSeletorRapido(scrollController),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // Estado recolhido: seletor rápido horizontal (7-10 dias visíveis)
  // ---------------------------------------------------------------------
  Widget _buildSeletorRapido(ScrollController scrollController) {
    final diasNoMes =
        DateTime(_mesVisivel.year, _mesVisivel.month + 1, 0).day;

    // O controller do sheet precisa estar conectado a ALGUM scrollable
    // pra o gesto de puxar pra cima funcionar mesmo em cima da lista
    // horizontal (que rola no eixo oposto). Um SingleChildScrollView
    // "mudo" (sem overflow vertical) cumpre esse papel.
    return SingleChildScrollView(
      key: const ValueKey('seletor_rapido'),
      controller: scrollController,
      child: SizedBox(
        height: 92,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // ~7 a 10 dias visíveis simultaneamente, dependendo da
            // largura da tela.
            final larguraItem =
                (MediaQuery.of(context).size.width / 8).clamp(38.0, 56.0);

            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: diasNoMes,
              itemBuilder: (context, index) {
                final dia = DateTime(
                  _mesVisivel.year, _mesVisivel.month, index + 1,
                );
                return _diaChip(dia, largura: larguraItem);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _diaChip(DateTime dia, {required double largura}) {
    final selecionado = dia.year == widget.dataSelecionada.year &&
        dia.month == widget.dataSelecionada.month &&
        dia.day == widget.dataSelecionada.day;
    final temEvento = _diasComEvento.any(
      (d) => d.day == dia.day && d.month == dia.month,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () => _selecionarData(dia),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: largura,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: selecionado
                ? kCorAcento.withOpacity(0.22)
                : Colors.white.withOpacity(0.03),
            border: Border.all(
              color: selecionado
                  ? kCorAcento.withOpacity(0.6)
                  : Colors.white.withOpacity(0.07),
              width: selecionado ? 1.3 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _diaSemanaAbrev(dia.weekday),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w300,
                  color: selecionado ? Colors.white : Colors.white38,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${dia.day}',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight:
                      selecionado ? FontWeight.bold : FontWeight.w300,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 3),
              if (temEvento)
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selecionado
                        ? kCorAcento
                        : Colors.white.withOpacity(0.5),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Estado expandido: VisaoMesLista — lista vertical, sem grade
  // ---------------------------------------------------------------------
  Widget _buildVisaoMesLista(ScrollController scrollController) {
    final diasNoMes =
        DateTime(_mesVisivel.year, _mesVisivel.month + 1, 0).day;

    return Column(
      key: const ValueKey('visao_mes_lista'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => _mudarMes(-1),
                icon: const Icon(Icons.chevron_left, color: Colors.white70),
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
                icon: const Icon(Icons.chevron_right, color: Colors.white70),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: diasNoMes,
            itemBuilder: (context, index) {
              final dia = DateTime(
                _mesVisivel.year, _mesVisivel.month, index + 1,
              );
              return _linhaDoMes(dia);
            },
          ),
        ),
      ],
    );
  }

  Widget _linhaDoMes(DateTime dia) {
    final selecionado = dia.year == widget.dataSelecionada.year &&
        dia.month == widget.dataSelecionada.month &&
        dia.day == widget.dataSelecionada.day;
    final temEvento = _diasComEvento.any(
      (d) => d.day == dia.day && d.month == dia.month,
    );
    final ehHoje = _ehMesmoDia(dia, DateTime.now());

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _selecionarData(dia),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            // Cartão individual flutuando — zero linha divisória rígida.
            borderRadius: BorderRadius.circular(16),
            color: selecionado
                ? kCorAcento.withOpacity(0.18)
                : Colors.white.withOpacity(0.05),
            border: selecionado
                ? Border.all(color: kCorAcento.withOpacity(0.5))
                : null,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: Text(
                  _diaSemanaAbrev(dia.weekday),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    color: Colors.white.withOpacity(0.55),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${dia.day}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: ehHoje ? FontWeight.bold : FontWeight.w300,
                  color: ehHoje ? kCorAcento : Colors.white,
                ),
              ),
              if (ehHoje) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: kCorAcento.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'hoje',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
              const Spacer(),
              // Indicação sutil de dias com eventos — um pontinho, nada
              // de números ou badges pesados.
              if (temEvento)
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kCorAcento.withOpacity(0.85),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _ehMesmoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _diaSemanaAbrev(int weekday) => _diasSemanaAbrev[weekday - 1];
}
