import "package:args/command_runner.dart";
import "package:mason_logger/mason_logger.dart";

import "../install_solvro/install_solvro.dart";

class InstallSolvroCommand extends Command<int> {
  InstallSolvroCommand({required this.logger}) {
    argParser.addFlag(
      "package",
      abbr: "p",
      help: "Install the same, but not for an app, but for a package.",
      negatable: false,
    );
  }

  @override
  String get description => "Install a Solvro config package in your project.";

  @override
  String get name => "install";

  final Logger logger;

  @override
  Future<int> run() async {
    logger.info(lightCyan.wrap("Installing Solvro config..."));
    try {
      if (argResults?["package"] == true) {
        logger.info(
          yellow.wrap("Requested package version installation (not an app)..."),
        );
        await installSolvroApp(logger, installAppVersion: false);
      } else {
        logger.info(lightCyan.wrap("Requested app version installation..."));
        await installSolvroApp(logger, installAppVersion: true);
      }

      logger.info(
        lightGreen.wrap("Solvro config installed successfully 🎉🚀✨"),
      );

      return ExitCode.success.code;
    } on Exception catch (e) {
      logger.err(e.toString());
      return ExitCode.software.code;
    }
  }
}
