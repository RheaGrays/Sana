import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import '../core/constants.dart';
import 'classifier_service.dart';
import 'caspa_engine.dart';
import 'geofence_service.dart';
import 'temporal_service.dart';
import 'database_service.dart';
import 'alert_dispatch_service.dart';
import '../models/acoustic_event.dart';

typedef OnDetectionCallback = void Function(AcousticEvent event, CaspaResult caspaResult);
typedef OnRmsUpdateCallback = void Function(double rms);

class AudioCaptureService {
  static final AudioCaptureService instance = AudioCaptureService._internal();

  final AudioRecorder _audioRecorder = AudioRecorder();
  StreamSubscription<Uint8List>? _audioStreamSub;
  Timer? _simulationTimer;

  bool _isListening = false;
  double rmsGateThreshold = AppConstants.defaultRmsGateThreshold;
  OnDetectionCallback? onDetection;
  OnRmsUpdateCallback? onRmsUpdate;

  AudioCaptureService._internal();

  bool get isListening => _isListening;

  Future<bool> requestPermissions() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  Future<void> startListening() async {
    if (_isListening) return;

    final hasPerm = await requestPermissions();
    _isListening = true;

    if (hasPerm) {
      try {
        final stream = await _audioRecorder.startStream(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: AppConstants.sampleRate,
            numChannels: 1,
          ),
        );

        final List<int> pcmBuffer = [];
        // Window size for 0.975s at 16kHz = 15600 samples * 2 bytes = 31200 bytes
        const targetByteCount = 31200;

        _audioStreamSub = stream.listen((chunk) {
          pcmBuffer.addAll(chunk);

          // Calculate instant RMS
          final rms = _calculateRmsFromBytes(chunk);
          onRmsUpdate?.call(rms);

          if (pcmBuffer.length >= targetByteCount) {
            final windowBytes = pcmBuffer.sublist(0, targetByteCount);
            pcmBuffer.removeRange(0, (targetByteCount * 0.5).toInt()); // 50% overlap

            final double windowRms = _calculateRmsFromBytes(windowBytes);

            // Energy Gating: Skip inference if sound energy is below RMS threshold
            if (windowRms >= rmsGateThreshold) {
              _processAudioWindow(windowBytes);
            }
          }
        });
      } catch (_) {
        _startSimulatedStream();
      }
    } else {
      _startSimulatedStream();
    }
  }

  void _startSimulatedStream() {
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (!_isListening) return;
      final randRms = 0.005 + (Random().nextDouble() * 0.04);
      onRmsUpdate?.call(randRms);

      if (randRms >= rmsGateThreshold) {
        _processSimulatedDetection();
      }
    });
  }

  double _calculateRmsFromBytes(List<int> bytes) {
    if (bytes.isEmpty) return 0.0;
    double sum = 0.0;
    int count = bytes.length ~/ 2;
    final byteData = ByteData.sublistView(Uint8List.fromList(bytes));

    for (int i = 0; i < count; i++) {
      int sample = byteData.getInt16(i * 2, Endian.little);
      double normalized = sample / 32768.0;
      sum += normalized * normalized;
    }

    return sqrt(sum / (count > 0 ? count : 1));
  }

  Future<void> _processAudioWindow(List<int> windowBytes) async {
    final int sampleCount = windowBytes.length ~/ 2;
    final byteData = ByteData.sublistView(Uint8List.fromList(windowBytes));
    final List<double> floatBuffer = List.filled(sampleCount, 0.0);

    for (int i = 0; i < sampleCount; i++) {
      floatBuffer[i] = byteData.getInt16(i * 2, Endian.little) / 32768.0;
    }

    final prediction = await ClassifierService.instance.classify(floatBuffer);
    await _handlePrediction(prediction);
  }

  Future<void> _processSimulatedDetection([String? manualClass]) async {
    final prediction = await ClassifierService.instance.classify([], injectedClass: manualClass);
    await _handlePrediction(prediction);
  }

  Future<void> injectManualSound(String soundClass) async {
    final prediction = await ClassifierService.instance.classify([], injectedClass: soundClass);
    await _handlePrediction(prediction);
  }

  Future<void> _handlePrediction(PredictionResult prediction) async {
    final currentZone = await GeofenceService.instance.determineCurrentZone();
    final timeLabel = TemporalService.instance.getTimeOfDayLabel();
    final position = await GeofenceService.instance.getCurrentPosition();

    final caspa = CaspaEngine.instance.evaluate(
      soundClass: prediction.label,
      confidence: prediction.confidence,
      currentZone: currentZone,
    );

    final event = AcousticEvent(
      timestamp: DateTime.now(),
      soundClass: prediction.label,
      confidence: prediction.confidence,
      priorityScore: caspa.score,
      priorityTier: caspa.tier,
      latitude: position?.latitude,
      longitude: position?.longitude,
      geofenceZone: currentZone,
      timeOfDayLabel: timeLabel,
    );

    // 1. Log to SQLite Acoustic Event Journal
    await DatabaseService.instance.insertEvent(event);

    // 2. Trigger Multi-Modal Haptic / Visual Alert
    await AlertDispatchService.instance.triggerAlert(
      priorityTier: caspa.tier,
      soundClass: event.soundClass,
    );

    // 3. Notify UI
    onDetection?.call(event, caspa);
  }

  Future<void> stopListening() async {
    _isListening = false;
    _simulationTimer?.cancel();
    await _audioStreamSub?.cancel();
    await _audioRecorder.stop();
  }
}
