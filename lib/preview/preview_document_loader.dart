import 'dart:io';

import 'preview_models.dart';
import 'preview_registry.dart';

/// Converts an incoming descriptor into a document that is ready for the UI.
///
/// Keeping filesystem access and format detection here leaves
/// [WorkspaceController] focused on workspace state and lifecycle.
class PreviewDocumentLoader {
  const PreviewDocumentLoader({required this.registry});

  final PreviewRegistry registry;

  Future<PreviewDocument> load(DocumentDescriptor descriptor) async {
    PreviewAdapter adapter = PreviewRegistry.unsupportedAdapter;
    DocumentLoadState state = DocumentLoadState.ready;
    String? error;

    try {
      final file = File(descriptor.path);
      if (!descriptor.accessAvailable || !await file.exists()) {
        throw const FileSystemException('The file is missing or inaccessible.');
      }
      adapter = await registry.resolve(descriptor);
      if (adapter.kind == PreviewKind.unsupported) {
        throw FormatException(
          'Unsupported .${descriptor.extension} resource.',
        );
      }
    } on Object catch (exception) {
      state = DocumentLoadState.error;
      error = _messageFor(exception);
    }

    final stat = await File(descriptor.path).stat();
    return PreviewDocument(
      descriptor: descriptor,
      adapter: adapter,
      state: state,
      errorMessage: error,
      metadata: <String, String>{
        'Format': adapter.label,
        if (stat.type != FileSystemEntityType.notFound)
          'File size': _formatBytes(stat.size),
        if (stat.type != FileSystemEntityType.notFound)
          'Modified': stat.modified.toLocal().toString().split('.').first,
      },
    );
  }

  static String _messageFor(Object exception) {
    if (exception is FormatException) return exception.message;
    if (exception is FileSystemException) {
      return exception.message.isEmpty
          ? 'The file is missing or inaccessible.'
          : exception.message;
    }
    return 'The resource could not be opened.';
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
