import 'package:flutter/material.dart';

/// Paleta de cores de calendário no estilo Apple/iOS.
/// Usada como opções de `corTint` ao criar um [Evento].
class AppleCalendarColors {
  AppleCalendarColors._();

  static const Color vermelho = Color(0xFFFF3B30);
  static const Color laranja = Color(0xFFFF9500);
  static const Color amarelo = Color(0xFFFFCC00);
  static const Color verde = Color(0xFF34C759);
  static const Color menta = Color(0xFF00C7BE);
  static const Color azulClaro = Color(0xFF32ADE6);
  static const Color azul = Color(0xFF007AFF);
  static const Color indigo = Color(0xFF5856D6);
  static const Color roxo = Color(0xFFAF52DE);
  static const Color rosa = Color(0xFFFF2D55);
  static const Color marrom = Color(0xFFA2845E);

  /// Lista com nome + cor, na ordem usada pelo seletor de cor do evento.
  static const List<MapEntry<String, Color>> paleta = [
    MapEntry('Vermelho', vermelho),
    MapEntry('Laranja', laranja),
    MapEntry('Amarelo', amarelo),
    MapEntry('Verde', verde),
    MapEntry('Menta', menta),
    MapEntry('Azul-claro', azulClaro),
    MapEntry('Azul', azul),
    MapEntry('Índigo', indigo),
    MapEntry('Roxo', roxo),
    MapEntry('Rosa', rosa),
    MapEntry('Marrom', marrom),
  ];

  /// Cor padrão quando o evento ainda não teve cor escolhida.
  static const Color padrao = azul;
}
