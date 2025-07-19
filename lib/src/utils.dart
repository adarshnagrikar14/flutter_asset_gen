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
