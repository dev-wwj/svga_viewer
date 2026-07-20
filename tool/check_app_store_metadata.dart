import 'dart:io';

const required = <String>[
  'name.txt',
  'subtitle.txt',
  'promotional_text.txt',
  'description.txt',
  'keywords.txt',
  'category.txt',
  'copyright.txt',
  'release_notes.txt',
  'review_notes.txt',
  'support_url.txt',
  'privacy_url.txt',
  'marketing_url.txt',
];

void main() {
  var failed = false;
  for (final locale in ['en-US', 'zh-Hans']) {
    final directory = Directory('metadata/app_store/$locale');
    for (final name in required) {
      final file = File('${directory.path}/$name');
      if (!file.existsSync() || file.readAsStringSync().trim().isEmpty) {
        stderr.writeln('Missing metadata: ${file.path}');
        failed = true;
      }
    }
    for (final url in [
      'support_url.txt',
      'privacy_url.txt',
      'marketing_url.txt'
    ]) {
      final value = File('${directory.path}/$url').readAsStringSync().trim();
      if (value.startsWith('TBD_')) {
        stderr.writeln(
            'URL placeholder must be replaced before release: ${directory.path}/$url');
        failed = true;
      }
    }
  }
  if (failed) exitCode = 1;
}
