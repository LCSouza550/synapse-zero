import 'package:shared_preferences/shared_preferences.dart';
import 'package:synapsezero/application/settings/player_account.dart';
import 'package:synapsezero/application/settings/settings_store.dart';

/// Guarda as configurações no armazenamento do aparelho (pacote
/// `shared_preferences`, API `SharedPreferencesAsync`).
class SharedPreferencesSettingsStore implements SettingsStore {
  SharedPreferencesSettingsStore({SharedPreferencesAsync? prefs})
      : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  static const String _soundEffects = 'settings.soundEffects';
  static const String _music = 'settings.music';
  static const String _avatar = 'settings.avatar';
  static const String _accountProvider = 'settings.account.provider';
  static const String _accountName = 'settings.account.name';
  static const String _accountSimulated = 'settings.account.simulated';

  @override
  Future<SettingsData> load() async {
    const defaults = SettingsData();
    final providerName = await _prefs.getString(_accountProvider);
    final name = await _prefs.getString(_accountName);
    PlayerAccount? account;
    if (providerName != null && name != null) {
      for (final provider in SocialProvider.values) {
        if (provider.name == providerName) {
          account = PlayerAccount(
            provider: provider,
            displayName: name,
            isSimulated: await _prefs.getBool(_accountSimulated) ?? false,
          );
        }
      }
    }
    return SettingsData(
      soundEffects: await _prefs.getBool(_soundEffects) ?? defaults.soundEffects,
      music: await _prefs.getBool(_music) ?? defaults.music,
      avatarId: await _prefs.getString(_avatar) ?? defaults.avatarId,
      account: account,
    );
  }

  @override
  Future<void> save(SettingsData data) async {
    await _prefs.setBool(_soundEffects, data.soundEffects);
    await _prefs.setBool(_music, data.music);
    await _prefs.setString(_avatar, data.avatarId);
    final account = data.account;
    if (account == null) {
      await _prefs.remove(_accountProvider);
      await _prefs.remove(_accountName);
      await _prefs.remove(_accountSimulated);
    } else {
      await _prefs.setString(_accountProvider, account.provider.name);
      await _prefs.setString(_accountName, account.displayName);
      await _prefs.setBool(_accountSimulated, account.isSimulated);
    }
  }
}
