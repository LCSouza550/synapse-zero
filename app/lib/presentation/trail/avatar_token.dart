import 'package:material_ui/material_ui.dart';
import 'package:synapsezero/application/settings/avatars.dart';
import 'package:synapsezero/presentation/theme/app_colors.dart';

/// Ficha circular com o avatar do jogador, mostrada sobre o nível atual.
class AvatarToken extends StatelessWidget {
  const AvatarToken({super.key, required this.avatar});

  final Avatar avatar;

  static const double size = 40;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Você está aqui, avatar ${avatar.label}',
      child: ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.nodeFillCurrent,
            border: Border.fromBorderSide(
              BorderSide(color: AppColors.alfa, width: 2),
            ),
            boxShadow: [BoxShadow(color: AppColors.alfaGlow, blurRadius: 14)],
          ),
          child: Text(avatar.emoji, style: const TextStyle(fontSize: 21, height: 1)),
        ),
      ),
    );
  }
}
