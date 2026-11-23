import 'package:synapsezero/application/audio/theme_music.dart';
import 'package:synapsezero/application/settings/settings_controller.dart';

/// Decide quando a música tema toca: só com a opção ligada, depois da
/// splash e com o app em primeiro plano. Reage às mudanças das configurações.
class ThemeMusicController {
  ThemeMusicController({
    required ThemeMusic music,
    required SettingsController settings,
  })  : _music = music,
        _settings = settings {
    _settings.addListener(_sync);
  }

  final ThemeMusic _music;
  final SettingsController _settings;

  bool _allowed = false;
  bool _foreground = true;
  bool _playing = false;
  bool _disposed = false;

  /// Libera a música (chamado ao fim da splash).
  void allow() {
    _allowed = true;
    _sync();
  }

  /// Informado pelo ciclo de vida do app (segundo plano silencia).
  void setForeground(bool value) {
    _foreground = value;
    _sync();
  }

  void _sync() {
    if (_disposed) return;
    final shouldPlay = _allowed && _foreground && _settings.music;
    if (shouldPlay == _playing) return;
    _playing = shouldPlay;
    final action = shouldPlay ? _music.play() : _music.pause();
    // Falha de áudio não deve derrubar o jogo.
    action.catchError((Object _) {});
  }

  Future<void> dispose() async {
    _disposed = true;
    _settings.removeListener(_sync);
    await _music.dispose();
  }
}
