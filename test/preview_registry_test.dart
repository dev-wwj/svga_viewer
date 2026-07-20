import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:svger/preview/preview_models.dart';
import 'package:svger/preview/preview_registry.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory =
        await Directory.systemTemp.createTemp('motion_preview_registry');
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test('resolves every supported extension to a preview adapter', () async {
    final registry = PreviewRegistry();
    for (final extension in PreviewRegistry.supportedExtensions) {
      final file = File('${directory.path}/sample.$extension');
      if (extension == 'json') {
        await file.writeAsString(
          '{"layers":[],"fr":30,"ip":0,"op":60}',
        );
      } else {
        await file.writeAsBytes(<int>[0]);
      }
      final adapter = await registry.resolve(_descriptor(file, extension));
      expect(adapter.kind, isNot(PreviewKind.unsupported));
    }
  });

  test('rejects ordinary JSON before it reaches the Lottie renderer', () async {
    final file = File('${directory.path}/ordinary.json');
    await file.writeAsString('{"hello":"world"}');

    expect(
      () => PreviewRegistry().resolve(_descriptor(file, 'json')),
      throwsFormatException,
    );
  });
}

DocumentDescriptor _descriptor(File file, String extension) {
  return DocumentDescriptor(
    id: file.path,
    path: file.path,
    displayName: file.uri.pathSegments.last,
    extension: extension,
    source: 'test',
  );
}
