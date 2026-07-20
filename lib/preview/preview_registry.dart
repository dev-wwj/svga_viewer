import 'dart:convert';
import 'dart:io';

import 'preview_models.dart';

class PreviewRegistry {
  static const Set<String> supportedExtensions = <String>{
    'svga',
    'json',
    'gif',
    'webp',
    'apng',
    'png',
    'jpg',
    'jpeg',
    'bmp',
    'heic',
    'svg',
    'mp4',
    'mov',
    'm4v',
    'webm',
  };

  static const PreviewAdapter unsupportedAdapter = PreviewAdapter(
    kind: PreviewKind.unsupported,
    label: 'Unsupported',
    capabilities: PreviewCapabilities(zoom: false, background: false),
  );

  static const PreviewAdapter _svgaAdapter = PreviewAdapter(
    kind: PreviewKind.svga,
    label: 'SVGA',
    capabilities: PreviewCapabilities(
      timeline: true,
      frameStep: true,
      speed: true,
      loop: true,
    ),
  );

  static const PreviewAdapter _lottieAdapter = PreviewAdapter(
    kind: PreviewKind.lottie,
    label: 'Lottie',
    capabilities: PreviewCapabilities(
      timeline: true,
      frameStep: true,
      speed: true,
      loop: true,
    ),
  );

  static const PreviewAdapter _animatedRasterAdapter = PreviewAdapter(
    kind: PreviewKind.raster,
    label: 'Animated image',
    capabilities: PreviewCapabilities(
      timeline: true,
      frameStep: true,
      speed: true,
      loop: true,
    ),
  );

  static const PreviewAdapter _rasterAdapter = PreviewAdapter(
    kind: PreviewKind.raster,
    label: 'Image',
    capabilities: PreviewCapabilities(),
  );

  static const PreviewAdapter _svgAdapter = PreviewAdapter(
    kind: PreviewKind.svg,
    label: 'SVG',
    capabilities: PreviewCapabilities(),
  );

  static const PreviewAdapter _videoAdapter = PreviewAdapter(
    kind: PreviewKind.video,
    label: 'Video',
    capabilities: PreviewCapabilities(
      timeline: true,
      frameStep: true,
      speed: true,
      loop: true,
    ),
  );

  Future<PreviewAdapter> resolve(DocumentDescriptor descriptor) async {
    switch (descriptor.extension.toLowerCase()) {
      case 'svga':
        return _svgaAdapter;
      case 'json':
        if (!await isLottieFile(descriptor.path)) {
          throw const FormatException(
              'This JSON file is not a Lottie animation.');
        }
        return _lottieAdapter;
      case 'gif':
      case 'webp':
      case 'apng':
        return _animatedRasterAdapter;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'bmp':
      case 'heic':
        return _rasterAdapter;
      case 'svg':
        return _svgAdapter;
      case 'mp4':
      case 'mov':
      case 'm4v':
      case 'webm':
        return _videoAdapter;
      default:
        return unsupportedAdapter;
    }
  }

  Future<bool> isLottieFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return false;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) return false;
      return decoded['layers'] is List &&
          decoded['fr'] is num &&
          decoded['ip'] is num &&
          decoded['op'] is num;
    } on Object {
      return false;
    }
  }
}
