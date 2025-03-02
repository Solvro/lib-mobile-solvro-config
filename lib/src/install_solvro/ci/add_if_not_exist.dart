import "dart:io";

import "package:mason_logger/mason_logger.dart";

void addCI(Logger logger, String workflowName, String workflowContent) {
  final workflowFile = File(".github/workflows/$workflowName.yml");

  if (!workflowFile.existsSync()) {
    workflowFile.createSync(recursive: true);
    workflowFile.writeAsStringSync(workflowContent);
    logger.info(
      green.wrap("Workflow $workflowName file created successfully."),
    );
  } else {
    logger.info(yellow.wrap("Workflow $workflowName file already exists."));
  }
}
