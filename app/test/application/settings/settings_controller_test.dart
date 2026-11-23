import 'package:flutter_test/flutter_test.dart';
import 'package:synapsezero/application/settings/avatars.dart';
import 'package:synapsezero/application/settings/player_account.dart';
import 'package:synapsezero/application/settings/settings_controller.dart';
import 'package:synapsezero/application/settings/settings_store.dart';

class _FailingStore implements SettingsStore {
  @override
  Future<SettingsData> load() async => throw StateError('falha ao ler');

  @override
  Future<void> save(SettingsData data) async => throw StateError('falha ao gravar');
}

SettingsController _controller(
  SettingsStore store, {
  bool release = false,
}) {
  return SettingsController(
    store: store,
    accountService: SimulatedAccountService(
      isRelease: release,
      delay: Duration.zero,
    ),
  );
}

void main() {
  group('avatares', () {
    test('ids são únicos e o padrão existe', () {
      final ids = avatars.map((a) => a.id).toSet();
      expect(ids.length, avatars.length);
      expect(ids, contains(defaultAvatar.id));
      expect(avatars.length, 8);
    });

    test('id desconhecido volta ao avatar padrão', () {
      expect(avatarById('inexistente'), same(defaultAvatar));
      expect(avatarById(null), same(defaultAvatar));
      expect(avatarById('brain').emoji, '🧠');
    });
  });

  group('SettingsController', () {
    test('padrões: sons e música ligados, sem conta', () {
      final c = _controller(InMemorySettingsStore());
      expect(c.soundEffects, isTrue);
      expect(c.music, isTrue);
      expect(c.account, isNull);
      expect(c.data.avatar, same(defaultAvatar));
    });

    test('load aplica o que estava gravado', () async {
      final store = InMemorySettingsStore(
        const SettingsData(soundEffects: false, music: false, avatarId: 'fox'),
      );
      final c = _controller(store);
      await c.load();
      expect(c.soundEffects, isFalse);
      expect(c.music, isFalse);
      expect(c.data.avatarId, 'fox');
    });

    test('alterações notificam e são gravadas', () async {
      final store = InMemorySettingsStore();
      final c = _controller(store);
      var notified = 0;
      c.addListener(() => notified++);

      await c.setSoundEffects(false);
      await c.setMusic(false);
      await c.setAvatar('robot');

      expect(notified, greaterThanOrEqualTo(3));
      expect(store.saved.soundEffects, isFalse);
      expect(store.saved.music, isFalse);
      expect(store.saved.avatarId, 'robot');
    });

    test('login simulado cria a conta e sair a remove', () async {
      final store = InMemorySettingsStore();
      final c = _controller(store);
      await c.signIn(SocialProvider.google);
      expect(c.account?.provider, SocialProvider.google);
      expect(c.account?.isSimulated, isTrue);
      expect(store.saved.account, isNotNull);
      expect(c.signingIn, isFalse);

      await c.signOut();
      expect(c.account, isNull);
      expect(store.saved.account, isNull);
    });

    test('em release o login fica indisponível e dá erro claro', () async {
      final c = _controller(InMemorySettingsStore(), release: true);
      expect(c.loginAvailable, isFalse);
      await c.signIn(SocialProvider.facebook);
      expect(c.account, isNull);
      expect(c.error, isNotNull);
    });

    test('mudar o avatar mantém a conta e vice-versa', () async {
      final c = _controller(InMemorySettingsStore());
      await c.signIn(SocialProvider.google);
      await c.setAvatar('dna');
      expect(c.account, isNotNull);
      expect(c.data.avatarId, 'dna');
      await c.signOut();
      expect(c.data.avatarId, 'dna');
    });

    test('falhas de leitura e gravação não quebram o controlador', () async {
      final c = _controller(_FailingStore());
      await c.load();
      expect(c.music, isTrue);
      await c.setMusic(false);
      expect(c.music, isFalse);
    });
  });
}
