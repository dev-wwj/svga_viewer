import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:svgaplayer_flutter/parser.dart';
import 'package:svgaplayer_flutter/player.dart';
import 'package:svgaplayer_flutter/proto/svga.pb.dart';
import 'package:video_player/video_player.dart';

import '../generated/app_localizations.dart';
import 'document_platform_service.dart';
import 'preview_controls.dart';
import 'preview_models.dart';

class PreviewHost extends StatefulWidget {
  const PreviewHost({
    super.key,
    required this.document,
    required this.background,
    required this.customBackground,
    required this.platformService,
    required this.onMetadata,
    required this.onReady,
    required this.onError,
    required this.onLocateMissing,
  });

  final PreviewDocument document;
  final CanvasBackground background;
  final Color customBackground;
  final DocumentPlatformService platformService;
  final ValueChanged<Map<String, String>> onMetadata;
  final VoidCallback onReady;
  final ValueChanged<String> onError;
  final VoidCallback onLocateMissing;

  @override
  State<PreviewHost> createState() => PreviewHostState();
}

class PreviewHostState extends State<PreviewHost> {
  late PreviewPlaybackController playbackController;

  @override
  void initState() {
    super.initState();
    playbackController =
        PreviewPlaybackController(widget.document.adapter.capabilities);
  }

  @override
  void didUpdateWidget(PreviewHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document.id != widget.document.id) {
      playbackController.dispose();
      playbackController =
          PreviewPlaybackController(widget.document.adapter.capabilities);
    }
  }

  void togglePlayback() => playbackController.onPlayPause?.call();
  void stepBackward() => playbackController.onStepBackward?.call();
  void stepForward() => playbackController.onStepForward?.call();
  void fit() => playbackController.onFit?.call();
  void actualSize() => playbackController.onActualSize?.call();
  void zoomIn() => playbackController.onZoomIn?.call();
  void zoomOut() => playbackController.onZoomOut?.call();

  @override
  void dispose() {
    playbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final document = widget.document;
    final l = AppLocalizations.of(context);
    if (document.state == DocumentLoadState.error) {
      return _ErrorPreview(
        title: document.displayName,
        message: document.errorMessage ?? l.resourceCouldNotOpen,
        locateLabel: l.locate,
        onLocate: widget.onLocateMissing,
      );
    }

    final preview = switch (document.adapter.kind) {
      PreviewKind.svga => _SvgaPreview(
          path: document.path,
          controller: playbackController,
          onMetadata: widget.onMetadata,
          onReady: widget.onReady,
          onError: widget.onError,
        ),
      PreviewKind.lottie => _LottiePreview(
          path: document.path,
          controller: playbackController,
          onMetadata: widget.onMetadata,
          onReady: widget.onReady,
          onError: widget.onError,
        ),
      PreviewKind.raster => _RasterPreview(
          path: document.path,
          controller: playbackController,
          onMetadata: widget.onMetadata,
          onReady: widget.onReady,
          onError: widget.onError,
        ),
      PreviewKind.svg => _SvgPreview(
          path: document.path,
          controller: playbackController,
          onMetadata: widget.onMetadata,
          onReady: widget.onReady,
          onError: widget.onError,
        ),
      PreviewKind.video => _VideoPreview(
          path: document.path,
          controller: playbackController,
          platformService: widget.platformService,
          onMetadata: widget.onMetadata,
          onReady: widget.onReady,
          onError: widget.onError,
        ),
      PreviewKind.unsupported => _ErrorPreview(
          title: document.displayName,
          message: l.unsupportedResource,
          locateLabel: l.locate,
          onLocate: widget.onLocateMissing,
        ),
    };

    final capabilities = document.adapter.capabilities;
    return Column(
      children: [
        Expanded(
          child: PreviewCanvasBackground(
            background: widget.background,
            customColor: widget.customBackground,
            child: preview,
          ),
        ),
        if (capabilities.timeline ||
            capabilities.frameStep ||
            capabilities.speed ||
            capabilities.loop)
          PreviewTransportBar(controller: playbackController),
      ],
    );
  }
}

class _PreviewViewport extends StatefulWidget {
  const _PreviewViewport({
    required this.controller,
    required this.child,
  });

  final PreviewPlaybackController controller;
  final Widget child;

  @override
  State<_PreviewViewport> createState() => _PreviewViewportState();
}

