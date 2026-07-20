import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

abstract interface class WorkspaceStore {
  Future<Map<String, dynamic>?> load();
  Future<void> save(Map<String, dynamic> value);
}

class SharedPreferencesWorkspaceStore implements WorkspaceStore {
  static const String _key = 'motion_preview.workspace.v1';

  @override
  Future<Map<String, dynamic>?> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final value = preferences.getString(_key);
      if (value == null || value.isEmpty) return null;
      final decoded = jsonDecode(value);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on Object {
      return null;
    }
  }

  @override
  Future<void> save(Map<String, dynamic> value) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_key, jsonEncode(value));
    } on Object {
      // Persistence is optional on unsupported/test platforms.
    }
  }
}
