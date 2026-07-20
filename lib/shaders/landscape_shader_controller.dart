import 'dart:ui' as ui;

/// Compila o shader `assets/shaders/landscape.frag` uma única vez por
/// execução do app e reaproveita o [ui.FragmentProgram] resultante.
///
/// `FragmentProgram.fromAsset` já faz cache interno no engine, mas manter
/// um singleton em Dart evita disparar múltiplos `Future`s concorrentes
/// (ex: se vários `HeroDayCard` existissem na árvore ao mesmo tempo) e dá
/// um único ponto para pré-carregar o shader no boot do app.
class LandscapeShaderController {
  LandscapeShaderController._();

  static Future<ui.FragmentProgram>? _programFuture;

  /// Caminho do asset — precisa bater com o declarado em `pubspec.yaml`
  /// na seção `flutter > shaders`.
  static const String assetPath = 'assets/shaders/landscape.frag';

  /// Retorna o [ui.FragmentProgram] já compilado, carregando-o (uma única
  /// vez) na primeira chamada.
  static Future<ui.FragmentProgram> program() {
    return _programFuture ??= ui.FragmentProgram.fromAsset(assetPath);
  }

  /// Chame em `main()` (antes de `runApp`) para começar a compilar o
  /// shader durante o splash/boot, evitando qualquer frame em branco na
  /// primeira vez que o `HeroDayCard` aparecer na tela.
  ///
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await LandscapeShaderController.preload();
  ///   runApp(const MyApp());
  /// }
  /// ```
  static Future<void> preload() => program();
}
