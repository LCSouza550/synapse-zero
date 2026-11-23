import 'package:material_ui/material_ui.dart';
import 'package:synapse_core/synapse_core.dart';
import 'package:synapsezero/application/trail/level_result.dart';
import 'package:synapsezero/presentation/common/grid_background.dart';
import 'package:synapsezero/presentation/theme/app_colors.dart';
import 'package:synapsezero/presentation/theme/app_typography.dart';

/// TEMPORÁRIA: ocupa o lugar do tabuleiro até a próxima etapa. Devolve um
/// [LevelResult] (vitória) ou `null` (saiu sem vencer), exatamente como o
/// tabuleiro real fará.
class BoardPlaceholderScreen extends StatelessWidget {
  const BoardPlaceholderScreen({
    super.key,
    required this.levelIndex,
    this.allowSimulation = !const bool.fromEnvironment('dart.vm.product'),
  });

  final int levelIndex;

  /// Mostra o botão de vitória simulada (só em debug por padrão).
  final bool allowSimulation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: GridBackground()),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Nível ${levelIndex + 1}',
                      style: AppTextStyles.value.copyWith(color: AppColors.muted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      levelNames[levelIndex],
                      textAlign: TextAlign.center,
                      style: AppTextStyles.sheetTitle,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tabuleiro em construção',
                      style: AppTextStyles.body.copyWith(color: AppColors.muted),
                    ),
                    const SizedBox(height: 32),
                    if (allowSimulation)
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(
                          LevelResult(
                            stars: levelIndex % 3 + 1,
                            score: 300 + 20 * levelIndex,
                          ),
                        ),
                        child: Text(
                          'Simular vitória (${levelIndex % 3 + 1} ★)',
                          style: AppTextStyles.button,
                        ),
                      ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Voltar à trilha', style: AppTextStyles.button),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
