import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:synapse_core/synapse_core.dart';
import 'package:synapsezero/application/settings/avatars.dart';
import 'package:synapsezero/application/trail/trail_progress.dart';
import 'package:synapsezero/presentation/common/grid_background.dart';
import 'package:synapsezero/presentation/theme/app_colors.dart';
import 'package:synapsezero/presentation/theme/app_typography.dart';
import 'package:synapsezero/presentation/trail/avatar_token.dart';
import 'package:synapsezero/presentation/trail/sector_section.dart';
import 'package:synapsezero/presentation/trail/trail_node.dart';
import 'package:synapsezero/presentation/trail/trail_summary.dart';

/// Tela inicial: a Trilha Neural (12 setores, 60 níveis).
///
/// O avatar do jogador fica sobre o nível atual. Quem controla o fluxo chama
/// [TrailScreenState.advanceAvatar] (via `GlobalKey<TrailScreenState>`) para
/// animá-lo até o próximo nível.
class TrailScreen extends StatefulWidget {
  const TrailScreen({
    super.key,
    required this.progress,
    required this.onLevelSelected,
    required this.avatar,
    this.onOpenSettings,
  });

  final TrailProgress progress;

  /// Chamado com o índice (0 a 59) de um nível jogável tocado.
  final ValueChanged<int> onLevelSelected;

  /// Avatar escolhido pelo jogador.
  final Avatar avatar;

  /// Chamado ao tocar na engrenagem (canto superior direito).
  final VoidCallback? onOpenSettings;

  @override
  State<TrailScreen> createState() => TrailScreenState();
}

class TrailScreenState extends State<TrailScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _travelDuration = Duration(milliseconds: 1000);
  static const Duration _scrollDuration = Duration(milliseconds: 600);

  final List<GlobalKey> _nodeKeys = List.generate(
    trailLength,
    (i) => GlobalKey(debugLabel: 'node$i'),
  );
  final GlobalKey _contentKey = GlobalKey(debugLabel: 'trailContent');
  late final AnimationController _travel = AnimationController(
    vsync: this,
    duration: _travelDuration,
  );

  /// Nível onde o avatar está parado.
  late int _avatarLevel = widget.progress.focusIndex;

  bool _traveling = false;
  Offset _from = Offset.zero;
  Offset _to = Offset.zero;

  @override
  void initState() {
    super.initState();
    // A trilha sobe (setor 1 na base): abre com o avatar no centro.
    _scrollToLevel(_avatarLevel);
  }

  @override
  void dispose() {
    _travel.dispose();
    super.dispose();
  }

  /// Anima o avatar do nível atual até [level], acompanhando-o com a rolagem.
  /// Completa quando o avatar chega.
  Future<void> advanceAvatar(int level) async {
    if (!mounted || _traveling || level == _avatarLevel) return;
    final from = _tokenSpot(_avatarLevel);
    final to = _tokenSpot(level);
    if (from == null || to == null) {
      setState(() => _avatarLevel = level);
      _scrollToLevel(level);
      return;
    }
    setState(() {
      _traveling = true;
      _from = from;
      _to = to;
    });
    _scrollToLevel(level, animated: true);
    try {
      await _travel.forward(from: 0).orCancel;
    } on TickerCanceled {
      return;
    }
    if (!mounted) return;
    setState(() {
      _avatarLevel = level;
      _traveling = false;
    });
  }

  /// Canto superior esquerdo da ficha do avatar sobre o nível [level], em
  /// coordenadas do conteúdo rolável (não mudam ao rolar).
  Offset? _tokenSpot(int level) {
    final node = _nodeKeys[level].currentContext?.findRenderObject();
    final content = _contentKey.currentContext?.findRenderObject();
    if (node is! RenderBox || content is! RenderBox) return null;
    if (!node.attached || !content.attached) return null;
    final top = node.localToGlobal(Offset(TrailNode.width / 2, 0));
    final local = content.globalToLocal(top);
    return Offset(
      local.dx - AvatarToken.size / 2,
      local.dy - TrailNode.avatarLift,
    );
  }

  void _scrollToLevel(int level, {bool animated = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = _nodeKeys[level].currentContext;
      if (target == null) return;
      Scrollable.ensureVisible(
        target,
        alignment: 0.5,
        duration: animated ? _scrollDuration : Duration.zero,
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.progress;
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: _Header(onOpenSettings: widget.onOpenSettings),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: TrailSummary(progress: progress),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                        child: Stack(
                          key: _contentKey,
                          clipBehavior: Clip.none,
                          children: [
                            Column(
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
                                      nodeKeys: _nodeKeys,
                                      avatar: widget.avatar,
                                      avatarAt:
                                          _traveling ? null : _avatarLevel,
                                    ),
                                  ),
                              ],
                            ),
                            if (_traveling)
                              AnimatedBuilder(
                                animation: _travel,
                                builder: (context, child) {
                                  final t =
                                      Curves.easeInOutCubic.transform(_travel.value);
                                  final spot = Offset.lerp(_from, _to, t)!;
                                  // Um pequeno salto durante a viagem.
                                  final hop = math.sin(math.pi * t) * 18;
                                  return Positioned(
                                    left: spot.dx,
                                    top: spot.dy - hop,
                                    child: child!,
                                  );
                                },
                                child: AvatarToken(avatar: widget.avatar),
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
  const _Header({this.onOpenSettings});

  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
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
            IconButton(
              tooltip: 'Configurações',
              onPressed: onOpenSettings,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: const Icon(Icons.settings_outlined, color: AppColors.text),
            ),
          ],
        ),
        const SizedBox(height: 4),
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
