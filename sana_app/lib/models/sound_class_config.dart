class SoundClassConfig {
  final String soundClass;
  double urgencyWeight; // U_sound in [1.0, 10.0]
  bool isEnabled;

  SoundClassConfig({
    required this.soundClass,
    this.urgencyWeight = 5.0,
    this.isEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'soundClass': soundClass,
      'urgencyWeight': urgencyWeight,
      'isEnabled': isEnabled ? 1 : 0,
    };
  }

  factory SoundClassConfig.fromMap(Map<String, dynamic> map) {
    return SoundClassConfig(
      soundClass: map['soundClass'] as String,
      urgencyWeight: (map['urgencyWeight'] as num).toDouble(),
      isEnabled: (map['isEnabled'] as int) == 1,
    );
  }

  // Baseline default priorities
  static double getDefaultUrgency(String name) {
    if (name.contains("Fire") || name.contains("Emergency") || name.contains("Explosion") || name.contains("Screaming")) {
      return 10.0;
    }
    if (name.contains("Glass Breaking") || name.contains("Smoke / CO") || name.contains("Baby Cry") || name.contains("Brake Squeal")) {
      return 8.5;
    }
    if (name.contains("Doorbell") || name.contains("Door Knocking") || name.contains("Vehicle Horn") || name.contains("Phone")) {
      return 6.5;
    }
    if (name.contains("Dog Barking") || name.contains("Microwave") || name.contains("Water Running")) {
      return 4.0;
    }
    if (name.contains("Talking") || name.contains("Coughing") || name.contains("Laughter") || name.contains("Footsteps")) {
      return 2.5;
    }
    return 1.5;
  }
}
