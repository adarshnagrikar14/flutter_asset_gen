import 'dart:convert';
import 'package:crypto/crypto.dart';

String contentHash(String content) =>
    md5.convert(utf8.encode(content)).toString();
