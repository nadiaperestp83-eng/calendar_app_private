/// Constantes de design compartilhadas entre os widgets glassmorphic,
/// para manter a harmonia visual "nível Pro" pedida:
/// mesmo raio de borda em todo o app, e mesmos parâmetros de vidro
/// (opacidade + blur) nos formulários.
library app_design_tokens;

/// Raio de borda padrão usado no Card "Hoje", nos cards do
/// DateSelectorSheet e no formulário de Novo Evento.
const double kBorderRadius = 24.0;

/// Opacidade do fundo branco translúcido nos GlassCards de formulário
/// (NovaConsultaScreen) — bem sutil, para um efeito de "flutuação".
const double kFormGlassOpacity = 0.05;

/// Sigma do blur (X e Y) aplicado via BackdropFilter nos formulários.
const double kFormGlassBlur = 10.0;
