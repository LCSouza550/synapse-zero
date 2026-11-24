/// Contrato de áudio da splash. A implementação real (com arquivos de som)
/// fica em `asset_splash_audio.dart`.
abstract interface class SplashAudio {
  /// Carrega o som antes de a animação começar, para manter áudio e imagem sincronizados.
  Future<void> prepare();

  /// Toca a abertura. Só completa quando o som realmente começou, para a
  /// animação partir junto com ele (o início do áudio no aparelho demora).
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

/// Só toca a abertura se [isEnabled] for verdadeiro no momento de tocar
/// (usado para respeitar a opção "efeitos sonoros").
class GatedSplashAudio implements SplashAudio {
  GatedSplashAudio({required this.inner, required this.isEnabled});

  final SplashAudio inner;
  final bool Function() isEnabled;

  @override
  Future<void> prepare() => inner.prepare();

  @override
  Future<void> playIntro() async {
    if (isEnabled()) await inner.playIntro();
  }

  @override
  Future<void> dispose() => inner.dispose();
}
