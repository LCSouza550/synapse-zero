import 'evaluator.dart';
import 'models.dart';
import 'scoring.dart';

enum GameStatus { playing, won, lost }

/// Resultado de uma vitória.
class WinResult {
  const WinResult({required this.stars, required this.score});

  final int stars;

  /// Pontuação desta partida (antes de comparar com o recorde salvo).
  final int score;
}

/// Efeito de um toque, para a interface reagir (som, animação, háptico).
class TapOutcome {
  const TapOutcome({
    required this.accepted,
    this.bonusCells = const [],
    this.newlyConnected = false,
    this.status = GameStatus.playing,
  });

  /// Falso se o toque foi ignorado (partida encerrada ou sem cliques).
  final bool accepted;

  /// Células de bônus ⚡+2 que acabaram de ser energizadas.
  final List<int> bonusCells;

  /// Verdadeiro se alguma rede acabou de se conectar (e a partida segue).
  final bool newlyConnected;
  final GameStatus status;
}

class _Move {
  const _Move(this.index, this.clockwise, this.bonusCells);

  final int index;
  final bool clockwise;
  final List<int> bonusCells;
}

/// Regras de uma partida: cliques, bônus, desfazer, vitória e colapso.
/// Sem dependência de interface; a UI apenas chama [tap], [undo] e [reset]
/// e se redesenha a partir do estado exposto.
class GameSession {
  GameSession(this.level) {
    _start();
  }

  final Level level;

  late List<int> _rots;
  late List<int> _quarterTurns;
  late int _clicks;
  late int _cap;
  late int _moves;
  late List<bool> _prevSolved;
  final Set<int> _claimed = <int>{};
  final List<_Move> _history = <_Move>[];
  GameStatus _status = GameStatus.playing;
  WinResult? _result;
  late Evaluation _evaluation;

  /// Rotação atual de cada célula (0 a 3).
  List<int> get rots => List<int>.unmodifiable(_rots);

  /// Giros acumulados por célula (positivo = horário), sem módulo, para a
  /// animação girar sempre no sentido certo.
  List<int> get quarterTurns => List<int>.unmodifiable(_quarterTurns);

  int get clicks => _clicks;

  /// Total de cliques da partida, incluindo bônus recebidos.
  int get cap => _cap;
  int get moves => _moves;
  GameStatus get status => _status;
  bool get isOver => _status != GameStatus.playing;
  bool get canUndo => !isOver && _history.isNotEmpty;
  Evaluation get evaluation => _evaluation;

  /// Bônus já coletados.
  Set<int> get claimedBonuses => Set<int>.unmodifiable(_claimed);

  /// Resultado, disponível só depois da vitória.
  WinResult? get result => _result;

  void _start() {
    _rots = level.initialRots;
    _quarterTurns = _rots.map((r) => r).toList();
    _clicks = level.budget;
    _cap = level.budget;
    _moves = 0;
    _prevSolved = List<bool>.filled(level.nets.length, false);
    _claimed.clear();
    _history.clear();
    _status = GameStatus.playing;
    _result = null;
    _evaluation = level.evaluate(_rots);
    _claimBonuses(_evaluation);
  }

  List<int> _claimBonuses(Evaluation ev) {
    final got = <int>[];
    for (final i in level.bonus) {
      if (!_claimed.contains(i) && ev.lit[i] >= 0) {
        _claimed.add(i);
        _clicks += 2;
        _cap += 2;
        got.add(i);
      }
    }
    return got;
  }

  /// Gira o conduíte [index] 90°. Gasta um clique.
  TapOutcome tap(int index, {bool counterClockwise = false}) {
    if (isOver || _clicks <= 0) return TapOutcome(accepted: false, status: _status);
    final clockwise = !counterClockwise;
    _rots[index] = (_rots[index] + (clockwise ? 1 : 3)) % 4;
    _quarterTurns[index] += clockwise ? 1 : -1;
    _clicks--;
    _moves++;
    final bonusCells = _claimBonuses(level.evaluate(_rots));
    _history.add(_Move(index, clockwise, bonusCells));
    _evaluation = level.evaluate(_rots);

    var newly = false;
    for (var k = 0; k < _evaluation.netSolved.length; k++) {
      if (_evaluation.netSolved[k] && !_prevSolved[k]) newly = true;
    }
    _prevSolved = List<bool>.of(_evaluation.netSolved);

    if (_evaluation.solved) {
      _status = GameStatus.won;
      final stars = starsFor(level, _moves);
      _result = WinResult(stars: stars, score: scoreFor(level, _clicks, stars));
    } else if (_clicks <= 0) {
      _status = GameStatus.lost;
    }
    return TapOutcome(
      accepted: true,
      bonusCells: bonusCells,
      newlyConnected: newly && _status == GameStatus.playing,
      status: _status,
    );
  }

  /// Desfaz o último toque, devolvendo o clique e retirando bônus que ele
  /// tenha liberado. Retorna falso se não há o que desfazer.
  bool undo() {
    if (!canUndo) return false;
    final h = _history.removeLast();
    _rots[h.index] = (_rots[h.index] + (h.clockwise ? 3 : 1)) % 4;
    _quarterTurns[h.index] -= h.clockwise ? 1 : -1;
    _clicks++;
    _moves--;
    for (final i in h.bonusCells) {
      _claimed.remove(i);
      _clicks -= 2;
      _cap -= 2;
    }
    _evaluation = level.evaluate(_rots);
    _prevSolved = List<bool>.of(_evaluation.netSolved);
    return true;
  }

  /// Volta ao circuito inicial, com o orçamento original de cliques.
  void reset() => _start();
}
