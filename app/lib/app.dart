import 'package:material_ui/material_ui.dart';
import 'package:synapsezero/application/audio/asset_splash_audio.dart';
import 'package:synapsezero/application/audio/asset_theme_music.dart';
import 'package:synapsezero/application/audio/splash_audio.dart';
import 'package:synapsezero/application/audio/theme_music.dart';
import 'package:synapsezero/application/audio/theme_music_controller.dart';
import 'package:synapsezero/application/settings/settings_controller.dart';
import 'package:synapsezero/presentation/splash/splash_screen.dart';
import 'package:synapsezero/presentation/theme/app_theme.dart';
import 'package:synapsezero/presentation/trail/trail_flow.dart';

class SynapseZeroApp extends StatelessWidget {
  const SynapseZeroApp({
    super.key,
    required this.settings,
    this.splashAudio,
    this.themeMusic,
    this.boardBuilder,
  });

  final SettingsController settings;

  /// Áudios injetáveis (testes usam versões mudas). Padrão: os do aplicativo.
  final SplashAudio? splashAudio;
  final ThemeMusic? themeMusic;

  /// Tela de jogo injetável (padrão: o tabuleiro provisório).
  final BoardBuilder? boardBuilder;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Synapse Zero',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: _Root(
        settings: settings,
        splashAudio: splashAudio,
        themeMusic: themeMusic,
        boardBuilder: boardBuilder,
      ),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root({
    required this.settings,
    this.splashAudio,
    this.themeMusic,
    this.boardBuilder,
  });

  final SettingsController settings;
  final SplashAudio? splashAudio;
  final ThemeMusic? themeMusic;
  final BoardBuilder? boardBuilder;

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> with WidgetsBindingObserver {
  bool _splashDone = false;

  /// A abertura só toca com "efeitos sonoros" ligado. O áudio pertence a este
  /// widget, que o libera.
  late final SplashAudio _splashAudio = GatedSplashAudio(
    inner: widget.splashAudio ?? AssetSplashAudio(),
    isEnabled: () => widget.settings.soundEffects,
  );

  late final ThemeMusicController _music = ThemeMusicController(
    music: widget.themeMusic ?? AssetThemeMusic(),
    settings: widget.settings,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Cria a música já aqui, para o dispose sempre liberar o que foi criado.
    _music.setForeground(true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _music.setForeground(state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _music.dispose();
    _splashAudio.dispose();
    super.dispose();
  }

  void _onSplashFinished() {
    setState(() => _splashDone = true);
    _music.allow();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: _splashDone
          ? TrailFlow(
              key: const ValueKey('trail'),
              settings: widget.settings,
              boardBuilder: widget.boardBuilder,
            )
          : SplashScreen(
              key: const ValueKey('splash'),
              audio: _splashAudio,
              onFinished: _onSplashFinished,
            ),
    );
  }
}
