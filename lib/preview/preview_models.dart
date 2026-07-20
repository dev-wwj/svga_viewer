import 'dart:io';

enum PreviewKind { svga, lottie, raster, svg, video, unsupported }

enum DocumentLoadState { ready, loading, error }

enum CanvasBackground { checkerboard, light, dark, custom }

class PreviewCapabilities {
  const PreviewCapabilities({
    this.timeline = false,
    this.frameStep = false,
    this.speed = false,
    this.loop = false,
    this.zoom = true,
    this.background = true,
  });

  final bool timeline;
  final bool frameStep;
  final bool speed;
  final bool loop;
  final bool zoom;
  final bool background;
}

class PreviewAdapter {
  const PreviewAdapter({
    required this.kind,
    required this.label,
    required this.capabilities,
  });

  final PreviewKind kind;
  final String label;
  final PreviewCapabilities capabilities;
}

class DocumentDescriptor {
  const DocumentDescriptor({
    required this.id,
    required this.path,
    required this.displayName,
    required this.extension,
    required this.source,
    this.accessAvailable = true,
  });

  factory DocumentDescriptor.fromMap(Map<dynamic, dynamic> map) {
    final path = (map['path'] ?? '').toString();
    final fileName =
        path.isEmpty ? 'Untitled' : path.split(Platform.pathSeparator).last;
    final displayName = (map['displayName'] ?? fileName).toString();
    final rawExtension = (map['extension'] ?? '').toString();
    final extension = rawExtension.isNotEmpty
        ? rawExtension.replaceFirst('.', '').toLowerCase()
        : _extensionOf(displayName);
    return DocumentDescriptor(
      id: (map['id'] ?? path).toString(),
      path: path,
      displayName: displayName,
      extension: extension,
      source: (map['source'] ?? 'unknown').toString(),
      accessAvailable: map['accessAvailable'] != false,
    );
  }

  final String id;
  final String path;
  final String displayName;
  final String extension;
  final String source;
  final bool accessAvailable;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'path': path,
        'displayName': displayName,
        'extension': extension,
        'source': source,
        'accessAvailable': accessAvailable,
      };

  static String _extensionOf(String name) {
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  }
}

class PreviewDocument {
  PreviewDocument({
    required this.descriptor,
    required this.adapter,
    this.state = DocumentLoadState.ready,
    this.errorMessage,
    Map<String, String>? metadata,
  }) : metadata = metadata ?? <String, String>{};

  final DocumentDescriptor descriptor;
  PreviewAdapter adapter;
  DocumentLoadState state;
  String? errorMessage;
  final Map<String, String> metadata;

  String get id => descriptor.id;
  String get path => descriptor.path;
  String get displayName => descriptor.displayName;
  String get extension => descriptor.extension;
}
