// Compara o núcleo Dart com os resultados do protótipo JavaScript original.
// Os vetores são gerados por tool/gen_golden.js a partir do HTML do protótipo.
import 'dart:convert';
import 'dart:io';

import 'package:synapse_core/synapse_core.dart';
import 'package:test/test.dart';

typedef Json = Map<String, dynamic>;

List<int> ints(Object? v) => (v! as List<dynamic>).cast<int>();
List<bool> bools(Object? v) => (v! as List<dynamic>).cast<bool>();
List<Json> maps(Object? v) => (v! as List<dynamic>).cast<Json>();
double dbl(Object? v) => (v! as num).toDouble();

LevelSpec specFromContext(Json ctx) {
  switch (ctx['mode']) {
    case 'trail':
      return trailSpec(ctx['index'] as int);
    case 'daily':
      return dailySpec(ctx['day'] as String, ctx['stage'] as int);
    default:
      return arenaSpec(ctx['diff'] as String, ctx['seed'] as int);
  }
}

void expectEvaluation(Evaluation actual, Json expected, String label) {
  expect(actual.lit, ints(expected['lit']), reason: '$label: lit');
  expect(actual.netSolved, bools(expected['netSolved']), reason: '$label: netSolved');
  expect(actual.fed, bools(expected['fed']), reason: '$label: fed');
  expect(actual.litCount, expected['litCount'], reason: '$label: litCount');
  expect(actual.solved, expected['solved'], reason: '$label: solved');
}

void expectSnapshot(GameSession s, Json e, String label) {
  expect(s.clicks, e['clicks'], reason: '$label: clicks');
  expect(s.cap, e['cap'], reason: '$label: cap');
  expect(s.moves, e['moves'], reason: '$label: moves');
  expect(s.status.name, e['status'], reason: '$label: status');
  expect(s.rots, ints(e['rots']), reason: '$label: rots');
  expect(s.quarterTurns, ints(e['quarterTurns']), reason: '$label: quarterTurns');
  expect(s.claimedBonuses.toList()..sort(), ints(e['claimed']), reason: '$label: bônus');
  expect(s.evaluation.litCount, e['litCount'], reason: '$label: litCount');
  expect(s.evaluation.netSolved, bools(e['netSolved']), reason: '$label: netSolved');
  final result = e['result'] as Json?;
  if (result == null) {
    expect(s.result, isNull, reason: '$label: result');
  } else {
    expect(s.result, isNotNull, reason: '$label: result');
    expect(s.result!.stars, result['stars'], reason: '$label: estrelas');
    expect(s.result!.score, result['gained'], reason: '$label: pontos');
  }
}

