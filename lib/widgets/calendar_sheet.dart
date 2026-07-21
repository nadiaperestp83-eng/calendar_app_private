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
    this.onExtentChanged,
  });

  final DateTime dataSelecionada;
  final ValueChanged<DateTime> onDataSelecionada;

  /// Notifica a extensão atual do sheet (0.0–1.0) a cada mudança
  /// perceptível — usado pela HomeScreen para o fade da DailyQuotes.
  final ValueChanged<double>? onExtentChanged;

  @override
  State<CalendarSheet> createState() => _CalendarSheetState();
}

class _CalendarSheetState extends State<CalendarSheet> {
  final _sheetController = DraggableScrollableController();

  /// Referência ao ScrollController que o `DraggableScrollableSheet`
  /// entrega no `builder` — guardamos aqui pra poder zerar a posição
  /// dele ao trocar de estado (ver `_onExtentChanged`).
  ScrollController? _innerScrollController;

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
      final expandidoAntes = _expandido;
      setState(() => _extent = novoExtent);
      widget.onExtentChanged?.call(novoExtent);

      // O seletor rápido (recolhido) rola HORIZONTAL e a grade do mês
      // (expandida) rola VERTICAL, mas os dois compartilham o MESMO
      // ScrollController do DraggableScrollableSheet (necessário pro
      // gesto de puxar funcionar mesmo longe de uma lista). Ao trocar
      // de eixo, sobra o offset do widget anterior — e é isso que faz
      // o DraggableScrollableSheet achar que o conteúdo não está na
      // borda, recusando ceder o próximo gesto de arraste pra baixo
      // (sensação de "travado"). Zeramos a posição sempre que o estado
      // recolhido/expandido muda, pra cada scrollable sempre começar
      // limpo no seu próprio eixo.
      if (expandidoAntes != _expandido) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final controller = _innerScrollController;
          if (controller != null && controller.hasClients) {
            controller.jumpTo(0);
          }
        });
      }
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
        _innerScrollController = scrollController;
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
      // Sem bounce: overscroll elástico (o padrão em iOS) faz o gesto
      // de arraste "brigar" com o redimensionamento do sheet perto da
      // borda — Clamping deixa a decisão de quem responde ao gesto
      // (sheet vs. scroll) mais previsível.
      physics: const ClampingScrollPhysics(),
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
  // Estado expandido: VisaoMesGrade — grade de cápsulas flutuantes,
  // 7 colunas, zero linha/borda de tabela.
  // ---------------------------------------------------------------------
  Widget _buildVisaoMesLista(ScrollController scrollController) {
    return Column(
      key: const ValueKey('visao_mes_grade'),
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
        // Cabeçalho fixo dos dias da semana — dá o alinhamento das
        // 7 colunas sem virar linha de tabela (sem borda/fundo).
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          child: Row(
            children: _diasSemanaAbrev
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w300,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        Expanded(
          // Gesto de swipe lateral pra trocar de mês, além dos chevrons.
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              final velocidade = details.primaryVelocity ?? 0;
              if (velocidade < -250) {
                _mudarMes(1);
              } else if (velocidade > 250) {
                _mudarMes(-1);
              }
            },
            behavior: HitTestBehavior.translucent,
            // AnimatedSwitcher com crossfade: ao trocar de mês, o que
            // muda é o conteúdo (números), não a estrutura da grade —
            // a moldura de 7 colunas permanece visualmente estável.
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: _buildGradeDoMes(scrollController),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradeDoMes(ScrollController scrollController) {
    final diasNoMes =
        DateTime(_mesVisivel.year, _mesVisivel.month + 1, 0).day;
    final primeiroDia = DateTime(_mesVisivel.year, _mesVisivel.month, 1);
    // weekday: segunda=1 ... domingo=7. Nossa semana começa na segunda,
    // então o offset de células vazias antes do dia 1 é (weekday - 1).
    final offset = primeiroDia.weekday - 1;

    return GridView.builder(
      key: ValueKey('grade_${_mesVisivel.year}_${_mesVisivel.month}'),
      controller: scrollController,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        // Espaçamento ENTRE cápsulas maior que o respiro interno de
        // cada uma — é isso que evita a leitura de "grade/tabela".
        mainAxisSpacing: 12,
        crossAxisSpacing: 8,
        childAspectRatio: 0.82,
      ),
      itemCount: offset + diasNoMes,
      itemBuilder: (context, index) {
        if (index < offset) {
          // Célula vazia antes do dia 1 — sem cápsula, sem número.
          return const SizedBox.shrink();
        }
        final dia = DateTime(
          _mesVisivel.year, _mesVisivel.month, index - offset + 1,
        );
        return _capsulaDoDia(dia);
      },
    );
  }

  Widget _capsulaDoDia(DateTime dia) {
    final selecionado = dia.year == widget.dataSelecionada.year &&
        dia.month == widget.dataSelecionada.month &&
        dia.day == widget.dataSelecionada.day;
    final temEvento = _diasComEvento.any(
      (d) => d.day == dia.day && d.month == dia.month,
    );
    final ehHoje = _ehMesmoDia(dia, DateTime.now());

    // Hierarquia de cor:
    // 1) Hoje → preenchimento sólido no acento índigo.
    // 2) Tem evento → preenchimento suave (0.15) + pontinho embaixo.
    // 3) Vazio → sem fundo, só o número com opacidade baixa (0.3).
    Color corFundo;
    Color corTexto;
    FontWeight peso;
    if (ehHoje) {
      corFundo = kCorAcento;
      corTexto = Colors.white;
      peso = FontWeight.bold;
    } else if (temEvento) {
      corFundo = kCorAcento.withOpacity(0.15);
      corTexto = Colors.white;
      peso = FontWeight.w400;
    } else {
      corFundo = Colors.transparent;
      corTexto = Colors.white.withOpacity(0.3);
      peso = FontWeight.w300;
    }

    return GestureDetector(
      onTap: () => _selecionarData(dia),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: corFundo,
          // Anel de seleção sutil, independente da categoria — indica
          // qual dia está ativo sem quebrar a hierarquia de cor acima.
          border: selecionado && !ehHoje
              ? Border.all(color: Colors.white.withOpacity(0.6), width: 1.4)
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '${dia.day}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: peso,
                color: corTexto,
              ),
            ),
            if (temEvento && !ehHoje)
              const Positioned(
                bottom: 6,
                child: SizedBox(
                  width: 4,
                  height: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kCorAcento,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _ehMesmoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _diaSemanaAbrev(int weekday) => _diasSemanaAbrev[weekday - 1];
}