class _PreviewViewportState extends State<_PreviewViewport> {
  late final TransformationController _transformationController;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _bindHandlers();
  }

  @override
  void didUpdateWidget(_PreviewViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) _bindHandlers();
  }

  void _bindHandlers() {
    widget.controller.onFit = _reset;
    widget.controller.onActualSize = _reset;
    widget.controller.onZoomIn = () => _zoomBy(1.2);
    widget.controller.onZoomOut = () => _zoomBy(1 / 1.2);
  }

  void _reset() {
    _transformationController.value = Matrix4.identity();
  }

  void _zoomBy(double factor) {
    final current = _transformationController.value.getMaxScaleOnAxis();
    final target = (current * factor).clamp(0.1, 12.0);
    _transformationController.value =
        Matrix4.diagonal3Values(target, target, 1);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.1,
      maxScale: 12,
      boundaryMargin: const EdgeInsets.all(240),
      child: Center(child: widget.child),
    );
  }
}

class _SvgaPreview extends StatefulWidget {
  const _SvgaPreview({
    required this.path,
    required this.controller,
    required this.onMetadata,
    required this.onReady,
    required this.onError,
  });

  final String path;
  final PreviewPlaybackController controller;
  final ValueChanged<Map<String, String>> onMetadata;
  final VoidCallback onReady;
  final ValueChanged<String> onError;

  @override
  State<_SvgaPreview> createState() => _SvgaPreviewState();
}

class _SvgaPreviewState extends State<_SvgaPreview>
    with SingleTickerProviderStateMixin {
  late final SVGAAnimationController _animationController;
  MovieEntity? _movie;
  double _speed = 1;

  @override
  void initState() {
    super.initState();
    _animationController = SVGAAnimationController(vsync: this)
      ..addListener(_syncState);
    _bindHandlers();
    unawaited(_load());
  }

  void _bindHandlers() {
    widget.controller.onPlayPause = _togglePlayback;
    widget.controller.onStepBackward = () => _step(-1);
    widget.controller.onStepForward = () => _step(1);
    widget.controller.onSeek = (value) {
      _animationController.value = value;
    };
    widget.controller.onSpeedChanged = (value) {
      _speed = value;
      if (_animationController.isAnimating) _play();
    };
    widget.controller.onLoopChanged = (_) {
      if (_animationController.isAnimating) _play();
    };
  }

  Future<void> _load() async {
    try {
      final bytes = await File(widget.path).readAsBytes();
      final movie = await SVGAParser.shared.decodeFromBuffer(bytes);
      if (!mounted) return;
      _movie = movie;
      _animationController.videoItem = movie;
      final params = movie.params;
      widget.onMetadata(<String, String>{
        'Dimensions':
            '${params.viewBoxWidth.toInt()} x ${params.viewBoxHeight.toInt()}',
        'Frames': '${params.frames}',
        'Frame rate': '${params.fps} fps',
        'Duration': _formatDuration(_animationController.duration),
      });
      _play();
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onReady();
      });
    } on Object catch (error) {
      widget.onError('SVGA decoding failed: $error');
    }
  }

  void _togglePlayback() {
    if (_animationController.isAnimating) {
      _animationController.stop();
    } else {
      _play();
    }
    _syncState();
  }

  void _play() {
    final duration = _animationController.duration;
    if (duration == null || duration == Duration.zero) return;
    final scaled = Duration(
      microseconds: math.max(1, duration.inMicroseconds ~/ _speed),
    );
    if (widget.controller.isLooping) {
      _animationController.repeat(period: scaled);
    } else {
      _animationController.forward(from: _animationController.value);
    }
  }

  void _step(int direction) {
    final frames = _movie?.params.frames ?? 1;
    _animationController.stop();
    _animationController.value =
        (_animationController.value + direction / frames).clamp(0, 1);
    _syncState();
  }

  void _syncState() {
    final duration = _animationController.duration ?? Duration.zero;
    widget.controller.update(
      playing: _animationController.isAnimating,
      progress: _animationController.value,
      position: duration * _animationController.value,
      duration: duration,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_movie == null) return const Center(child: ProgressCircle());
    return _PreviewViewport(
      controller: widget.controller,
      child: SVGAImage(_animationController, fit: BoxFit.contain),
    );
  }
}

