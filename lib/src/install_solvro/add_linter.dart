import "dart:io";

import "package:mason_logger/mason_logger.dart";

import "utils/add_if_not_exist.dart";

void addLinter(String yamlName, Logger logger) {
  final template = "include: package:solvro_config/$yamlName.yaml";
  final file = File("analysis_options.yaml");
  addIfNotExist(logger, file, template);
}
