import 'dart:convert';

import 'package:crypto/crypto.dart';

abstract final class FriendStateHash {
  static String compute({required String fen, required List<String> moves}) {
    final String canonical = '$fen\n${moves.join(',')}';
    return sha256.convert(utf8.encode(canonical)).toString();
  }
}
