import 'package:flutter/material.dart';

import '../models/evento.dart';
import '../services/isar_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/date_selector_sheet.dart';

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
          // Imagem de fundo (estática ou dinâmica conforme período do dia).
          // Troque por Image.network/Image.file se quiser fundo dinâmico —
          // desde que a fonte continue local, sem telemetria embutida.
          Image.asset(
            'assets/images/fundo_dia.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF3A1C71), Color(0xFFD76D77)],
                ),
              ),
            ),
          ),
          // Camada de escurecimento para legibilidade do texto
          Container(color: Colors.black.withOpacity(0.25)),

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
                    SliverToBoxAdapter(child: _buildCabecalho()),
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

  Widget _buildCabecalho() {
    final ehHoje = _ehHoje(_dataSelecionada);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 90, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ehHoje ? 'Hoje' : _diasSemana[_dataSelecionada.weekday % 7],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_dataSelecionada.day} de ${_meses[_dataSelecionada.month - 1]} de ${_dataSelecionada.year}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 15,
            ),
          ),
        ],
      ),
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

  void _abrirNovoEvento() {
    // Placeholder simples de criação rápida — substitua por uma tela
    // dedicada (ex.: NovoEventoScreen) seguindo a mesma estética glass.
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final controller = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Título do evento',
                  hintStyle: TextStyle(color: Colors.white38),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (controller.text.trim().isEmpty) return;
                  final novo = Evento.novo(
                    titulo: controller.text.trim(),
                    dataHoraInicio: DateTime(
                      _dataSelecionada.year,
                      _dataSelecionada.month,
                      _dataSelecionada.day,
                      DateTime.now().hour,
                      DateTime.now().minute,
                    ),
                  );
                  await IsarService.instance.add(novo);
                  if (mounted) Navigator.pop(context);
                  _carregarEventos();
                },
                child: const Text('Adicionar'),
              ),
            ],
          ),
        );
      },
    );
  }
}
