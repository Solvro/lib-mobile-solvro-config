import "dart:io";

import "package:script_runner/script_runner.dart";

void main() async {
  print('Is this a package or an app? (Enter "package" or "app")');
  final String? input = stdin.readLineSync()?.trim().toLowerCase();

  if (input == "package") {
    await runScript("install-solvro-package", []);
  } else if (input == "app") {
    await runScript("install-solvro", []);
  } else {
    print('Invalid input. Please enter "package" or "app".');
  }
}
