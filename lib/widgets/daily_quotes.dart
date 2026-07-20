import 'package:flutter/material.dart';
import 'package:daily_quotes/daily_quotes.dart';

/// Exibida no lugar do estado vazio quando o dia selecionado não tem
/// nenhum evento — um convite ao descanso/reflexão, não um "vazio".
///
/// Usa o pacote `daily_quotes` (pub.dev, ^0.0.1) — 100% local/offline,
/// sem chamada de rede. A frase é sorteada uma única vez na criação do
/// widget (initState/late final) e fica fixa enquanto ele existir na
/// árvore, evitando que ela mude a cada rebuild/AnimatedSwitcher.
class DailyQuotes extends StatefulWidget {
  const DailyQuotes({super.key});

  @override
  State<DailyQuotes> createState() => _DailyQuotesState();
}

class _DailyQuotesState extends State<DailyQuotes> {
  // getRandomQuote() do pacote daily_quotes — sorteada uma vez só.
  late final String _frase = getRandomQuote().toString();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Text(
        _frase,
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
