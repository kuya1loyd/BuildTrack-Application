import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buildtrack/data/password_hash.dart';

void main() {
  group('PasswordHash', () {
    test('produces the documented pbkdf2-sha256 format', () {
      final stored = PasswordHash.hash('correct horse battery staple');

      expect(stored.startsWith('pbkdf2-sha256\$'), isTrue);
      final parts = stored.split('\$');
      expect(parts, hasLength(4));
      expect(parts[1], '150000');
      expect(parts[2], hasLength(32));
      expect(parts[3], hasLength(64));
    });

    test('verifies its own hash and rejects wrong passwords', () {
      final stored = PasswordHash.hash('hunter2hunter2');
      expect(PasswordHash.verify('hunter2hunter2', stored), isTrue);
      expect(PasswordHash.verify('hunter2hunter', stored), isFalse);
      expect(PasswordHash.verify('', stored), isFalse);
    });

    test('salts are unique per account', () {
      final a = PasswordHash.hash('same-password');
      final b = PasswordHash.hash('same-password');
      expect(a, isNot(equals(b)));
      expect(PasswordHash.verify('same-password', a), isTrue);
      expect(PasswordHash.verify('same-password', b), isTrue);
    });

    test('matches a reference PBKDF2-HMAC-SHA256 implementation', () {
      expect(
        PasswordHash.verify(
          'correct horse battery staple',
          r'pbkdf2-sha256$1000$00112233445566778899aabbccddeeff'
              r'$dfb233c3b5065575ef404328c881a0cba71b7180f72298a2edc5ea5f3a4c02f9',
        ),
        isTrue,
      );

      final wrong =
          r'pbkdf2-sha256$1000$00112233445566778899aabbccddeeff'
          r'$0000000000000000000000000000000000000000000000000000000000000000';
      expect(
        PasswordHash.verify('correct horse battery staple', wrong),
        isFalse,
      );
    });

    test('honours the iteration count embedded in the stored hash', () {
      final tampered =
          r'pbkdf2-sha256$999$00112233445566778899aabbccddeeff'
          r'$dfb233c3b5065575ef404328c881a0cba71b7180f72298a2edc5ea5f3a4c02f9';
      expect(
        PasswordHash.verify('correct horse battery staple', tampered),
        isFalse,
      );
    });

    test('still verifies legacy salted SHA-256 hashes', () {
      final legacy =
          'salt-123:${sha256.convert(utf8.encode('salt-123::correct horse battery staple')).toString()}';
      expect(PasswordHash.isLegacy(legacy), isTrue);
      expect(
        PasswordHash.verify('correct horse battery staple', legacy),
        isTrue,
      );
      expect(PasswordHash.verify('wrong password', legacy), isFalse);
    });

    test('rejects malformed stored hashes', () {
      expect(PasswordHash.verify('x', ''), isFalse);
      expect(PasswordHash.verify('x', 'salt:'), isFalse);
      expect(
        PasswordHash.verify('x', 'pbkdf2-sha256\$abc\$salt\$hash'),
        isFalse,
      );
      expect(PasswordHash.verify('x', 'pbkdf2-sha256\$1000\$\$'), isFalse);
    });
  });
}
