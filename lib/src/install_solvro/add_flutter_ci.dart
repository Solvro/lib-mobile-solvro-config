import "dart:io";

import "package:mason_logger/mason_logger.dart";

void addFlutterCI(Logger logger) {
  const workflowContent = '''
name: Lint & formatting

on:
  push:
    branches:
      - main
  pull_request:
    branches: [ "**" ]

jobs:
  build:
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
        
      - name: Remove lib/l10n directory
        run: rm -rf lib/l10n/*.dart

      - name: Verify formatting
        run: dart format --output=none --set-exit-if-changed .
      
      - name: Regenerate the localization files
        run: flutter gen-l10n

      - name: Example .env
        run: cp example.env .env

      - name: generate files
        run: dart run build_runner build --delete-conflicting-outputs

      - name: Analyze project source
        run: flutter analyze --fatal-infos

      - name: Run custom lints
        run: dart run custom_lint --fatal-infos

      - name: Flutter tests
        run: flutter test
  ''';

  final workflowFile = File(".github/workflows/flutter_ci.yml");

  if (!workflowFile.existsSync()) {
    workflowFile.createSync(recursive: true);
    workflowFile.writeAsStringSync(workflowContent);
    logger.info(green.wrap("Workflow file created successfully."));
  } else {
    logger.info(yellow.wrap("Workflow file already exists."));
  }
}
