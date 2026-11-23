import 'package:material_ui/material_ui.dart';
import 'package:synapsezero/presentation/theme/app_colors.dart';
import 'package:synapsezero/presentation/theme/app_typography.dart';

/// Tema escuro único do jogo (cores do protótipo + tipografia empacotada).
abstract final class AppTheme {
  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: AppColors.alfa,
      onPrimary: AppColors.onAlfa,
      secondary: AppColors.beta,
      onSecondary: AppColors.onAlfa,
      tertiary: AppColors.blue,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      onSurfaceVariant: AppColors.muted,
      outline: AppColors.line,
      error: AppColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: AppTypography.textTheme,
    );
  }
}
