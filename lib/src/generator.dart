import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:glob/glob.dart';
import 'config.dart';
import 'utils.dart';
import 'hashing.dart';
import 'validation.dart';

/// Result of asset generation process.
///
/// Contains information about the generation process including the number
/// of assets generated, whether the operation was skipped, any warnings
/// that occurred, and validation results if validation was enabled.
///
/// ## Example
///
/// ```dart
/// final result = await generateAssets(config: config);
/// print('Generated ${result.count} assets');
/// if (result.warnings.isNotEmpty) {
///   print('Warnings: ${result.warnings}');
/// }
/// ```
class GenerationResult {
  /// Number of assets that were generated.
  final int count;

  /// Whether the generation was skipped due to no changes.
  ///
  /// This is true when the generated content would be identical
  /// to the existing file, so no write operation was performed.
  final bool skipped;

  /// List of warnings that occurred during generation.
  ///
  /// Common warnings include duplicate identifiers that were automatically
  /// resolved by adding numbers to the end.
  final List<String> warnings;

  /// Validation results if validation was enabled.
  ///
  /// Contains information about assets that are missing from pubspec.yaml
  /// or unused assets in pubspec.yaml.
  final ValidationResult? validationResult;

  /// Creates a new [GenerationResult].
  ///
  /// [count] The number of assets generated.
  /// [skipped] Whether generation was skipped.
  /// [warnings] Any warnings that occurred.
  /// [validationResult] Optional validation results.
  GenerationResult(this.count, this.skipped, this.warnings,
      [this.validationResult]);
}

/// Generates asset constants from the specified configuration.
///
/// This is the main function for generating asset constants. It scans
/// the configured directories, processes the files according to the
/// configuration, and generates a Dart file with constants for all
/// discovered assets.
///
/// ## Example
///
/// ```dart
/// // Basic usage with default config
/// final result = await generateAssets();
///
/// // Custom configuration
/// final config = AssetGenConfig.defaults().copyWith(
///   output: 'lib/custom/assets.dart',
///   generateEnum: true,
/// );
/// final result = await generateAssets(config: config);
///
/// // With validation disabled
/// final result = await generateAssets(
///   config: config,
///   verbose: true,
///   dryRun: true,
/// );
/// ```
///
/// ## Parameters
///
/// [config] The configuration to use. If null, loads from `asset_gen.yaml`.
/// [configPath] Path to the configuration file. Only used if [config] is null.
/// [dryRun] If true, doesn't write the output file, just returns the result.
/// [verbose] If true, prints detailed information about the generation process.
///
/// ## Returns
///
/// A [GenerationResult] containing information about the generation process.
Future<GenerationResult> generateAssets({
  AssetGenConfig? config,
  String? configPath,
  bool dryRun = false,
  bool verbose = false,
}) async {
  final cfg = config ?? loadConfig(configPath);
  final excludeGlobs = cfg.exclude.map((e) => Glob(e)).toList();
  final warnings = <String>[];

  final entries = <_E>[];

  for (final root in cfg.roots) {
    final dir = Directory(root);
    if (!dir.existsSync()) continue;
    for (final ent in dir.listSync(recursive: true)) {
      if (ent is! File) continue;
      final rel = p.relative(ent.path, from: root).replaceAll('\\', '/');
      if (rel.endsWith('/')) continue;
      final full = '${root.replaceAll('\\', '/')}/$rel';

      if (excludeGlobs.any((g) => g.matches(full))) continue;

      if (cfg.includeExtensions != null) {
        final ext = p.extension(rel).toLowerCase();
        if (!cfg.includeExtensions!.contains(ext)) continue;
      }

      final id =
          buildIdentifier(rel, caseStyle: cfg.namingCase, prefix: cfg.prefix);

      entries.add(_E(root: root, rel: rel, id: id));
    }
  }

  // Deduplicate
  final used = <String, int>{};
  for (var i = 0; i < entries.length; i++) {
    final e = entries[i];
    if (used.containsKey(e.id)) {
      final base = e.id;
      var n = used[base]! + 2;
      var cand = '$base$n';
      while (used.containsKey(cand)) {
        n++;
        cand = '$base$n';
      }
      warnings.add('Duplicate "$base" for ${e.rel} -> $cand');
      entries[i] = e.copy(id: cand);
      used[cand] = 1;
    } else {
      used[e.id] = 1;
    }
  }

  // Sort
  if (cfg.sort == 'path') {
    entries.sort((a, b) => a.rel.compareTo(b.rel));
  } else {
    entries.sort((a, b) => a.id.compareTo(b.id));
  }

  // Validate against pubspec.yaml if enabled
  ValidationResult? validationResult;
  if (cfg.validatePubspec) {
    final assetPaths =
        entries.map((e) => '${e.root.replaceAll('\\', '/')}/${e.rel}').toList();
    validationResult = PubspecValidator.validateAssets(
      assetPaths: assetPaths,
      roots: cfg.roots,
      pubspecPath: cfg.pubspecPath,
    );

    if (verbose && !validationResult.isValid) {
      PubspecValidator.printValidationReport(validationResult);
    }
  }

  // Build content
  final b = StringBuffer();
  if (cfg.addHeader) {
    b
      ..writeln('// GENERATED CODE – DO NOT MODIFY.')
      ..writeln('// Run: dart run flutter_asset_gen');
    if (cfg.buildRunnerMode) {
      b.writeln('// Generated by build_runner');
    }
    b.writeln();
  }

  if (cfg.generateEnum) {
    _generateEnumOutput(b, cfg, entries);
  } else {
    _generateClassOutput(b, cfg, entries);
  }

  final out = File(cfg.output)..createSync(recursive: true);
  final newContent = b.toString();
  final newHash = contentHash(newContent);
  final oldContent = out.existsSync() ? out.readAsStringSync() : '';
  final oldHash = contentHash(oldContent);
  final skipped = newHash == oldHash;

  if (!dryRun && !skipped) {
    out.writeAsStringSync(newContent);
  }

  if (verbose) {
    stdout.writeln(skipped
        ? 'No changes. (${entries.length} assets)'
        : 'Generated ${entries.length} assets → ${cfg.output}');
    for (final w in warnings) {
      stdout.writeln('WARN: $w');
    }
  }

  return GenerationResult(entries.length, skipped, warnings, validationResult);
}

