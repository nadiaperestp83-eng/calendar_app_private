import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Teste de sanidade simples — não depende do Isar nem de inicialização
// de banco, só garante que o pipeline de testes do CI tem algo pra
// rodar e que widgets básicos do app renderizam sem quebrar.
void main() {
  testWidgets('Renderiza um texto simples sem erros', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Hoje')),
        ),
      ),
    );

    expect(find.text('Hoje'), findsOneWidget);
  });
}
