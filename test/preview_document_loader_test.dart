import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:svger/preview/preview_document_loader.dart';
import 'package:svger/preview/preview_models.dart';
import 'package:svger/preview/preview_registry.dart';

void main() {
  test('loads a descriptor and produces initial file metadata', () async {
    final directory = await Directory.systemTemp.createTemp('motion-preview-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/sample.png');
    await file.writeAsBytes(List<int>.filled(12, 1));

    final document = await PreviewDocumentLoader(
      registry: PreviewRegistry(),
    ).load(
      DocumentDescriptor(
        id: 'sample',
        path: file.path,
        displayName: 'sample.png',
        extension: 'png',
        source: 'test',
      ),
    );

    expect(document.state, DocumentLoadState.ready);
    expect(document.adapter.kind, PreviewKind.raster);
    expect(document.metadata['File size'], '12 B');
  });

  test('keeps missing resources in an explicit error state', () async {
    final document = await PreviewDocumentLoader(
      registry: PreviewRegistry(),
    ).load(
      const DocumentDescriptor(
        id: 'missing',
        path: '/definitely/missing/sample.png',
        displayName: 'sample.png',
        extension: 'png',
        source: 'test',
        accessAvailable: false,
      ),
    );

    expect(document.state, DocumentLoadState.error);
    expect(document.errorMessage, contains('missing or inaccessible'));
  });
}
