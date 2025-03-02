import "dart:io";

import "package:mason_logger/mason_logger.dart";

void addIfNotExist(Logger logger, File file, String content) {
  if (!file.existsSync()) {
    file.createSync(recursive: true);
    file.writeAsStringSync(content);
    logger.info(green.wrap("Workflow ${file.path} file created successfully."));
  } else {
    if (file.readAsStringSync() != content) {
      logger.warn(
        "Workflow ${file.path} file already exists and was changed. See if the changes are necessary.",
      );
    } else {
      logger.info(
        lightBlue.wrap(
          "Workflow ${file.path} file already exists and is up to date with the content.",
        ),
      );
    }
  }
}
