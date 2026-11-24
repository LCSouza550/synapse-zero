import 'package:material_ui/material_ui.dart';
import 'package:synapsezero/application/audio/splash_audio.dart';
import 'package:synapsezero/presentation/splash/splash_painter.dart';
import 'package:synapsezero/presentation/splash/splash_timeline.dart';
import 'package:synapsezero/presentation/theme/app_typography.dart';
import 'package:synapsezero/presentation/theme/synapse_palette.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.onFinished,
    this.audio = const SilentSplashAudio(),
  });

  /// Chamado uma vez, após o fim do percurso e da pausa final.
  final VoidCallback onFinished;

  /// O ciclo de vida do áudio pertence a quem o cria, não à splash.
  final SplashAudio audio;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final SplashTimeline _timeline = SplashTimeline();
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: SplashTimeline.duration,
    )..addStatusListener(_onStatus);
    // Só inicia após o primeiro frame: o tempo de montagem não consome a animação.
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    try {
      await widget.audio.prepare();
    } catch (_) {
      // Falha de áudio não deve impedir a abertura do jogo.
    }
    if (!mounted) return;
    // O som começa primeiro; a animação só parte quando ele realmente tocou.
    try {
      await widget.audio.playIntro();
    } catch (_) {
      // Sem som, a abertura segue.
    }
    if (!mounted) return;
    _controller.forward();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_finished) {
      _finished = true;
      widget.onFinished();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SynapsePalette.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const RepaintBoundary(child: CustomPaint(painter: GridPainter())),
          RepaintBoundary(
            child: CustomPaint(
              painter: SplashPainter(
                animation: _controller,
                timeline: _timeline,
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.30),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Opacity(
                opacity: _timeline.titleOpacity(_controller.value),
                child: child,
              ),
              child: const _Title(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'SYNAPSE // ZERO',
          textAlign: TextAlign.center,
          style: AppTextStyles.splashTitle.copyWith(
            color: SynapsePalette.textPrimary,
            shadows: const [Shadow(color: SynapsePalette.cyan, blurRadius: 18)],
          ),
        ),
      ),
    );
  }
}
