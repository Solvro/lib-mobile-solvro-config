import "package:mason_logger/mason_logger.dart";

import "add_ci_if_not_exist.dart";

void addPRTitleCI(Logger logger) {
  const workflowContent = r'''
name: PR Title Check
on:
  pull_request:
    branches: [ "main" ]
    types: [opened, synchronize]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: dart-lang/setup-dart@v1.3

      - name: Get Dependencies
        run: dart pub get

      - name: Validate Title of PR
        run: echo ${{github.event.pull_request.title}} | dart run commitlint_cli
  ''';

  addCI(logger, "pr_title_ci", workflowContent);
}
