import 'package:audioplayers/audioplayers.dart';
import 'package:synapsezero/application/audio/game_sounds.dart';

/// Toca os efeitos de `assets/audio/` com o pacote audioplayers.
///
/// Os players usam `AudioContextConfigFocus.mixWithOthers` (no Android, sem
/// pedir o foco de áudio) para que um efeito não pause a música tema.
class AssetGameSounds implements GameSounds {
  final Map<GameSound, AudioPlayer> _players = {};

  /// Caminhos relativos à pasta `assets/`.
  static const Map<GameSound, String> _assets = {
    GameSound.tap: 'audio/tap.wav',
    GameSound.advance: 'audio/advance.wav',
  };

  Future<AudioPlayer> _playerFor(GameSound sound) async {
    final existing = _players[sound];
    if (existing != null) return existing;
    final player = AudioPlayer();
    _players[sound] = player;
    await player.setAudioContext(
      AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build(),
    );
    await player.setReleaseMode(ReleaseMode.stop);
    return player;
  }

  @override
  Future<void> play(GameSound sound) async {
    final player = await _playerFor(sound);
    await player.stop();
    await player.play(AssetSource(_assets[sound]!));
  }

  @override
  Future<void> dispose() async {
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();
  }
}
