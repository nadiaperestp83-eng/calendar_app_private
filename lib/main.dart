import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/isar_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Abre o banco local ANTES de renderizar a UI.
  // Nenhuma chamada de rede acontece aqui — 100% offline.
  await IsarService.instance.db;

  runApp(const CalendarApp());
}

class CalendarApp extends StatelessWidget {
  const CalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calendar App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'SF Pro Display', // troque pela fonte que preferir
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7B6EF6),
          brightness: Brightness.dark,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
