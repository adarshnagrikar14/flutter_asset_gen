# flutter_asset_gen

[![pub version](https://img.shields.io/pub/v/flutter_asset_gen.svg)](https://pub.dev/packages/flutter_asset_gen)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Dart SDK](https://img.shields.io/badge/sdk-%3E%3D3.2.0-blue.svg)](https://dart.dev)

Fast, configurable, and **idempotent** asset constants generator for Dart/Flutter projects. Generate strongly-typed constants from your `assets/` folders with zero boilerplate.

## ✨ Features

- **📁 Multiple asset roots** - Support for `assets/images`, `assets/icons`, `assets/audio`, etc.
- **⚙️ YAML configuration** - Flexible config with `asset_gen.yaml`
- **🔍 Smart filtering** - Glob patterns, extensions, and exclusions
- **🎯 Case styles** - `camel`, `snake`, or `keep` naming conventions
- **🔄 Idempotent** - Only regenerates when files actually change
- **🚫 Collision handling** - Automatic deduplication with warnings
- **📦 Pure Dart** - No build_runner or Flutter plugin required
- **🗺️ Optional map export** - Generate `Map<String,String>` of all assets
- **📊 Grouping** - Organize constants by asset root

## 🚀 Quick Start

### 1. Install

Add as a dev dependency:

```yaml
dev_dependencies:
  flutter_asset_gen: ^0.1.0
```

### 2. Configure

Create `asset_gen.yaml` in your project root:

```yaml
roots:
  - assets/images
  - assets/icons
  - assets/audio

output: lib/core/constants/assets.dart
class_name: Assets

exclude:
  - "**/.*"
  - "**/*.DS_Store"

case: camel
group_by_root: true
generate_map: true
```

### 3. Run

```bash
dart run flutter_asset_gen
```

### 4. Use

```dart
import 'package:your_app/core/constants/assets.dart';

// Use in widgets
Image.asset(Assets.appLogo);
SvgPicture.asset(Assets.playIcon);

// Iterate all assets
Assets.all.forEach((name, path) {
  print('$name: $path');
});
```

## 📋 Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `roots` | `List<String>` | Required | Asset directories to scan |
| `output` | `String` | Required | Output file path |
| `class_name` | `String` | `Assets` | Generated class name |
| `exclude` | `List<String>` | `[]` | Glob patterns to exclude |
| `include_extensions` | `List<String>` | All | File extensions to include |
| `case` | `String` | `camel` | `camel`, `snake`, or `keep` |
| `prefix` | `String` | `""` | Prefix for all identifiers |
| `sort` | `String` | `identifier` | `identifier` or `path` |
| `group_by_root` | `bool` | `true` | Group constants by root |
| `generate_map` | `bool` | `true` | Generate `all` map |
| `add_header` | `bool` | `true` | Add generation header |

## 🧬 Generated Output

```dart
// GENERATED CODE - DO NOT MODIFY
// Run: dart run flutter_asset_gen

class Assets {
  const Assets._();

  // --- assets/images ---
  /// assets/images/logo/app_icon.png
  static const appIcon = "assets/images/logo/app_icon.png";
  
  /// assets/images/background/hero.jpg
  static const heroBackground = "assets/images/background/hero.jpg";

  // --- assets/icons ---
  /// assets/icons/play.svg
  static const play = "assets/icons/play.svg";
  
  /// assets/icons/pause.svg
  static const pause = "assets/icons/pause.svg";

  static const Map<String, String> all = {
    "appIcon": appIcon,
    "heroBackground": heroBackground,
    "play": play,
    "pause": pause,
  };
}
```

## 🛠️ CLI Usage

```bash
# Basic usage
dart run flutter_asset_gen

# Verbose output
dart run flutter_asset_gen --verbose

# Dry run (no file writing)
dart run flutter_asset_gen --dry-run

# Custom config file
dart run flutter_asset_gen --config=config/asset_gen.yaml

# Help
dart run flutter_asset_gen --help
```

## 🔧 Advanced Configuration

### Multiple Asset Roots

```yaml
roots:
  - assets/images
  - assets/icons
  - assets/audio
  - assets/fonts
  - assets/raw
```

### File Type Filtering

```yaml
include_extensions:
  - .png
  - .jpg
  - .jpeg
  - .svg
  - .mp3
  - .wav
```

### Custom Exclusions

```yaml
exclude:
  - "**/.*"                    # Hidden files
  - "**/*.DS_Store"           # macOS files
  - "**/temp/**"              # Temp folders
  - "**/*_draft.*"            # Draft files
  - "assets/images/old/**"    # Specific folders
```

### Naming Conventions

```yaml
# camelCase (default)
case: camel
# Result: appIcon, playButton, heroBackground

# snake_case
case: snake
# Result: app_icon, play_button, hero_background

# keep original
case: keep
# Result: app_icon, play_button, hero_background

# With prefix
case: camel
prefix: asset
# Result: assetAppIcon, assetPlayButton
```

## 🚦 Workflow Integration

### Git Hooks

Add to your pre-commit hook:

```bash
#!/bin/bash
dart run flutter_asset_gen
git add lib/core/constants/assets.dart
```

### CI/CD

```yaml
# GitHub Actions example
- name: Generate assets
  run: dart run flutter_asset_gen

- name: Check for changes
  run: |
    git diff --exit-code lib/core/constants/assets.dart || \
    (echo "Asset constants need regeneration. Run 'dart run flutter_asset_gen'" && exit 1)
```

## 🧪 Development

```bash
# Run tests
dart test

# Format code
dart format .

# Analyze code
dart analyze
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests (`dart test`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⭐ Support

If this package helps you, please give it a star! ⭐

---

**Made with ❤️ for the Flutter community**
