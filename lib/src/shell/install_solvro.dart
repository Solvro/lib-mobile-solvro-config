import 'package:process_run/shell.dart';

Future<void> installSolvroApp({required bool installAppVersion}) async {
  final shell = Shell();
  final yamlName = installAppVersion ? 'app' : 'package';
  await shell.run('''
      dart run husky install
      dart run husky set .husky/commit-msg 'dart run commitlint_cli --edit "\$1"'
      dart run husky set .husky/pre-commit "dart run lint_staged"
      echo "include: package:solvro_config/commitlint.yaml" > commitlint.yaml
      echo "include: package:solvro_config/$yamlName.yaml" > analysis_options.yaml
      echo "rules:" >> commitlint.yaml
      echo "  scope-enum: # define your own scopes here" >> commitlint.yaml
      echo "    - 2" >> commitlint.yaml
      echo "    - always" >> commitlint.yaml
      echo "    - - example-scope-1" >> commitlint.yaml
      echo "      - example-scope-2" >> commitlint.yaml
''');
}
