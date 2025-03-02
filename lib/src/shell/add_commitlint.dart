import "dart:io";

import "package:mason_logger/mason_logger.dart";

Future<void> addCommitLint(Logger logger) async {
  final commitlintFile = File("commitlint.yaml");
  if (commitlintFile.existsSync()) {
    final content = await commitlintFile.readAsString();
    if (content.contains("include: package:solvro_config/commitlint.yaml")) {
      logger.warn("commitlint.yaml already includes commitlint.yaml");
      return;
    }
  }
  await commitlintFile.writeAsString("""
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
