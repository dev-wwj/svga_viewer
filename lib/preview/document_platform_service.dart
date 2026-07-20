import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'preview_models.dart';
import 'preview_registry.dart';

class DocumentPlatformService {
  static const EventChannel _eventChannel =
      EventChannel('com.motionpreview.documents');
  static const MethodChannel _methodChannel =
      MethodChannel('com.motionpreview.workspace');

  Stream<List<DocumentDescriptor>> get documentEvents => _eventChannel
          .receiveBroadcastStream()
          .map(_descriptorsFromValue)
          .handleError((Object error) {
        debugPrint('Document EventChannel error: $error');
      });

  void setNativeCommandHandler(
    Future<Object?> Function(MethodCall call) handler,
  ) {
    _methodChannel.setMethodCallHandler(handler);
  }

  Future<List<DocumentDescriptor>> takePendingDocuments() async {
    return _invokeForDocuments('takePendingDocuments');
  }

  Future<bool> shouldRestoreSession() async {
    try {
      final value = await _methodChannel.invokeMapMethod<String, dynamic>(
        'workspaceContext',
      );
      return value?['restoreSession'] != false;
    } on MissingPluginException {
      return true;
    } on PlatformException {
      return true;
    }
  }

  Future<List<DocumentDescriptor>> showOpenPanel() async {
    try {
      final documents = await _invokeForDocuments('showOpenPanel');
      if (documents.isNotEmpty || Platform.isMacOS) return documents;
    } on MissingPluginException {
      // Use the cross-platform picker below.
    }
    return _showFallbackPicker();
  }

  Future<List<DocumentDescriptor>> resolveBookmarks(
    List<Map<String, dynamic>> savedDocuments,
  ) async {
    try {
      final value = await _methodChannel.invokeMethod<dynamic>(
        'resolveBookmarks',
        <String, dynamic>{'documents': savedDocuments},
      );
      return _descriptorsFromValue(value);
    } on MissingPluginException {
      return savedDocuments
          .map(DocumentDescriptor.fromMap)
          .toList(growable: false);
    } on PlatformException catch (error) {
      debugPrint('resolveBookmarks failed: ${error.message}');
      return savedDocuments
          .map(DocumentDescriptor.fromMap)
          .toList(growable: false);
    }
  }

  Future<void> createWorkspaceWindow() async {
    try {
      await _methodChannel.invokeMethod<void>('createWorkspaceWindow');
    } on MissingPluginException {
      // A second native window is a macOS-only feature.
    }
  }

  Future<void> showResourceWindow() async {
    try {
      await _methodChannel.invokeMethod<void>('showResourceWindow');
    } on MissingPluginException {
      // Resource windows are a macOS-only presentation detail.
    }
  }

  Future<void> openDocument(DocumentDescriptor descriptor) async {
    try {
      await _methodChannel.invokeMethod<void>(
        'openDocument',
        descriptor.toMap(),
      );
    } on MissingPluginException {
      // Independent native windows are a macOS-only feature.
    }
  }

  Future<void> releaseDocuments(Iterable<String> ids) async {
    try {
      await _methodChannel.invokeMethod<void>(
        'releaseDocuments',
        <String, dynamic>{'ids': ids.toList(growable: false)},
      );
    } on MissingPluginException {
      // No persistent native access exists on fallback platforms.
    }
  }

  Future<DocumentDescriptor?> locateMissingDocument(String id) async {
    try {
      final value = await _methodChannel.invokeMethod<dynamic>(
        'locateMissingDocument',
        <String, dynamic>{'id': id},
      );
      final documents = _descriptorsFromValue(value);
      return documents.isEmpty ? null : documents.first;
    } on MissingPluginException {
      return null;
    }
  }

  Future<Map<String, String>> mediaMetadata(String path) async {
    try {
      final value = await _methodChannel.invokeMapMethod<String, dynamic>(
        'mediaMetadata',
        <String, dynamic>{'path': path},
      );
      return value?.map(
            (key, dynamic value) => MapEntry(key, value.toString()),
          ) ??
          <String, String>{};
    } on MissingPluginException {
      return <String, String>{};
    } on PlatformException {
      return <String, String>{};
    }
  }

  Future<List<DocumentDescriptor>> _invokeForDocuments(String method) async {
    try {
      final value = await _methodChannel.invokeMethod<dynamic>(method);
      return _descriptorsFromValue(value);
    } on MissingPluginException {
      return <DocumentDescriptor>[];
    } on PlatformException catch (error) {
      debugPrint('$method failed: ${error.message}');
      return <DocumentDescriptor>[];
    }
  }

  Future<List<DocumentDescriptor>> _showFallbackPicker() async {
    final group = XTypeGroup(
      label: 'Motion Preview resources',
      extensions: PreviewRegistry.supportedExtensions.toList()..sort(),
    );
    final files = await openFiles(acceptedTypeGroups: <XTypeGroup>[group]);
    return files
        .where((file) => file.path.isNotEmpty)
        .map(
          (file) => DocumentDescriptor(
            id: file.path,
            path: file.path,
            displayName: file.name,
            extension: _extensionOf(file.name),
            source: 'openPanel',
          ),
        )
        .toList(growable: false);
  }

  static List<DocumentDescriptor> _descriptorsFromValue(dynamic value) {
    dynamic rawDocuments = value;
    if (value is Map) rawDocuments = value['documents'] ?? value;
    if (rawDocuments is Map) rawDocuments = <dynamic>[rawDocuments];
    if (rawDocuments is! List) return <DocumentDescriptor>[];
    return rawDocuments
        .whereType<Map>()
        .map(DocumentDescriptor.fromMap)
        .where((document) => document.path.isNotEmpty)
        .toList(growable: false);
  }

  static String _extensionOf(String name) {
    final index = name.lastIndexOf('.');
    return index < 0 ? '' : name.substring(index + 1).toLowerCase();
  }
}
