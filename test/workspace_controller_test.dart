import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:svger/preview/document_platform_service.dart';
import 'package:svger/preview/preview_models.dart';
import 'package:svger/preview/workspace_controller.dart';
import 'package:svger/preview/workspace_store.dart';

void main() {
  late Directory directory;
  late _FakePlatformService platform;
  late _MemoryStore store;
  late WorkspaceController controller;

  setUp(() async {
    directory =
        await Directory.systemTemp.createTemp('motion_preview_workspace');
    platform = _FakePlatformService();
    store = _MemoryStore();
    controller = WorkspaceController(platformService: platform, store: store);
    await controller.initialize();
  });

  tearDown(() async {
    controller.dispose();
    await directory.delete(recursive: true);
  });

  test('deduplicates paths and releases a document when its tab closes',
      () async {
    final file = File('${directory.path}/image.png');
    await file.writeAsBytes(<int>[1, 2, 3]);
    final descriptor = _descriptor(file, id: 'image-id');

    await controller.addDocuments(<DocumentDescriptor>[descriptor, descriptor]);
    expect(controller.documents, hasLength(1));

    await controller.closeDocument(0);
    expect(controller.documents, isEmpty);
    expect(platform.releasedIds, contains('image-id'));
  });

  test('restores saved documents and the selected tab', () async {
    controller.dispose();
    final first = File('${directory.path}/first.png')
      ..writeAsBytesSync(<int>[1]);
    final second = File('${directory.path}/second.jpg')
      ..writeAsBytesSync(<int>[2]);
    store.value = <String, dynamic>{
      'documents': [
        _descriptor(first, id: 'first').toMap(),
        _descriptor(second, id: 'second').toMap(),
      ],
      'selectedId': 'second',
      'background': 'dark',
    };

    controller = WorkspaceController(platformService: platform, store: store);
    await controller.initialize();

    expect(controller.documents, hasLength(2));
    expect(controller.selectedDocument?.id, 'second');
    expect(controller.background, CanvasBackground.dark);
  });

  test('loads a pending document for an independent resource window', () async {
    final file = File('${directory.path}/pending.png');
    await file.writeAsBytes(<int>[1, 2, 3]);
    platform.pending = <DocumentDescriptor>[_descriptor(file, id: 'pending')];

    controller.dispose();
    controller = WorkspaceController(platformService: platform, store: store);
    await controller.initialize();

    expect(controller.selectedDocument?.id, 'pending');
    expect(controller.documents, hasLength(1));
    expect(controller.initializing, isFalse);
  });

  test('keeps an inaccessible resource in an explicit error state', () async {
    final missing = File('${directory.path}/missing.png');
    await controller.addDocuments(<DocumentDescriptor>[
      _descriptor(missing, id: 'missing'),
    ]);

    expect(controller.selectedDocument?.state, DocumentLoadState.error);
    expect(controller.selectedDocument?.errorMessage, isNotEmpty);
  });

  test('defaults Inspector to visible while preserving a saved preference',
      () async {
    expect(controller.inspectorShown, isTrue);

    controller.dispose();
    store.value = <String, dynamic>{'inspectorShown': false};
    controller = WorkspaceController(platformService: platform, store: store);
    await controller.initialize();

    expect(controller.inspectorShown, isFalse);
  });
}

DocumentDescriptor _descriptor(File file, {required String id}) {
  final name = file.uri.pathSegments.last;
  return DocumentDescriptor(
    id: id,
    path: file.path,
    displayName: name,
    extension: name.split('.').last,
    source: 'test',
  );
}

class _FakePlatformService extends DocumentPlatformService {
  final List<String> releasedIds = <String>[];
  List<DocumentDescriptor> pending = <DocumentDescriptor>[];

  @override
  Stream<List<DocumentDescriptor>> get documentEvents => const Stream.empty();

  @override
  Future<bool> shouldRestoreSession() async => true;

  @override
  Future<List<DocumentDescriptor>> takePendingDocuments() async {
    final value = List<DocumentDescriptor>.of(pending);
    pending.clear();
    return value;
  }

  @override
  Future<List<DocumentDescriptor>> resolveBookmarks(
    List<Map<String, dynamic>> savedDocuments,
  ) async {
    return savedDocuments
        .map(DocumentDescriptor.fromMap)
        .toList(growable: false);
  }

  @override
  Future<void> releaseDocuments(Iterable<String> ids) async {
    releasedIds.addAll(ids);
  }
}

class _MemoryStore implements WorkspaceStore {
  Map<String, dynamic>? value;

  @override
  Future<Map<String, dynamic>?> load() async => value;

  @override
  Future<void> save(Map<String, dynamic> value) async {
    this.value = value;
  }
}
