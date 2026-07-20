import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:macos_ui/macos_ui.dart';

import '../generated/app_localizations.dart';
import 'preview_models.dart';

typedef AsyncDoubleCallback = FutureOr<void> Function(double value);

class PreviewPlaybackController extends ChangeNotifier {
  PreviewPlaybackController(this.capabilities);

  final PreviewCapabilities capabilities;
  bool isPlaying = false;
  bool isLooping = true;
  double progress = 0;
  double speed = 1;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  FutureOr<void> Function()? onPlayPause;
  FutureOr<void> Function()? onStepBackward;
  FutureOr<void> Function()? onStepForward;
  AsyncDoubleCallback? onSeek;
  AsyncDoubleCallback? onSpeedChanged;
  FutureOr<void> Function(bool value)? onLoopChanged;
  VoidCallback? onFit;
  VoidCallback? onActualSize;
  VoidCallback? onZoomIn;
  VoidCallback? onZoomOut;

  void update({
    bool? playing,
    bool? looping,
    double? progress,
    double? speed,
    Duration? position,
    Duration? duration,
  }) {
    isPlaying = playing ?? isPlaying;
    isLooping = looping ?? isLooping;
    this.progress = (progress ?? this.progress).clamp(0, 1);
    this.speed = speed ?? this.speed;
    this.position = position ?? this.position;
    this.duration = duration ?? this.duration;
    notifyListeners();
  }

  void clearHandlers() {
    onPlayPause = null;
    onStepBackward = null;
    onStepForward = null;
    onSeek = null;
    onSpeedChanged = null;
    onLoopChanged = null;
    onFit = null;
    onActualSize = null;
    onZoomIn = null;
    onZoomOut = null;
  }
}

class PreviewTransportBar extends StatelessWidget {
  const PreviewTransportBar({
    super.key,
    required this.controller,
  });

