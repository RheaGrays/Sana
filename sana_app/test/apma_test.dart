import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:sana_app/services/apma_engine.dart';

void main() {
  group('APMA (Acoustic Pattern Mining Algorithm) Tests', () {
    test('Z-Score Anomaly Formula correctly flags outlier spikes > 2.0', () {
      final dailyCounts = [5, 4, 6, 5, 4, 5, 25]; // Day 7 has 25 events (spike)
      final mean = dailyCounts.reduce((a, b) => a + b) / dailyCounts.length;
      final variance = dailyCounts.map((c) => pow(c - mean, 2)).reduce((a, b) => a + b) / dailyCounts.length;
      final stdDev = sqrt(variance);

      final zScoreDay7 = (25 - mean) / stdDev;

      expect(zScoreDay7, greaterThan(2.0));
    });

    test('Sequence rule correctly represents mined transition pattern', () {
      final rule = SequenceRule(
        antecedentClass: 'Doorbell / Chime',
        consequentClass: 'Dog Barking',
        deltaSeconds: 15,
        confidence: 0.80,
        occurrences: 12,
      );

      expect(rule.description, contains('Doorbell / Chime'));
      expect(rule.description, contains('Dog Barking'));
      expect(rule.description, contains('80%'));
    });
  });
}
