/// Contrato da música tema (laço contínuo de fundo).
abstract interface class ThemeMusic {
  /// Começa (ou retoma) a tocar em laço.
  Future<void> play();

  /// Pausa, mantendo a posição para retomar depois.
  Future<void> pause();

  /// Libera os recursos.
  Future<void> dispose();
}

class SilentThemeMusic implements ThemeMusic {
  const SilentThemeMusic();

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> dispose() async {}
}
