import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:synapsezero/presentation/theme/app_colors.dart';
import 'package:synapsezero/presentation/theme/app_fonts.dart';
import 'package:synapsezero/presentation/theme/app_theme.dart';

/// Arquivos que o `pubspec.yaml` declara; criados por `tool/fetch_fonts.ps1`.
const _fontFiles = [
  'Unbounded-Variable.ttf',
  'IBMPlexSans-Regular.ttf',
  'IBMPlexSans-Medium.ttf',
  'IBMPlexSans-SemiBold.ttf',
  'IBMPlexMono-Regular.ttf',
  'IBMPlexMono-Medium.ttf',
];

void main() {
  group('AppTheme', () {
    final theme = AppTheme.dark();

    test('usa os tokens de cor do protótipo', () {
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, AppColors.bg);
      expect(theme.colorScheme.primary, AppColors.alfa);
      expect(theme.colorScheme.secondary, AppColors.beta);
      expect(theme.colorScheme.error, AppColors.danger);
    });

    test('todos os papéis do TextTheme usam uma família empacotada', () {
      final t = theme.textTheme;
      final styles = [
        t.displayLarge, t.displayMedium, t.displaySmall,
        t.headlineLarge, t.headlineMedium, t.headlineSmall,
        t.titleLarge, t.titleMedium, t.titleSmall,
        t.bodyLarge, t.bodyMedium, t.bodySmall,
        t.labelLarge, t.labelMedium, t.labelSmall,
      ];
      const families = {AppFonts.display, AppFonts.body, AppFonts.mono};
      for (final style in styles) {
        expect(style, isNotNull);
        expect(families, contains(style!.fontFamily));
      }
    });

    test('números e títulos usam Unbounded; rótulos usam IBM Plex Mono', () {
      expect(theme.textTheme.displayLarge!.fontFamily, AppFonts.display);
      expect(theme.textTheme.labelSmall!.fontFamily, AppFonts.mono);
      expect(theme.textTheme.bodyLarge!.fontFamily, AppFonts.body);
    });

    test('o peso da Unbounded é fixado no eixo wght', () {
      final style = theme.textTheme.displayLarge!;
      expect(style.fontVariations, isNotNull);
      expect(style.fontVariations!.single.axis, 'wght');
      expect(style.fontVariations!.single.value, 700);
    });
  });

  test('arquivos de fonte existem em assets/fonts', () {
    final missing = [
      for (final name in _fontFiles)
        if (!File('assets/fonts/$name').existsSync()) name,
    ];
    expect(
      missing,
      isEmpty,
      reason: 'Fontes ausentes. Execute: '
          'powershell -ExecutionPolicy Bypass -File tool\\fetch_fonts.ps1',
    );
  });
}
