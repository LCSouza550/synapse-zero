/// Efeitos sonoros do jogo.
enum GameSound {
  /// Toque num nível.
  tap,

  /// O avatar anda até a próxima etapa (dura o mesmo que a animação).
  advance,
}

abstract interface class GameSounds {
  Future<void> play(GameSound sound);

  Future<void> dispose();
}

class SilentGameSounds implements GameSounds {
  const SilentGameSounds();

  @override
  Future<void> play(GameSound sound) async {}

  @override
  Future<void> dispose() async {}
}

/// Só toca se [isEnabled] for verdadeiro no momento de tocar (opção
/// "efeitos sonoros" das configurações).
class GatedGameSounds implements GameSounds {
  GatedGameSounds({required this.inner, required this.isEnabled});

  final GameSounds inner;
  final bool Function() isEnabled;

  @override
  Future<void> play(GameSound sound) async {
    if (isEnabled()) await inner.play(sound);
  }

  @override
  Future<void> dispose() => inner.dispose();
}
