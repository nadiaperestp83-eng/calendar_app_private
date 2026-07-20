import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/home_screen.dart';
import 'services/isar_service.dart';
import 'theme/app_design_tokens.dart';

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
        // Inter é a fonte do Google Fonts com a métrica mais próxima da
        // SF Pro (fonte nativa do iOS Calendar). Lembrete: por vir do
        // pacote google_fonts, ela é baixada da internet no 1º uso —
        // você optou por manter assim (ver aviso no pubspec.yaml).
        textTheme: GoogleFonts.interTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: kCorAcento,
          brightness: Brightness.dark,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
