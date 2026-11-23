import 'package:synapsezero/application/settings/avatars.dart';
import 'package:synapsezero/application/settings/player_account.dart';

/// Configurações do jogador (valores imutáveis).
class SettingsData {
  const SettingsData({
    this.soundEffects = true,
    this.music = true,
    this.avatarId = 'satellite',
    this.account,
  });

  /// Efeitos sonoros ligados (a splash e, nas próximas etapas, o tabuleiro).
  final bool soundEffects;

  /// Música tema ligada.
  final bool music;

  /// Id do avatar (ver `avatars.dart`).
  final String avatarId;

  /// Conta conectada, se houver.
  final PlayerAccount? account;

  Avatar get avatar => avatarById(avatarId);

  SettingsData copyWith({
    bool? soundEffects,
    bool? music,
    String? avatarId,
    PlayerAccount? account,
    bool clearAccount = false,
  }) {
    return SettingsData(
      soundEffects: soundEffects ?? this.soundEffects,
      music: music ?? this.music,
      avatarId: avatarId ?? this.avatarId,
      account: clearAccount ? null : (account ?? this.account),
    );
  }
}

/// Onde as configurações ficam guardadas.
abstract interface class SettingsStore {
  Future<SettingsData> load();
  Future<void> save(SettingsData data);
}

/// Guarda em memória. Usada nos testes.
class InMemorySettingsStore implements SettingsStore {
  InMemorySettingsStore([SettingsData initial = const SettingsData()])
      : saved = initial;

  /// Último valor salvo.
  SettingsData saved;

  /// Quantas vezes [save] foi chamado.
  int saveCount = 0;

  @override
  Future<SettingsData> load() async => saved;

  @override
  Future<void> save(SettingsData data) async {
    saved = data;
    saveCount++;
  }
}
