import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:synapsezero/application/audio/game_sounds.dart';
import 'package:synapsezero/application/settings/player_account.dart';
import 'package:synapsezero/application/settings/settings_controller.dart';
import 'package:synapsezero/application/settings/settings_store.dart';
import 'package:synapsezero/application/trail/level_result.dart';
import 'package:synapsezero/application/trail/trail_progress.dart';
import 'package:synapsezero/presentation/theme/app_theme.dart';
import 'package:synapsezero/presentation/trail/avatar_token.dart';
import 'package:synapsezero/presentation/trail/trail_flow.dart';

/// Tabuleiro de mentira: "Vencer" devolve 2 estrelas; "Sair" não devolve nada.
Widget _board(BuildContext context, int level) {
  return Scaffold(
    body: Column(
      children: [
        Text('TABULEIRO $level'),
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            const LevelResult(stars: 2, score: 100),
          ),
          child: const Text('Vencer'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Sair'),
        ),
      ],
    ),
  );
}

class _RecordingSounds implements GameSounds {
  final List<GameSound> played = [];

  @override
  Future<void> play(GameSound sound) async => played.add(sound);

  @override
  Future<void> dispose() async {}
}

SettingsController _settings() => SettingsController(
      store: InMemorySettingsStore(),
      accountService: const SimulatedAccountService(delay: Duration.zero),
    );

Future<void> _pump(
  WidgetTester tester, {
  TrailProgress? progress,
  SettingsController? settings,
  GameSounds sounds = const SilentGameSounds(),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: TrailFlow(
        settings: settings ?? _settings(),
        boardBuilder: _board,
        initialProgress: progress,
        sounds: sounds,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('vencer volta à trilha, o avatar anda e só então abre o próximo tabuleiro',
      (tester) async {
    await _pump(tester);
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    expect(find.text('TABULEIRO 0'), findsOneWidget);

    await tester.tap(find.text('Vencer'));
    // Logo depois de vencer, o próximo tabuleiro ainda não apareceu.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('TABULEIRO 1'), findsNothing);

    await tester.pumpAndSettle();
    expect(find.text('TABULEIRO 1'), findsOneWidget);

    // Sai sem vencer: a trilha mostra o progresso e o avatar no nível 2.
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();
    expect(find.text('TABULEIRO 1'), findsNothing);
    expect(find.textContaining('2 / 180'), findsOneWidget);
    final avatar = tester.getCenter(find.byType(AvatarToken));
    final level = tester.getCenter(find.text('2'));
    expect((avatar.dx - level.dx).abs(), lessThan(1));
  });

  testWidgets('sair sem vencer não muda nada', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    expect(find.textContaining('0 / 180'), findsOneWidget);
    expect(find.text('TABULEIRO 1'), findsNothing);
  });

  testWidgets('refazer um nível concluído não move o avatar nem abre outro', (tester) async {
    await _pump(tester, progress: TrailProgress.fromLists(stars: [3]));
    await tester.ensureVisible(find.text('1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    expect(find.text('TABULEIRO 0'), findsOneWidget);

    await tester.tap(find.text('Vencer'));
    await tester.pumpAndSettle();

    expect(find.textContaining('TABULEIRO'), findsNothing);
    final avatar = tester.getCenter(find.byType(AvatarToken));
    final level = tester.getCenter(find.text('2'));
    expect((avatar.dx - level.dx).abs(), lessThan(1));
  });

  testWidgets('vencer o último nível encerra o fluxo sem abrir outro', (tester) async {
    await _pump(
      tester,
      progress: TrailProgress.fromLists(stars: List.filled(59, 3)),
    );
    await tester.tap(find.text('👑').first);
    await tester.pumpAndSettle();
    expect(find.text('TABULEIRO 59'), findsOneWidget);

    await tester.tap(find.text('Vencer'));
    await tester.pumpAndSettle();

    expect(find.textContaining('TABULEIRO'), findsNothing);
    expect(find.textContaining('179 / 180'), findsOneWidget);
  });

  testWidgets('a engrenagem abre as configurações e trocar o avatar atualiza a trilha',
      (tester) async {
    await _pump(tester);
    await tester.tap(find.byTooltip('Configurações'));
    await tester.pumpAndSettle();
    expect(find.text('Efeitos sonoros'), findsOneWidget);

    await tester.tap(find.text('🧠'));
    await tester.pumpAndSettle();
    // A ficha da trilha e o avatar do cabeçalho passam a ser o escolhido.
    expect(
      find.descendant(of: find.byType(AvatarToken), matching: find.text('🧠')),
      findsOneWidget,
    );
  });

  testWidgets('toca efeito ao escolher o nível e ao avançar o avatar', (tester) async {
    final sounds = _RecordingSounds();
    await _pump(tester, sounds: sounds);
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    expect(sounds.played, [GameSound.tap]);

    await tester.tap(find.text('Vencer'));
    await tester.pumpAndSettle();
    expect(sounds.played, [GameSound.tap, GameSound.advance]);
  });

  testWidgets('refazer um nível concluído não toca o som de avanço', (tester) async {
    final sounds = _RecordingSounds();
    await _pump(
      tester,
      progress: TrailProgress.fromLists(stars: [3]),
      sounds: sounds,
    );
    await tester.ensureVisible(find.text('1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vencer'));
    await tester.pumpAndSettle();

    expect(sounds.played, [GameSound.tap]);
  });
}
