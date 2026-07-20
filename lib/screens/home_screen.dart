import 'package:flutter/material.dart';

import '../models/evento.dart';
import '../services/isar_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/calendar_sheet.dart';
import '../widgets/hero_day_card.dart';
import '../widgets/daily_quotes.dart';
import '../theme/app_design_tokens.dart';
import 'nova_consulta_screen.dart';

/// Tela inicial "Focus-First".
///
/// Abre direto no dia atual — sem grade mensal. Fundo em degradê
/// "Deep Twilight" (sem preto opaco). O calendário completo do mês
/// vive num CalendarSheet persistente, ancorado na base da tela
/// (estilo Google Maps) — não é mais um modal sob demanda.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _dataSelecionada = DateTime.now();
  List<Evento> _eventosDoDia = [];
  bool _carregando = true;
  double _sheetExtent = kSheetMinExtent;

  static const _diasSemana = [
    'Domingo', 'Segunda-feira', 'Terça-feira', 'Quarta-feira',
    'Quinta-feira', 'Sexta-feira', 'Sábado',
  ];
  static const _meses = [
    'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
    'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
  ];

  @override
  void initState() {
    super.initState();
    _carregarEventos();
  }

  Future<void> _carregarEventos() async {
    setState(() => _carregando = true);
    final eventos = await IsarService.instance.getByDate(_dataSelecionada);
    if (!mounted) return;
    setState(() {
      _eventosDoDia = eventos;
      _carregando = false;
    });
  }

  bool _ehHoje(DateTime data) {
    final agora = DateTime.now();
    return data.year == agora.year &&
        data.month == agora.month &&
        data.day == agora.day;
  }

  @override
  Widget build(BuildContext context) {
    final alturaTela = MediaQuery.of(context).size.height;
    // Espaço reservado no fim da lista pra o conteúdo não ficar
    // escondido atrás do CalendarSheet recolhido (sempre visível).
    final espacoParaSheet = alturaTela * kSheetMinExtent + 40;

    return Scaffold(
      // Sem Colors.black — o fundo é o Container com o degradê abaixo.
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kGradienteTopo, kGradienteBase],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: RefreshIndicator(
                onRefresh: _carregarEventos,
                color: Colors.white,
                backgroundColor: kGradienteBase,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(child: _buildHero()),
                    // Respiro mínimo de 30px entre o Card "Hoje" e
                    // qualquer outro elemento (Hero já tem 8px de
                    // padding inferior, então completamos com 22px).
                    const SliverToBoxAdapter(child: SizedBox(height: 22)),
                    if (_carregando)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.white54,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      )
                    else if (_eventosDoDia.isEmpty)
                      SliverToBoxAdapter(child: _buildEstadoVazio())
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final evento = _eventosDoDia[index];
                            return GlassCard(
                              evento: evento,
                              onLongPress: () => _confirmarExclusao(evento),
                            );
                          },
                          childCount: _eventosDoDia.length,
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: SizedBox(height: espacoParaSheet),
                    ),
                  ],
                ),
              ),
            ),

            // CalendarSheet fixo na base — sempre visível, muda de
            // tamanho ao arrastar (snap inteligente entre os 3 pontos).
            CalendarSheet(
              dataSelecionada: _dataSelecionada,
              onDataSelecionada: (novaData) {
                setState(() => _dataSelecionada = novaData);
                _carregarEventos();
              },
              onExtentChanged: (extent) {
                setState(() => _sheetExtent = extent);
              },
            ),
          ],
        ),
      ),

      // Só o botão de novo evento — a navegação de data agora é
      // sempre o CalendarSheet ancorado embaixo.
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white.withOpacity(0.92),
        onPressed: _abrirNovoEvento,
        child: const Icon(Icons.add_rounded, color: Colors.black87),
      ),
    );
  }

  Widget _buildHero() {
    final ehHoje = _ehHoje(_dataSelecionada);
    final titulo = ehHoje ? 'Hoje' : _diasSemana[_dataSelecionada.weekday % 7];
    final subtitulo =
        '${_dataSelecionada.day} de ${_meses[_dataSelecionada.month - 1]} de ${_dataSelecionada.year}';

    return HeroDayCard(
      titulo: titulo,
      subtitulo: subtitulo,
      quantidadeEventos: _eventosDoDia.length,
    );
  }

  Widget _buildEstadoVazio() {
    // Só quando não há eventos: exibe a DailyQuotes, com fade
    // controlado pela extensão do CalendarSheet — some suavemente
    // quando o usuário expande o sheet, dando espaço total pro
    // calendário (a frase ficaria coberta de qualquer forma).
    final sheetExpandido = _sheetExtent >= kSheetMidExtent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: sheetExpandido
            ? const SizedBox(key: ValueKey('vazio_oculto'), height: 1)
            : const DailyQuotes(key: ValueKey('daily_quote')),
      ),
    );
  }

  void _confirmarExclusao(Evento evento) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kGradienteBase,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kBorderRadius),
        ),
        title: const Text('Excluir evento?',
            style: TextStyle(color: Colors.white)),
        content: Text(evento.titulo,
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await IsarService.instance.delete(evento.id);
              if (mounted) Navigator.pop(context);
              _carregarEventos();
            },
            child: const Text('Excluir',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirNovoEvento() async {
    final salvou = await NovaConsultaScreen.show(
      context,
      dataInicial: _dataSelecionada,
    );
    if (salvou == true) {
      _carregarEventos();
    }
  }
}