/// Generates class-based output with static constants.
///
/// Creates a class with static const string constants for each asset.
///
/// [b] The StringBuffer to write to.
/// [cfg] The configuration to use.
/// [entries] The asset entries to generate constants for.
void _generateClassOutput(
    StringBuffer b, AssetGenConfig cfg, List<_E> entries) {
  b
    ..writeln('class ${cfg.className} {')
    ..writeln('  const ${cfg.className}._();')
    ..writeln();

  if (cfg.groupByRoot) {
    final rootsOrder = entries.map((e) => e.root).toSet();
    for (final r in rootsOrder) {
      b.writeln('  // --- $r ---');
      for (final e in entries.where((x) => x.root == r)) {
        final path = '${r.replaceAll('\\', '/')}/${e.rel}';
        b
          ..writeln('  /// $path')
          ..writeln('  static const ${e.id} = "$path";');
      }
      b.writeln();
    }
  } else {
    for (final e in entries) {
      final path = '${e.root.replaceAll('\\', '/')}/${e.rel}';
      b
        ..writeln('  /// $path')
        ..writeln('  static const ${e.id} = "$path";');
    }
    b.writeln();
  }

  if (cfg.generateMap) {
    b.writeln('  static const Map<String,String> all = {');
    for (final e in entries) {
      b.writeln('    "${e.id}": ${e.id},');
    }
    b.writeln('  };');
  }
  b.writeln('}');
}

/// Generates enum-based output with path property.
///
/// Creates an enum with a path property for each asset.
///
/// [b] The StringBuffer to write to.
/// [cfg] The configuration to use.
/// [entries] The asset entries to generate constants for.
void _generateEnumOutput(StringBuffer b, AssetGenConfig cfg, List<_E> entries) {
  b.writeln('enum ${cfg.className} {');

  for (final e in entries) {
    final path = '${e.root.replaceAll('\\', '/')}/${e.rel}';
    b
      ..writeln('  /// $path')
      ..writeln('  ${e.id}("$path"),');
  }

  b
    ..writeln('  ;')
    ..writeln()
    ..writeln('  const ${cfg.className}(this.path);')
    ..writeln()
    ..writeln('  final String path;')
    ..writeln()
    ..writeln('  @override')
    ..writeln('  String toString() => path;')
    ..writeln()
    ..writeln('  static const Map<String, ${cfg.className}> values = {');

  for (final e in entries) {
    b.writeln('    "${e.id}": ${cfg.className}.${e.id},');
  }

  b
    ..writeln('  };')
    ..writeln('}');
}

/// Internal class representing an asset entry.
///
/// Used internally to track asset information during generation.
class _E {
  /// The root directory this asset belongs to.
  final String root;

  /// The relative path within the root directory.
  final String rel;

  /// The generated identifier for this asset.
  final String id;

  /// Creates a new asset entry.
  _E({required this.root, required this.rel, required this.id});

  /// Creates a copy of this entry with an optional new ID.
  _E copy({String? id}) => _E(root: root, rel: rel, id: id ?? this.id);
}
