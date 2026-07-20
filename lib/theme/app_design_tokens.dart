import 'package:flutter/material.dart';

/// Constantes de design compartilhadas — paleta "Deep Twilight" e
/// parâmetros do glassmorphism, usados em toda a HomeScreen, no
/// HeroDayCard, no CalendarSheet e no formulário de novo evento.
library app_design_tokens;

// --- Raio de borda padrão (Card Hoje, Sheet, formulário) ---
const double kBorderRadius = 24.0;

// --- Paleta "Deep Twilight" ---
/// Topo do gradiente de fundo do Scaffold.
const Color kGradienteTopo = Color(0xFF0F172A);

/// Base do gradiente de fundo do Scaffold.
const Color kGradienteBase = Color(0xFF1E1B4B);

/// Cor de acento (azul-índigo) — usada SÓ no destaque do dia atual
/// e em ícones/ações rápidas, nunca como preenchimento grande.
const Color kCorAcento = Color(0xFF818CF8);

/// Cinza quente usado no texto do estado vazio, para harmonizar com
/// o degradê noturno (não é um cinza frio/neutro).
const Color kCinzaQuente = Color(0xFFB8AFC2);

// --- Glassmorphism geral (cards, sheet) ---
/// Opacidade baixa para o fundo branco translúcido dos elementos de
/// vidro — o degradê de fundo continua sendo o protagonista visual.
const double kGlassOpacityMin = 0.05;
const double kGlassOpacityMax = 0.08;

// --- Glassmorphism específico do formulário (Novo Evento) ---
const double kFormGlassOpacity = 0.05;
const double kFormGlassBlur = 10.0;

// --- CalendarSheet (persistente, estilo Google Maps) ---
/// Extensão mínima — só o suficiente para não tapar o Card "Hoje"
/// nem a área central da tela.
const double kSheetMinExtent = 0.15;

/// Ponto de snap intermediário — também é o limiar (threshold) que
/// decide se mostramos o seletor rápido (recolhido) ou a lista do
/// mês inteira (expandido).
const double kSheetMidExtent = 0.5;

/// Extensão máxima ao puxar o sheet totalmente para cima.
const double kSheetMaxExtent = 0.85;

/// Blur do BackdropFilter do sheet — intenso, mas com opacidade de
/// fundo baixa, pra o degradê de trás continuar visível de forma difusa.
const double kSheetBlurSigma = 18.0;
