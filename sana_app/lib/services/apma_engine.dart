import 'dart:math';
import '../models/acoustic_event.dart';
import 'database_service.dart';

class AnomalyReport {
  final String soundClass;
  final String date;
  final int count;
  final double mean;
  final double stdDev;
  final double zScore;

  AnomalyReport({
    required this.soundClass,
    required this.date,
    required this.count,
    required this.mean,
    required this.stdDev,
    required this.zScore,
  });
}

class SequenceRule {
  final String antecedentClass;
  final String consequentClass;
  final int deltaSeconds;
  final double confidence; // e.g. 0.75 for 75%
  final int occurrences;

  SequenceRule({
    required this.antecedentClass,
    required this.consequentClass,
    required this.deltaSeconds,
    required this.confidence,
    required this.occurrences,
  });

  String get description =>
      "$antecedentClass  ➔  $consequentClass (within ${deltaSeconds}s in ${(confidence * 100).toStringAsFixed(0)}% of cases)";
}

class ApmaEngine {
  static final ApmaEngine instance = ApmaEngine._internal();
  final DatabaseService _db = DatabaseService.instance;

  ApmaEngine._internal();

  /// 1. Temporal Clustering: Computes hourly distribution D(c, h) for a specific sound class or all classes
  Future<Map<int, double>> computeHourlyDistribution([String? soundClass]) async {
    final events = await _db.getAllEvents();
    final Map<int, int> hourCounts = {for (int i = 0; i < 24; i++) i: 0};
    int totalCount = 0;

    for (var event in events) {
      if (soundClass == null || soundClass == 'All' || event.soundClass == soundClass) {
        final hour = event.timestamp.hour;
        hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
        totalCount++;
      }
    }

    final Map<int, double> hourlyDensity = {};
    for (int h = 0; h < 24; h++) {
      hourlyDensity[h] = totalCount > 0 ? (hourCounts[h]! / totalCount.toDouble()) : 0.0;
    }

    return hourlyDensity;
  }

  /// 2. Anomaly Detection: Z-Score z(c, d) = (N(c, d) - mu) / sigma > 2.0
  Future<List<AnomalyReport>> detectAnomalies() async {
    final events = await _db.getAllEvents();
    if (events.isEmpty) return [];

    // Group counts by SoundClass -> DateString (YYYY-MM-DD)
    final Map<String, Map<String, int>> classDailyCounts = {};
    for (var event in events) {
      final dateStr = "${event.timestamp.year}-${event.timestamp.month.toString().padLeft(2, '0')}-${event.timestamp.day.toString().padLeft(2, '0')}";
      classDailyCounts.putIfAbsent(event.soundClass, () => {});
      classDailyCounts[event.soundClass]![dateStr] =
          (classDailyCounts[event.soundClass]![dateStr] ?? 0) + 1;
    }

    final List<AnomalyReport> anomalies = [];

    classDailyCounts.forEach((soundClass, dailyMap) {
      if (dailyMap.length >= 3) {
        final counts = dailyMap.values.toList();
        final double mean = counts.reduce((a, b) => a + b) / counts.length;
        
        final double variance = counts.map((c) => pow(c - mean, 2)).reduce((a, b) => a + b) / counts.length;
        final double stdDev = sqrt(variance);

        if (stdDev > 0.001) {
          dailyMap.forEach((date, count) {
            final double zScore = (count - mean) / stdDev;
            if (zScore > 2.0) {
              anomalies.add(
                AnomalyReport(
                  soundClass: soundClass,
                  date: date,
                  count: count,
                  mean: mean,
                  stdDev: stdDev,
                  zScore: zScore,
                ),
              );
            }
          });
        }
      }
    });

    return anomalies;
  }

  /// 3. Sequential Pattern Mining: Find A -> B within deltaT
  Future<List<SequenceRule>> mineSequentialPatterns({int deltaSeconds = 30}) async {
    final events = await _db.getAllEvents();
    if (events.length < 2) return [];

    // Events are sorted chronologically
    final sorted = List<AcousticEvent>.from(events)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final Map<String, int> antecedentCounts = {};
    final Map<String, Map<String, int>> pairTransitions = {};

    for (int i = 0; i < sorted.length - 1; i++) {
      final current = sorted[i];
      antecedentCounts[current.soundClass] = (antecedentCounts[current.soundClass] ?? 0) + 1;

      // Look ahead within deltaSeconds window
      for (int j = i + 1; j < sorted.length; j++) {
        final next = sorted[j];
        final diff = next.timestamp.difference(current.timestamp).inSeconds;

        if (diff > deltaSeconds) break;

        if (current.soundClass != next.soundClass) {
          pairTransitions.putIfAbsent(current.soundClass, () => {});
          pairTransitions[current.soundClass]![next.soundClass] =
              (pairTransitions[current.soundClass]![next.soundClass] ?? 0) + 1;
          break; // Count first succeeding transition within window
        }
      }
    }

    final List<SequenceRule> rules = [];

    pairTransitions.forEach((aClass, transitions) {
      final totalA = antecedentCounts[aClass] ?? 1;
      transitions.forEach((bClass, coOccurrences) {
        final double confidence = coOccurrences / totalA;
        if (confidence >= 0.3 && coOccurrences >= 2) {
          rules.add(
            SequenceRule(
              antecedentClass: aClass,
              consequentClass: bClass,
              deltaSeconds: deltaSeconds,
              confidence: confidence,
              occurrences: coOccurrences,
            ),
          );
        }
      });
    });

    rules.sort((a, b) => b.confidence.compareTo(a.confidence));
    return rules;
  }
}
