// Propriedades que valem para QUALQUER semente, não só as dos vetores de
// referência: solvabilidade, determinismo e consistência da pontuação.
import 'package:synapse_core/synapse_core.dart';
import 'package:test/test.dart';

void main() {
  group('solvabilidade 100%', () {
    for (final diff in arenaDifficulties) {
      test('Arena ${diff.name}: 150 sementes', () {
        for (var seed = 1; seed <= 150; seed++) {
          final level = generateLevel(arenaSpec(diff.key, seed * 7919));
          final solvedRots = <int>[
            for (final t in level.tiles) t.solved != null ? t.solved!.first : t.rot,
          ];
          expect(level.evaluate(solvedRots).solved, isTrue, reason: '${diff.key} semente ${seed * 7919} deveria ter solução');
          expect(level.evaluate(level.initialRots).solved, isFalse, reason: '${diff.key} semente ${seed * 7919} já começa resolvido');
          expect(level.budget, greaterThanOrEqualTo(level.optCW + 2));
          expect(level.optBoth, lessThanOrEqualTo(level.optCW));
        }
      });
    }

    test('Trilha: 20 níveis solúveis e sem circuito de emergência', () {
      for (var i = 0; i < trailLength; i++) {
        final level = generateLevel(trailSpec(i));
        expect(level.fallback, isFalse, reason: 'nível ${i + 1} caiu no caminho de emergência');
        final solvedRots = <int>[
          for (final t in level.tiles) t.solved != null ? t.solved!.first : t.rot,
        ];
        expect(level.evaluate(solvedRots).solved, isTrue, reason: 'nível ${i + 1}');
      }
    });
  });

  group('determinismo', () {
    test('mesma especificação gera o mesmo circuito', () {
      final a = generateLevel(dailySpec('2026-11-19', 2));
      final b = generateLevel(dailySpec('2026-11-19', 2));
      expect(a.initialRots, b.initialRots);
      expect(a.nets.map((n) => n.path).toList(), b.nets.map((n) => n.path).toList());
      expect(a.budget, b.budget);
    });

    test('dias diferentes geram circuitos diferentes', () {
      final a = generateLevel(dailySpec('2026-11-19', 0));
      final b = generateLevel(dailySpec('2026-11-20', 0));
      expect(a.seed, isNot(b.seed));
    });
  });

  group('partida', () {
    test('solução ótima vence com 3 estrelas', () {
      final level = generateLevel(trailSpec(3));
      final game = GameSession(level);
      for (var i = 0; i < level.tiles.length; i++) {
        final t = level.tiles[i];
        if (t.solved == null) continue;
        var turns = 4;
        for (final r in t.solved!) {
          final need = (r - t.rot + 4) % 4;
          if (need < turns) turns = need;
        }
        for (var k = 0; k < turns; k++) {
          game.tap(i);
        }
      }
      expect(game.status, GameStatus.won);
      expect(game.result!.stars, 3);
      expect(game.moves, level.optCW);
    });

    test('toques depois do fim da partida são ignorados', () {
      final level = generateLevel(trailSpec(0));
      final game = GameSession(level);
      final dummy = level.tiles.indexWhere((t) => t.role == TileRole.decoy);
      var guard = 0;
      while (!game.isOver && guard++ < 500) {
        game.tap(dummy);
      }
      final clicksAtEnd = game.clicks;
      final outcome = game.tap(dummy);
      expect(outcome.accepted, isFalse);
      expect(game.clicks, clicksAtEnd);
      expect(game.undo(), isFalse);
    });

    test('desfazer devolve o clique e a rotação', () {
      final level = generateLevel(trailSpec(1));
      final game = GameSession(level);
      final before = game.rots;
      final clicks = game.clicks;
      game.tap(0);
      expect(game.canUndo, isTrue);
      expect(game.undo(), isTrue);
      expect(game.rots, before);
      expect(game.clicks, clicks);
      expect(game.moves, 0);
    });
  });
}
