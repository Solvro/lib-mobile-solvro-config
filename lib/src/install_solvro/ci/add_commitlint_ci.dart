import "package:mason_logger/mason_logger.dart";

import "add_ci_if_not_exist.dart";

void addCommitLintCI(Logger logger, {required bool installAppVersion}) {
  const contentForPackage = r'''
on:
  pull_request:
    branches: [ "main" ]
    types: [opened, synchronize]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - uses: dart-lang/setup-dart@v1.3

      - name: Get Dependencies
        run: dart pub get

      - name: Validate PR Commits
        run: VERBOSE=true dart run commitlint_cli --from=${{ github.event.pull_request.head.sha }}~${{ github.event.pull_request.commits }} --to=${{ github.event.pull_request.head.sha }} --config commitlint.yaml
  ''';

  const contentForApp = r'''
on:
  pull_request:
    branches: [ "main" ]
    types: [opened, synchronize]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - uses: subosito/flutter-action@v2
        with:
          channel: "stable"
          flutter-version-file: pubspec.yaml
          
      - run: flutter --version

      - name: Install dependencies
        run: flutter pub get

      - name: Validate PR Commits
        run: VERBOSE=true dart run commitlint_cli --from=${{ github.event.pull_request.head.sha }}~${{ github.event.pull_request.commits }} --to=${{ github.event.pull_request.head.sha }} --config commitlint.yaml
  ''';
  final workflowContent = installAppVersion ? contentForApp : contentForPackage;

  addCI(logger, "commit_lint_ci", workflowContent);
}
