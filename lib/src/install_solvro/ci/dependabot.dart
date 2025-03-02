import "dart:io";

import "package:mason_logger/mason_logger.dart";

import "../utils/add_if_not_exist.dart";

void addDependabot(Logger logger) {
  const template = """
version: 2
enable-beta-ecosystems: true
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "daily"
  - package-ecosystem: "pub"
    directory: "/"
    schedule:
      interval: "daily"
    """;
  final workflowFile = File(".github/dependabot.yaml");
  return addIfNotExist(logger, workflowFile, template);
}
