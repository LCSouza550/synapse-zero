/// Contrato de áudio da splash. A implementação real (com arquivos de som)
/// fica em `asset_splash_audio.dart`.
abstract interface class SplashAudio {
  /// Carrega o som antes de a animação começar, para manter áudio e imagem sincronizados.
  Future<void> prepare();

  Future<void> playIntro();

  /// Libera os recursos. Chamado por quem criou o áudio.
  Future<void> dispose();
}

class SilentSplashAudio implements SplashAudio {
  const SilentSplashAudio();

  @override
  Future<void> prepare() async {}

  @override
  Future<void> playIntro() async {}

  @override
  Future<void> dispose() async {}
}
