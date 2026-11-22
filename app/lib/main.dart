import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:synapsezero/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
  runApp(const SynapseZeroApp());
}