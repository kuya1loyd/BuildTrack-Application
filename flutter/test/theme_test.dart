import 'package:buildtrack/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('brand palette is intact', () {
    expect(AppColors.primary, const Color(0xFFF97316));
    expect(AppColors.dark, const Color(0xFF0F172A));
    expect(AppColors.success, const Color(0xFF17A34A));
  });

  test('motion constants are ordered', () {
    expect(AppRadius.sm, lessThan(AppRadius.md));
    expect(AppRadius.md, lessThan(AppRadius.lg));
    expect(AppRadius.lg, lessThan(AppRadius.xl));
  });
}
