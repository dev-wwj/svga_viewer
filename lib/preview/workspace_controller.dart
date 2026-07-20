import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'document_platform_service.dart';
import 'preview_document_loader.dart';
import 'preview_models.dart';
import 'preview_registry.dart';
import 'workspace_store.dart';

class WorkspaceController extends ChangeNotifier {
  WorkspaceController({
    DocumentPlatformService? platformService,
    PreviewRegistry? registry,
    PreviewDocumentLoader? loader,
    WorkspaceStore? store,
  })  : platformService = platformService ?? DocumentPlatformService(),
        loader = loader ??
            PreviewDocumentLoader(registry: registry ?? PreviewRegistry()),
        store = store ?? SharedPreferencesWorkspaceStore();

  final DocumentPlatformService platformService;
  final PreviewDocumentLoader loader;
  final WorkspaceStore store;

  final List<PreviewDocument> _documents = <PreviewDocument>[];
  final List<Map<String, dynamic>> _recentDocuments = <Map<String, dynamic>>[];
  StreamSubscription<List<DocumentDescriptor>>? _eventSubscription;
  int _selectedIndex = -1;
  bool _initializing = true;
  bool _inspectorShown = true;
  CanvasBackground _background = CanvasBackground.checkerboard;
  int _customBackgroundValue = 0xFF3A3A3A;
  bool _persistenceEnabled = true;
  bool _restoring = false;

  List<PreviewDocument> get documents =>
      List<PreviewDocument>.unmodifiable(_documents);
  List<Map<String, dynamic>> get recentDocuments =>
      List<Map<String, dynamic>>.unmodifiable(_recentDocuments);
  int get selectedIndex => _selectedIndex;
  bool get initializing => _initializing;
  PreviewDocument? get selectedDocument =>
      _selectedIndex >= 0 && _selectedIndex < _documents.length
          ? _documents[_selectedIndex]
          : null;
  CanvasBackground get background => _background;
  int get customBackgroundValue => _customBackgroundValue;
  bool get inspectorShown => _inspectorShown;

  Future<void> initialize() async {
    _eventSubscription = platformService.documentEvents.listen(addDocuments);
    _persistenceEnabled = await platformService.shouldRestoreSession();
    final saved = await store.load();
    if (saved != null) {
      if (_persistenceEnabled) {
        _restoring = true;
        await _restore(saved);
        _restoring = false;
      } else {
        _restoreRecent(saved);
      }
    }
    final pending = await platformService.takePendingDocuments();
    if (pending.isNotEmpty) await addDocuments(pending);
    _initializing = false;
    notifyListeners();
  }

  Future<void> openDocuments() async {
    final documents = await platformService.showOpenPanel();
    if (documents.isNotEmpty) await addDocuments(documents);
  }

  Future<void> reopenRecent(Map<String, dynamic> value) async {
    final resolved = await platformService.resolveBookmarks(
      <Map<String, dynamic>>[value],
    );
    if (resolved.isEmpty) return;
    if (Platform.isMacOS) {
      await platformService.openDocument(resolved.first);
    } else {
      await addDocuments(resolved);
    }
  }

  Future<void> addDocuments(List<DocumentDescriptor> descriptors) async {
    if (descriptors.isEmpty) return;
    int? firstAddedIndex;
    for (final descriptor in descriptors) {
      final existing = _documents.indexWhere(
        (document) => _samePath(document.path, descriptor.path),
      );
      if (existing >= 0) {
        firstAddedIndex ??= existing;
        continue;
      }

      final document = await loader.load(descriptor);
      _documents.add(document);
      firstAddedIndex ??= _documents.length - 1;
      _rememberRecent(descriptor);
    }

    if (firstAddedIndex != null) _selectedIndex = firstAddedIndex;
    notifyListeners();
    await _persist();
  }

  Future<void> selectDocument(int index) async {
    if (index < 0 || index >= _documents.length || index == _selectedIndex) {
      return;
    }
    _selectedIndex = index;
    notifyListeners();
    await _persist();
  }

