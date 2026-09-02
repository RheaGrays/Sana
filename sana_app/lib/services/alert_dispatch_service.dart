import 'package:vibration/vibration.dart';

class AlertDispatchService {
  static final AlertDispatchService instance = AlertDispatchService._internal();

  AlertDispatchService._internal();

  Future<void> triggerAlert({
    required String priorityTier,
    required String soundClass,
  }) async {
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator != true) return;

    if (priorityTier == 'HIGH') {
      // Emergency / High Priority: Intense pulsing vibration
      if (soundClass.contains('Fire') || soundClass.contains('Siren') || soundClass.contains('Explosion')) {
        await Vibration.vibrate(
          pattern: [0, 500, 200, 500, 200, 500],
          intensities: [0, 255, 0, 255, 0, 255],
        );
      } else {
        // High household (e.g. Baby Cry, Glass Breaking)
        await Vibration.vibrate(
          pattern: [0, 300, 150, 300],
          intensities: [0, 200, 0, 200],
        );
      }
    } else if (priorityTier == 'MEDIUM') {
      // Medium Priority: Subtle double tap
      await Vibration.vibrate(
        pattern: [0, 150, 100, 150],
        intensities: [0, 128, 0, 128],
      );
    }
    // LOW priority: Silent (No vibration)
  }
}
