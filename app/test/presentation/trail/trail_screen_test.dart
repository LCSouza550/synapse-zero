import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:synapse_core/synapse_core.dart';
import 'package:synapsezero/application/trail/trail_progress.dart';
import 'package:synapsezero/presentation/theme/app_theme.dart';
import 'package:synapsezero/presentation/trail/trail_screen.dart';

Widget _app(TrailProgress progress, ValueChanged<int> onSelected) {
  return MaterialApp(
    theme: AppTheme.dark(),
    home: TrailScreen(progress: progress, onLevelSelected: onSelected),
  );
}

void main() {
  testWidgets('mostra o resumo e o primeiro setor', (tester) async {
    await tester.pumpWidget(_app(TrailProgress.empty(), (_) {}));
    await tester.pumpAndSettle();

    expect(find.text('Setor 1 • Córtex Primário'), findsWidgets);
    expect(find.textContaining('0 / 180'), findsOneWidget);
    expect(find.textContaining('0 / $trailLength Nódulos'), findsOneWidget);
    expect(find.text('Primeiro Pulso'), findsOneWidget);
    expect(find.text('VOCÊ'), findsOneWidget);
  });

  testWidgets('tocar o nível atual chama o callback com o índice', (tester) async {
    final selected = <int>[];
    await tester.pumpWidget(_app(TrailProgress.empty(), selected.add));
    await tester.pumpAndSettle();

    await tester.tap(find.text('1'));
    expect(selected, [0]);
  });

  testWidgets('nível bloqueado não responde ao toque', (tester) async {
    final selected = <int>[];
    await tester.pumpWidget(_app(TrailProgress.empty(), selected.add));
    await tester.pumpAndSettle();

    await tester.tap(find.text('2'), warnIfMissed: false);
    expect(selected, isEmpty);
  });

  testWidgets('níveis concluídos mostram estrelas e podem ser refeitos', (tester) async {
    final selected = <int>[];
    final progress = TrailProgress.empty().withResult(0, stars: 2, score: 300);
    await tester.pumpWidget(_app(progress, selected.add));
    await tester.pumpAndSettle();

    expect(find.textContaining('2 / 180'), findsOneWidget);
    expect(find.textContaining('1 / $trailLength Nódulos'), findsOneWidget);
    expect(find.text('300'), findsOneWidget);

    await tester.tap(find.text('1'));
    expect(selected, [0]);
  });

  testWidgets('abre no setor do nível atual', (tester) async {
    final progress = TrailProgress.fromLists(stars: List.filled(6, 3));
    await tester.pumpWidget(_app(progress, (_) {}));
    await tester.pumpAndSettle();

    // Resumo e cabeçalho do setor 2.
    expect(find.text('Setor 2 • Ponte Sináptica'), findsWidgets);
    expect(find.text('Etapas 6–10'), findsOneWidget);
  });

  testWidgets('trilha concluída: resumo mostra o último setor', (tester) async {
    final progress = TrailProgress.fromLists(stars: List.filled(trailLength, 3));
    await tester.pumpWidget(_app(progress, (_) {}));
    await tester.pumpAndSettle();

    expect(find.text('Setor 12 • Ponto Zero'), findsWidgets);
    expect(find.textContaining('180 / 180'), findsOneWidget);
    expect(find.text('VOCÊ'), findsNothing);
  });

  testWidgets('a trilha sobe: nível 1 abaixo do 2, setor 1 abaixo do setor 2', (tester) async {
    await tester.pumpWidget(_app(TrailProgress.empty(), (_) {}));
    await tester.pumpAndSettle();

    final level1 = tester.getCenter(find.text('1')).dy;
    final level2 = tester.getCenter(find.text('2')).dy;
    final level5 = tester.getCenter(find.text('👑').first).dy;
    expect(level1, greaterThan(level2));
    expect(level2, greaterThan(level5));

    final sector1 = tester.getCenter(find.text('Etapas 1–5')).dy;
    final sector2 = tester.getCenter(find.text('Etapas 6–10')).dy;
    expect(sector1, greaterThan(sector2));
  });

  testWidgets('abre com o nível atual visível, sem rolar à mão', (tester) async {
    await tester.pumpWidget(_app(TrailProgress.empty(), (_) {}));
    await tester.pumpAndSettle();

    final viewport = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final y = tester.getCenter(find.text('1')).dy;
    expect(y, inInclusiveRange(0, viewport));
  });

  testWidgets('ao concluir um nível, a tela acompanha o novo nível atual', (tester) async {
    var progress = TrailProgress.fromLists(stars: List.filled(4, 3));
    late StateSetter update;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          update = setState;
          return _app(progress, (_) {});
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('VOCÊ'), findsOneWidget);

    update(() => progress = progress.withResult(4, stars: 3, score: 1));
    await tester.pumpAndSettle();

    final viewport = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final y = tester.getCenter(find.text('6')).dy;
    expect(y, inInclusiveRange(0, viewport));
  });
}
