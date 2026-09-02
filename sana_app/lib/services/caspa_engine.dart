import 'dart:math';
import '../core/constants.dart';
import '../models/sound_class_config.dart';
import 'temporal_service.dart';
import 'geofence_service.dart';

class CaspaResult {
  final double score;
  final String tier; // 'HIGH', 'MEDIUM', 'LOW'
  final double decayFactor;
  final double confidence;
  final double userUrgency;
  final double timeMultiplier;
  final double envMultiplier;

  CaspaResult({
    required this.score,
    required this.tier,
    required this.decayFactor,
    required this.confidence,
    required this.userUrgency,
    required this.timeMultiplier,
    required this.envMultiplier,
  });
}

class CaspaEngine {
  static final CaspaEngine instance = CaspaEngine._internal();

  // Weights W1, W2, W3 (sum = 1.0)
  double w1 = AppConstants.defaultWeightUrgency;
  double w2 = AppConstants.defaultWeightTime;
  double w3 = AppConstants.defaultWeightEnv;
  double lambda = AppConstants.defaultLambda;

  double highThreshold = AppConstants.defaultHighThreshold;
  double lowThreshold = AppConstants.defaultLowThreshold;

  // Track last occurrence timestamp for each sound class to apply exponential decay
  final Map<String, DateTime> _lastOccurrenceMap = {};

  // User urgency configurations per sound class
  final Map<String, SoundClassConfig> soundConfigs = {};

  CaspaEngine._internal() {
    _initDefaultConfigs();
  }

  void _initDefaultConfigs() {
    for (var sound in AppConstants.soundClasses) {
      soundConfigs[sound] = SoundClassConfig(
        soundClass: sound,
        urgencyWeight: SoundClassConfig.getDefaultUrgency(sound),
        isEnabled: true,
      );
    }
  }

  CaspaResult evaluate({
    required String soundClass,
    required double confidence,
    required String currentZone,
    DateTime? eventTime,
  }) {
    final now = eventTime ?? DateTime.now();

    // 1. Calculate exponential decay cooldown R_decay(c)
    double rDecay = 1.0;
    if (_lastOccurrenceMap.containsKey(soundClass)) {
      final lastTime = _lastOccurrenceMap[soundClass]!;
      final deltaSeconds = now.difference(lastTime).inMilliseconds / 1000.0;
      // Formula: R_decay(c) = 1.0 - 0.9 * e^(-lambda * delta_t)
      rDecay = 1.0 - (0.9 * exp(-lambda * deltaSeconds));
      // Clamp between [0.1, 1.0]
      rDecay = rDecay.clamp(0.1, 1.0);
    }

    // Update last occurrence
    _lastOccurrenceMap[soundClass] = now;

    // 2. Fetch User Urgency U_sound(c)
    final config = soundConfigs[soundClass] ??
        SoundClassConfig(
          soundClass: soundClass,
          urgencyWeight: SoundClassConfig.getDefaultUrgency(soundClass),
        );
    final double uSound = config.isEnabled ? config.urgencyWeight : 0.0;

    // 3. Fetch Time Multiplier T_time(t)
    final double tTime = TemporalService.instance.getTimeMultiplier(soundClass, now);

    // 4. Fetch Environmental Zone Multiplier E_env(z, c)
    final double eEnv = GeofenceService.instance.getEnvironmentalMultiplier(currentZone, soundClass);

    // 5. Compute Composite Priority Score Sp
    // Formula: Sp = C_class * R_decay * (W1 * U_sound + W2 * T_time + W3 * E_env)
    final double contextSum = (w1 * uSound) + (w2 * tTime) + (w3 * eEnv);
    final double sp = confidence * rDecay * contextSum;

    // 6. Determine Alert Tier
    String tier = 'LOW';
    if (sp >= highThreshold) {
      tier = 'HIGH';
    } else if (sp >= lowThreshold) {
      tier = 'MEDIUM';
    } else {
      tier = 'LOW';
    }

    return CaspaResult(
      score: sp,
      tier: tier,
      decayFactor: rDecay,
      confidence: confidence,
      userUrgency: uSound,
      timeMultiplier: tTime,
      envMultiplier: eEnv,
    );
  }

  void resetCooldowns() {
    _lastOccurrenceMap.clear();
  }
}
