import "package:mason_logger/mason_logger.dart";

import "add_if_not_exist.dart";

void addCommitLintCI(Logger logger) {
  const workflowContent = r'''
on:
  pull_request:
    branches: [ "main" ]
    types: [opened, synchronize]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0

      - uses: dart-lang/setup-dart@v1.3

      - name: Get Dependencies
        run: dart pub get

      - name: Validate PR Commits
        run: VERBOSE=true dart run commitlint_cli --from=${{ github.event.pull_request.head.sha }}~${{ github.event.pull_request.commits }} --to=${{ github.event.pull_request.head.sha }} --config lib/commitlint.yaml
  ''';

  addCI(logger, "commit_lint_ci.yml", workflowContent);
}
