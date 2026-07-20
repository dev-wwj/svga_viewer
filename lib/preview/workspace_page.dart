import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Colors, Divider, SelectableText;
import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:async';

import 'preview_controls.dart';
import 'preview_host.dart';
import 'preview_models.dart';
import 'workspace_controller.dart';
import '../generated/app_localizations.dart';

class WorkspacePage extends StatefulWidget {
  const WorkspacePage({
    super.key,
    this.controller,
  });

  final WorkspaceController? controller;

  @override
  State<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends State<WorkspacePage> {
  late final WorkspaceController controller;
  final GlobalKey<PreviewHostState> _previewKey = GlobalKey<PreviewHostState>();
  bool _inspectorVisibilityApplied = false;
  bool _resourceWindowShown = false;
  Size? _appliedMinimumSize;
  VoidCallback? _toggleInspectorAction;

  @override
  void initState() {
    super.initState();
    controller = widget.controller ?? WorkspaceController();
    controller.addListener(_workspaceChanged);
    controller.initialize();
  }

  void _workspaceChanged() {
    if (mounted) setState(() {});
    final document = controller.selectedDocument;
    final title = document?.displayName;
    windowManager.setTitle(
      title == null ? 'Motion Preview' : '$title — Motion Preview',
    );
    if (document != null) _applyWindowMinimumSize(document);
  }

  void _handleMetadata(Map<String, String> values) {
    final document = controller.selectedDocument;
    if (document == null) return;
    controller.updateMetadata(document.id, values);
  }

  Size _minimumWindowSizeFor(PreviewDocument document) {
    final capabilities = document.adapter.capabilities;
    final hasTransport = capabilities.timeline ||
        capabilities.frameStep ||
        capabilities.speed ||
        capabilities.loop;
    return hasTransport ? const Size(800, 520) : const Size(640, 420);
  }

  void _applyWindowMinimumSize(PreviewDocument document) {
    final minimum = _minimumWindowSizeFor(document);
    if (_appliedMinimumSize == minimum) return;
    _appliedMinimumSize = minimum;
    unawaited(windowManager.setMinimumSize(minimum));
  }

  Future<void> _handlePreviewReady() async {
    if (!mounted) return;
    _showResourceWindow();
  }

  void _handlePreviewError(PreviewDocument document, String message) {
    final l = AppLocalizations.of(context);
    final localized = switch (message) {
      final value when value.startsWith('SVGA decoding failed: ') =>
        l.svgaDecodingFailed(value.substring('SVGA decoding failed: '.length)),
      final value when value.startsWith('Lottie decoding failed: ') =>
        l.lottieDecodingFailed(
            value.substring('Lottie decoding failed: '.length)),
      final value when value.startsWith('Image decoding failed: ') =>
        l.imageDecodingFailed(
            value.substring('Image decoding failed: '.length)),
      final value when value.startsWith('SVG decoding failed: ') =>
        l.svgDecodingFailed(value.substring('SVG decoding failed: '.length)),
      final value when value.startsWith('Video decoding failed: ') =>
        l.videoDecodingFailed(
            value.substring('Video decoding failed: '.length)),
      _ => message,
    };
    controller.reportError(document.id, localized);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_handlePreviewReady());
    });
  }

  void _showResourceWindow() {
    if (_resourceWindowShown ||
        !mounted ||
        controller.selectedDocument == null) {
      return;
    }
    _resourceWindowShown = true;
    unawaited(controller.platformService.showResourceWindow());
  }

  @override
  void dispose() {
    controller.removeListener(_workspaceChanged);
    if (widget.controller == null) controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PlatformMenuBar(
      menus: _menus(),
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.keyN, meta: true):
              controller.platformService.createWorkspaceWindow,
          const SingleActivator(LogicalKeyboardKey.keyW, meta: true):
              windowManager.close,
          const SingleActivator(LogicalKeyboardKey.space): () =>
              _previewKey.currentState?.togglePlayback(),
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
              _previewKey.currentState?.stepBackward(),
          const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
              _previewKey.currentState?.stepForward(),
          const SingleActivator(LogicalKeyboardKey.digit0, meta: true): () =>
              _previewKey.currentState?.fit(),
          const SingleActivator(LogicalKeyboardKey.digit1, meta: true): () =>
              _previewKey.currentState?.actualSize(),
          const SingleActivator(LogicalKeyboardKey.equal, meta: true): () =>
              _previewKey.currentState?.zoomIn(),
          const SingleActivator(LogicalKeyboardKey.minus, meta: true): () =>
              _previewKey.currentState?.zoomOut(),
        },
        child: Focus(
          autofocus: true,
          child: MacosWindow(
            // Use the native macOS title bar so the preview canvas can reach
            // the window edges without an extra Flutter title strip.
            titleBar: null,
            endSidebar: _buildInspector(),
            child: Builder(
              builder: (windowContext) {
                final scope = MacosWindowScope.of(windowContext);
                controller.platformService
                    .setNativeCommandHandler((call) async {
                  if (call.method == 'toggleInspector' &&
                      mounted &&
                      controller.selectedDocument != null) {
                    _toggleInspector(scope);
                  }
                  return null;
                });
                _toggleInspectorAction = () => _toggleInspector(scope);
                _applyInitialInspectorVisibility(scope);
                return MediaQuery.removePadding(
                  context: windowContext,
                  removeTop: true,
                  removeBottom: true,
                  child: MacosScaffold(
                    children: [
                      ContentArea(
                        minWidth: 360,
                        builder: (context, _) => _buildContent(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<PlatformMenuItem> _menus() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.macOS) {
      return const <PlatformMenuItem>[];
    }
    final l = AppLocalizations.of(context);
    return <PlatformMenuItem>[
      const PlatformMenu(
        label: 'Motion Preview',
        menus: [
          PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.about),
          PlatformMenuItemGroup(
            members: [
              PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.hide,
              ),
              PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.hideOtherApplications,
              ),
            ],
          ),
          PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.quit),
        ],
      ),
      PlatformMenu(
        label: l.file,
        menus: [
          PlatformMenuItem(
            label: l.newWindow,
            shortcut:
                const SingleActivator(LogicalKeyboardKey.keyN, meta: true),
            onSelected: controller.platformService.createWorkspaceWindow,
          ),
          PlatformMenuItem(
            label: l.closeWindow,
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyW,
              meta: true,
            ),
            onSelected: windowManager.close,
          ),
        ],
      ),
      PlatformMenu(
        label: l.playback,
        menus: [
          PlatformMenuItem(
            label: l.playPause,
            shortcut: const SingleActivator(LogicalKeyboardKey.space),
            onSelected: () => _previewKey.currentState?.togglePlayback(),
          ),
          PlatformMenuItem(
            label: l.previousFrame,
            shortcut: const SingleActivator(LogicalKeyboardKey.arrowLeft),
            onSelected: () => _previewKey.currentState?.stepBackward(),
          ),
          PlatformMenuItem(
            label: l.nextFrame,
            shortcut: const SingleActivator(LogicalKeyboardKey.arrowRight),
            onSelected: () => _previewKey.currentState?.stepForward(),
          ),
        ],
      ),
      PlatformMenu(
        label: l.view,
        menus: [
          PlatformMenuItem(
            label: l.fitWindow,
            shortcut:
                const SingleActivator(LogicalKeyboardKey.digit0, meta: true),
            onSelected: () => _previewKey.currentState?.fit(),
          ),
          PlatformMenuItem(
            label: l.actualSize,
            shortcut:
                const SingleActivator(LogicalKeyboardKey.digit1, meta: true),
            onSelected: () => _previewKey.currentState?.actualSize(),
          ),
          if (controller.selectedDocument != null)
            PlatformMenuItem(
              label:
                  controller.inspectorShown ? l.hideInspector : l.showInspector,
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyI,
                meta: true,
                shift: true,
              ),
              onSelected: _toggleInspectorAction,
            ),
          const PlatformProvidedMenuItem(
            type: PlatformProvidedMenuItemType.toggleFullScreen,
          ),
        ],
      ),
      const PlatformMenu(
        label: 'Window',
        menus: [
          PlatformProvidedMenuItem(
            type: PlatformProvidedMenuItemType.minimizeWindow,
          ),
          PlatformProvidedMenuItem(
            type: PlatformProvidedMenuItemType.zoomWindow,
          ),
        ],
      ),
    ];
  }

  Sidebar _buildInspector() {
    return Sidebar(
      minWidth: 230,
      maxWidth: 340,
      startWidth: 260,
      shownByDefault: false,
      // Resource windows can be small (especially for SVGA/Lottie files).
      // Keep the inspector available at every supported window size.
      windowBreakpoint: 0,
      topOffset: 0,
      builder: (context, scrollController) {
        final l = AppLocalizations.of(context);
        final theme = MacosTheme.of(context);
        final foreground =
            theme.brightness == Brightness.dark ? Colors.white : Colors.black;
        final document = controller.selectedDocument;
        return ColoredBox(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF2C2C2E)
              : const Color(0xFFF6F6F6),
          child: DefaultTextStyle(
            style: theme.typography.body.copyWith(color: foreground),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  l.inspector,
                  style: theme.typography.title3.copyWith(color: foreground),
                ),
                const SizedBox(height: 16),
                if (document == null)
                  Text(
                    l.noSelection,
                    style: theme.typography.body.copyWith(color: foreground),
                  )
                else ...[
                  Text(
                    l.resource,
                    style:
                        theme.typography.headline.copyWith(color: foreground),
                  ),
                  const SizedBox(height: 10),
                  _InspectorValue(label: l.name, value: document.displayName),
                  _InspectorValue(
                    label: l.type,
                    value: document.adapter.label,
                  ),
                  _InspectorValue(
                    label: l.extension,
                    value: document.extension.isEmpty
                        ? '-'
                        : '.${document.extension}',
                  ),
                  _InspectorValue(
                    label: l.source,
                    value: document.descriptor.source,
                  ),
                  _InspectorValue(label: l.path, value: document.path),
                  _InspectorValue(
                    label: l.status,
                    value: document.state == DocumentLoadState.ready
                        ? l.ready
                        : document.state.name,
                  ),
                  ..._metadataRows(document, <String, String>{
                    'File size': l.fileSize,
                    'Modified': l.modified,
                  }),
                  ..._typeSpecificInspector(document, theme, foreground),
                  ..._capabilityInspector(document, theme, foreground, l),
                  const SizedBox(height: 4),
                  Divider(color: theme.dividerColor),
                  const SizedBox(height: 14),
                  Text(
                    l.canvas,
                    style:
                        theme.typography.headline.copyWith(color: foreground),
                  ),
                  const SizedBox(height: 10),
                  CanvasBackgroundPicker(
                    value: controller.background,
                    customColor: Color(controller.customBackgroundValue),
                    onChanged: controller.setBackground,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: Text(l.customColor)),
                      _ColorWellBridge(
                        color: Color(controller.customBackgroundValue),
                        onChanged: (color) {
                          controller.setCustomBackground(color.toARGB32());
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    final document = controller.selectedDocument;
    final content = controller.initializing &&
            defaultTargetPlatform == TargetPlatform.macOS
        ? ColoredBox(
            color: MacosTheme.of(context).canvasColor,
            child: const Center(child: ProgressCircle()),
          )
        : document == null
            ? _EmptyWorkspace(
                recentDocuments: controller.recentDocuments,
                onOpenRecent: controller.reopenRecent,
              )
            : PreviewHost(
                key: _previewKey,
                document: document,
                background: controller.background,
                customBackground: Color(controller.customBackgroundValue),
                platformService: controller.platformService,
                onMetadata: _handleMetadata,
                onReady: _handlePreviewReady,
                onError: (message) => _handlePreviewError(document, message),
                onLocateMissing: () =>
                    controller.locateMissingDocument(document),
              );
    if (document == null) return content;
    if (document.state == DocumentLoadState.error) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => unawaited(_handlePreviewReady()));
    }
    return content;
  }

  void _applyInitialInspectorVisibility(MacosWindowScope scope) {
    if (_inspectorVisibilityApplied || controller.selectedDocument == null) {
      return;
    }
    _inspectorVisibilityApplied = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || scope.isEndSidebarShown == controller.inspectorShown) {
        return;
      }
      scope.toggleEndSidebar();
    });
  }

  void _toggleInspector(MacosWindowScope scope) {
    final nextVisibility = !scope.isEndSidebarShown;
    scope.toggleEndSidebar();
    controller.setInspectorShown(nextVisibility);
  }

  List<Widget> _typeSpecificInspector(
    PreviewDocument document,
    MacosThemeData theme,
    Color foreground,
  ) {
    final l = AppLocalizations.of(context);
    final headingStyle = theme.typography.headline.copyWith(color: foreground);
    final values = switch (document.adapter.kind) {
      PreviewKind.svga || PreviewKind.lottie => <String, String>{
          'Dimensions': l.dimensions,
          'Frames': l.frames,
          'Frame rate': l.frameRate,
          'Duration': l.duration,
        },
      PreviewKind.video => <String, String>{
          'Dimensions': l.dimensions,
          'Duration': l.duration,
          'Frame rate': l.frameRate,
          'Codec': l.codec,
        },
      PreviewKind.raster => <String, String>{
          'Dimensions': l.dimensions,
          'Frames': l.frames,
          'Duration': l.duration,
          'Animation': l.animation,
        },
      PreviewKind.svg => <String, String>{
          'Dimensions': l.dimensions,
          'ViewBox': l.viewBox,
        },
      PreviewKind.unsupported => <String, String>{},
    };
    final title = switch (document.adapter.kind) {
      PreviewKind.svga || PreviewKind.lottie => l.animation,
      PreviewKind.video => l.video,
      PreviewKind.raster => document.metadata['Animation'] == 'Animated raster'
          ? l.animatedImage
          : l.image,
      PreviewKind.svg => l.vectorImage,
      PreviewKind.unsupported => '',
    };
    final rows = _metadataRows(document, values);
    if (title.isEmpty || rows.isEmpty) return const <Widget>[];
    return <Widget>[
      const SizedBox(height: 14),
      Divider(color: theme.dividerColor),
      const SizedBox(height: 14),
      Text(title, style: headingStyle),
      const SizedBox(height: 10),
      ...rows,
    ];
  }

  List<Widget> _metadataRows(
    PreviewDocument document,
    Map<String, String> labels,
  ) {
    return labels.entries
        .map((entry) {
          final value = document.metadata[entry.key];
          return value == null
              ? null
              : _InspectorValue(label: entry.value, value: value);
        })
        .whereType<Widget>()
        .toList(growable: false);
  }

  List<Widget> _capabilityInspector(
    PreviewDocument document,
    MacosThemeData theme,
    Color foreground,
    AppLocalizations l,
  ) {
    final capabilities = <String, bool>{
      l.timeline: document.adapter.capabilities.timeline,
      l.frameStep: document.adapter.capabilities.frameStep,
      l.speed: document.adapter.capabilities.speed,
      l.loop: document.adapter.capabilities.loop,
    }..removeWhere((_, enabled) => !enabled);
    if (capabilities.isEmpty) return const <Widget>[];
    return <Widget>[
      const SizedBox(height: 14),
      Divider(color: theme.dividerColor),
      const SizedBox(height: 14),
      Text(
        l.capabilities,
        style: theme.typography.headline.copyWith(color: foreground),
      ),
      const SizedBox(height: 10),
      for (final label in capabilities.keys)
        _InspectorValue(label: label, value: l.available),
    ];
  }
}

