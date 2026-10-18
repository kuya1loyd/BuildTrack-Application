import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme.dart';

String formatCurrency(double amount) {
  final formatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: r'$',
    decimalDigits: 0,
  );
  return formatter.format(amount);
}

String compactCurrency(double amount) {
  final abs = amount.abs();
  if (abs >= 1000000) {
    return '\$${(amount / 1000000).toStringAsFixed(1)}M';
  }
  if (abs >= 1000) {
    final k = amount / 1000;
    return '\$${k >= 100 ? k.toStringAsFixed(0) : k.toStringAsFixed(1)}K';
  }
  return '\$${amount.toStringAsFixed(0)}';
}

String formatDate(DateTime? date) {
  if (date == null) return '';
  return DateFormat('MMM d, y').format(date);
}

DateTime? parseDate(String raw) => raw.isEmpty ? null : DateTime.tryParse(raw);

String greetingForHour(DateTime time) {
  final hour = time.hour;
  if (hour < 12) return 'Good morning,';
  if (hour < 17) return 'Good afternoon,';
  return 'Good evening,';
}

String formatQuantity(double quantity) {
  if (quantity == quantity.roundToDouble()) {
    return quantity.toInt().toString();
  }
  return quantity.toString();
}

Color toneForProgress(int progress) {
  if (progress >= 80) return AppColors.success;
  if (progress >= 40) return AppColors.primary;
  return AppColors.warning;
}
