import 'package:flutter/foundation.dart';
import 'package:synapsezero/application/settings/player_account.dart';
import 'package:synapsezero/application/settings/settings_store.dart';

/// Estado das configurações do jogador. A interface escuta este objeto e
/// chama os métodos abaixo; toda alteração é gravada no [SettingsStore].
class SettingsController extends ChangeNotifier {
  SettingsController({
    required SettingsStore store,
    required AccountService accountService,
  })  : _store = store,
        _accountService = accountService;

  final SettingsStore _store;
  final AccountService _accountService;

  SettingsData _data = const SettingsData();
  bool _signingIn = false;
  String? _error;
  bool _disposed = false;

  SettingsData get data => _data;
  bool get soundEffects => _data.soundEffects;
  bool get music => _data.music;
  PlayerAccount? get account => _data.account;

  /// Falso quando o login não está disponível nesta versão do app.
  bool get loginAvailable => _accountService.isAvailable;

  /// Verdadeiro enquanto o login está em andamento.
  bool get signingIn => _signingIn;

  /// Última mensagem de erro do login (nula se não houve erro).
  String? get error => _error;

  /// Lê as configurações gravadas. Se falhar, mantém os padrões.
  Future<void> load() async {
    try {
      _data = await _store.load();
    } catch (_) {
      _data = const SettingsData();
    }
    _notify();
  }

  Future<void> setSoundEffects(bool value) => _update(
        _data.copyWith(soundEffects: value),
      );

  Future<void> setMusic(bool value) => _update(_data.copyWith(music: value));

  Future<void> setAvatar(String avatarId) =>
      _update(_data.copyWith(avatarId: avatarId));

  Future<void> signIn(SocialProvider provider) async {
    if (_signingIn) return;
    _signingIn = true;
    _error = null;
    _notify();
    try {
      final account = await _accountService.signIn(provider);
      _signingIn = false;
      await _update(_data.copyWith(account: account));
    } on AccountException catch (e) {
      _signingIn = false;
      _error = e.message;
      _notify();
    } catch (_) {
      _signingIn = false;
      _error = 'Não foi possível entrar. Tente novamente.';
      _notify();
    }
  }

  Future<void> signOut() async {
    try {
      await _accountService.signOut();
    } catch (_) {
      // Sair localmente mesmo se o serviço falhar.
    }
    _error = null;
    await _update(_data.copyWith(clearAccount: true));
  }

  Future<void> _update(SettingsData next) async {
    _data = next;
    _notify();
    try {
      await _store.save(next);
    } catch (_) {
      // Falha ao gravar não deve travar o jogo; o valor segue em memória.
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
