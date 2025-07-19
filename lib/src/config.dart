import 'dart:io';
import 'package:yaml/yaml.dart';

class AssetGenConfig {
  final List<String> roots;
  final String output;
  final String className;
  final List<String> exclude;
  final List<String>? includeExtensions;
  final String namingCase;
  final String sort;
  final bool groupByRoot;
  final bool addHeader;
  final bool generateMap;
  final String prefix;

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
  });

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
      );

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
    );
  }
}

AssetGenConfig loadConfig([String? path]) {
  final file = File(path ?? 'asset_gen.yaml');
  if (!file.existsSync()) return AssetGenConfig.defaults();
  final doc = loadYaml(file.readAsStringSync()) as YamlMap;
  List<String>? _list(dynamic v) =>
      v == null ? null : List<String>.from(v.map((e) => e.toString()));

  return AssetGenConfig.defaults().copyWith(
    roots: _list(doc['roots']) ?? AssetGenConfig.defaults().roots,
    output: doc['output']?.toString(),
    className: doc['class_name']?.toString(),
    exclude: _list(doc['exclude']) ?? AssetGenConfig.defaults().exclude,
    includeExtensions: _list(doc['include_extensions']),
    namingCase: doc['case']?.toString(),
    sort: doc['sort']?.toString(),
    groupByRoot: doc['group_by_root'] is bool ? doc['group_by_root'] : null,
    addHeader: doc['add_header'] is bool ? doc['add_header'] : null,
    generateMap: doc['generate_map'] is bool ? doc['generate_map'] : null,
    prefix: doc['prefix']?.toString(),
  );
}