class _InspectorValue extends StatelessWidget {
  const _InspectorValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    final foreground =
        theme.brightness == Brightness.dark ? Colors.white : Colors.black;
    final secondary = theme.brightness == Brightness.dark
        ? const Color(0xFFB8B8BD)
        : const Color(0xFF66666B);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: theme.typography.caption1.copyWith(
                color: secondary,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: theme.typography.caption1.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

/// A controlled bridge to the macOS color panel.
class _ColorWellBridge extends StatefulWidget {
  const _ColorWellBridge({required this.color, required this.onChanged});

  final Color color;
  final ValueChanged<Color> onChanged;

  @override
  State<_ColorWellBridge> createState() => _ColorWellBridgeState();
}

class _ColorWellBridgeState extends State<_ColorWellBridge> {
  static const MethodChannel _methodChannel =
      MethodChannel('dev.groovinchip.macos_ui');
  static const EventChannel _colorChannel =
      EventChannel('dev.groovinchip.macos_ui/color_panel');
  StreamSubscription<dynamic>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = _colorChannel.receiveBroadcastStream().listen((value) {
      final argb = value is int ? value : int.tryParse(value.toString());
      if (argb != null) widget.onChanged(Color(argb));
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MacosTooltip(
      message: 'Choose custom canvas color',
      child: GestureDetector(
        onTap: () {
          unawaited(
            _methodChannel.invokeMethod<void>('color_panel', <String, String>{
              'mode': 'ColorPickerMode.wheel',
            }),
          );
        },
        child: Container(
          width: 44,
          height: 23,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: Border.all(color: MacosTheme.of(context).dividerColor),
          ),
          child: ColoredBox(color: widget.color),
        ),
      ),
    );
  }
}

class _EmptyWorkspace extends StatelessWidget {
  const _EmptyWorkspace({
    required this.recentDocuments,
    required this.onOpenRecent,
  });

  final List<Map<String, dynamic>> recentDocuments;
  final ValueChanged<Map<String, dynamic>> onOpenRecent;

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    return ColoredBox(
      color: theme.canvasColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth < 900 ? 36.0 : 64.0;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 48,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 6,
                      child: _RecentPanel(
                        recentDocuments: recentDocuments,
                        onOpenRecent: onOpenRecent,
                      ),
                    ),
                    SizedBox(width: constraints.maxWidth < 900 ? 40 : 72),
                    const Expanded(
                      flex: 4,
                      child: _AboutPanel(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RecentPanel extends StatelessWidget {
  const _RecentPanel({
    required this.recentDocuments,
    required this.onOpenRecent,
  });

  final List<Map<String, dynamic>> recentDocuments;
  final ValueChanged<Map<String, dynamic>> onOpenRecent;

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    final l = AppLocalizations.of(context);
    final secondaryColor = theme.brightness == Brightness.dark
        ? const Color(0xFFB5B5BA)
        : const Color(0xFF69696E);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.recent, style: theme.typography.largeTitle),
        const SizedBox(height: 22),
        if (recentDocuments.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 34),
            child: Row(
              children: [
                MacosIcon(
                  CupertinoIcons.clock,
                  size: 22,
                  color: secondaryColor,
                ),
                const SizedBox(width: 12),
                Text(
                  l.noRecent,
                  style: theme.typography.body.copyWith(
                    color: secondaryColor,
                  ),
                ),
              ],
            ),
          )
        else
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (final recent in recentDocuments.take(8))
                  _RecentResourceTile(
                    recent: recent,
                    onPressed: () => onOpenRecent(recent),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RecentResourceTile extends StatefulWidget {
  const _RecentResourceTile({required this.recent, required this.onPressed});

  final Map<String, dynamic> recent;
  final VoidCallback onPressed;

  @override
  State<_RecentResourceTile> createState() => _RecentResourceTileState();
}

class _RecentResourceTileState extends State<_RecentResourceTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    final displayName =
        (widget.recent['displayName'] ?? widget.recent['path'] ?? '')
            .toString();
    final path = (widget.recent['path'] ?? '').toString();
    final secondaryColor = theme.brightness == Brightness.dark
        ? const Color(0xFFB5B5BA)
        : const Color(0xFF69696E);
    final hoverColor = theme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    return MacosTooltip(
      message: path,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            margin: const EdgeInsets.only(bottom: 3),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: _hovered ? hoverColor : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                MacosIcon(
                  CupertinoIcons.doc,
                  size: 18,
                  color: secondaryColor,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.typography.body,
                      ),
                      if (path.isNotEmpty && path != displayName) ...[
                        const SizedBox(height: 2),
                        Text(
                          path,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.typography.caption1.copyWith(
                            color: secondaryColor,
                          ),
                        ),
                      ],
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

class _AboutPanel extends StatelessWidget {
  const _AboutPanel();

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    final l = AppLocalizations.of(context);
    final secondaryColor = theme.brightness == Brightness.dark
        ? const Color(0xFFB5B5BA)
        : const Color(0xFF69696E);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'images/motion_preview_app_icon.png',
          width: 112,
          height: 112,
          filterQuality: FilterQuality.high,
        ),
        const SizedBox(height: 22),
        Text(l.appTitle, style: theme.typography.largeTitle),
        const SizedBox(height: 10),
        Text(
          l.aboutDescription,
          textAlign: TextAlign.center,
          style: theme.typography.body.copyWith(
            color: secondaryColor,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'SVGA · Lottie · GIF · WebP · SVG · Video',
          textAlign: TextAlign.center,
          style: theme.typography.caption1.copyWith(color: secondaryColor),
        ),
      ],
    );
  }
}
