import 'package:material_ui/material_ui.dart';

import 'presentation/home/home_placeholder.dart';
import 'presentation/splash/splash_screen.dart';

void main() {
  runApp(const SynapseZeroApp());
}

class SynapseZeroApp extends StatelessWidget {
  const SynapseZeroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SYNAPSE // ZERO',
      debugShowCheckedModeBanner: false,
      home: const _Root(),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    return SplashScreen(
      onFinished: () {
        // Troca para a tela principal com fade de 450 ms, como o protótipo.
        Navigator.of(context).pushReplacement(
          PageRouteBuilder<void>(
            transitionDuration: const Duration(milliseconds: 450),
            pageBuilder: (_, _, _) => const HomePlaceholder(),
            transitionsBuilder: (_, animation, _, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
      },
    );
  }
}
