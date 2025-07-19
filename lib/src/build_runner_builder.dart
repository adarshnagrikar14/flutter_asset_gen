import 'config.dart';
import 'generator.dart';
import 'package:build/build.dart';

/// Build runner builder for asset generation.
///
/// This class provides integration with the build_runner system, allowing
/// asset generation to be part of the automated build process. It watches
/// for changes to `asset_gen.yaml` and generates the corresponding asset
/// constants file.
///
/// ## Usage
///
/// Add to your `build.yaml`:
///
/// ```yaml
/// targets:
///   $default:
///     builders:
///       flutter_asset_gen|assetGenBuilder:
///         enabled: true
///         options:
///           output: lib/generated/assets.dart
///           class_name: Assets
/// ```
///
/// Then run:
///
/// ```bash
/// dart run build_runner build
/// ```
class AssetGenBuilder extends Builder {
  /// Creates a new [AssetGenBuilder].
  AssetGenBuilder();

  @override

  /// Defines the build extensions for this builder.
  ///
  /// Maps `asset_gen.yaml` input files to generated Dart output files.
  Map<String, List<String>> get buildExtensions => {
        'asset_gen.yaml': ['lib/generated/assets.dart'],
      };

  @override

  /// Performs the asset generation build step.
  ///
  /// This method is called by build_runner when it detects changes to
  /// `asset_gen.yaml` files. It reads the configuration, generates
  /// the asset constants, and writes the output file.
  ///
  /// [buildStep] The build step context provided by build_runner.
  Future<void> build(BuildStep buildStep) async {
    final configFile = AssetId('', 'asset_gen.yaml');

    if (!await buildStep.canRead(configFile)) {
      return;
    }

    final configContent = await buildStep.readAsString(configFile);
    var config = _parseConfigFromString(configContent);

    // Set build runner mode
    config = config.copyWith(buildRunnerMode: true);

    final result = await generateAssets(
      config: config,
      verbose: false,
    );

    if (!result.skipped) {
      final outputId = AssetId('', config.output);
      await buildStep.writeAsString(outputId, _generateContent(config, result));
    }
  }

  /// Parses configuration from a YAML string.
  ///
  /// This is a simplified YAML parser for the build_runner context.
  /// It extracts key configuration options from the YAML content.
  ///
  /// ## Supported Options
  ///
  /// - `output`: Output file path
  /// - `class_name`: Generated class/enum name
  /// - `generate_enum`: Whether to generate enum output
  /// - `roots`: Asset directories to scan
  /// - `exclude`: Patterns to exclude
  /// - `include_extensions`: File extensions to include
  /// - `case`: Naming case style
  /// - `sort`: Sort order
  /// - `group_by_root`: Whether to group by root
  /// - `add_header`: Whether to add header
  /// - `generate_map`: Whether to generate map
  /// - `prefix`: Prefix for identifiers
  /// - `validate_pubspec`: Whether to validate against pubspec.yaml
  ///
  /// [content] The YAML configuration content as a string.
  ///
  /// Returns an [AssetGenConfig] with the parsed options.
  AssetGenConfig _parseConfigFromString(String content) {
    final lines = content.split('\n');
    var config = AssetGenConfig.defaults();

    List<String>? roots;
    List<String>? exclude;
    List<String>? includeExtensions;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      if (trimmed.startsWith('roots:')) {
        roots = _parseStringList(lines, i);
        continue;
      }

      if (trimmed.startsWith('exclude:')) {
        exclude = _parseStringList(lines, i);
        continue;
      }

      if (trimmed.startsWith('include_extensions:')) {
        includeExtensions = _parseStringList(lines, i);
        continue;
      }

      if (trimmed.startsWith('output:')) {
        final output = trimmed.substring('output:'.length).trim();
        config = config.copyWith(output: output);
        continue;
      }

      if (trimmed.startsWith('class_name:')) {
        final className = trimmed.substring('class_name:'.length).trim();
        config = config.copyWith(className: className);
        continue;
      }

      if (trimmed.startsWith('generate_enum:')) {
        final value = trimmed.substring('generate_enum:'.length).trim();
        config = config.copyWith(generateEnum: value == 'true');
        continue;
      }

      if (trimmed.startsWith('case:')) {
        final caseStyle = trimmed.substring('case:'.length).trim();
        config = config.copyWith(namingCase: caseStyle);
        continue;
      }

      if (trimmed.startsWith('sort:')) {
        final sort = trimmed.substring('sort:'.length).trim();
        config = config.copyWith(sort: sort);
        continue;
      }

      if (trimmed.startsWith('group_by_root:')) {
        final value = trimmed.substring('group_by_root:'.length).trim();
        config = config.copyWith(groupByRoot: value == 'true');
        continue;
      }

      if (trimmed.startsWith('add_header:')) {
        final value = trimmed.substring('add_header:'.length).trim();
        config = config.copyWith(addHeader: value == 'true');
        continue;
      }

      if (trimmed.startsWith('generate_map:')) {
        final value = trimmed.substring('generate_map:'.length).trim();
        config = config.copyWith(generateMap: value == 'true');
        continue;
      }

      if (trimmed.startsWith('prefix:')) {
        final prefix = trimmed.substring('prefix:'.length).trim();
        config = config.copyWith(prefix: prefix);
        continue;
      }

      if (trimmed.startsWith('validate_pubspec:')) {
        final value = trimmed.substring('validate_pubspec:'.length).trim();
        config = config.copyWith(validatePubspec: value == 'true');
        continue;
      }
    }

