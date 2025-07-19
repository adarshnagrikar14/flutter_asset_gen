import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as p;

/// Result of asset validation against pubspec.yaml.
///
/// Contains information about the validation process including whether
/// all assets are properly declared, any missing or unused assets,
/// and any warnings that occurred during validation.
///
/// ## Example
///
/// ```dart
/// final result = PubspecValidator.validateAssets(
///   assetPaths: ['assets/logo.png', 'assets/icon.svg'],
///   roots: ['assets'],
/// );
///
/// if (!result.isValid) {
///   print('Missing assets: ${result.missingAssets}');
/// }
/// ```
class ValidationResult {
  /// Whether all assets are properly declared in pubspec.yaml.
  ///
  /// This is true when all generated assets are found in the
  /// `flutter.assets` section of pubspec.yaml.
  final bool isValid;

  /// List of assets that are missing from pubspec.yaml.
  ///
  /// These are assets that were found in the asset directories
  /// but are not declared in the `flutter.assets` section.
  final List<String> missingAssets;

  /// List of assets declared in pubspec.yaml but not found.
  ///
  /// These are assets that are declared in the `flutter.assets`
  /// section but don't exist in the asset directories.
  final List<String> unusedAssets;

  /// List of warnings that occurred during validation.
  ///
  /// Common warnings include parsing errors or missing pubspec.yaml file.
  final List<String> warnings;

  /// Creates a new [ValidationResult].
  ///
  /// [isValid] Whether validation passed.
  /// [missingAssets] Assets missing from pubspec.yaml.
  /// [unusedAssets] Assets in pubspec.yaml but not found.
  /// [warnings] Any warnings that occurred.
  ValidationResult({
    required this.isValid,
    required this.missingAssets,
    required this.unusedAssets,
    required this.warnings,
  });
}

/// Validates assets against pubspec.yaml configuration.
///
/// This class provides static methods to validate that generated assets
/// are properly declared in the `flutter.assets` section of pubspec.yaml
/// and to identify any discrepancies.
///
/// ## Example
///
/// ```dart
/// final result = PubspecValidator.validateAssets(
///   assetPaths: ['assets/logo.png', 'assets/icon.svg'],
///   roots: ['assets'],
/// );
///
/// if (!result.isValid) {
///   PubspecValidator.printValidationReport(result);
/// }
/// ```
class PubspecValidator {
  /// Validates asset paths against pubspec.yaml.
  ///
  /// Checks that all provided asset paths are properly declared in the
  /// `flutter.assets` section of pubspec.yaml and identifies any missing
  /// or unused assets.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final result = PubspecValidator.validateAssets(
  ///   assetPaths: ['assets/logo.png', 'assets/icon.svg'],
  ///   roots: ['assets'],
  ///   pubspecPath: 'custom_pubspec.yaml',
  /// );
  ///
  /// if (!result.isValid) {
  ///   print('Validation failed: ${result.missingAssets.length} missing assets');
  /// }
  /// ```
  ///
  /// ## Parameters
  ///
  /// [assetPaths] List of asset paths to validate.
  /// [roots] List of root directories that were scanned.
  /// [pubspecPath] Optional custom path to pubspec.yaml file.
  ///
  /// ## Returns
  ///
  /// A [ValidationResult] containing validation information.
  static ValidationResult validateAssets({
    required List<String> assetPaths,
    required List<String> roots,
    String? pubspecPath,
  }) {
    final pubspecFile = File(pubspecPath ?? 'pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      return ValidationResult(
        isValid: false,
        missingAssets: [],
        unusedAssets: [],
        warnings: ['pubspec.yaml not found'],
      );
    }

    try {
      final doc = loadYaml(pubspecFile.readAsStringSync()) as YamlMap;
      final flutterSection = doc['flutter'] as YamlMap?;
      final declaredAssets = <String>{};

      if (flutterSection != null) {
        final assets = flutterSection['assets'] as YamlList?;
        if (assets != null) {
          for (final asset in assets) {
            final assetStr = asset.toString();
            if (assetStr.endsWith('/')) {
              // Directory pattern - add all files in that directory
              final dir = Directory(assetStr);
              if (dir.existsSync()) {
                for (final file in dir.listSync(recursive: true)) {
                  if (file is File) {
                    final relPath = p.relative(file.path, from: '.');
                    declaredAssets.add(relPath.replaceAll('\\', '/'));
                  }
                }
              }
            } else {
              declaredAssets.add(assetStr);
            }
          }
        }
      }

      final missingAssets = <String>[];
      final unusedAssets = <String>[];
      final warnings = <String>[];

      // Check for missing assets in pubspec.yaml
      for (final assetPath in assetPaths) {
        final normalizedPath = assetPath.replaceAll('\\', '/');
        if (!declaredAssets.contains(normalizedPath)) {
          missingAssets.add(normalizedPath);
        }
      }

      // Check for unused assets in pubspec.yaml
      for (final declaredAsset in declaredAssets) {
        final normalizedDeclared = declaredAsset.replaceAll('\\', '/');
        bool found = false;
        for (final assetPath in assetPaths) {
          final normalizedPath = assetPath.replaceAll('\\', '/');
          if (normalizedPath == normalizedDeclared) {
            found = true;
            break;
          }
        }
        if (!found) {
          unusedAssets.add(normalizedDeclared);
        }
      }

      return ValidationResult(
        isValid: missingAssets.isEmpty,
        missingAssets: missingAssets,
        unusedAssets: unusedAssets,
        warnings: warnings,
      );
    } catch (e) {
      return ValidationResult(
        isValid: false,
        missingAssets: [],
        unusedAssets: [],
        warnings: ['Error parsing pubspec.yaml: $e'],
      );
    }
  }

  /// Prints a formatted validation report to the console.
  ///
  /// Displays a user-friendly report of validation results including
  /// missing assets, unused assets, and suggestions for fixing issues.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final result = PubspecValidator.validateAssets(
  ///   assetPaths: ['assets/logo.png'],
  ///   roots: ['assets'],
  /// );
  ///
  /// PubspecValidator.printValidationReport(result);
  /// ```
  ///
  /// ## Output Example
  ///
  /// ```
  /// ❌ Missing assets in pubspec.yaml:
  ///   - assets/logo.png
  ///
  /// Add these to your pubspec.yaml:
  /// flutter:
  ///   assets:
  ///     - assets/logo.png
  /// ```
  ///
  /// [result] The validation result to report.
  static void printValidationReport(ValidationResult result) {
    if (result.isValid && result.unusedAssets.isEmpty) {
      print('✅ All assets are properly declared in pubspec.yaml');
      return;
    }

    if (!result.isValid) {
      print('❌ Missing assets in pubspec.yaml:');
      for (final asset in result.missingAssets) {
        print('  - $asset');
      }
      print('\nAdd these to your pubspec.yaml:');
      print('flutter:');
      print('  assets:');
      for (final asset in result.missingAssets) {
        print('    - $asset');
      }
    }

    if (result.unusedAssets.isNotEmpty) {
      print('\n⚠️  Unused assets in pubspec.yaml:');
      for (final asset in result.unusedAssets) {
        print('  - $asset');
      }
    }

    for (final warning in result.warnings) {
      print('⚠️  $warning');
    }
  }
}
