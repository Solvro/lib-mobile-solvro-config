import "package:mason_logger/mason_logger.dart";
import "package:process_run/shell.dart";

import "add_commitlint.dart";
import "add_lint_staged_to_pubspec.dart";
import "add_linter.dart";
import "ci/add_commitlint_ci.dart";
import "ci/add_flutter_ci.dart";
import "ci/add_pr_title_ci.dart";

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
  addLinter(yamlName, logger);
  addCommitLint(logger);
  await addLintStageToPubspec(logger);
  if (installAppVersion) {
    addFlutterCI(logger);
  } else {
    logger.warn(
      "Skipping Flutter CI for package installation. Currently, Flutter CI is only supported for app installation.",
    );
  }
  addPRTitleCI(logger);
  addCommitLintCI(logger);
}
