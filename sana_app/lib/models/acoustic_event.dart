class AcousticEvent {
  final int? eventId;
  final DateTime timestamp;
  final String soundClass;
  final double confidence;
  final double priorityScore;
  final String priorityTier; // 'HIGH', 'MEDIUM', 'LOW'
  final double? latitude;
  final double? longitude;
  final String geofenceZone; // 'Home', 'Work', 'Street/Other'
  final String timeOfDayLabel; // 'Morning', 'Afternoon', 'Evening', 'Night'

  AcousticEvent({
    this.eventId,
    required this.timestamp,
    required this.soundClass,
    required this.confidence,
    required this.priorityScore,
    required this.priorityTier,
    this.latitude,
    this.longitude,
    required this.geofenceZone,
    required this.timeOfDayLabel,
  });

  Map<String, dynamic> toMap() {
    return {
      'event_id': eventId,
      'timestamp': timestamp.toIso8601String(),
      'sound_class': soundClass,
      'confidence': confidence,
      'priority_score': priorityScore,
      'priority_tier': priorityTier,
      'latitude': latitude,
      'longitude': longitude,
      'geofence_zone': geofenceZone,
      'time_of_day_label': timeOfDayLabel,
    };
  }

  factory AcousticEvent.fromMap(Map<String, dynamic> map) {
    return AcousticEvent(
      eventId: map['event_id'] as int?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      soundClass: map['sound_class'] as String,
      confidence: (map['confidence'] as num).toDouble(),
      priorityScore: (map['priority_score'] as num).toDouble(),
      priorityTier: map['priority_tier'] as String,
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      geofenceZone: map['geofence_zone'] as String? ?? 'Other',
      timeOfDayLabel: map['time_of_day_label'] as String? ?? 'Morning',
    );
  }
}
