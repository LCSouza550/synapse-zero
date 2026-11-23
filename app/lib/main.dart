import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:synapsezero/app.dart';
import 'package:synapsezero/application/settings/player_account.dart';
import 'package:synapsezero/application/settings/settings_controller.dart';
import 'package:synapsezero/application/settings/shared_preferences_settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
  // As configurações são lidas antes da primeira tela: a splash já respeita
  // a opção de efeitos sonoros.
  final settings = SettingsController(
    store: SharedPreferencesSettingsStore(),
    accountService: const SimulatedAccountService(),
  );
  await settings.load();
  runApp(SynapseZeroApp(settings: settings));
}
