import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Tipos de cenário que o shader sabe desenhar. O valor numérico é o que
/// vai para o uniform `uScenario` no GLSL — não reordene sem atualizar o
/// `.frag`.
enum LandscapeScenario {
  montanhas(0.0),
  colinasComVegetacao(1.0),
  formasOrganicas(2.0);

  const LandscapeScenario(this.uniformValue);
  final double uniformValue;
}

/// Períodos do dia — reaproveita a mesma ideia do `LandscapePainter`
/// original, só que agora alimenta o shader em vez de um `Path` manual.
enum PeriodoDoDia { madrugada, manha, tarde, entardecer, noite }

PeriodoDoDia periodoAtual(DateTime agora) {
  final h = agora.hour;
  if (h >= 5 && h < 8) return PeriodoDoDia.madrugada;
  if (h >= 8 && h < 12) return PeriodoDoDia.manha;
  if (h >= 12 && h < 17) return PeriodoDoDia.tarde;
  if (h >= 17 && h < 20) return PeriodoDoDia.entardecer;
  return PeriodoDoDia.noite;
}

/// Todos os parâmetros que o fragment shader precisa para desenhar um
/// frame da paisagem. Construa um novo `LandscapeParams` sempre que a
/// data ou o período do dia mudar — os valores são baratos de calcular.
@immutable
class LandscapeParams {
  const LandscapeParams({
    required this.seed,
    required this.scenario,
    required this.sunDir,
    required this.skyTop,
    required this.skyBottom,
    required this.grassColor,
    required this.rockColor,
    required this.hazeColor,
    required this.sunColor,
    required this.isNight,
  });

  final double seed;
  final LandscapeScenario scenario;
  final Offset sunDir;
  final Color skyTop;
  final Color skyBottom;
  final Color grassColor;
  final Color rockColor;
  final Color hazeColor;
  final Color sunColor;
  final bool isNight;

  /// Gera os parâmetros do dia a partir de uma [DateTime].
  ///
  /// A seed é o número de dias desde uma época fixa — assim ela muda uma
  /// vez por dia e é estável durante o dia inteiro (o usuário não vê o
  /// cenário "pulando" a cada rebuild). O [LandscapeScenario] também é
  /// sorteado a partir dessa mesma seed, então tanto o "tipo" de paisagem
  /// quanto os detalhes do terreno mudam todo dia, mas de forma
  /// determinística (mesmo dia = mesma paisagem, sempre).
  factory LandscapeParams.fromDate(DateTime data) {
    final dias = data.difference(DateTime(2020, 1, 1)).inDays;
    final rnd = math.Random(dias);

    final scenario = LandscapeScenario
        .values[rnd.nextInt(LandscapeScenario.values.length)];

    // Seed "fina" (float) para variar os detalhes do terreno dentro da
    // mesma família de cenário — deriva do mesmo rnd para manter
    // determinismo por dia.
    final seedFino = rnd.nextDouble() * 1000.0;

    final periodo = periodoAtual(data);
    return LandscapeParams._paraPeriodo(
      seed: seedFino,
      scenario: scenario,
      periodo: periodo,
    );
  }

  factory LandscapeParams._paraPeriodo({
    required double seed,
    required LandscapeScenario scenario,
    required PeriodoDoDia periodo,
  }) {
    final isNight =
        periodo == PeriodoDoDia.noite || periodo == PeriodoDoDia.madrugada;

    switch (periodo) {
      case PeriodoDoDia.madrugada:
        return LandscapeParams(
          seed: seed,
          scenario: scenario,
          sunDir: const Offset(-0.6, 0.5),
          skyTop: const Color(0xFF1E2140),
          skyBottom: const Color(0xFFD67A4D),
          grassColor: const Color(0xFF4B5D45),
          rockColor: const Color(0xFF3A3550),
          hazeColor: const Color(0xFFB98A63),
          sunColor: const Color(0xFFF3D9C4),
          isNight: isNight,
        );
      case PeriodoDoDia.manha:
        return LandscapeParams(
          seed: seed,
          scenario: scenario,
          sunDir: const Offset(0.55, 0.65),
          skyTop: const Color(0xFF3B82F6),
          skyBottom: const Color(0xFF7DD3FC),
          grassColor: const Color(0xFF5B8A4F),
          rockColor: const Color(0xFF6B7280),
          hazeColor: const Color(0xFFCFEBFA),
          sunColor: const Color(0xFFFFF6D9),
          isNight: isNight,
        );
      case PeriodoDoDia.tarde:
        return LandscapeParams(
          seed: seed,
          scenario: scenario,
          sunDir: const Offset(0.15, 0.85),
          skyTop: const Color(0xFF0284C7),
          skyBottom: const Color(0xFF38BDF8),
          grassColor: const Color(0xFF4E8A45),
          rockColor: const Color(0xFF5B6472),
          hazeColor: const Color(0xFFBEE7F7),
          sunColor: const Color(0xFFFFFFFF),
          isNight: isNight,
        );
      case PeriodoDoDia.entardecer:
        return LandscapeParams(
          seed: seed,
          scenario: scenario,
          sunDir: const Offset(-0.5, 0.35),
          skyTop: const Color(0xFFF97316),
          skyBottom: const Color(0xFFFDBA74),
          grassColor: const Color(0xFF6B5330),
          rockColor: const Color(0xFF5B3A3A),
          hazeColor: const Color(0xFFFCD5A5),
          sunColor: const Color(0xFFFFE3B0),
          isNight: isNight,
        );
      case PeriodoDoDia.noite:
        return LandscapeParams(
          seed: seed,
          scenario: scenario,
          sunDir: const Offset(-0.4, 0.55),
          skyTop: const Color(0xFF0F172A),
          skyBottom: const Color(0xFF1E293B),
          grassColor: const Color(0xFF283220),
          rockColor: const Color(0xFF23222E),
          hazeColor: const Color(0xFF161B33),
          sunColor: const Color(0xFFE8ECF7), // cor da lua
          isNight: isNight,
        );
    }
  }
}
