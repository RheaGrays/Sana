class GeofenceZone {
  final String id;
  final String name; // 'Home', 'Work', 'Street/Other'
  final String? wifiSsid; // Connected Wi-Fi for instant indoor recognition
  final double? latitude;
  final double? longitude;
  final double radiusMeters;

  GeofenceZone({
    required this.id,
    required this.name,
    this.wifiSsid,
    this.latitude,
    this.longitude,
    this.radiusMeters = 100.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'wifiSsid': wifiSsid,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
    };
  }

  factory GeofenceZone.fromMap(Map<String, dynamic> map) {
    return GeofenceZone(
      id: map['id'] as String,
      name: map['name'] as String,
      wifiSsid: map['wifiSsid'] as String?,
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      radiusMeters: (map['radiusMeters'] as num?)?.toDouble() ?? 100.0,
    );
  }
}
