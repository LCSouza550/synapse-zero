/// Avatar neural escolhido pelo jogador (emoji do conceito visual).
class Avatar {
  const Avatar({required this.id, required this.emoji, required this.label});

  /// Identificador estável, gravado nas configurações. Nunca renomear.
  final String id;
  final String emoji;

  /// Nome para leitores de tela.
  final String label;
}

const List<Avatar> avatars = [
  Avatar(id: 'brain', emoji: '🧠', label: 'Cérebro'),
  Avatar(id: 'bolt', emoji: '⚡', label: 'Raio'),
  Avatar(id: 'robot', emoji: '🤖', label: 'Robô'),
  Avatar(id: 'dna', emoji: '🧬', label: 'DNA'),
  Avatar(id: 'satellite', emoji: '🛰️', label: 'Satélite'),
  Avatar(id: 'crystal', emoji: '🔮', label: 'Bola de cristal'),
  Avatar(id: 'fox', emoji: '🦊', label: 'Raposa'),
  Avatar(id: 'alien', emoji: '👾', label: 'Alienígena'),
];

/// Avatar inicial (o mesmo do conceito visual).
final Avatar defaultAvatar = avatars.firstWhere((a) => a.id == 'satellite');

/// Avatar com o [id] dado; um id desconhecido (por exemplo, de uma versão
/// futura) volta ao padrão.
Avatar avatarById(String? id) {
  for (final avatar in avatars) {
    if (avatar.id == id) return avatar;
  }
  return defaultAvatar;
}