class _LottiePreview extends StatefulWidget {
  const _LottiePreview({
    required this.path,
    required this.controller,
    required this.onMetadata,
    required this.onReady,
    required this.onError,
  });

  final String path;
  final PreviewPlaybackController controller;
  final ValueChanged<Map<String, String>> onMetadata;
  final VoidCallback onReady;
  final ValueChanged<String> onError;

  @override
  State<_LottiePreview> createState() => _LottiePreviewState();
}

class _LottiePreviewState extends State<_LottiePreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  LottieComposition? _composition;
  double _speed = 1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this)
      ..addListener(_syncState);
    _bindHandlers();
  }

  void _bindHandlers() {
    widget.controller.onPlayPause = _togglePlayback;
    widget.controller.onStepBackward = () => _step(-1);
    widget.controller.onStepForward = () => _step(1);
    widget.controller.onSeek = (value) {
      _animationController.value = value;
    };
    widget.controller.onSpeedChanged = (value) {
      _speed = value;
      if (_animationController.isAnimating) _play();
    };
    widget.controller.onLoopChanged = (_) {
      if (_animationController.isAnimating) _play();
    };
  }

  void _loaded(LottieComposition composition) {
    _composition = composition;
    _animationController.duration = composition.duration;
    widget.onMetadata(<String, String>{
      'Dimensions':
          '${composition.bounds.width.toInt()} x ${composition.bounds.height.toInt()}',
      'Frames': composition.durationFrames.toStringAsFixed(0),
      'Frame rate': '${composition.frameRate.toStringAsFixed(0)} fps',
      'Duration': _formatDuration(composition.duration),
    });
    _play();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onReady();
    });
  }

  void _togglePlayback() {
    if (_animationController.isAnimating) {
      _animationController.stop();
    } else {
      _play();
    }
    _syncState();
  }

  void _play() {
    final baseDuration = _animationController.duration;
    if (baseDuration == null) return;
    final scaled = Duration(
      microseconds: math.max(1, baseDuration.inMicroseconds ~/ _speed),
    );
    _animationController.duration = scaled;
    if (widget.controller.isLooping) {
      _animationController.repeat();
    } else {
      _animationController.forward(from: _animationController.value);
    }
  }

  void _step(int direction) {
    final frames = math.max(1, _composition?.durationFrames ?? 1);
    _animationController.stop();
    _animationController.value =
        (_animationController.value + direction / frames).clamp(0, 1);
    _syncState();
  }

  void _syncState() {
    final duration = _composition?.duration ?? Duration.zero;
    widget.controller.update(
      playing: _animationController.isAnimating,
      progress: _animationController.value,
      position: duration * _animationController.value,
      duration: duration,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PreviewViewport(
      controller: widget.controller,
      child: Lottie.file(
        File(widget.path),
        controller: _animationController,
        fit: BoxFit.contain,
        onLoaded: _loaded,
        errorBuilder: (context, error, _) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onError('Lottie decoding failed: $error');
          });
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _RasterPreview extends StatefulWidget {
  const _RasterPreview({
    required this.path,
    required this.controller,
    required this.onMetadata,
    required this.onReady,
    required this.onError,
  });

  final String path;
  final PreviewPlaybackController controller;
  final ValueChanged<Map<String, String>> onMetadata;
  final VoidCallback onReady;
  final ValueChanged<String> onError;

  @override
  State<_RasterPreview> createState() => _RasterPreviewState();
}

class _RasterPreviewState extends State<_RasterPreview> {
  Uint8List? _bytes;
  ui.Codec? _codec;
  ui.Image? _image;
  Timer? _timer;
  int _frameIndex = 0;
  int _frameCount = 1;
  Duration _frameDuration = const Duration(milliseconds: 100);
  bool _playing = true;
  bool _busy = false;
  double _speed = 1;

  @override
  void initState() {
    super.initState();
    _bindHandlers();
    unawaited(_load());
  }

  void _bindHandlers() {
    widget.controller.onPlayPause = () {
      _playing = !_playing;
      if (_playing) _scheduleNext();
      widget.controller.update(playing: _playing);
    };
    widget.controller.onStepBackward = () => _seekFrame(_frameIndex - 1);
    widget.controller.onStepForward = () => _seekFrame(_frameIndex + 1);
    widget.controller.onSeek =
        (value) => _seekFrame((value * (_frameCount - 1)).round());
    widget.controller.onSpeedChanged = (value) {
      _speed = value;
    };
    widget.controller.onLoopChanged = (_) {};
  }

  Future<void> _load() async {
    try {
      _bytes = await File(widget.path).readAsBytes();
      _codec = await ui.instantiateImageCodec(_bytes!);
      _frameCount = _codec!.frameCount;
      await _readNextFrame();
      if (!mounted) return;
      widget.onMetadata(<String, String>{
        'Dimensions': '${_image!.width} x ${_image!.height}',
        'Frames': '$_frameCount',
        if (_frameCount > 1) 'Animation': 'Animated raster',
        if (_frameCount > 1)
          'Duration': _formatDuration(_frameDuration * _frameCount),
      });
      widget.controller.update(
        playing: _frameCount > 1,
        duration: _frameDuration * _frameCount,
      );
      if (_frameCount > 1) _scheduleNext();
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onReady();
      });
    } on Object catch (error) {
      widget.onError('Image decoding failed: $error');
    }
  }

  Future<void> _readNextFrame() async {
    if (_busy || _codec == null) return;
    _busy = true;
    final frame = await _codec!.getNextFrame();
    _image?.dispose();
    _image = frame.image;
    _frameDuration = frame.duration == Duration.zero
        ? const Duration(milliseconds: 100)
        : frame.duration;
    _busy = false;
    if (mounted) setState(() {});
  }

  void _scheduleNext() {
    _timer?.cancel();
    if (!_playing || _frameCount <= 1) return;
    _timer = Timer(
      Duration(
        microseconds: math.max(1, _frameDuration.inMicroseconds ~/ _speed),
      ),
      () async {
        if (_frameIndex == _frameCount - 1 && !widget.controller.isLooping) {
          _playing = false;
          widget.controller.update(playing: false);
          return;
        }
        _frameIndex = (_frameIndex + 1) % _frameCount;
        await _readNextFrame();
        _syncState();
        _scheduleNext();
      },
    );
  }

  Future<void> _seekFrame(int target) async {
    if (_bytes == null || _busy) return;
    _timer?.cancel();
    _playing = false;
    target = target.clamp(0, _frameCount - 1);
    _codec?.dispose();
    _codec = await ui.instantiateImageCodec(_bytes!);
    for (var index = 0; index <= target; index++) {
      await _readNextFrame();
    }
    _frameIndex = target;
    _syncState();
  }

  void _syncState() {
    final progress = _frameCount <= 1 ? 0.0 : _frameIndex / (_frameCount - 1);
    final duration = _frameDuration * _frameCount;
    widget.controller.update(
      playing: _playing,
      progress: progress,
      position: duration * progress,
      duration: duration,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codec?.dispose();
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_image == null) return const Center(child: ProgressCircle());
    return _PreviewViewport(
      controller: widget.controller,
      child: RawImage(image: _image, fit: BoxFit.contain),
    );
  }
}

