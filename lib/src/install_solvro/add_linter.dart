import "dart:io";

import "package:mason_logger/mason_logger.dart";

import "utils/add_if_not_exist.dart";

void addLinter(String yamlName, Logger logger) {
  final template =
      """
include: package:solvro_config/$yamlName.yaml

plugins:
  riverpod_lint:
    version: ^3.1.3
    diagnostics:
      provider_dependencies: false # this works weirdly
${yamlName == "app" ? _solvroCustomLinterPlugin : ""}""";
  final file = File("analysis_options.yaml");
  addIfNotExist(logger, file, template);
}

const _solvroCustomLinterPlugin = """
  solvro_config:
    version: ^1.7.0
    diagnostics:
      provider_dependencies: false # this works weirdly
""";
