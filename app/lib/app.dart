import 'package:material_ui/material_ui.dart';
import 'package:synapsezero/application/audio/asset_splash_audio.dart';
import 'package:synapsezero/application/audio/splash_audio.dart';
import 'package:synapsezero/presentation/home/home_placeholder.dart';
import 'package:synapsezero/presentation/splash/splash_screen.dart';
import 'package:synapsezero/presentation/theme/app_theme.dart';

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
  bool _splashDone = false;

  /// Som ativo por padrão. O áudio pertence a este widget, que o libera.
  final SplashAudio _audio = AssetSplashAudio();

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: _splashDone
          ? const HomePlaceholder(key: ValueKey('home'))
          : SplashScreen(
              key: const ValueKey('splash'),
              audio: _audio,
              onFinished: () => setState(() => _splashDone = true),
            ),
    );
  }
}
