/// Nomes das famílias tipográficas declaradas em `pubspec.yaml`.
///
/// Os arquivos ficam em `assets/fonts/` e são baixados por
/// `tool/fetch_fonts.ps1` (licença OFL 1.1, textos incluídos na mesma pasta).
abstract final class AppFonts {
  /// Títulos e números de destaque. Fonte variável (eixo `wght`).
  static const String display = 'Unbounded';

  /// Texto corrente e botões.
  static const String body = 'IBM Plex Sans';

  /// Rótulos, contadores e valores tabulares.
  static const String mono = 'IBM Plex Mono';
}
