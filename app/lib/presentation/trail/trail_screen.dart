import 'package:material_ui/material_ui.dart';
import 'package:synapse_core/synapse_core.dart';
import 'package:synapsezero/application/trail/trail_progress.dart';
import 'package:synapsezero/presentation/common/grid_background.dart';
import 'package:synapsezero/presentation/theme/app_colors.dart';
import 'package:synapsezero/presentation/theme/app_typography.dart';
import 'package:synapsezero/presentation/trail/sector_section.dart';
import 'package:synapsezero/presentation/trail/trail_summary.dart';

/// Tela inicial: a Trilha Neural (12 setores, 60 níveis).
class TrailScreen extends StatefulWidget {
  const TrailScreen({
    super.key,
    required this.progress,
    required this.onLevelSelected,
  });

  final TrailProgress progress;

  /// Chamado com o índice (0 a 59) de um nível jogável tocado.
  final ValueChanged<int> onLevelSelected;

  @override
  State<TrailScreen> createState() => _TrailScreenState();
}

class _TrailScreenState extends State<TrailScreen> {
  final GlobalKey _focusedNodeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // A trilha sobe (setor 1 na base): abre com o nível atual no centro.
    _scrollToFocus();
  }

  @override
  void didUpdateWidget(TrailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress.focusIndex != widget.progress.focusIndex) {
      _scrollToFocus(animated: true);
    }
  }

  void _scrollToFocus({bool animated = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = _focusedNodeKey.currentContext;
      if (target == null) return;
      Scrollable.ensureVisible(
        target,
        alignment: 0.5,
        duration: animated ? const Duration(milliseconds: 450) : Duration.zero,
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.progress;
    final focusedSector = progress.focusIndex ~/ levelsPerSector;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: GridBackground()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: _Header(),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: TrailSummary(progress: progress),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Do último setor (topo) ao primeiro (base).
                            for (var s = sectors.length - 1; s >= 0; s--)
                              Padding(
                                padding: EdgeInsets.only(
                                  bottom: s == 0 ? 0 : 16,
                                ),
                                child: SectorSection(
                                  sectorIndex: s,
                                  progress: progress,
                                  onLevelSelected: widget.onLevelSelected,
                                  focusKey:
                                      s == focusedSector ? _focusedNodeKey : null,
                                ),
                              ),
                          ],
                        ),
                      ),
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

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SYNAPSE',
                style: AppTextStyles.brand.copyWith(color: AppColors.alfa),
              ),
              Text('// ZERO', style: AppTextStyles.brand),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _ModeTabs(),
      ],
    );
  }
}

/// Abas de modo. Só a Trilha existe por enquanto: Diário e Arena aparecem
/// apagadas e sem ação até serem implementadas.
class _ModeTabs extends StatelessWidget {
  const _ModeTabs();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: const Row(
        children: [
          _Tab(label: 'Trilha', selected: true),
          SizedBox(width: 4),
          _Tab(label: 'Diário', selected: false),
          SizedBox(width: 4),
          _Tab(label: 'Arena', selected: false),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        enabled: selected,
        label: label,
        child: ExcludeSemantics(
          child: Opacity(
            opacity: selected ? 1 : 0.4,
            child: Container(
              constraints: const BoxConstraints(minHeight: 40),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.blue : null,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : AppColors.muted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
