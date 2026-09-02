import 'package:flutter_test/flutter_test.dart';
import 'package:sana_app/services/caspa_engine.dart';

void main() {
  group('CASPA (Context-Aware Sound Prioritization Algorithm) Tests', () {
    final caspa = CaspaEngine.instance;

    setUp(() {
      caspa.resetCooldowns();
    });

    test('Initial High-Priority Emergency Sound produces HIGH tier', () {
      final result = caspa.evaluate(
        soundClass: 'Fire Alarm / Smoke Detector',
        confidence: 0.95,
        currentZone: 'Home',
      );

      expect(result.score, greaterThanOrEqualTo(caspa.highThreshold));
      expect(result.tier, equals('HIGH'));
      expect(result.decayFactor, equals(1.0));
    });

    test('Exponential Cooldown R_decay suppresses rapid duplicate alerts', () {
      final time1 = DateTime(2026, 9, 2, 10, 0, 0);
      final time2 = DateTime(2026, 9, 2, 10, 0, 2);

      final result1 = caspa.evaluate(
        soundClass: 'Dog Barking',
        confidence: 0.85,
        currentZone: 'Home',
        eventTime: time1,
      );

      final result2 = caspa.evaluate(
        soundClass: 'Dog Barking',
        confidence: 0.85,
        currentZone: 'Home',
        eventTime: time2,
      );

      expect(result2.decayFactor, lessThan(result1.decayFactor));
      expect(result2.score, lessThan(result1.score));
    });

    test('Ambient talking produces LOW tier without interrupting user', () {
      final result = caspa.evaluate(
        soundClass: 'Speech / Talking',
        confidence: 0.70,
        currentZone: 'Home',
      );

      expect(result.tier, equals('LOW'));
    });
  });
}
