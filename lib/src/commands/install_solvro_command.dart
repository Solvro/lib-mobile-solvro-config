import "package:args/command_runner.dart";
import "package:mason_logger/mason_logger.dart";
import "../shell/install_solvro.dart";

class InstallSolvroCommand extends Command<int> {
  InstallSolvroCommand({required Logger logger}) : _logger = logger {
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

  final Logger _logger;

  @override
  Future<int> run() async {
    _logger.info(lightCyan.wrap("Installing Solvro config..."));
    try {
      if (argResults?["package"] == true) {
        _logger.info(
          yellow.wrap("Requested package version installation (not an app)..."),
        );
        await installSolvroApp(_logger, installAppVersion: false);
      } else {
        _logger.info(lightCyan.wrap("Requested app version installation..."));
        await installSolvroApp(_logger, installAppVersion: true);
      }

      _logger.info(
        lightGreen.wrap("Solvro config installed successfully 🎉🚀✨"),
      );

      return ExitCode.success.code;
    } on Exception catch (e) {
      _logger.err(e.toString());
      return ExitCode.software.code;
    }
  }
}
