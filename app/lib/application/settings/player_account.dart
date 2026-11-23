/// Redes sociais oferecidas para entrar no jogo.
enum SocialProvider {
  google('Google'),
  facebook('Facebook');

  const SocialProvider(this.label);
  final String label;
}

/// Conta do jogador numa rede social.
class PlayerAccount {
  const PlayerAccount({
    required this.provider,
    required this.displayName,
    this.isSimulated = false,
  });

  final SocialProvider provider;
  final String displayName;

  /// Verdadeiro para a conta de teste criada sem login real.
  final bool isSimulated;

  @override
  bool operator ==(Object other) =>
      other is PlayerAccount &&
      other.provider == provider &&
      other.displayName == displayName &&
      other.isSimulated == isSimulated;

  @override
  int get hashCode => Object.hash(provider, displayName, isSimulated);
}

class AccountException implements Exception {
  const AccountException(this.message);
  final String message;

  @override
  String toString() => 'AccountException: $message';
}

/// Contrato do login social. A tela só conhece esta interface: o login real
/// (Google Sign-In, Facebook, Firebase Auth) entra trocando a implementação.
abstract interface class AccountService {
  /// Falso quando o login não está disponível nesta versão do app.
  bool get isAvailable;

  /// Abre o fluxo de login. Lança [AccountException] se falhar ou for cancelado.
  Future<PlayerAccount> signIn(SocialProvider provider);

  Future<void> signOut();
}

/// Login de mentira, para validar a interface. Cria uma conta de teste
/// claramente identificada e fica indisponível em builds de release, para
/// nenhum jogador real ver uma conta falsa.
class SimulatedAccountService implements AccountService {
  const SimulatedAccountService({
    this.isRelease = const bool.fromEnvironment('dart.vm.product'),
    this.delay = const Duration(milliseconds: 600),
  });

  final bool isRelease;
  final Duration delay;

  @override
  bool get isAvailable => !isRelease;

  @override
  Future<PlayerAccount> signIn(SocialProvider provider) async {
    if (!isAvailable) {
      throw const AccountException('Login indisponível nesta versão.');
    }
    await Future<void>.delayed(delay);
    return PlayerAccount(
      provider: provider,
      displayName: 'Conta de teste',
      isSimulated: true,
    );
  }

  @override
  Future<void> signOut() async {}
}
