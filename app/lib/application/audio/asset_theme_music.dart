import 'package:audioplayers/audioplayers.dart';
import 'package:synapsezero/application/audio/theme_music.dart';

/// Toca `assets/audio/theme.wav` em laço com o pacote audioplayers.
class AssetThemeMusic implements ThemeMusic {
  AssetThemeMusic({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  static const String _asset = 'audio/theme.wav';

  /// Música de fundo: mais baixa que os efeitos.
  static const double _volume = 0.45;

  bool _loaded = false;

  @override
  Future<void> play() async {
    if (!_loaded) {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(_volume);
      await _player.setSource(AssetSource(_asset));
      _loaded = true;
    }
    await _player.resume();
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> dispose() => _player.dispose();
}