  Future<void> closeDocument(int index) async {
    if (index < 0 || index >= _documents.length) return;
    final removed = _documents.removeAt(index);
    await platformService.releaseDocuments(<String>[removed.id]);
    if (_documents.isEmpty) {
      _selectedIndex = -1;
    } else if (_selectedIndex >= _documents.length) {
      _selectedIndex = _documents.length - 1;
    } else if (index < _selectedIndex) {
      _selectedIndex -= 1;
    }
    notifyListeners();
    await _persist();
  }

  Future<void> locateMissingDocument(PreviewDocument document) async {
    final replacement =
        await platformService.locateMissingDocument(document.id);
    if (replacement == null) return;
    final index = _documents.indexOf(document);
    if (index < 0) return;
    _documents.removeAt(index);
    await addDocuments(<DocumentDescriptor>[replacement]);
  }

  void updateMetadata(String documentId, Map<String, String> values) {
    final index =
        _documents.indexWhere((document) => document.id == documentId);
    if (index < 0) return;
    _documents[index].metadata.addAll(values);
    notifyListeners();
  }

  void reportError(String documentId, String message) {
    final index =
        _documents.indexWhere((document) => document.id == documentId);
    if (index < 0) return;
    _documents[index]
      ..state = DocumentLoadState.error
      ..errorMessage = message;
    notifyListeners();
  }

  void setBackground(CanvasBackground value) {
    _background = value;
    notifyListeners();
    unawaited(_persist());
  }

  void setCustomBackground(int value) {
    _customBackgroundValue = value;
    _background = CanvasBackground.custom;
    notifyListeners();
    unawaited(_persist());
  }

  void setInspectorShown(bool value) {
    _inspectorShown = value;
    notifyListeners();
    unawaited(_persist());
  }

  Future<void> _restore(Map<String, dynamic> saved) async {
    final rawDocuments = saved['documents'];
    final savedDocuments = rawDocuments is List
        ? rawDocuments.whereType<Map>().map((map) {
            return map.map(
              (dynamic key, dynamic value) => MapEntry(key.toString(), value),
            );
          }).toList(growable: false)
        : <Map<String, dynamic>>[];
    final resolved = await platformService.resolveBookmarks(savedDocuments);
    await addDocuments(resolved);
    final selectedId = saved['selectedId']?.toString();
    final restoredIndex =
        _documents.indexWhere((document) => document.id == selectedId);
    if (restoredIndex >= 0) _selectedIndex = restoredIndex;

    final backgroundName = saved['background']?.toString();
    _background = CanvasBackground.values.firstWhere(
      (value) => value.name == backgroundName,
      orElse: () => CanvasBackground.checkerboard,
    );
    _customBackgroundValue =
        (saved['customBackground'] as num?)?.toInt() ?? 0xFF3A3A3A;
    _inspectorShown = saved['inspectorShown'] is bool
        ? saved['inspectorShown'] == true
        : true;

    _restoreRecent(saved);
  }

  void _restoreRecent(Map<String, dynamic> saved) {
    final recent = saved['recent'];
    if (recent is List) {
      _recentDocuments
        ..clear()
        ..addAll(recent.whereType<Map>().map((map) {
          return map.map(
            (dynamic key, dynamic value) => MapEntry(key.toString(), value),
          );
        }));
    }
  }

  void _rememberRecent(DocumentDescriptor descriptor) {
    _recentDocuments.removeWhere(
      (value) => _samePath(value['path']?.toString() ?? '', descriptor.path),
    );
    _recentDocuments.insert(0, descriptor.toMap());
    if (_recentDocuments.length > 12) {
      _recentDocuments.removeRange(12, _recentDocuments.length);
    }
  }

  Future<void> _persist() {
    if (_restoring) return Future<void>.value();
    return store.save(<String, dynamic>{
      'documents': _persistenceEnabled
          ? _documents
              .map((document) => document.descriptor.toMap())
              .toList(growable: false)
          : const <Map<String, dynamic>>[],
      'selectedId': _persistenceEnabled ? selectedDocument?.id : null,
      'background': _background.name,
      'customBackground': _customBackgroundValue,
      'inspectorShown': _inspectorShown,
      'recent': _recentDocuments,
    });
  }

  static bool _samePath(String first, String second) {
    if (Platform.isWindows || Platform.isMacOS) {
      return first.toLowerCase() == second.toLowerCase();
    }
    return first == second;
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    unawaited(platformService.releaseDocuments(_documents.map((e) => e.id)));
    super.dispose();
  }
}
