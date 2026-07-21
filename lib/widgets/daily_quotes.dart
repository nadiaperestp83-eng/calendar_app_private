import 'package:flutter/material.dart';
import 'package:daily_quotes/daily_quotes.dart' as pkg;

/// Exibida no lugar do estado vazio quando o dia selecionado não tem
/// nenhum evento — um convite ao descanso/reflexão, não um "vazio".
///
/// Antes tínhamos uma lista local em PT-BR porque o pacote `daily_quotes`
/// original do pub.dev tinha a `getRandomQuote()` anunciada no README mas
/// não exportada de verdade. Isso foi corrigido no fork próprio
/// (`package:daily_quotes` via git, ver pubspec.yaml), então agora usamos
/// a função de lá.
///
/// NOTA: `getRandomQuote()` é aleatória a cada chamada (não determinística
/// por dia, diferente da lista antiga). Por isso a frase é sorteada uma
/// vez em [initState] e guardada — assim ela não muda a cada rebuild do
/// card (ex: ao trocar de aba e voltar sem recriar o widget), mas pode
/// mudar se o widget for reconstruído do zero (trocar de dia selecionado,
/// por exemplo). Se você quiser voltar a ter "uma frase fixa por dia",
/// me avisa que eu adiciono uma seed determinística por cima da função.
class DailyQuotes extends StatefulWidget {
  const DailyQuotes({super.key, this.data});

  /// Mantido por compatibilidade com quem já chama `DailyQuotes(data: ...)`
  /// — não é mais usado para escolher a frase (a função do pacote não
  /// aceita data), só existe pra não quebrar chamadas existentes.
  final DateTime? data;

  @override
  State<DailyQuotes> createState() => _DailyQuotesState();
}

class _DailyQuotesState extends State<DailyQuotes> {
  late final String _frase;

  @override
  void initState() {
    super.initState();
    // .toString() é só uma salvaguarda; locale: 'pt' pede explicitamente a
    // tradução em português do pacote (default dele é inglês, por
    // compatibilidade com quem já usava sem parâmetro).
    _frase = pkg.getRandomQuote(locale: 'pt').toString();
  }

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
