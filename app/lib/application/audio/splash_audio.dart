/// Contrato de áudio da splash. A implementação real (com arquivos de som)
/// entra na próxima etapa, sem alterar a tela.
abstract interface class SplashAudio {
  /// Carrega o som antes de a animação começar, para manter áudio e imagem sincronizados.
  Future<void> prepare();

  Future<void> playIntro();
}

class SilentSplashAudio implements SplashAudio {
  const SilentSplashAudio();

  @override
  Future<void> prepare() async {}

  @override
  Future<void> playIntro() async {}
}