import 'package:flutter/material.dart';

/// Exibida no lugar do estado vazio quando o dia selecionado não tem
/// nenhum evento — um convite ao descanso/reflexão, não um "vazio".
///
/// A frase é escolhida de forma determinística a partir do dia do ano,
/// então ela não muda a cada rebuild, mas varia dia a dia.
class DailyQuotes extends StatelessWidget {
  const DailyQuotes({super.key, this.data});

  /// Data usada para escolher a frase. Se omitida, usa hoje.
  final DateTime? data;

  static const List<String> _frases = [
    'A simplicidade é o último grau de sofisticação.',
    'Um dia livre também é produtivo.',
    'Nada agendado. Só espaço pra respirar.',
    'O silêncio na agenda também é um presente.',
    'Menos compromissos, mais presença.',
    'Hoje o tempo é todo seu.',
    'Descansar também está na lista.',
    'Um respiro no calendário.',
  ];

  @override
  Widget build(BuildContext context) {
    final referencia = data ?? DateTime.now();
    final indice = referencia.difference(DateTime(referencia.year)).inDays %
        _frases.length;
    final frase = _frases[indice];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Text(
        frase,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 16,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w300,
          letterSpacing: 0.3,
          height: 1.5,
        ),
      ),
    );
  }
}
