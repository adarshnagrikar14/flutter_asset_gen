/// Builds a valid Dart identifier from a file path.
///
/// Converts a relative file path into a valid Dart identifier that can be
/// used as a constant name. The conversion process includes:
///
/// 1. Removing the file extension
/// 2. Splitting the path into segments
/// 3. Converting segments to the specified case style
/// 4. Adding a prefix if specified
/// 5. Ensuring the identifier starts with a valid character
///
/// ## Example
///
/// ```dart
/// // camelCase (default)
/// buildIdentifier('assets/images/logo.png', caseStyle: 'camel', prefix: '')
/// // Returns: 'logoPng'
///
/// // snake_case
/// buildIdentifier('assets/icons/play_button.svg', caseStyle: 'snake', prefix: '')
/// // Returns: 'play_button'
///
/// // with prefix
/// buildIdentifier('assets/logo.png', caseStyle: 'camel', prefix: 'asset')
/// // Returns: 'assetLogoPng'
/// ```
///
/// ## Case Styles
///
/// - `'camel'`: camelCase (e.g., `logoPng`, `playButton`)
/// - `'snake'`: snake_case (e.g., `logo_png`, `play_button`)
/// - `'keep'`: Keep original segments (e.g., `logo`, `play_button`)
///
/// ## Edge Cases
///
/// - If the path results in an empty identifier, returns `'_'`
/// - If the identifier starts with a number, prepends `'_'`
/// - Handles special characters by removing them and splitting on them
///
/// [relativePath] The relative file path to convert.
/// [caseStyle] The case style to use ('camel', 'snake', or 'keep').
/// [prefix] Optional prefix to add to the identifier.
///
/// Returns a valid Dart identifier string.
String buildIdentifier(
  String relativePath, {
  required String caseStyle,
  required String prefix,
}) {
  final withoutExt = relativePath.replaceAll(RegExp(r'\.[^.]+$'), '');
  final raw = withoutExt
      .split('/')
      .expand((seg) => seg.split(RegExp(r'[^A-Za-z0-9]+')))
      .where((s) => s.isNotEmpty)
      .toList();
  if (raw.isEmpty) return '_';
  String id;
  switch (caseStyle) {
    case 'snake':
      id = raw.map((s) => s.toLowerCase()).join('_');
      break;
    case 'keep':
      id = raw.join('_');
      break;
    case 'camel':
    default:
      id = raw.first.toLowerCase() +
          raw.skip(1).map((s) => s[0].toUpperCase() + s.substring(1)).join();
  }
  if (prefix.isNotEmpty) {
    id = prefix + id[0].toUpperCase() + id.substring(1);
  }
  if (RegExp(r'^[0-9]').hasMatch(id)) id = '_$id';
  return id;
}
