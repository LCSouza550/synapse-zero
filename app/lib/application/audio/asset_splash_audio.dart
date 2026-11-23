import 'package:audioplayers/audioplayers.dart';
import 'package:synapsezero/application/audio/splash_audio.dart';

/// Toca `assets/audio/splash.wav` com o pacote audioplayers.
class AssetSplashAudio implements SplashAudio {
  AssetSplashAudio({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  /// Caminho relativo à pasta `assets/` (o AssetSource já a considera).
  static const String _asset = 'audio/splash.wav';

  @override
  Future<void> prepare() async {
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setSource(AssetSource(_asset));
  }

  @override
  Future<void> playIntro() => _player.resume();

  @override
  Future<void> dispose() => _player.dispose();
}
