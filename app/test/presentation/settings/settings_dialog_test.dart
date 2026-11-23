import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:synapsezero/application/settings/player_account.dart';
import 'package:synapsezero/application/settings/settings_controller.dart';
import 'package:synapsezero/application/settings/settings_store.dart';
import 'package:synapsezero/presentation/settings/settings_dialog.dart';
import 'package:synapsezero/presentation/theme/app_theme.dart';

Future<(SettingsController, InMemorySettingsStore)> _open(
  WidgetTester tester, {
  bool release = false,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  final store = InMemorySettingsStore();
  final settings = SettingsController(
    store: store,
    accountService: SimulatedAccountService(
      isRelease: release,
      delay: Duration.zero,
    ),
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(body: Center(child: SettingsDialog(settings: settings))),
    ),
  );
  await tester.pumpAndSettle();
  return (settings, store);
}

void main() {
  testWidgets('mostra as opções e os 8 avatares', (tester) async {
    await _open(tester);
    expect(find.text('Configurações'), findsOneWidget);
    expect(find.text('Efeitos sonoros'), findsOneWidget);
    expect(find.text('Música tema'), findsOneWidget);
    for (final emoji in ['🧠', '⚡', '🤖', '🧬', '🛰️', '🔮', '🦊', '👾']) {
      expect(find.text(emoji), findsOneWidget);
    }
  });

  testWidgets('desliga e religa efeitos sonoros e música', (tester) async {
    final (settings, store) = await _open(tester);

    await tester.tap(find.text('Efeitos sonoros'));
    await tester.pump();
    expect(settings.soundEffects, isFalse);
    expect(store.saved.soundEffects, isFalse);

    await tester.tap(find.text('Música tema'));
    await tester.pump();
    expect(settings.music, isFalse);

    await tester.tap(find.text('Música tema'));
    await tester.pump();
    expect(settings.music, isTrue);
  });

  testWidgets('escolher um avatar o grava', (tester) async {
    final (settings, store) = await _open(tester);
    await tester.tap(find.text('🧠'));
    await tester.pump();
    expect(settings.data.avatarId, 'brain');
    expect(store.saved.avatarId, 'brain');
  });

  testWidgets('login simulado e saída', (tester) async {
    final (settings, _) = await _open(tester);

    await tester.tap(find.text('Entrar com Google'));
    await tester.pumpAndSettle();
    expect(settings.account?.provider, SocialProvider.google);
    expect(find.text('Conectado com Google'), findsOneWidget);
    expect(find.textContaining('(simulada)'), findsOneWidget);
    expect(find.text('Entrar com Google'), findsNothing);

    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();
    expect(settings.account, isNull);
    expect(find.text('Entrar com Facebook'), findsOneWidget);
  });

  testWidgets('em release não oferece login', (tester) async {
    await _open(tester, release: true);
    expect(find.text('Login em breve.'), findsOneWidget);
    expect(find.text('Entrar com Google'), findsNothing);
    expect(find.text('Entrar com Facebook'), findsNothing);
  });
}
