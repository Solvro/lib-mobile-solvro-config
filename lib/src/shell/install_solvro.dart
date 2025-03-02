import "package:mason_logger/mason_logger.dart";
import "package:process_run/shell.dart";

import "add_commitlint.dart";
import "add_lint_staged_to_pubspec.dart";
import "add_linter.dart";

Future<void> installSolvroApp(
  Logger logger, {
  required bool installAppVersion,
}) async {
  final shell = Shell();
  final yamlName = installAppVersion ? "app" : "package";
  await shell.run(r'''
      dart run husky install
      dart run husky set .husky/commit-msg 'dart run commitlint_cli --edit "$1"'
      dart run husky set .husky/pre-commit "dart run lint_staged"
''');
  logger.info(green.wrap("Added husky hooks"));
  await addLinter(yamlName, logger);
  await addCommitLint(logger);
  await addLintStageToPubspec(logger);
}
