import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class PasswordHash {
  PasswordHash._();

  static const iterations = 150000;
  static const _saltBytes = 16;
  static const _hashBytes = 32;
  static const _prefix = 'pbkdf2-sha256';

  static String hash(String password) {
    final salt = _randomBytes(_saltBytes);
    final hash = _pbkdf2Sha256(
      utf8.encode(password),
      salt,
      iterations,
      _hashBytes,
    );
    return '$_prefix\$$iterations\$${_hex(salt)}\$${_hex(hash)}';
  }

  static bool verify(String password, String stored) {
    if (stored.startsWith('$_prefix\$')) {
      final parts = stored.split('\$');
      if (parts.length != 4) return false;
      final rounds = int.tryParse(parts[1]);
      if (rounds == null || rounds <= 0) return false;
      final salt = _hexDecode(parts[2]);
      final expected = _hexDecode(parts[3]);
      if (salt.isEmpty || expected.isEmpty) return false;
      final actual = _pbkdf2Sha256(
        utf8.encode(password),
        salt,
        rounds,
        expected.length,
      );
      return _fixedTimeEquals(actual, expected);
    }

    final parts = stored.split(':');
    if (parts.length != 2) return false;
    final legacy = sha256
        .convert(utf8.encode('${parts[0]}::$password'))
        .toString();
    return _fixedTimeEquals(utf8.encode(legacy), utf8.encode(parts[1]));
  }

  static bool isLegacy(String stored) => !stored.startsWith('$_prefix\$');

   static Uint8List _randomBytes(int length) {
     // Use cryptographically secure random number generator for salt
     final random = Random.secure();
     return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
   }

  static Uint8List _pbkdf2Sha256(
    List<int> password,
    List<int> salt,
    int rounds,
    int keyLength,
  ) {
    const digestLength = 32;
    final blockCount = (keyLength / digestLength).ceil();
    final output = <int>[];

    for (var blockIndex = 1; blockIndex <= blockCount; blockIndex++) {
      final chunk = <int>[
        ...salt,
        (blockIndex >> 24) & 0xff,
        (blockIndex >> 16) & 0xff,
        (blockIndex >> 8) & 0xff,
        blockIndex & 0xff,
      ];
      var u = Hmac(sha256, password).convert(chunk).bytes;
      final accumulator = List<int>.from(u);
      for (var i = 1; i < rounds; i++) {
        u = Hmac(sha256, password).convert(u).bytes;
        for (var j = 0; j < accumulator.length; j++) {
          accumulator[j] ^= u[j];
        }
      }
      output.addAll(accumulator);
    }
    return Uint8List.fromList(output.sublist(0, keyLength));
  }

  static bool _fixedTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  static String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  static Uint8List _hexDecode(String hex) {
    final out = <int>[];
    for (var i = 0; i + 1 < hex.length; i += 2) {
      out.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(out);
  }
}
