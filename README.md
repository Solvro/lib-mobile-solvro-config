# Solvro Dart Config

---

## Getting Started 🚀 - Installation

```sh
dart pub add dev:solvro_config
dart run solvro_config install
```

## Usage

```sh
# Install config for an app
$ solvro_config install

# Install config for a package
$ solvro_config install --package

# Show CLI version
$ solvro_config --version

# Show usage help
$ solvro_config --help
```

## Haptic feedback

The `add_haptic_feedback_on_user_interaction` rule accepts custom haptic wrappers in `analysis_options.yaml`:

```yaml
plugins:
  solvro_config:
    version: ^1.8.0
    haptic_wrappers:
      - HapticFeedback.
      - AppHaptics.
```

Reusable widgets that trigger haptics internally can be listed as haptic-owning widgets. Callback arguments passed to these widgets will not be reported by the rule, so callers can keep callbacks business-only:

```yaml
plugins:
  solvro_config:
    version: ^1.8.0
    haptic_owning_widgets:
      - MySplashTile
      - WideTileCard
```