class _SvgPreview extends StatefulWidget {
  const _SvgPreview({
    required this.path,
    required this.controller,
    required this.onMetadata,
    required this.onReady,
    required this.onError,
  });

  final String path;
  final PreviewPlaybackController controller;
  final ValueChanged<Map<String, String>> onMetadata;
  final VoidCallback onReady;
  final ValueChanged<String> onError;

  @override
  State<_SvgPreview> createState() => _SvgPreviewState();
}

class _SvgPreviewState extends State<_SvgPreview> {
  @override
  void initState() {
    super.initState();
    unawaited(_loadMetadata());
  }

  Future<void> _loadMetadata() async {
    try {
      final source = await File(widget.path).readAsString();
      final svgTag = RegExp(r'<svg\b[^>]*>', caseSensitive: false)
          .firstMatch(source)
          ?.group(0);
      final viewBox = _attribute(svgTag, 'viewBox');
      final width = _attribute(svgTag, 'width');
      final height = _attribute(svgTag, 'height');
      final metadata = <String, String>{
        if (viewBox != null) 'ViewBox': viewBox,
        if (width != null && height != null) 'Dimensions': '$width x $height',
      };
      if (!mounted) return;
      widget.onMetadata(metadata);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onReady();
      });
    } on Object catch (error) {
      widget.onError('SVG decoding failed: $error');
    }
  }

  String? _attribute(String? svgTag, String name) {
    if (svgTag == null) return null;
    return RegExp("""$name\\s*=\\s*['"]([^'"]+)['"]""", caseSensitive: false)
        .firstMatch(svgTag)
        ?.group(1);
  }

  @override
  Widget build(BuildContext context) {
    return _PreviewViewport(
      controller: widget.controller,
      child: SvgPicture.file(
        File(widget.path),
        fit: BoxFit.contain,
        placeholderBuilder: (_) => const ProgressCircle(),
      ),
    );
  }
}

