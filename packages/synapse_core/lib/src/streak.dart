String _pad2(int x) => x < 10 ? '0$x' : '$x';

/// Chave de data local no formato AAAA-MM-DD.
String dateKey(DateTime d) => '${d.year}-${_pad2(d.month)}-${_pad2(d.day)}';

/// Chave do dia anterior a [key] (AAAA-MM-DD).
String prevDateKey(String key) {
  final p = key.split('-').map(int.parse).toList();
  return dateKey(DateTime(p[0], p[1], p[2] - 1));
}

/// Nova ofensiva após concluir as 3 etapas do dia [today].
int streakAfterCompletion(int prevStreak, String lastDone, String today) {
  if (lastDone == today) return prevStreak;
  if (lastDone == prevDateKey(today)) return prevStreak + 1;
  return 1;
}

/// Ofensiva a exibir: zera se o jogador deixou passar um dia.
int activeStreak(int streak, String lastDone, String today) {
  return lastDone == today || lastDone == prevDateKey(today) ? streak : 0;
}
