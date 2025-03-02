import "package:mason_logger/mason_logger.dart";

import "add_ci_if_not_exist.dart";

void addPRTitleCI(Logger logger, {required bool installAppVersion}) {
  const contentForPackage = r'''
name: PR Title Check
on:
  pull_request:
    branches: [ "main" ]
    types: [opened, synchronize]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dart-lang/setup-dart@v1.3

      - name: Get Dependencies
        run: dart pub get

      - name: Validate Title of PR
        run: echo ${{github.event.pull_request.title}} | dart run commitlint_cli
  ''';

  const contentForApp = r'''
name: PR Title Check
on:
  pull_request:
    branches: [ "main" ]
    types: [opened, synchronize]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: "stable"
          flutter-version-file: pubspec.yaml
          
      - run: flutter --version

      - name: Install dependencies
        run: flutter pub get

      - name: Validate Title of PR
        run: echo ${{github.event.pull_request.title}} | dart run commitlint_cli
  ''';

  final workflowContent = installAppVersion ? contentForApp : contentForPackage;

  addCI(logger, "pr_title_ci", workflowContent);
}
