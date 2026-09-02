class TemporalService {
  static final TemporalService instance = TemporalService._internal();

  TemporalService._internal();

  String getTimeOfDayLabel([DateTime? now]) {
    final current = now ?? DateTime.now();
    final hour = current.hour;

    if (hour >= 6 && hour < 12) {
      return 'Morning';
    } else if (hour >= 12 && hour < 18) {
      return 'Afternoon';
    } else if (hour >= 18 && hour < 22) {
      return 'Evening';
    } else {
      return 'Night'; // 22:00 to 06:00
    }
  }

  double getTimeMultiplier(String soundClass, [DateTime? now]) {
    final label = getTimeOfDayLabel(now);

    // During nighttime (22:00 - 06:00), safety sounds have increased priority
    if (label == 'Night') {
      if (soundClass.contains('Fire') ||
          soundClass.contains('Smoke') ||
          soundClass.contains('Screaming') ||
          soundClass.contains('Breaking') ||
          soundClass.contains('Explosion') ||
          soundClass.contains('Baby')) {
        return 2.5; // High-risk period boost
      }
      // Non-critical sounds get lower priority at night to allow sleep
      return 1.0;
    }

    if (label == 'Evening') {
      if (soundClass.contains('Door') || soundClass.contains('Alarm')) {
        return 1.8;
      }
      return 1.2;
    }

    // Day time baseline
    return 1.0;
  }
}
