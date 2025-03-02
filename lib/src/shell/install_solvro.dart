import "dart:io";

import "package:mason_logger/mason_logger.dart";
import "package:process_run/shell.dart";

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
  await File(
    "analysis_options.yaml",
  ).writeAsString("include: package:solvro_config/$yamlName.yaml");
  logger.info(green.wrap("Overriden analysis_options.yaml"));
  await File("commitlint.yaml").writeAsString("""
include: package:solvro_config/commitlint.yaml
rules:
  scope-enum: # define your own scopes here
    - 2
    - always
    - - example-scope-1
      - example-scope-2
""");
  logger.info(green.wrap("Overriden commitlint.yaml"));
}
