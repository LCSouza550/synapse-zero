import 'package:audioplayers/audioplayers.dart';
import 'package:synapsezero/application/audio/splash_audio.dart';

/// Toca `assets/audio/splash.wav` com o pacote audioplayers.
class AssetSplashAudio implements SplashAudio {
  AssetSplashAudio({
    AudioPlayer? player,
    this.outputLatency = defaultOutputLatency,
  }) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  /// Atraso entre o player dizer que começou e o som sair no aparelho.
  /// Medido em gravação de tela no celular de teste: o som saía ~0,65 s depois
  /// da animação. A animação espera esse tempo para os dois coincidirem.
  /// Se o som ainda sair atrasado (ou adiantado), ajuste este valor.
  static const Duration defaultOutputLatency = Duration(milliseconds: 650);

  final Duration outputLatency;

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
    await Future<void>.delayed(outputLatency);
  }

  @override
  Future<void> dispose() => _player.dispose();
}
