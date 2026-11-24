import 'package:flutter_test/flutter_test.dart';
import 'package:synapsezero/application/audio/game_sounds.dart';
import 'package:synapsezero/application/audio/splash_audio.dart';
import 'package:synapsezero/application/audio/theme_music.dart';
import 'package:synapsezero/application/audio/theme_music_controller.dart';
import 'package:synapsezero/application/settings/player_account.dart';
import 'package:synapsezero/application/settings/settings_controller.dart';
import 'package:synapsezero/application/settings/settings_store.dart';

class _FakeMusic implements ThemeMusic {
  final List<String> calls = [];

  @override
  Future<void> play() async => calls.add('play');

  @override
  Future<void> pause() async => calls.add('pause');

  @override
  Future<void> dispose() async => calls.add('dispose');
}

class _FakeSounds implements GameSounds {
  final List<GameSound> played = [];

  @override
  Future<void> play(GameSound sound) async => played.add(sound);

  @override
  Future<void> dispose() async {}
}

class _FakeSplash implements SplashAudio {
  int played = 0;

  @override
  Future<void> prepare() async {}

  @override
  Future<void> playIntro() async => played++;

  @override
  Future<void> dispose() async {}
}

SettingsController _settings() => SettingsController(
      store: InMemorySettingsStore(),
      accountService: const SimulatedAccountService(),
    );

void main() {
  group('ThemeMusicController', () {
    test('não toca antes de liberada (splash)', () {
      final music = _FakeMusic();
      ThemeMusicController(music: music, settings: _settings());
      expect(music.calls, isEmpty);
    });

    test('toca ao liberar e obedece à opção de música', () async {
      final music = _FakeMusic();
      final settings = _settings();
      ThemeMusicController(music: music, settings: settings).allow();
      expect(music.calls, ['play']);

      await settings.setMusic(false);
      expect(music.calls, ['play', 'pause']);

      await settings.setMusic(true);
      expect(music.calls, ['play', 'pause', 'play']);
    });

    test('segundo plano silencia e primeiro plano retoma', () {
      final music = _FakeMusic();
      final controller =
          ThemeMusicController(music: music, settings: _settings())..allow();
      controller.setForeground(false);
      controller.setForeground(true);
      expect(music.calls, ['play', 'pause', 'play']);
    });

    test('não repete chamadas sem mudança de estado', () {
      final music = _FakeMusic();
      final controller =
          ThemeMusicController(music: music, settings: _settings())..allow();
      controller.allow();
      controller.setForeground(true);
      expect(music.calls, ['play']);
    });

    test('mudar só o avatar não mexe na música', () async {
      final music = _FakeMusic();
      final settings = _settings();
      ThemeMusicController(music: music, settings: settings).allow();
      await settings.setAvatar('fox');
      expect(music.calls, ['play']);
    });

    test('dispose libera a música e para de ouvir', () async {
      final music = _FakeMusic();
      final settings = _settings();
      final controller = ThemeMusicController(music: music, settings: settings)
        ..allow();
      await controller.dispose();
      await settings.setMusic(false);
      expect(music.calls, ['play', 'dispose']);
    });
  });

  group('GatedSplashAudio', () {
    test('toca a abertura só com efeitos sonoros ligados', () async {
      final inner = _FakeSplash();
      var enabled = true;
      final gated = GatedSplashAudio(inner: inner, isEnabled: () => enabled);

      await gated.playIntro();
      enabled = false;
      await gated.playIntro();

      expect(inner.played, 1);
    });
  });

  group('GatedGameSounds', () {
    test('só toca efeitos com a opção ligada', () async {
      final inner = _FakeSounds();
      var enabled = true;
      final gated = GatedGameSounds(inner: inner, isEnabled: () => enabled);

      await gated.play(GameSound.tap);
      enabled = false;
      await gated.play(GameSound.advance);
      enabled = true;
      await gated.play(GameSound.advance);

      expect(inner.played, [GameSound.tap, GameSound.advance]);
    });
  });
}
