import "dart:io";

import "package:mason_logger/mason_logger.dart";

import "../utils/add_if_not_exist.dart";

void addCSpell(Logger logger) {
  const template = r"""
{
  "version": "0.2",
  "$schema": "https://raw.githubusercontent.com/streetsidesoftware/cspell/main/cspell.schema.json",
  "dictionaries": ["vgv_allowed", "vgv_forbidden"],
  "dictionaryDefinitions": [
    {
      "name": "vgv_allowed",
      "path": "https://raw.githubusercontent.com/verygoodopensource/very_good_dictionaries/main/allowed.txt",
      "description": "Allowed VGV Spellings"
    },
    {
      "name": "vgv_forbidden",
      "path": "https://raw.githubusercontent.com/verygoodopensource/very_good_dictionaries/main/forbidden.txt",
      "description": "Forbidden VGV Spellings"
    }
  ],
  "useGitignore": true,
  "words": ["solvro", "Solvro", "KN Solvro", "Koło Naukowe Solvro", "riverpod"]
}
""";
  addIfNotExist(logger, File(".github/cspell.json"), template);
}
