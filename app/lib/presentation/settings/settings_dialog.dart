import 'package:material_ui/material_ui.dart';
import 'package:synapsezero/application/settings/avatars.dart';
import 'package:synapsezero/application/settings/player_account.dart';
import 'package:synapsezero/application/settings/settings_controller.dart';
import 'package:synapsezero/presentation/theme/app_colors.dart';
import 'package:synapsezero/presentation/theme/app_typography.dart';

/// Abre a janela de Configurações.
Future<void> showSettingsDialog(
  BuildContext context,
  SettingsController settings,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => SettingsDialog(settings: settings),
  );
}

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key, required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.line),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: ListenableBuilder(
          listenable: settings,
          builder: (context, _) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Configurações', style: AppTextStyles.heading),
                    ),
                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _ToggleRow(
                  label: 'Efeitos sonoros',
                  value: settings.soundEffects,
                  onChanged: settings.setSoundEffects,
                ),
                _ToggleRow(
                  label: 'Música tema',
                  value: settings.music,
                  onChanged: settings.setMusic,
                ),
                const SizedBox(height: 16),
                const _SectionTitle('Avatar'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final avatar in avatars)
                      _AvatarChoice(
                        avatar: avatar,
                        selected: avatar.id == settings.data.avatarId,
                        onTap: () => settings.setAvatar(avatar.id),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const _SectionTitle('Conta'),
                const SizedBox(height: 8),
                _AccountSection(settings: settings),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.label.copyWith(color: AppColors.muted),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: label,
      onTap: () => onChanged(!value),
      child: ExcludeSemantics(
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onChanged(!value),
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(child: Text(label, style: AppTextStyles.body)),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeTrackColor: AppColors.alfa,
                  activeThumbColor: AppColors.onAlfa,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarChoice extends StatelessWidget {
  const _AvatarChoice({
    required this.avatar,
    required this.selected,
    required this.onTap,
  });

  final Avatar avatar;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: avatar.label,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: selected ? AppColors.alfaSoft : AppColors.plate,
              border: Border.all(
                color: selected ? AppColors.alfa : AppColors.line,
                width: selected ? 2 : 1,
              ),
            ),
            child: Text(avatar.emoji, style: const TextStyle(fontSize: 26, height: 1)),
          ),
        ),
      ),
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection({required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final account = settings.account;
    if (account != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Conectado com ${account.provider.label}',
            style: AppTextStyles.body,
          ),
          Text(
            account.isSimulated
                ? '${account.displayName} (simulada)'
                : account.displayName,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          _ActionButton(label: 'Sair', onPressed: settings.signOut),
        ],
      );
    }
    if (!settings.loginAvailable) {
      return Text(
        'Login em breve.',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Entre para salvar seu progresso. Nesta versão de teste o login é '
          'simulado e nada é enviado a nenhuma rede.',
          style: AppTextStyles.caption.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        for (final provider in SocialProvider.values) ...[
          _ActionButton(
            label: 'Entrar com ${provider.label}',
            onPressed:
                settings.signingIn ? null : () => settings.signIn(provider),
          ),
          const SizedBox(height: 8),
        ],
        if (settings.signingIn)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        if (settings.error != null)
          Text(
            settings.error!,
            style: AppTextStyles.caption.copyWith(color: AppColors.danger),
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.line),
      ),
      child: Text(label, style: AppTextStyles.button),
    );
  }
}
