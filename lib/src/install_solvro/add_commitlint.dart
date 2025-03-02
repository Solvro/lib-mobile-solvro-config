import "dart:io";

import "package:mason_logger/mason_logger.dart";

import "utils/add_if_not_exist.dart";

void addCommitLint(Logger logger) {
  const template = """
include: package:solvro_config/commitlint.yaml
rules:
  scope-enum: # define your own scopes here
    - 2
    - always
    - - example-scope-1
      - example-scope-2
""";
  addIfNotExist(logger, File("commitlint.yaml"), template);
}
