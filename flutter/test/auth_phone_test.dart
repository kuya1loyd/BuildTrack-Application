import 'package:flutter_test/flutter_test.dart';
import 'package:buildtrack/data/repositories.dart';

void main() {
  group('AuthRepository phone matching', () {
    test('cleans digits properly', () {
      expect(AuthRepository.phoneDigits('0994-990-4508'), '09949904508');
      expect(AuthRepository.phoneDigits('+63 (994) 990-4508'), '639949904508');
      expect(AuthRepository.phoneDigits(''), '');
    });

    test('matches exact same phone numbers', () {
      expect(AuthRepository.phoneMatches('09949904508', '09949904508'), isTrue);
      expect(AuthRepository.phoneMatches('0994-990-4508', '0994 990 4508'), isTrue);
    });

    test('matches local prefix with international country code', () {
      expect(AuthRepository.phoneMatches('09949904508', '+639949904508'), isTrue);
      expect(AuthRepository.phoneMatches('+639949904508', '09949904508'), isTrue);
      expect(AuthRepository.phoneMatches('09949904508', '+63 994 990 4508'), isTrue);
    });

    test('matches phone with or without leading zero', () {
      expect(AuthRepository.phoneMatches('09949904508', '9949904508'), isTrue);
      expect(AuthRepository.phoneMatches('9949904508', '09949904508'), isTrue);
    });

    test('matches international numbers worldwide', () {
      // US / Canada (+1)
      expect(AuthRepository.phoneMatches('+1 (415) 555-2671', '4155552671'), isTrue);
      // UK (+44)
      expect(AuthRepository.phoneMatches('+44 7911 123456', '07911 123456'), isTrue);
      // Egypt (+20)
      expect(AuthRepository.phoneMatches('+20 100 123 4567', '0100 123 4567'), isTrue);
    });

    test('rejects different phone numbers', () {
      expect(AuthRepository.phoneMatches('09949904508', '09123456789'), isFalse);
      expect(AuthRepository.phoneMatches('09949904508', ''), isFalse);
    });
  });
}
