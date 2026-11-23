import 'package:material_ui/material_ui.dart';
import 'package:synapsezero/application/audio/asset_splash_audio.dart';
import 'package:synapsezero/application/audio/splash_audio.dart';
import 'package:synapsezero/application/trail/trail_progress.dart';
import 'package:synapsezero/presentation/splash/splash_screen.dart';
import 'package:synapsezero/presentation/theme/app_theme.dart';
import 'package:synapsezero/presentation/trail/trail_screen.dart';

class SynapseZeroApp extends StatelessWidget {
  const SynapseZeroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Synapse Zero',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const _Root(),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  /// Verdadeiro em builds de release (`flutter run --release`, APK de loja).
  static const bool _isRelease = bool.fromEnvironment('dart.vm.product');

  bool _splashDone = false;

  /// Progresso da trilha. Ainda só em memória: a persistência é uma etapa
  /// futura.
  TrailProgress _progress = TrailProgress.empty();

  /// Som ativo por padrão. O áudio pertence a este widget, que o libera.
  final SplashAudio _audio = AssetSplashAudio();

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  /// TEMPORÁRIO até a etapa do tabuleiro, que abrirá o nível tocado.
  /// Em debug, concluir o nível tocado permite ver o mapa evoluir
  /// (1 a 3 estrelas, em rodízio). Em release, apenas informa.
  void _onLevelSelected(int index) {
    if (_isRelease) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tabuleiro em construção')),
      );
      return;
    }
    setState(() {
      _progress = _progress.withResult(
        index,
        stars: index % 3 + 1,
        score: 300 + 20 * index,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: _splashDone
          ? TrailScreen(
              key: const ValueKey('trail'),
              progress: _progress,
              onLevelSelected: _onLevelSelected,
            )
          : SplashScreen(
              key: const ValueKey('splash'),
              audio: _audio,
              onFinished: () => setState(() => _splashDone = true),
            ),
    );
  }
}
