import 'package:flutter/material.dart';

import '../models/evento.dart';
import '../services/isar_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/date_selector_sheet.dart';
import '../widgets/hero_day_card.dart';
import 'nova_consulta_screen.dart';

/// Tela inicial "Focus-First".
///
/// Abre direto no dia atual — sem grade mensal. A grade só aparece
/// se o usuário pedir, via swipe-down ou pelo botão flutuante,
/// como um seletor de data discreto (DateSelectorSheet).
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

  void _abrirSeletorDeData() {
    DateSelectorSheet.show(
      context,
      dataSelecionada: _dataSelecionada,
      onDataSelecionada: (novaData) {
        setState(() => _dataSelecionada = novaData);
        _carregarEventos();
      },
    );
  }

  bool _ehHoje(DateTime data) {
    final agora = DateTime.now();
    return data.year == agora.year &&
        data.month == agora.month &&
        data.day == agora.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fundo: gradiente sutil gerado por código (sem asset de imagem).
          // Neutro e escuro, no espírito do Apple Calendar em modo escuro,
          // com só um leve toque de cor para o blur do glass ter o que
          // desfocar. Nenhum arquivo externo é necessário.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1C1C1E), // cinza-quase-preto (system background dark)
                  Color(0xFF232326),
                  Color(0xFF17171A),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
            child: SizedBox.expand(),
          ),

          // Gesto de swipe-down para revelar o seletor de mês
          GestureDetector(
            onVerticalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0) > 200) {
                _abrirSeletorDeData();
              }
            },
            behavior: HitTestBehavior.translucent,
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: _carregarEventos,
                color: Colors.white,
                backgroundColor: Colors.black.withOpacity(0.4),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(child: _buildHero()),
                    if (_carregando)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.white70,
                          ),
                        ),
                      )
                    else if (_eventosDoDia.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEstadoVazio(),
                      )
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
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // Botão flutuante minimalista — alternativa ao swipe-down
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'seletor_data',
            mini: true,
            backgroundColor: Colors.white.withOpacity(0.18),
            elevation: 0,
            onPressed: _abrirSeletorDeData,
            child: const Icon(Icons.expand_less_rounded, color: Colors.white),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'novo_evento',
            backgroundColor: Colors.white.withOpacity(0.9),
            onPressed: _abrirNovoEvento,
            child: const Icon(Icons.add_rounded, color: Colors.black87),
          ),
        ],
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.spa_outlined,
                color: Colors.white.withOpacity(0.6), size: 44),
            const SizedBox(height: 16),
            Text(
              'Nenhum compromisso por aqui.\nAproveite o dia livre.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarExclusao(Evento evento) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
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
    // Tela cheia dedicada (NovaConsultaScreen), com blur real sobre
    // esta tela e formulário completo (data, hora, local, categoria).
    final salvou = await NovaConsultaScreen.show(
      context,
      dataInicial: _dataSelecionada,
    );
    if (salvou == true) {
      _carregarEventos();
    }
  }
}
