import 'dart:async';
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import 'splash_painter.dart';
import 'splash_timeline.dart';

/// Splash animada do SYNAPSE // ZERO.
///
/// Um único [AnimationController] comanda feixe, capacitor, halo, nome e som,
/// então nada pode sair de compasso. Toque na tela para pular.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.onFinished,
    this.playSound = true,
  });

  /// Chamado uma única vez, ao terminar a animação ou ao tocar para pular.
  final VoidCallback onFinished;

  /// Som ativo por padrão (futuramente vem das configurações do operador).
  final bool playSound;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const String _soundAsset = 'audio/splash.wav';

  late final AnimationController _clock;
  AudioPlayer? _player;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (SplashTimeline.total * 1000).round()),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finish();
      });
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  /// Prepara o som e só então dispara animação e áudio juntos.
  Future<void> _start() async {
    var soundReady = false;
    if (widget.playSound) {
      try {
        final player = AudioPlayer();
        _player = player;
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setSource(AssetSource(_soundAsset));
        soundReady = true;
      } catch (error) {
        debugPrint('Splash: som indisponível ($error)');
      }
    }
    if (!mounted || _finished) return;
    if (soundReady) unawaited(_player!.resume());
    _clock.forward();
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    _fadeOutSound();
    widget.onFinished();
  }

  /// Silencia o som em ~250 ms, como o protótipo (`stopSplash`).
  Future<void> _fadeOutSound() async {
    final player = _player;
    if (player == null) return;
    try {
      for (var step = 4; step >= 0; step--) {
        await player.setVolume(step / 5);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      await player.stop();
    } catch (_) {
      // Som é acessório: qualquer falha aqui é ignorada.
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    final player = _player;
    if (player != null) unawaited(player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _finish,
      child: CustomPaint(
        painter: const SplashGridPainter(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // max-width 440 e padding 24 do protótipo
            final width = (constraints.maxWidth - 48).clamp(0.0, 392.0).toDouble();
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RepaintBoundary(
                    child: CustomPaint(
                      size: Size(width, width * SplashPainter.aspect),
                      painter: SplashPainter(_clock),
                    ),
                  ),
                  const SizedBox(height: 26),
                  _SplashTitle(clock: _clock, maxWidth: width + 48),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Nome do jogo: surge com fade e desfoque a partir de 1,85 s.
class _SplashTitle extends StatelessWidget {
  const _SplashTitle({required this.clock, required this.maxWidth});

  final Animation<double> clock;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    // clamp(26px, 9vw, 38px) do protótipo
    final screenWidth = MediaQuery.sizeOf(context).width;
    final fontSize = (screenWidth * 0.09).clamp(26.0, 38.0).toDouble();
    TextStyle style(Color color) => TextStyle(
          fontFamily: 'Unbounded',
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
          height: 1.05,
          color: color,
          decoration: TextDecoration.none,
        );

    final text = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('SYNAPSE', textAlign: TextAlign.center, style: style(AppColors.text)),
        Text('// ZERO', textAlign: TextAlign.center, style: style(AppColors.alfa)),
      ],
    );

    return AnimatedBuilder(
      animation: clock,
      child: text,
      builder: (context, child) {
        final t = clock.value * SplashTimeline.total;
        final p = SplashTimeline.titleCurve.transform(
            SplashTimeline.seg(t, SplashTimeline.glowStart, SplashTimeline.titleDur));
        if (p <= 0) return Opacity(opacity: 0, child: child);
        final sigma = 8 * (1 - p);
        return Opacity(
          opacity: p,
          child: sigma < 0.05
              ? child
              : ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(
                    sigmaX: sigma,
                    sigmaY: sigma,
                    tileMode: ui.TileMode.decal,
                  ),
                  child: child,
                ),
        );
      },
    );
  }
}
