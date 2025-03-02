import "dart:io";

import "package:mason_logger/mason_logger.dart";

import "../utils/add_if_not_exist.dart";

void addCI(Logger logger, String workflowName, String workflowContent) {
  final workflowFile = File(".github/workflows/$workflowName.yaml");
  return addIfNotExist(logger, workflowFile, workflowContent);
}
