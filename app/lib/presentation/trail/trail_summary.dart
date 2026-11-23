import 'package:material_ui/material_ui.dart';
import 'package:synapse_core/synapse_core.dart';
import 'package:synapsezero/application/trail/trail_progress.dart';
import 'package:synapsezero/presentation/theme/app_colors.dart';
import 'package:synapsezero/presentation/theme/app_typography.dart';

/// Resumo no topo da trilha: setor atual, estrelas, nódulos e pontos.
class TrailSummary extends StatelessWidget {
  const TrailSummary({super.key, required this.progress});

  final TrailProgress progress;

  @override
  Widget build(BuildContext context) {
    final sectorIndex = progress.focusIndex ~/ levelsPerSector;
    final muted = AppTextStyles.bodySmall.copyWith(color: AppColors.muted);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Setor ${sectorIndex + 1} • ${sectors[sectorIndex].name}',
                    style: AppTextStyles.heading.copyWith(color: AppColors.alfa),
                  ),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${progress.totalStars} / ${TrailProgress.maxStars} ',
                        ),
                        const TextSpan(
                          text: '★',
                          style: TextStyle(color: AppColors.star),
                        ),
                        TextSpan(
                          text: ' • ${progress.completedCount} / $trailLength Nódulos',
                        ),
                      ],
                    ),
                    style: muted,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('PONTOS', style: AppTextStyles.label),
                Text(
                  '${progress.totalPoints}',
                  style: AppTextStyles.points.copyWith(color: AppColors.beta),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
