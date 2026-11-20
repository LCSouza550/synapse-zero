import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';

/// Tela provisória exibida depois da splash, até a tela principal existir.
class HomePlaceholder extends StatelessWidget {
  const HomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.bg,
      child: Center(
        child: Text(
          'Tela principal em construção',
          textDirection: TextDirection.ltr,
          style: TextStyle(
            color: AppColors.text,
            fontSize: 16,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}
