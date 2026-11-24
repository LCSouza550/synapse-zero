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

  /// Limite de espera pelo início real do som; passado isso, a animação parte
  /// mesmo assim (melhor sem sincronia do que travar a abertura).
  static const Duration _startTimeout = Duration(milliseconds: 1000);

  @override
  Future<void> playIntro() async {
    // Assina antes de mandar tocar: o 1º evento de posição marca o início real.
    final started = _player.onPositionChanged.first.timeout(
      _startTimeout,
      onTimeout: () => Duration.zero,
    );
    await _player.resume();
    await started;
  }

  @override
  Future<void> dispose() => _player.dispose();
}
