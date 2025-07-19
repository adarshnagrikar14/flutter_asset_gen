import 'dart:io';
import 'package:yaml/yaml.dart';

/// Configuration for asset generation.
///
/// This class holds all configuration options for the asset generation process,
/// including directories to scan, output settings, filtering options, and
/// advanced features like watch mode and validation.
///
/// ## Example
///
/// ```dart
/// final config = AssetGenConfig(
///   roots: ['assets', 'images'],
///   output: 'lib/generated/assets.dart',
///   className: 'Assets',
///   generateEnum: true,
///   validatePubspec: true,
/// );
/// ```
class AssetGenConfig {
  /// Directories to scan for assets.
  ///
  /// These directories will be recursively scanned for files to include
  /// in the generated constants.
  final List<String> roots;

  /// Output file path for generated code.
  ///
  /// The path where the generated Dart file will be written.
  final String output;

  /// Name of the generated class or enum.
  ///
  /// This will be used as the class name for class output or enum name
  /// for enum output.
  final String className;

  /// Patterns to exclude from asset generation.
  ///
  /// Supports glob patterns like `"**/*.tmp"` or `"**/.*"`.
  final List<String> exclude;

  /// File extensions to include.
  ///
  /// If null, all files are included. If specified, only files with
  /// these extensions will be included.
  final List<String>? includeExtensions;

  /// Naming case style for generated identifiers.
  ///
  /// Options: `'camel'`, `'snake'`, `'kebab'`.
  final String namingCase;

  /// Sort order for generated assets.
  ///
  /// Options: `'identifier'` (sort by generated name) or `'path'` (sort by file path).
  final String sort;

  /// Whether to group assets by root directory.
  ///
  /// If true, assets will be organized by their root directory in the output.
  final bool groupByRoot;

  /// Whether to add a header comment to the generated file.
  ///
  /// The header includes generation timestamp and instructions.
  final bool addHeader;

  /// Whether to generate a map of all assets.
  ///
  /// If true, a static `Map<String, String>` will be generated containing
  /// all asset paths indexed by their identifiers.
  final bool generateMap;

  /// Prefix for all generated identifiers.
  ///
  /// This prefix will be added to all generated constant names.
  final String prefix;

  /// Whether to enable watch mode.
  ///
  /// In watch mode, the generator will monitor asset directories for changes
  /// and automatically regenerate when files are added, modified, or deleted.
  final bool watchMode;

  /// Whether to generate enum output instead of class output.
  ///
  /// If true, generates an enum with a `path` property instead of a class
  /// with static constants.
  final bool generateEnum;

  /// Whether to validate assets against pubspec.yaml.
  ///
  /// If true, checks that all generated assets are properly declared
  /// in the `flutter.assets` section of pubspec.yaml.
  final bool validatePubspec;

  /// Whether to run in build_runner mode.
  ///
  /// This affects the header comment and some internal behavior
  /// when used with build_runner.
  final bool buildRunnerMode;

  /// Custom path to pubspec.yaml file.
  ///
  /// If null, uses the default `pubspec.yaml` in the project root.
  final String? pubspecPath;

  /// Creates a new [AssetGenConfig] with the specified options.
  ///
  /// All parameters are required to ensure explicit configuration.
  /// Use [AssetGenConfig.defaults()] for a pre-configured instance.
  AssetGenConfig({
    required this.roots,
    required this.output,
    required this.className,
    required this.exclude,
    required this.includeExtensions,
    required this.namingCase,
    required this.sort,
    required this.groupByRoot,
    required this.addHeader,
    required this.generateMap,
    required this.prefix,
    required this.watchMode,
    required this.generateEnum,
    required this.validatePubspec,
    required this.buildRunnerMode,
    this.pubspecPath,
  });

  /// Creates a default configuration with sensible defaults.
  ///
  /// Returns a configuration suitable for most Flutter projects:
  /// - Scans `assets` directory
  /// - Outputs to `lib/generated/assets.dart`
  /// - Uses `Assets` as class name
  /// - Enables validation and map generation
  /// - Uses camelCase naming
  factory AssetGenConfig.defaults() => AssetGenConfig(
        roots: const ['assets'],
        output: 'lib/generated/assets.dart',
        className: 'Assets',
        exclude: const [],
        includeExtensions: null,
        namingCase: 'camel',
        sort: 'identifier',
        groupByRoot: true,
        addHeader: true,
        generateMap: true,
        prefix: '',
        watchMode: false,
        generateEnum: false,
        validatePubspec: true,
        buildRunnerMode: false,
        pubspecPath: null,
      );

