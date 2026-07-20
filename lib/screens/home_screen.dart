import 'package:flutter/material.dart';

import '../models/evento.dart';
import '../services/isar_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/calendar_sheet.dart';
import '../widgets/hero_day_card.dart';
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
    // Sem números gigantes no fundo — só uma frase minimalista logo
    // abaixo do Card "Hoje", em cinza quente pra harmonizar com o
    // degradê Deep Twilight.
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 20),
      child: Text(
        'Nada agendado. Um respiro no calendário.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: kCinzaQuente,
          fontSize: 15,
          fontWeight: FontWeight.w300,
          letterSpacing: 0.3,
          height: 1.4,
        ),
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
