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

## Custom haptic wrappers

The `add_haptic_feedback_on_user_interaction` rule accepts custom haptic wrappers in `analysis_options.yaml`:

```yaml
plugins:
  solvro_config:
    version: ^1.8.0
    haptic_wrappers:
      - HapticFeedback.
      - AppHaptics.
```
