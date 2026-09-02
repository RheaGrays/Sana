import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'SANA';
  static const String appFullName = 'Sound-Aware Notification Assistant';
  
  // Audio Constants
  static const int sampleRate = 16000;
  static const int audioWindowSizeMs = 975; // 0.975s window for YAMNet
  static const double defaultRmsGateThreshold = 0.015; // RMS energy threshold
  
  // CASPA Algorithm Defaults
  static const double defaultWeightUrgency = 0.45; // W1
  static const double defaultWeightTime = 0.25;    // W2
  static const double defaultWeightEnv = 0.30;     // W3
  static const double defaultLambda = 0.05;        // Cooldown decay constant
  
  // CASPA Decision Thresholds (Scale: 0 to 10)
  static const double defaultHighThreshold = 5.0;
  static const double defaultLowThreshold = 2.5;

  // APMA Constants
  static const double anomalyZScoreThreshold = 2.0;
  static const int sequentialWindowSeconds = 30;
  static const double minSequenceConfidence = 0.50; // 50% minimum support

  // Sound Class Taxonomy (28 Classes grouped into 4 domains)
  static const List<String> soundClasses = [
    // Emergency & Safety (5)
    "Fire Alarm / Smoke Detector",
    "Emergency Siren",
    "Screaming",
    "Glass Breaking",
    "Explosion / Gunshot",
    // Household & Indoor (9)
    "Doorbell / Chime",
    "Door Knocking",
    "Phone Ringing / Alarm Clock",
    "Baby Cry",
    "Dog Barking",
    "Cat Meowing",
    "Water Running",
    "Microwave Beep",
    "Smoke / CO Detector",
    // Urban & Traffic (5)
    "Vehicle Horn / Car Honking",
    "Brake Squeal",
    "Motorcycle Engine",
    "Train Whistle",
    "Rain / Thunder",
    // Human Interaction & Ambient (9)
    "Speech / Talking",
    "Coughing",
    "Sneezing",
    "Laughter",
    "Footsteps",
    "Kitchen Clatter",
    "Door Open / Slam",
    "Ambient / Background Noise",
    "Appliance Alert Beep"
  ];

  static const Map<String, IconData> classIcons = {
    "Fire Alarm / Smoke Detector": Icons.local_fire_department,
    "Emergency Siren": Icons.warning_rounded,
    "Screaming": Icons.record_voice_over,
    "Glass Breaking": Icons.hardware,
    "Explosion / Gunshot": Icons.dangerous,
    "Doorbell / Chime": Icons.notifications_active,
    "Door Knocking": Icons.meeting_room,
    "Phone Ringing / Alarm Clock": Icons.alarm,
    "Baby Cry": Icons.child_care,
    "Dog Barking": Icons.pets,
    "Cat Meowing": Icons.pets_outlined,
    "Water Running": Icons.water_drop,
    "Microwave Beep": Icons.microwave,
    "Smoke / CO Detector": Icons.sensors,
    "Vehicle Horn / Car Honking": Icons.volume_up,
    "Brake Squeal": Icons.car_crash,
    "Motorcycle Engine": Icons.two_wheeler,
    "Train Whistle": Icons.train,
    "Rain / Thunder": Icons.thunderstorm,
    "Speech / Talking": Icons.forum,
    "Coughing": Icons.sick,
    "Sneezing": Icons.coronavirus,
    "Laughter": Icons.sentiment_very_satisfied,
    "Footsteps": Icons.directions_walk,
    "Kitchen Clatter": Icons.restaurant,
    "Door Open / Slam": Icons.door_sliding,
    "Ambient / Background Noise": Icons.graphic_eq,
    "Appliance Alert Beep": Icons.timer_outlined,
  };
}
