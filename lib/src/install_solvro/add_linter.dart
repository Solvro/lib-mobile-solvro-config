import "dart:io";

import "package:mason_logger/mason_logger.dart";

Future<void> addLinter(String yamlName, Logger logger) async {
  await File(
    "analysis_options.yaml",
  ).writeAsString("include: package:solvro_config/$yamlName.yaml");
  logger.info(green.wrap("Overriden analysis_options.yaml"));
}
