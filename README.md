# flutter_asset_gen

[![Pub](https://img.shields.io/pub/v/flutter_asset_gen.svg)](https://pub.dev/packages/flutter_asset_gen)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Fast, configurable Dart/Flutter asset constants generator with watch mode, enum output, pubspec validation, and build_runner integration.

## Features

- 🚀 **Fast Generation** - Efficient asset discovery and code generation
- 👀 **Watch Mode** - Automatically regenerate on file changes
- 📝 **Enum Output** - Generate enum-based asset constants
- ✅ **Pubspec Validation** - Validate assets against `pubspec.yaml`
- 🔧 **Build Runner** - Full build_runner integration
- 🎯 **Flexible Configuration** - Extensive customization options
- 🔍 **Smart Filtering** - Include/exclude patterns and extensions
- 📦 **Zero Dependencies** - Minimal runtime dependencies

## Quick Start

### 1. Install

```bash
dart pub add --dev flutter_asset_gen
```

### 2. Create Configuration

Create `asset_gen.yaml` in your project root:

```yaml
# Asset directories to scan
roots:
  - assets
  - images

# Output file location
output: lib/generated/assets.dart

# Generated class name
class_name: Assets

# Generate enum instead of class
generate_enum: false

# Watch mode (for CLI)
watch_mode: false

# Validate against pubspec.yaml
validate_pubspec: true

# Build runner mode
build_runner_mode: false

# File extensions to include (null = all)
include_extensions:
  - .png
  - .jpg
  - .jpeg
  - .gif
  - .svg

# Patterns to exclude
exclude:
  - "**/*.tmp"
  - "**/.*"

# Naming case style
case: camel  # camel, snake, kebab

# Sort order
sort: identifier  # identifier, path

# Group by root directory
group_by_root: true

# Add header comment
add_header: true

# Generate map of all assets
generate_map: true

# Prefix for identifiers
prefix: ""
```

### 3. Generate Assets

#### CLI Usage

```bash
# Basic generation
dart run flutter_asset_gen

# Watch mode
dart run flutter_asset_gen --watch

# Verbose output
dart run flutter_asset_gen --verbose

# Skip validation
dart run flutter_asset_gen --no-validate

# Custom config file
dart run flutter_asset_gen --config=custom_config.yaml

# Dry run (no file writing)
dart run flutter_asset_gen --dry-run
```

#### Build Runner Integration

Add to your `pubspec.yaml`:

```yaml
dev_dependencies:
  build_runner: ^2.4.0
  flutter_asset_gen: ^0.1.0
```

Create `build.yaml`:

```yaml
targets:
  $default:
    builders:
      flutter_asset_gen|assetGenBuilder:
        enabled: true
        options:
          output: lib/generated/assets.dart
          class_name: Assets
          generate_enum: false
```

Run build_runner:

```bash
dart run build_runner build
```

## Usage Examples

### Class Output (Default)

```dart
// Generated file: lib/generated/assets.dart
class Assets {
  const Assets._();

  // --- assets ---
  /// assets/images/logo.png
  static const logoPng = "assets/images/logo.png";
  
  /// assets/images/icon.svg
  static const iconSvg = "assets/images/icon.svg";

  static const Map<String,String> all = {
    "logoPng": logoPng,
    "iconSvg": iconSvg,
  };
}
```

### Enum Output

```dart
// Generated file: lib/generated/assets.dart
enum Assets {
  /// assets/images/logo.png
  logoPng("assets/images/logo.png"),
  
  /// assets/images/icon.svg
  iconSvg("assets/images/icon.svg"),
  ;

  const Assets(this.path);

  final String path;

  @override
  String toString() => path;

  static const Map<String, Assets> values = {
    "logoPng": Assets.logoPng,
    "iconSvg": Assets.iconSvg,
  };
}
```

### Using Generated Assets

```dart
import 'package:flutter/material.dart';
import 'generated/assets.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Class-based usage
        Image.asset(Assets.logoPng),
        
        // Enum-based usage
        Image.asset(Assets.logoPng.path),
        
        // Map-based usage
        Image.asset(Assets.all['logoPng']!),
      ],
    );
  }
}
```

## Configuration Options

### Basic Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `roots` | `List<String>` | `['assets']` | Directories to scan for assets |
| `output` | `String` | `'lib/generated/assets.dart'` | Output file path |
| `class_name` | `String` | `'Assets'` | Generated class/enum name |

### Output Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `generate_enum` | `bool` | `false` | Generate enum instead of class |
| `add_header` | `bool` | `true` | Add header comment |
| `generate_map` | `bool` | `true` | Generate map of all assets |

### Filtering Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `include_extensions` | `List<String>?` | `null` | File extensions to include |
| `exclude` | `List<String>` | `[]` | Patterns to exclude |
| `prefix` | `String` | `''` | Prefix for identifiers |

### Organization Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `group_by_root` | `bool` | `true` | Group assets by root directory |
| `sort` | `String` | `'identifier'` | Sort order (`identifier` or `path`) |
| `case` | `String` | `'camel'` | Naming case (`camel`, `snake`, `kebab`) |

### Advanced Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `watch_mode` | `bool` | `false` | Enable watch mode |
| `validate_pubspec` | `bool` | `true` | Validate against pubspec.yaml |
| `build_runner_mode` | `bool` | `false` | Build runner integration |
| `pubspec_path` | `String?` | `null` | Custom pubspec.yaml path |

## Validation

The library can validate your assets against `pubspec.yaml`:

```bash
dart run flutter_asset_gen --verbose
```

This will:
- Check if all generated assets are declared in `pubspec.yaml`
- Report missing assets that need to be added
- Report unused assets in `pubspec.yaml`

Example output:
```
❌ Missing assets in pubspec.yaml:
  - assets/images/new_logo.png
  - assets/icons/icon.svg

Add these to your pubspec.yaml:
flutter:
  assets:
    - assets/images/new_logo.png
    - assets/icons/icon.svg
```

## Watch Mode

Enable watch mode to automatically regenerate assets when files change:

```bash
dart run flutter_asset_gen --watch
```

Features:
- Debounced file watching (300ms)
- Recursive directory monitoring
- Smart filtering (excludes temp files, hidden files)
- Graceful shutdown with Ctrl+C

## Build Runner Integration

For seamless integration with your build process:

1. **Add dependencies:**
```yaml
dev_dependencies:
  build_runner: ^2.4.0
  flutter_asset_gen: ^0.1.0
```

2. **Create build.yaml:**
```yaml
targets:
  $default:
    builders:
      flutter_asset_gen|assetGenBuilder:
        enabled: true
        options:
          output: lib/generated/assets.dart
          class_name: Assets
          generate_enum: false
```

3. **Run build_runner:**
```bash
dart run build_runner build
dart run build_runner watch
```

## CLI Reference

### Commands

```bash
dart run flutter_asset_gen [options]
```

### Options

| Option | Description |
|--------|-------------|
| `--config=FILE` | Use custom config file |
| `--verbose` | Verbose output |
| `--dry-run` | Do not write file |
| `--watch` | Watch mode - regenerate on file changes |
| `--no-validate` | Skip pubspec.yaml validation |
| `--help, -h` | Show help |

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
