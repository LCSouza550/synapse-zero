import 'package:material_ui/material_ui.dart';
import 'package:synapsezero/presentation/home/home_placeholder.dart';
import 'package:synapsezero/presentation/splash/splash_screen.dart';
import 'package:synapsezero/presentation/theme/synapse_palette.dart';

class SynapseZeroApp extends StatelessWidget {
  const SynapseZeroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Synapse Zero',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: SynapsePalette.background,
        useMaterial3: true,
      ),
      home: const _Root(),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: _splashDone
          ? const HomePlaceholder(key: ValueKey('home'))
          : SplashScreen(
              key: const ValueKey('splash'),
              onFinished: () => setState(() => _splashDone = true),
            ),
    );
  }
}