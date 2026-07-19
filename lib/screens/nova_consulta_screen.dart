import 'dart:ui';
import 'package:flutter/material.dart';

import '../models/evento.dart';
import '../services/isar_service.dart';
import '../theme/apple_calendar_colors.dart';

/// Tela cheia de criação de evento — "NovaConsultaScreen".
///
/// Visual: BackdropFilter (blur) sobre a tela anterior, formulário
/// composto por GlassCards verticais. Sem grade, sem tabela.
/// Ao salvar, chama IsarService.instance.salvarEvento(...) — 100% local.
class NovaConsultaScreen extends StatefulWidget {
  const NovaConsultaScreen({super.key, required this.dataInicial});

  /// Data pré-selecionada (normalmente o dia que estava aberto na HomeScreen).
  final DateTime dataInicial;

  /// Abre a tela como uma rota não-opaca, para que o BackdropFilter
  /// desta tela borre de fato o conteúdo da tela anterior por baixo.
  static Future<bool?> show(BuildContext context, {DateTime? dataInicial}) {
    return Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        opaque: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (context, animation, __) {
          return FadeTransition(
            opacity: animation,
            child: NovaConsultaScreen(
              dataInicial: dataInicial ?? DateTime.now(),
            ),
          );
        },
      ),
    );
  }

  @override
  State<NovaConsultaScreen> createState() => _NovaConsultaScreenState();
}

class _NovaConsultaScreenState extends State<NovaConsultaScreen> {
  final _tituloController = TextEditingController();
  final _localController = TextEditingController();

  late DateTime _data = widget.dataInicial;
  TimeOfDay _horaInicio = TimeOfDay.now();
  TimeOfDay? _horaFim;

  // 5 círculos, estilo seletor rápido do Apple Calendar.
  // A paleta completa (11 cores) continua disponível em
  // AppleCalendarColors.paleta, caso queira expandir para mais opções.
  static const _coresRapidas = [
    AppleCalendarColors.vermelho,
    AppleCalendarColors.laranja,
    AppleCalendarColors.verde,
    AppleCalendarColors.azul,
    AppleCalendarColors.roxo,
  ];

  Color _corSelecionada = AppleCalendarColors.azul;
  bool _salvando = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _localController.dispose();
    super.dispose();
  }

  String _formatarData(DateTime d) {
    const meses = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez',
    ];
    return '${d.day} de ${meses[d.month - 1]} de ${d.year}';
  }

  String _formatarHora(TimeOfDay h) {
    final hh = h.hour.toString().padLeft(2, '0');
    final mm = h.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _escolherData() async {
    final selecionada = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selecionada != null) setState(() => _data = selecionada);
  }

  Future<void> _escolherHora({required bool inicio}) async {
    final selecionada = await showTimePicker(
      context: context,
      initialTime: inicio ? _horaInicio : (_horaFim ?? _horaInicio),
    );
    if (selecionada == null) return;
    setState(() {
      if (inicio) {
        _horaInicio = selecionada;
      } else {
        _horaFim = selecionada;
      }
    });
  }

  Future<void> _salvar() async {
    if (_tituloController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dê um título ao evento antes de salvar.')),
      );
      return;
    }

    setState(() => _salvando = true);

    final inicio = DateTime(
      _data.year, _data.month, _data.day,
      _horaInicio.hour, _horaInicio.minute,
    );
    final fim = _horaFim != null
        ? DateTime(_data.year, _data.month, _data.day, _horaFim!.hour, _horaFim!.minute)
        : null;

    final evento = Evento.novo(
      titulo: _tituloController.text.trim(),
      dataHoraInicio: inicio,
      dataHoraFim: fim,
      local: _localController.text.trim().isEmpty
          ? null
          : _localController.text.trim(),
      corTint: _corSelecionada.value,
    );

    // 100% local — nenhuma chamada de rede acontece aqui.
    await IsarService.instance.salvarEvento(evento);

    if (!mounted) return;
    Navigator.of(context).pop(true); // retorna true para a tela chamadora recarregar
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Blur de fato sobre o conteúdo da tela anterior (rota opaque:false).
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
            child: Container(color: Colors.black.withOpacity(0.35)),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                    children: [
                      _glassCardWrapper(
                        child: TextField(
                          controller: _tituloController,
                          autofocus: true,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: const InputDecoration.collapsed(
                            hintText: 'Título do evento',
                            hintStyle: TextStyle(color: Colors.white38),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _glassCardWrapper(
                              onTap: _escolherData,
                              child: _buildLinhaIcone(
                                icone: Icons.calendar_today_rounded,
                                texto: _formatarData(_data),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _glassCardWrapper(
                              onTap: () => _escolherHora(inicio: true),
                              child: _buildLinhaIcone(
                                icone: Icons.schedule_rounded,
                                texto: 'Início  ${_formatarHora(_horaInicio)}',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _glassCardWrapper(
                              onTap: () => _escolherHora(inicio: false),
                              child: _buildLinhaIcone(
                                icone: Icons.schedule_outlined,
                                texto: _horaFim != null
                                    ? 'Fim  ${_formatarHora(_horaFim!)}'
                                    : 'Fim  --:--',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _glassCardWrapper(
                        child: TextField(
                          controller: _localController,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                          decoration: const InputDecoration.collapsed(
                            hintText: 'Local (opcional)',
                            hintStyle: TextStyle(color: Colors.white38),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _glassCardWrapper(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Categoria',
                              style: TextStyle(color: Colors.white54, fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: _coresRapidas.map((cor) {
                                final selecionada = cor.value == _corSelecionada.value;
                                return GestureDetector(
                                  onTap: () => setState(() => _corSelecionada = cor),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: selecionada ? 40 : 34,
                                    height: selecionada ? 40 : 34,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: cor,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: selecionada ? 2.5 : 0,
                                      ),
                                      boxShadow: selecionada
                                          ? [
                                              BoxShadow(
                                                color: cor.withOpacity(0.6),
                                                blurRadius: 10,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: selecionada
                                        ? const Icon(Icons.check,
                                            color: Colors.white, size: 18)
                                        : null,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        elevation: 4,
        onPressed: _salvando ? null : _salvar,
        child: _salvando
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.black54),
              )
            : const Icon(Icons.check_rounded, color: Colors.black87, size: 28),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
          ),
          const Text(
            'Novo evento',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 48), // balanceia o IconButton da esquerda
        ],
      ),
    );
  }

  Widget _buildLinhaIcone({required IconData icone, required String texto}) {
    return Row(
      children: [
        Icon(icone, color: Colors.white70, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(color: Colors.white, fontSize: 14.5),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// GlassCard reutilizável para os campos do formulário — mesma
  /// linguagem visual do GlassCard usado na listagem de eventos.
  Widget _glassCardWrapper({required Widget child, VoidCallback? onTap}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: Colors.white.withOpacity(0.12),
              border: Border.all(color: Colors.white.withOpacity(0.22)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
