import 'package:material_ui/material_ui.dart';
import 'package:synapsezero/presentation/theme/synapse_palette.dart';

/// Substituída pela tela da Trilha Neural em etapa futura.
class HomePlaceholder extends StatelessWidget {
  const HomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: SynapsePalette.background,
      body: Center(
        child: Text(
          'Tela principal em construção',
          style: TextStyle(color: SynapsePalette.textPrimary),
        ),
      ),
    );
  }
}