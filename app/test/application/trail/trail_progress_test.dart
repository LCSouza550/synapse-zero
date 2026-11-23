import 'package:flutter_test/flutter_test.dart';
import 'package:synapse_core/synapse_core.dart';
import 'package:synapsezero/application/trail/trail_progress.dart';

void main() {
  group('TrailProgress', () {
    test('começa sem nada concluído, com o primeiro nível atual', () {
      final p = TrailProgress.empty();
      expect(p.completedCount, 0);
      expect(p.totalStars, 0);
      expect(p.totalPoints, 0);
      expect(p.currentIndex, 0);
      expect(p.stateOf(0), TrailNodeState.current);
      expect(p.stateOf(1), TrailNodeState.locked);
      expect(p.stateOf(trailLength - 1), TrailNodeState.locked);
      expect(TrailProgress.maxStars, 180);
    });

    test('concluir o nível atual libera o próximo', () {
      final p = TrailProgress.empty().withResult(0, stars: 2, score: 400);
      expect(p.stateOf(0), TrailNodeState.done);
      expect(p.starsAt(0), 2);
      expect(p.currentIndex, 1);
      expect(p.stateOf(1), TrailNodeState.current);
      expect(p.canPlay(0), isTrue);
      expect(p.canPlay(1), isTrue);
      expect(p.canPlay(2), isFalse);
    });

    test('refazer um nível guarda o melhor resultado', () {
      var p = TrailProgress.empty().withResult(0, stars: 3, score: 500);
      p = p.withResult(0, stars: 1, score: 200);
      expect(p.starsAt(0), 3);
      expect(p.scoreAt(0), 500);
      p = p.withResult(0, stars: 3, score: 650);
      expect(p.scoreAt(0), 650);
      expect(p.totalPoints, 650);
    });

    test('estrelas ficam entre 1 e 3', () {
      var p = TrailProgress.empty().withResult(0, stars: 9, score: 1);
      expect(p.starsAt(0), 3);
      p = p.withResult(1, stars: 0, score: 1);
      expect(p.starsAt(1), 1);
    });

    test('é imutável: withResult não altera o original', () {
      final original = TrailProgress.empty();
      original.withResult(0, stars: 3, score: 100);
      expect(original.starsAt(0), 0);
    });

    test('trilha concluída: não há nível atual e o foco é o último', () {
      final p = TrailProgress.fromLists(stars: List.filled(trailLength, 3));
      expect(p.currentIndex, isNull);
      expect(p.focusIndex, trailLength - 1);
      expect(p.completedCount, trailLength);
      expect(p.totalStars, TrailProgress.maxStars);
      expect(p.stateOf(trailLength - 1), TrailNodeState.done);
    });

    test('fromLists completa listas curtas (progresso de 20 níveis)', () {
      final p = TrailProgress.fromLists(
        stars: List.filled(20, 2),
        scores: List.filled(20, 100),
      );
      expect(p.completedCount, 20);
      expect(p.currentIndex, 20);
      expect(p.totalPoints, 2000);
      expect(p.stars.length, trailLength);
    });

    test('fromLists descarta excedentes e normaliza valores', () {
      final p = TrailProgress.fromLists(
        stars: [5, -2, 1, ...List.filled(100, 3)],
        scores: [-50, 10],
      );
      expect(p.stars.length, trailLength);
      expect(p.starsAt(0), 3);
      expect(p.starsAt(1), 0);
      expect(p.starsAt(2), 1);
      expect(p.scoreAt(0), 0);
      expect(p.scoreAt(1), 10);
    });
  });
}
