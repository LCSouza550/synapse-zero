import 'package:material_ui/material_ui.dart';
import 'package:synapsezero/presentation/theme/app_colors.dart';
import 'package:synapsezero/presentation/theme/app_fonts.dart';

/// Estilos nomeados, derivados das regras `font:` do protótipo.
///
/// Todos usam a cor de texto padrão (`AppColors.text`), exceto `label`.
/// Para destaque, use `copyWith(color: AppColors.alfa)` na tela.
abstract final class AppTextStyles {
  static TextStyle _display(
    double size,
    FontWeight weight, {
    double height = 1.3,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: AppFonts.display,
      fontSize: size,
      fontWeight: weight,
      // A Unbounded é uma fonte variável: o eixo `wght` é fixado de forma
      // explícita para o peso pedido não depender de negrito sintético.
      fontVariations: [FontVariation('wght', weight.value.toDouble())],
      height: height,
      letterSpacing: letterSpacing,
      color: AppColors.text,
    );
  }

  static TextStyle _body(double size, FontWeight weight, {double height = 1.5}) {
    return TextStyle(
      fontFamily: AppFonts.body,
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: AppColors.text,
    );
  }

  static TextStyle _mono(
    double size,
    FontWeight weight, {
    double height = 1.3,
    double letterSpacing = 0,
    Color color = AppColors.text,
  }) {
    return TextStyle(
      fontFamily: AppFonts.mono,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
      // Algarismos de largura fixa para contadores e pontuação.
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  // Display (Unbounded)
  static final TextStyle streak = _display(44, FontWeight.w700, height: 1);
  static final TextStyle gain = _display(28, FontWeight.w700, height: 1.1);
  static final TextStyle points = _display(26, FontWeight.w700, height: 1.1);
  static final TextStyle stat = _display(22, FontWeight.w500, height: 1.2);
  static final TextStyle sheetTitle =
      _display(20, FontWeight.w700, height: 1.25);
  static final TextStyle gameTitle = _display(17, FontWeight.w500);
  static final TextStyle heading = _display(15, FontWeight.w500);
  static final TextStyle brand = _display(11, FontWeight.w500, height: 1.15);

  /// Nome do jogo na splash (tamanho e espaçamento já usados na splash).
  static final TextStyle splashTitle =
      _display(26, FontWeight.w700, height: 1.05, letterSpacing: 6);

  // Corpo (IBM Plex Sans)
  static final TextStyle body = _body(15, FontWeight.w400);
  static final TextStyle bodySmall = _body(14, FontWeight.w400);
  static final TextStyle caption = _body(12, FontWeight.w400, height: 1.4);
  static final TextStyle button = _body(15, FontWeight.w600, height: 1.2);

  // Mono (IBM Plex Mono)
  static final TextStyle value = _mono(12, FontWeight.w500);
  static final TextStyle label = _mono(
    11,
    FontWeight.w500,
    letterSpacing: 11 * 0.14, // 0,14em
    color: AppColors.muted,
  );
}

/// Mapeia os estilos nomeados para os 15 papéis do `TextTheme`.
///
/// Todos os papéis são definidos porque `ThemeData(fontFamily: ...)` não é
/// usado: ele sobrescreveria a família de cada estilo.
abstract final class AppTypography {
  static final TextTheme textTheme = TextTheme(
    displayLarge: AppTextStyles.streak,
    displayMedium: AppTextStyles.gain,
    displaySmall: AppTextStyles.points,
    headlineLarge: AppTextStyles.stat,
    headlineMedium: AppTextStyles.sheetTitle,
    headlineSmall: AppTextStyles.gameTitle,
    titleLarge: AppTextStyles.heading,
    titleMedium: AppTextStyles.button,
    titleSmall: AppTextStyles.brand,
    bodyLarge: AppTextStyles.body,
    bodyMedium: AppTextStyles.bodySmall,
    bodySmall: AppTextStyles.caption,
    labelLarge: AppTextStyles.button,
    labelMedium: AppTextStyles.value,
    labelSmall: AppTextStyles.label,
  );
}