class _VideoPreview extends StatefulWidget {
  const _VideoPreview({
    required this.path,
    required this.controller,
    required this.platformService,
    required this.onMetadata,
    required this.onReady,
    required this.onError,
  });

  final String path;
  final PreviewPlaybackController controller;
  final DocumentPlatformService platformService;
  final ValueChanged<Map<String, String>> onMetadata;
  final VoidCallback onReady;
  final ValueChanged<String> onError;

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  late final VideoPlayerController _videoController;
  double _frameRate = 30;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.file(File(widget.path))
      ..addListener(_syncState);
    _bindHandlers();
    unawaited(_initialize());
  }

  void _bindHandlers() {
    widget.controller.onPlayPause = () async {
      if (_videoController.value.isPlaying) {
        await _videoController.pause();
      } else {
        await _videoController.play();
      }
    };
    widget.controller.onStepBackward = () => _step(-1);
    widget.controller.onStepForward = () => _step(1);
    widget.controller.onSeek = (value) => _videoController.seekTo(
          _videoController.value.duration * value,
        );
    widget.controller.onSpeedChanged = _videoController.setPlaybackSpeed;
    widget.controller.onLoopChanged = _videoController.setLooping;
  }

  Future<void> _initialize() async {
    try {
      await _videoController.initialize();
      await _videoController.setLooping(true);
      final native = await widget.platformService.mediaMetadata(widget.path);
      _frameRate = double.tryParse(native['frameRate'] ?? '') ?? 30;
      final size = _videoController.value.size;
      widget.onMetadata(<String, String>{
        'Dimensions': '${size.width.toInt()} x ${size.height.toInt()}',
        'Duration': _formatDuration(_videoController.value.duration),
        if (native['frameRate'] != null)
          'Frame rate': '${native['frameRate']} fps',
        if (native['codec'] != null) 'Codec': native['codec']!,
      });
      await _videoController.play();
      if (mounted) setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onReady();
      });
    } on Object catch (error) {
      final isWebm = widget.path.toLowerCase().endsWith('.webm');
      widget.onError(
        isWebm
            ? 'This WebM encoding is not supported by this macOS version.'
            : 'Video decoding failed: $error',
      );
    }
  }

  Future<void> _step(int direction) async {
    await _videoController.pause();
    final frame = Duration(
      microseconds: math.max(1, (1000000 / _frameRate).round()),
    );
    final target = _videoController.value.position + frame * direction;
    final duration = _videoController.value.duration;
    final clamped = target < Duration.zero
        ? Duration.zero
        : target > duration
            ? duration
            : target;
    await _videoController.seekTo(clamped);
  }

  void _syncState() {
    if (!_videoController.value.isInitialized) return;
    final value = _videoController.value;
    final duration = value.duration;
    final progress = duration == Duration.zero
        ? 0.0
        : value.position.inMicroseconds / duration.inMicroseconds;
    widget.controller.update(
      playing: value.isPlaying,
      progress: progress,
      position: value.position,
      duration: duration,
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_videoController.value.isInitialized) {
      return const Center(child: ProgressCircle());
    }
    final size = _videoController.value.size;
    return _PreviewViewport(
      controller: widget.controller,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: VideoPlayer(_videoController),
      ),
    );
  }
}

class _ErrorPreview extends StatelessWidget {
  const _ErrorPreview({
    required this.title,
    required this.message,
    required this.locateLabel,
    required this.onLocate,
  });

  final String title;
  final String message;
  final String locateLabel;
  final VoidCallback onLocate;

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MacosIcon(CupertinoIcons.exclamationmark_triangle, size: 36),
            const SizedBox(height: 14),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.typography.title2,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.typography.body,
            ),
            const SizedBox(height: 18),
            PushButton(
              controlSize: ControlSize.regular,
              onPressed: onLocate,
              child: Text(locateLabel),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDuration(Duration? value) {
  final duration = value ?? Duration.zero;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