  final PreviewPlaybackController controller;

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final capabilities = controller.capabilities;
        final l = AppLocalizations.of(context);
        return Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: theme.canvasColor,
          ),
          child: Row(
            children: [
              if (capabilities.frameStep)
                _ControlButton(
                  tooltip: l.previousFrame,
                  icon: CupertinoIcons.backward_end_fill,
                  onPressed: controller.onStepBackward,
                ),
              if (capabilities.timeline)
                _ControlButton(
                  tooltip: controller.isPlaying ? l.pause : l.play,
                  icon: controller.isPlaying
                      ? CupertinoIcons.pause_fill
                      : CupertinoIcons.play_fill,
                  onPressed: controller.onPlayPause,
                ),
              if (capabilities.frameStep)
                _ControlButton(
                  tooltip: l.nextFrame,
                  icon: CupertinoIcons.forward_end_fill,
                  onPressed: controller.onStepForward,
                ),
              if (capabilities.timeline) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 56,
                  child: Text(
                    _formatDuration(controller.position),
                    textAlign: TextAlign.right,
                    style: theme.typography.caption1,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MacosSlider(
                    value: controller.progress,
                    onChanged: (value) {
                      controller.update(progress: value);
                      controller.onSeek?.call(value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 56,
                  child: Text(
                    _formatDuration(controller.duration),
                    style: theme.typography.caption1,
                  ),
                ),
              ] else
                const Spacer(),
              if (capabilities.speed)
                MacosPopupButton<double>(
                  value: controller.speed,
                  onChanged: (value) {
                    if (value == null) return;
                    controller.update(speed: value);
                    controller.onSpeedChanged?.call(value);
                  },
                  items: const <MacosPopupMenuItem<double>>[
                    MacosPopupMenuItem(value: 0.25, child: Text('0.25x')),
                    MacosPopupMenuItem(value: 0.5, child: Text('0.5x')),
                    MacosPopupMenuItem(value: 1, child: Text('1x')),
                    MacosPopupMenuItem(value: 1.5, child: Text('1.5x')),
                    MacosPopupMenuItem(value: 2, child: Text('2x')),
                  ],
                ),
              if (capabilities.loop)
                _ControlButton(
                  tooltip: controller.isLooping ? l.disableLoop : l.enableLoop,
                  icon: CupertinoIcons.repeat,
                  selected: controller.isLooping,
                  onPressed: () {
                    final value = !controller.isLooping;
                    controller.update(looping: value);
                    controller.onLoopChanged?.call(value);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  static String _formatDuration(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class CanvasBackgroundPicker extends StatelessWidget {
  const CanvasBackgroundPicker({
    super.key,
    required this.value,
    required this.customColor,
    required this.onChanged,
  });

  final CanvasBackground value;
  final Color customColor;
  final ValueChanged<CanvasBackground> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _BackgroundSwatch(
          tooltip: l.checkerboard,
          selected: value == CanvasBackground.checkerboard,
          onPressed: () => onChanged(CanvasBackground.checkerboard),
          child: const CustomPaint(painter: CheckerboardPainter(cellSize: 4)),
        ),
        _BackgroundSwatch(
          tooltip: l.lightBackground,
          color: const Color(0xFFF4F4F4),
          selected: value == CanvasBackground.light,
          onPressed: () => onChanged(CanvasBackground.light),
        ),
        _BackgroundSwatch(
          tooltip: l.darkBackground,
          color: const Color(0xFF242424),
          selected: value == CanvasBackground.dark,
          onPressed: () => onChanged(CanvasBackground.dark),
        ),
        _BackgroundSwatch(
          tooltip: l.customBackground,
          color: customColor,
          selected: value == CanvasBackground.custom,
          onPressed: () => onChanged(CanvasBackground.custom),
        ),
      ],
    );
  }
}

class PreviewCanvasBackground extends StatelessWidget {
  const PreviewCanvasBackground({
    super.key,
    required this.background,
    required this.customColor,
    required this.child,
  });

  final CanvasBackground background;
  final Color customColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final color = switch (background) {
      CanvasBackground.light => const Color(0xFFF4F4F4),
      CanvasBackground.dark => const Color(0xFF242424),
      CanvasBackground.custom => customColor,
      CanvasBackground.checkerboard => null,
    };
    return ColoredBox(
      color: color ?? const Color(0xFFE9E9E9),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (background == CanvasBackground.checkerboard)
            const CustomPaint(painter: CheckerboardPainter()),
          child,
        ],
      ),
    );
  }
}

class CheckerboardPainter extends CustomPainter {
  const CheckerboardPainter({this.cellSize = 12});

  final double cellSize;

  @override
  void paint(Canvas canvas, Size size) {
    final light = Paint()..color = const Color(0xFFE7E7E7);
    final dark = Paint()..color = const Color(0xFFD1D1D1);
    for (double y = 0; y < size.height; y += cellSize) {
      for (double x = 0; x < size.width; x += cellSize) {
        final column = (x / cellSize).floor();
        final row = (y / cellSize).floor();
        canvas.drawRect(
          Rect.fromLTWH(x, y, cellSize, cellSize),
          (column + row).isEven ? light : dark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CheckerboardPainter oldDelegate) =>
      oldDelegate.cellSize != cellSize;
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.tooltip,
    required this.icon,
    this.onPressed,
    this.selected = false,
  });

  final String tooltip;
  final IconData icon;
  final FutureOr<void> Function()? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return MacosTooltip(
      message: tooltip,
      child: MacosIconButton(
        onPressed: onPressed == null ? null : () => onPressed?.call(),
        backgroundColor: selected
            ? MacosTheme.of(context).primaryColor.withValues(alpha: 0.16)
            : Colors.transparent,
        icon: MacosIcon(icon, size: 17),
      ),
    );
  }
}

class _BackgroundSwatch extends StatelessWidget {
  const _BackgroundSwatch({
    required this.tooltip,
    required this.selected,
    required this.onPressed,
    this.color,
    this.child,
  });

  final String tooltip;
  final bool selected;
  final VoidCallback onPressed;
  final Color? color;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return MacosTooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 22,
          height: 22,
          margin: const EdgeInsets.only(left: 6),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: selected
                  ? MacosTheme.of(context).primaryColor
                  : MacosTheme.of(context).dividerColor,
              width: selected ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: child ?? ColoredBox(color: color ?? Colors.transparent),
          ),
        ),
      ),
    );
  }
}
