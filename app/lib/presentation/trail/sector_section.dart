import 'package:material_ui/material_ui.dart';
import 'package:synapse_core/synapse_core.dart';
import 'package:synapsezero/application/settings/avatars.dart';
import 'package:synapsezero/application/trail/trail_progress.dart';
import 'package:synapsezero/presentation/theme/app_colors.dart';
import 'package:synapsezero/presentation/theme/app_typography.dart';
import 'package:synapsezero/presentation/trail/trail_map.dart';

/// Um setor da trilha: cabeçalho com nome e faixa de níveis, e o mapa.
class SectorSection extends StatelessWidget {
  const SectorSection({
    super.key,
    required this.sectorIndex,
    required this.progress,
    required this.onLevelSelected,
    required this.nodeKeys,
    required this.avatar,
    required this.avatarAt,
    required this.avatarLevel,
    this.travel,
    this.travelFrom,
  });

  final int sectorIndex;
  final TrailProgress progress;
  final ValueChanged<int> onLevelSelected;

  /// Repassados ao mapa (ver [TrailMap]).
  final List<GlobalKey> nodeKeys;
  final Avatar avatar;
  final int? avatarAt;
  final int avatarLevel;
  final Animation<double>? travel;
  final int? travelFrom;

  /// Setores à frente do nível atual aparecem apagados, como no protótipo.
  bool get _locked {
    final current = progress.currentIndex;
    return current != null && sectorIndex * levelsPerSector > current;
  }

  @override
  Widget build(BuildContext context) {
    final first = sectorIndex * levelsPerSector + 1;
    final last = first + levelsPerSector - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectorHeader(
          title: 'Setor ${sectorIndex + 1} • ${sectors[sectorIndex].name}',
          range: 'Etapas $first–$last',
          locked: _locked,
        ),
        const SizedBox(height: 8),
        TrailMap(
          sectorIndex: sectorIndex,
          progress: progress,
          onLevelSelected: onLevelSelected,
          nodeKeys: nodeKeys,
          avatar: avatar,
          avatarAt: avatarAt,
          avatarLevel: avatarLevel,
          travel: travel,
          travelFrom: travelFrom,
        ),
      ],
    );
  }
}

class _SectorHeader extends StatelessWidget {
  const _SectorHeader({
    required this.title,
    required this.range,
    required this.locked,
  });

  final String title;
  final String range;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 10, 14, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    range,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 3,
              child: ColoredBox(
                color: locked ? AppColors.line : AppColors.alfa,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
