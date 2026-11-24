import 'package:material_ui/material_ui.dart';
import 'package:synapsezero/application/audio/game_sounds.dart';
import 'package:synapsezero/application/settings/settings_controller.dart';
import 'package:synapsezero/application/trail/level_result.dart';
import 'package:synapsezero/application/trail/trail_progress.dart';
import 'package:synapsezero/presentation/board/board_placeholder_screen.dart';
import 'package:synapsezero/presentation/settings/settings_dialog.dart';
import 'package:synapsezero/presentation/trail/trail_screen.dart';

/// Constrói a tela de jogo do nível [levelIndex]. Ela deve fechar com
/// `Navigator.pop(LevelResult)` ao vencer ou `pop()` ao sair sem vencer.
typedef BoardBuilder = Widget Function(BuildContext context, int levelIndex);

Widget _defaultBoardBuilder(BuildContext context, int levelIndex) =>
    BoardPlaceholderScreen(levelIndex: levelIndex);

/// Fluxo principal: trilha -> tabuleiro -> trilha (o avatar anda até a próxima
/// etapa e fica parado). O tabuleiro da nova etapa só abre quando o jogador
/// toca nela.
class TrailFlow extends StatefulWidget {
  const TrailFlow({
    super.key,
    required this.settings,
    this.boardBuilder,
    this.initialProgress,
    this.sounds = const SilentGameSounds(),
  });

  final SettingsController settings;
  /// Tela de jogo (padrão: o tabuleiro provisório).
  final BoardBuilder? boardBuilder;

  /// Efeitos sonoros (já filtrados pela opção das configurações).
  final GameSounds sounds;

  /// Progresso inicial (padrão: trilha vazia). Ainda só em memória: a
  /// persistência do progresso é uma etapa futura.
  final TrailProgress? initialProgress;

  @override
  State<TrailFlow> createState() => _TrailFlowState();
}

class _TrailFlowState extends State<TrailFlow> {
  final GlobalKey<TrailScreenState> _trailKey = GlobalKey<TrailScreenState>();
  late TrailProgress _progress = widget.initialProgress ?? TrailProgress.empty();
  bool _playing = false;

  void _sfx(GameSound sound) {
    // Falha de áudio não deve interromper o jogo.
    widget.sounds.play(sound).catchError((Object _) {});
  }

  Future<void> _play(int first) async {
    if (_playing) return;
    _playing = true;
    _sfx(GameSound.tap);
    final navigator = Navigator.of(context);
    try {
      final route = MaterialPageRoute<LevelResult>(
        builder: (context) =>
            (widget.boardBuilder ?? _defaultBoardBuilder)(context, first),
      );
      final result = await navigator.push(route);
      // Espera a tela do tabuleiro sair por completo antes de animar.
      await route.completed;
      if (!mounted || result == null) return;

      final advances = _progress.stateOf(first) == TrailNodeState.current;
      setState(() {
        _progress = _progress.withResult(
          first,
          stars: result.stars,
          score: result.score,
        );
      });
      // Refazer um nível já concluído não move o avatar.
      final next = _progress.currentIndex;
      if (!advances || next == null) return;

      await WidgetsBinding.instance.endOfFrame;
      _sfx(GameSound.advance);
      // O avatar chega e estaciona: nada abre sozinho.
      await _trailKey.currentState?.advanceAvatar(next);
    } finally {
      _playing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (context, _) => TrailScreen(
        key: _trailKey,
        progress: _progress,
        avatar: widget.settings.data.avatar,
        onLevelSelected: _play,
        onOpenSettings: () => showSettingsDialog(context, widget.settings),
      ),
    );
  }
}
