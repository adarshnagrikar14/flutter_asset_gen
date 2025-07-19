import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Generates an MD5 hash of the given content.
///
/// This function is used to determine if the generated content has changed
/// since the last generation, allowing the generator to skip writing the
/// output file when no changes have occurred (idempotent behavior).
///
/// ## Example
///
/// ```dart
/// final content = 'class Assets { static const logo = "assets/logo.png"; }';
/// final hash = contentHash(content);
/// print('Content hash: $hash');
/// ```
///
/// ## Use Case
///
/// The hash is used to compare the newly generated content with the
/// existing output file to avoid unnecessary file writes when the
/// content hasn't changed. This improves performance and prevents
/// unnecessary rebuilds in build systems.
///
/// [content] The string content to hash.
///
/// Returns an MD5 hash string of the content.
String contentHash(String content) =>
    md5.convert(utf8.encode(content)).toString();
