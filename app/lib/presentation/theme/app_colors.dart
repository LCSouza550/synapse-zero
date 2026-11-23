import 'dart:ui';

/// Tokens de cor do protótipo (variáveis CSS `:root` de
/// `reference/synapse-zero-prototype.html`). É a fonte das cores do tema
/// (`AppTheme`) e das telas do jogo.
///
/// A splash aprovada usa `SynapsePalette` e permanece inalterada.
abstract final class AppColors {
  // Superfícies
  static const Color bg = Color(0xFF050F16);
  static const Color surface = Color(0xFF0A1B25);
  static const Color plate = Color(0xFF0D2230);
  static const Color line = Color(0xFF17394A);
  static const Color grid = Color(0x0F3DEAF2); // rgba(61, 234, 242, 0.06)

  // Texto
  static const Color text = Color(0xFFE4FBFF);
  static const Color muted = Color(0xFF8FB5BF);
  static const Color onAlfa = Color(0xFF021A1D); // texto sobre fundo ciano

  // Rede Alfa (ciano)
  static const Color alfa = Color(0xFF3DEAF2);
  static const Color alfaSoft = Color(0x1F3DEAF2); // rgba(61, 234, 242, 0.12)
  static const Color alfaGlow = Color(0x8C3DEAF2); // rgba(61, 234, 242, 0.55)

  // Rede Beta (âmbar)
  static const Color beta = Color(0xFFE6AE45);
  static const Color betaSoft = Color(0x24E6AE45); // rgba(230, 174, 69, 0.14)
  static const Color betaGlow = Color(0x8CE6AE45); // rgba(230, 174, 69, 0.55)

  // Estados e destaques
  static const Color wireOff = Color(0xFF3A7586);
  static const Color blue = Color(0xFF3B82F6);
  static const Color danger = Color(0xFFFF5C7A);
  static const Color star = Color(0xFFF0C35A);

  // Usadas pela animação da splash do protótipo
  static const Color flash = Color(0xFFEAFCFF);
  static const Color wake = Color(0xFF2B8E9A);
}
