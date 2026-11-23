import 'package:material_ui/material_ui.dart';
import 'package:synapsezero/application/settings/avatars.dart';
import 'package:synapsezero/application/trail/trail_progress.dart';
import 'package:synapsezero/presentation/theme/app_colors.dart';
import 'package:synapsezero/presentation/theme/app_typography.dart';
import 'package:synapsezero/presentation/trail/avatar_token.dart';

/// Nó de um nível no mapa da Trilha Neural.
class TrailNode extends StatelessWidget {
  const TrailNode({
    super.key,
    required this.index,
    required this.name,
    required this.state,
    required this.stars,
    required this.isBoss,
    this.avatar,
    this.onTap,
  });

  /// Largura do nó (também usada pelo mapa para centralizá-lo).
  static const double width = 130;

  /// Distância do topo do nó ao topo da ficha do avatar (que paira acima do anel).
  static const double avatarLift = 46;

  /// Índice do nível (0 a 59); o número exibido é `index + 1`.
  final int index;
  final String name;
  final TrailNodeState state;

  /// Estrelas conquistadas (0 a 3).
  final int stars;
  final bool isBoss;

  /// Avatar do jogador, quando está neste nível (`null` nos demais).
  final Avatar? avatar;
  final VoidCallback? onTap;

  bool get _locked => state == TrailNodeState.locked;
  bool get _current => state == TrailNodeState.current;

  String get _semanticLabel {
    final base = 'Nível ${index + 1}, $name';
    switch (state) {
      case TrailNodeState.done:
        return '$base, $stars de 3 estrelas';
      case TrailNodeState.current:
        return '$base, atual';
      case TrailNodeState.locked:
        return '$base, bloqueado';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ringSize = isBoss ? 72.0 : 60.0;
    return Semantics(
      button: true,
      enabled: !_locked,
      label: _semanticLabel,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _locked ? null : onTap,
          child: SizedBox(
            width: width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: width,
                  height: ringSize,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Align(child: _Ring(
                        size: ringSize,
                        locked: _locked,
                        current: _current,
                        label: isBoss ? '👑' : '${index + 1}',
                        fontSize: isBoss ? 26 : 20,
                      )),
                      if (avatar != null)
                        Positioned(
                          top: -avatarLift,
                          left: 0,
                          right: 0,
                          child: Center(child: AvatarToken(avatar: avatar!)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                _Footer(locked: _locked, stars: stars),
                const SizedBox(height: 2),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 13,
                    height: 1.25,
                    color: (state == TrailNodeState.locked)
                        ? AppColors.muted
                        : AppColors.text,
                    shadows: const [
                      Shadow(color: AppColors.bg, blurRadius: 6),
                      Shadow(color: AppColors.bg, blurRadius: 6),
                      Shadow(color: AppColors.bg, blurRadius: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({
    required this.size,
    required this.locked,
    required this.current,
    required this.label,
    required this.fontSize,
  });

  final double size;
  final bool locked;
  final bool current;
  final String label;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: locked
            ? AppColors.surface
            : (current ? AppColors.nodeFillCurrent : AppColors.nodeFill),
        border: Border.all(
          color: locked ? AppColors.line : AppColors.alfa,
          width: 3,
        ),
        boxShadow: locked
            ? null
            : const [BoxShadow(color: AppColors.alfaGlow, blurRadius: 14)],
      ),
      child: Text(
        label,
        style: AppTextStyles.stat.copyWith(
          fontSize: fontSize,
          height: 1,
          color: locked ? AppColors.muted : AppColors.text,
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.locked, required this.stars});

  final bool locked;
  final int stars;

  @override
  Widget build(BuildContext context) {
    if (locked || stars <= 0) {
      return Text(
        '•••',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.muted,
          letterSpacing: 6,
          height: 1.2,
        ),
      );
    }
    return Text.rich(
      TextSpan(
        children: [
          for (var i = 0; i < 3; i++)
            TextSpan(
              text: '★',
              style: TextStyle(
                color: i < stars ? AppColors.star : AppColors.line,
              ),
            ),
        ],
      ),
      style: const TextStyle(fontSize: 16, letterSpacing: 2, height: 1.2),
    );
  }
}
