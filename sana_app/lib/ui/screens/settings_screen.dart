import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/sound_class_config.dart';
import '../../services/caspa_engine.dart';
import '../../services/audio_capture_service.dart';
import '../../services/geofence_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final caspa = CaspaEngine.instance;
  final audio = AudioCaptureService.instance;
  final geofence = GeofenceService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SANA Settings & Personalization', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'User Sound Urgency Weights (U_sound)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent),
          ),
          const SizedBox(height: 4),
          const Text(
            'Customize priority ranking per sound class (1: Low, 10: Critical Alert)',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: AppConstants.soundClasses.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final sound = AppConstants.soundClasses[index];
                final config = caspa.soundConfigs[sound] ??
                    SoundClassConfig(soundClass: sound, urgencyWeight: 5.0);

                return ListTile(
                  title: Text(sound, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Slider(
                    value: config.urgencyWeight,
                    min: 1.0,
                    max: 10.0,
                    divisions: 9,
                    label: config.urgencyWeight.toStringAsFixed(0),
                    activeColor: _getSliderColor(config.urgencyWeight),
                    onChanged: (val) {
                      setState(() {
                        config.urgencyWeight = val;
                        caspa.soundConfigs[sound] = config;
                      });
                    },
                  ),
                  trailing: Text(
                    config.urgencyWeight.toStringAsFixed(0),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _getSliderColor(config.urgencyWeight),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'CASPA Priority Thresholds (Sp)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('High-Priority Threshold (Haptic + Visual):'),
                      Text(caspa.highThreshold.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: caspa.highThreshold,
                    min: 3.0,
                    max: 8.0,
                    divisions: 10,
                    activeColor: Colors.redAccent,
                    onChanged: (val) {
                      setState(() => caspa.highThreshold = val);
                    },
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Medium-Priority Threshold (Visual Only):'),
                      Text(caspa.lowThreshold.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: caspa.lowThreshold,
                    min: 1.0,
                    max: 4.5,
                    divisions: 7,
                    activeColor: Colors.amberAccent,
                    onChanged: (val) {
                      setState(() => caspa.lowThreshold = val);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Battery Energy Gating (RMS Threshold)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Minimum Sound Threshold:'),
                      Text('${(audio.rmsGateThreshold * 100).toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: audio.rmsGateThreshold,
                    min: 0.005,
                    max: 0.08,
                    divisions: 15,
                    activeColor: Colors.greenAccent,
                    onChanged: (val) {
                      setState(() => audio.rmsGateThreshold = val);
                    },
                  ),
                  const Text(
                    'Higher threshold saves more battery by skipping quiet ambient noise.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Color _getSliderColor(double val) {
    if (val >= 8.0) return Colors.redAccent;
    if (val >= 5.0) return Colors.amber;
    return Colors.teal;
  }
}