void main() {
  final vectors = jsonDecode(File('test/golden/core_vectors.json').readAsStringSync()) as Json;

  group('PRNG e hash', () {
    for (final entry in maps(vectors['rng'])) {
      test('mulberry32 semente ${entry['seed']}', () {
        final rnd = Mulberry32(entry['seed'] as int);
        for (final expected in (entry['values'] as List<dynamic>)) {
          expect(rnd.next(), dbl(expected));
        }
      });
    }
    for (final entry in maps(vectors['hash'])) {
      test('hashString "${entry['input']}"', () {
        expect(hashString(entry['input'] as String), entry['value']);
      });
    }
    test('rotMask', () {
      for (final e in maps(vectors['rotMask'])) {
        expect(rotMask(e['mask'] as int, e['rot'] as int), e['value'], reason: '${e['mask']} / ${e['rot']}');
      }
    });
  });

  group('especificações', () {
    void expectSpec(LevelSpec s, Json e, String label) {
      expect(s.size, e['size'], reason: '$label: size');
      expect(s.nets, e['nets'], reason: '$label: nets');
      expect(s.winding, dbl(e['winding']), reason: '$label: winding');
      expect(s.slack, dbl(e['slack']), reason: '$label: slack');
      expect(s.seed, e['seed'], reason: '$label: seed');
      expect(s.bonus, e['bonus'], reason: '$label: bonus');
      expect(s.complexity, e['complexity'], reason: '$label: complexity');
      expect(s.name, e['name'], reason: '$label: name');
    }

    test('Trilha Neural (20 níveis)', () {
      final specs = maps(vectors['trailSpecs']);
      for (var i = 0; i < specs.length; i++) {
        expectSpec(trailSpec(i), specs[i], 'trilha $i');
        expect(trailSpec(i).boss, specs[i]['boss'], reason: 'trilha $i: boss');
      }
    });
    test('Desafio Diário', () {
      for (final e in maps(vectors['dailySpecs'])) {
        expectSpec(dailySpec(e['day'] as String, e['stage'] as int), e['spec'] as Json, '${e['day']}:${e['stage']}');
      }
    });
    test('Modo Arena', () {
      for (final e in maps(vectors['arenaSpecs'])) {
        expectSpec(arenaSpec(e['diff'] as String, e['seed'] as int), e['spec'] as Json, 'arena ${e['diff']}');
      }
    });
  });

  group('circuitos idênticos ao protótipo', () {
    for (final entry in maps(vectors['levels'])) {
      final label = entry['label'] as String;
      final expected = entry['level'] as Json;

      test(label, () {
        final level = generateLevel(specFromContext(entry['ctx'] as Json));

        expect(level.n, expected['n']);
        expect(level.seed, expected['seed']);
        expect(level.fallback, expected['fallback']);
        expect(level.optCW, expected['optCW']);
        expect(level.optBoth, expected['optBoth']);
        expect(level.slack, expected['slack']);
        expect(level.budget, expected['budget']);
        expect(level.pathTiles, expected['pathTiles']);
        expect(level.bonus, ints(expected['bonus']));
        final meta = expected['meta'] as Json;
        expect(level.meta.name, meta['name']);
        expect(level.meta.complexity, meta['complexity']);
        expect(level.meta.boss, meta['boss']);

        final nets = maps(expected['nets']);
        expect(level.nets.length, nets.length);
        for (var k = 0; k < nets.length; k++) {
          expect(level.nets[k].src, nets[k]['src']);
          expect(level.nets[k].dst, nets[k]['dst']);
          expect(level.nets[k].inRow, nets[k]['inRow']);
          expect(level.nets[k].outRow, nets[k]['outRow']);
          expect(level.nets[k].path, ints(nets[k]['path']));
        }

        final tiles = maps(expected['tiles']);
        expect(level.tiles.length, tiles.length);
        for (var i = 0; i < tiles.length; i++) {
          final t = level.tiles[i];
          expect(t.role.name, tiles[i]['kind'], reason: 'célula $i: papel');
          expect(t.net, tiles[i]['net'], reason: 'célula $i: rede');
          expect(t.pos, tiles[i]['pos'], reason: 'célula $i: posição');
          expect(t.mask, tiles[i]['mask'], reason: 'célula $i: máscara');
          expect(t.rot, tiles[i]['rot'], reason: 'célula $i: rotação');
          final solved = tiles[i]['solved'];
          if (solved == null) {
            expect(t.solved, isNull, reason: 'célula $i: solved');
          } else {
            expect(t.solved, ints(solved), reason: 'célula $i: solved');
          }
        }

        expectEvaluation(level.evaluate(level.initialRots), entry['evalInitial'] as Json, '$label inicial');
        expectEvaluation(level.evaluate(ints(entry['solvedRots'])), entry['evalSolved'] as Json, '$label resolvido');

        for (final s in maps(entry['scoring'])) {
          final moves = s['moves'] as int;
          expect(starsFor(level, moves), s['stars'], reason: '$label: estrelas com $moves movimentos');
          final left = level.budget - moves;
          expect(scoreFor(level, left, s['stars'] as int), s['score'], reason: '$label: pontos');
          expect(scoreFor(level, left, s['stars'] as int, assist: true), s['assistScore'], reason: '$label: pontos assistidos');
        }
      });

      test('$label: sessões de jogo', () {
        final level = generateLevel(specFromContext(entry['ctx'] as Json));
        for (final session in maps(entry['sessions'])) {
          final name = '$label/${session['name']}';
          final game = GameSession(level);
          expectSnapshot(game, session['initial'] as Json, '$name inicial');
          final ops = maps(session['ops']);
          final steps = maps(session['steps']);
          for (var i = 0; i < ops.length; i++) {
            final op = ops[i];
            switch (op['op']) {
              case 'tap':
                game.tap(op['i'] as int, counterClockwise: op['ccw'] as bool);
              case 'undo':
                game.undo();
              default:
                game.reset();
            }
            expectSnapshot(game, steps[i], '$name passo $i');
          }
        }
      });
    }
  });

  group('ofensiva diária', () {
    final dates = vectors['dates'] as Json;
    test('prevDateKey', () {
      for (final e in maps(dates['prev'])) {
        expect(prevDateKey(e['key'] as String), e['prev']);
      }
    });
    test('streakAfterCompletion', () {
      for (final e in maps(dates['streakAfter'])) {
        expect(streakAfterCompletion(e['streak'] as int, e['lastDone'] as String, e['today'] as String), e['value']);
      }
    });
    test('activeStreak', () {
      for (final e in maps(dates['active'])) {
        expect(activeStreak(e['streak'] as int, e['lastDone'] as String, e['today'] as String), e['value']);
      }
    });
  });
}
