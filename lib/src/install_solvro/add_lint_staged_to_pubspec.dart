import "dart:io";

import "package:mason_logger/mason_logger.dart";

Future<void> addLintStageToPubspec(Logger logger) async {
  final pubspecFile = File("pubspec.yaml");
  if (pubspecFile.existsSync()) {
    final pubspecContent = await pubspecFile.readAsString();
    if (!pubspecContent.contains(
      'lint_staged:\n  "lib/**.dart": dart format && dart fix --apply',
    )) {
      const updatedPubspecContent = '''
lint_staged:
  "lib/**.dart": dart format && dart fix --apply
''';
      await pubspecFile.writeAsString(
        updatedPubspecContent,
        mode: FileMode.append,
      );
      logger.info(
        green.wrap("Updated pubspec.yaml with lint_staged configuration"),
      );
    } else {
      logger.info(
        blue.wrap("lint_staged configuration already exists in pubspec.yaml"),
      );
    }
  } else {
    logger.err(red.wrap("pubspec.yaml file not found"));
  }
}
