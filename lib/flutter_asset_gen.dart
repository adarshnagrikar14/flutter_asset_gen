/// Fast, configurable Dart/Flutter asset constants generator.
///
/// This library provides tools to automatically generate strongly-typed
/// constants for your Flutter assets, with support for watch mode,
/// enum output, pubspec validation, and build_runner integration.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:flutter_asset_gen/flutter_asset_gen.dart';
///
/// // Load configuration and generate assets
/// final config = loadConfig();
/// final result = await generateAssets(config: config);
/// ```
///
/// ## Features
///
/// - **Watch Mode**: Automatically regenerate on file changes
/// - **Enum Output**: Generate enum-based asset constants
/// - **Pubspec Validation**: Validate against pubspec.yaml
/// - **Build Runner**: Full build_runner integration
/// - **Flexible Configuration**: Extensive customization options
library flutter_asset_gen;

export 'src/config.dart' show AssetGenConfig, loadConfig;
export 'src/generator.dart' show generateAssets, GenerationResult;
export 'src/validation.dart' show ValidationResult, PubspecValidator;
export 'src/watcher.dart' show AssetWatcher;
export 'src/build_runner_builder.dart' show AssetGenBuilder, assetGenBuilder;