  /// Creates a copy of this configuration with the specified fields replaced.
  ///
  /// Only the fields you specify will be changed; all other fields
  /// will remain the same as in the original configuration.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final config = AssetGenConfig.defaults();
  /// final customConfig = config.copyWith(
  ///   output: 'lib/custom/assets.dart',
  ///   generateEnum: true,
  /// );
  /// ```
  AssetGenConfig copyWith({
    List<String>? roots,
    String? output,
    String? className,
    List<String>? exclude,
    List<String>? includeExtensions,
    String? namingCase,
    String? sort,
    bool? groupByRoot,
    bool? addHeader,
    bool? generateMap,
    String? prefix,
    bool? watchMode,
    bool? generateEnum,
    bool? validatePubspec,
    bool? buildRunnerMode,
    String? pubspecPath,
  }) {
    return AssetGenConfig(
      roots: roots ?? this.roots,
      output: output ?? this.output,
      className: className ?? this.className,
      exclude: exclude ?? this.exclude,
      includeExtensions: includeExtensions ?? this.includeExtensions,
      namingCase: namingCase ?? this.namingCase,
      sort: sort ?? this.sort,
      groupByRoot: groupByRoot ?? this.groupByRoot,
      addHeader: addHeader ?? this.addHeader,
      generateMap: generateMap ?? this.generateMap,
      prefix: prefix ?? this.prefix,
      watchMode: watchMode ?? this.watchMode,
      generateEnum: generateEnum ?? this.generateEnum,
      validatePubspec: validatePubspec ?? this.validatePubspec,
      buildRunnerMode: buildRunnerMode ?? this.buildRunnerMode,
      pubspecPath: pubspecPath ?? this.pubspecPath,
    );
  }
}

/// Loads configuration from a YAML file.
///
/// Reads the configuration from the specified YAML file and returns
/// an [AssetGenConfig] instance. If the file doesn't exist, returns
/// the default configuration.
///
/// ## Example
///
/// ```dart
/// // Load from default asset_gen.yaml
/// final config = loadConfig();
///
/// // Load from custom file
/// final config = loadConfig('custom_config.yaml');
/// ```
///
/// ## YAML Format
///
/// The YAML file should contain configuration options:
///
/// ```yaml
/// roots:
///   - assets
///   - images
/// output: lib/generated/assets.dart
/// class_name: Assets
/// generate_enum: false
/// validate_pubspec: true
/// ```
///
/// [path] The path to the YAML configuration file. If null, uses `asset_gen.yaml`.
AssetGenConfig loadConfig([String? path]) {
  final file = File(path ?? 'asset_gen.yaml');
  if (!file.existsSync()) return AssetGenConfig.defaults();
  final doc = loadYaml(file.readAsStringSync()) as YamlMap;
  List<String>? parseList(dynamic v) =>
      v == null ? null : List<String>.from(v.map((e) => e.toString()));

  return AssetGenConfig.defaults().copyWith(
    roots: parseList(doc['roots']) ?? AssetGenConfig.defaults().roots,
    output: doc['output']?.toString(),
    className: doc['class_name']?.toString(),
    exclude: parseList(doc['exclude']) ?? AssetGenConfig.defaults().exclude,
    includeExtensions: parseList(doc['include_extensions']),
    namingCase: doc['case']?.toString(),
    sort: doc['sort']?.toString(),
    groupByRoot: doc['group_by_root'] is bool ? doc['group_by_root'] : null,
    addHeader: doc['add_header'] is bool ? doc['add_header'] : null,
    generateMap: doc['generate_map'] is bool ? doc['generate_map'] : null,
    prefix: doc['prefix']?.toString(),
    watchMode: doc['watch_mode'] is bool ? doc['watch_mode'] : null,
    generateEnum: doc['generate_enum'] is bool ? doc['generate_enum'] : null,
    validatePubspec:
        doc['validate_pubspec'] is bool ? doc['validate_pubspec'] : null,
    buildRunnerMode:
        doc['build_runner_mode'] is bool ? doc['build_runner_mode'] : null,
    pubspecPath: doc['pubspec_path']?.toString(),
  );
}