    // Apply parsed lists
    if (roots != null) {
      config = config.copyWith(roots: roots);
    }
    if (exclude != null) {
      config = config.copyWith(exclude: exclude);
    }
    if (includeExtensions != null) {
      config = config.copyWith(includeExtensions: includeExtensions);
    }

    return config;
  }

  /// Parses a YAML list from the given line index.
  ///
  /// Reads subsequent lines to extract a list of strings from YAML format.
  /// Handles both inline lists and multi-line lists.
  ///
  /// [lines] All lines of the YAML content.
  /// [startIndex] The index of the line containing the list key.
  ///
  /// Returns a list of strings, or null if parsing fails.
  List<String>? _parseStringList(List<String> lines, int startIndex) {
    final result = <String>[];
    final startLine = lines[startIndex].trim();

    // Check if it's an inline list: key: [value1, value2]
    if (startLine.contains('[') && startLine.contains(']')) {
      final listStart = startLine.indexOf('[');
      final listEnd = startLine.indexOf(']');
      if (listStart != -1 && listEnd != -1) {
        final listContent = startLine.substring(listStart + 1, listEnd);
        return listContent
            .split(',')
            .map((s) => s.trim().replaceAll('"', '').replaceAll("'", ''))
            .where((s) => s.isNotEmpty)
            .toList();
      }
    }

    // Check if it's a multi-line list
    if (startLine.endsWith(':')) {
      for (int i = startIndex + 1; i < lines.length; i++) {
        final line = lines[i];
        final trimmed = line.trim();

        // Stop if we hit another key (no indentation)
        if (trimmed.isNotEmpty &&
            !line.startsWith(' ') &&
            !line.startsWith('\t')) {
          break;
        }

        // Skip empty lines
        if (trimmed.isEmpty) continue;

        // Parse list item: - value
        if (trimmed.startsWith('-')) {
          final value = trimmed
              .substring(1)
              .trim()
              .replaceAll('"', '')
              .replaceAll("'", '');
          if (value.isNotEmpty) {
            result.add(value);
          }
        }
      }
    }

    return result.isNotEmpty ? result : null;
  }

  /// Generates the content for the output file.
  ///
  /// This method creates the actual Dart code that will be written
  /// to the output file. It uses the configuration and generation
  /// result to produce the appropriate content.
  ///
  /// [config] The configuration used for generation.
  /// [result] The result of the asset generation process.
  ///
  /// Returns the generated Dart code as a string.
  String _generateContent(AssetGenConfig config, GenerationResult result) {
    // For build_runner, we need to generate the content manually
    // since we can't use the file system directly
    final b = StringBuffer();

    if (config.addHeader) {
      b
        ..writeln('// GENERATED CODE – DO NOT MODIFY.')
        ..writeln('// Generated by build_runner')
        ..writeln();
    }

    if (config.generateEnum) {
      b.writeln('enum ${config.className} {');
      b.writeln('  // TODO: Add enum values based on discovered assets');
      b.writeln('  ;');
      b.writeln();
      b.writeln('  const ${config.className}(this.path);');
      b.writeln();
      b.writeln('  final String path;');
      b.writeln();
      b.writeln('  @override');
      b.writeln('  String toString() => path;');
      b.writeln('}');
    } else {
      b
        ..writeln('class ${config.className} {')
        ..writeln('  const ${config.className}._();')
        ..writeln()
        ..writeln('  // TODO: Add static constants based on discovered assets')
        ..writeln();

      if (config.generateMap) {
        b.writeln('  static const Map<String,String> all = {');
        b.writeln('    // TODO: Add asset mappings');
        b.writeln('  };');
      }
      b.writeln('}');
    }

    return b.toString();
  }
}

/// Creates a new [AssetGenBuilder] instance.
///
/// This function is used by build_runner to create instances of the
/// [AssetGenBuilder]. It's the entry point for the build_runner
/// integration.
///
/// [options] The builder options from build.yaml.
///
/// Returns a new [AssetGenBuilder] instance.
Builder assetGenBuilder(BuilderOptions options) => AssetGenBuilder();
