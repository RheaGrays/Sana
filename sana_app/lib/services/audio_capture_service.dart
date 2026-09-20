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
  double rmsGateThreshold = 0.015; // Responsive threshold
  OnDetectionCallback? onDetection;
  OnRmsUpdateCallback? onRmsUpdate;

  // Rolling Ring Buffer (15,600 samples = 0.975s @ 16kHz)
  static const int _targetSampleCount = 15600;
  final List<double> _rollingAudioBuffer = List<double>.filled(_targetSampleCount, 0.0);
  int _bufferWriteIndex = 0;
  DateTime _lastInferenceTime = DateTime.fromMillisecondsSinceEpoch(0);

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

        _audioStreamSub = stream.listen((chunk) {
          if (!_isListening) return;

          final sampleCount = chunk.length ~/ 2;
          final byteData = ByteData.sublistView(Uint8List.fromList(chunk));
          double sumSquares = 0.0;

          // Ingest incoming PCM chunk into rolling ring buffer
          for (int i = 0; i < sampleCount; i++) {
            final sample = byteData.getInt16(i * 2, Endian.little) / 32768.0;
            _rollingAudioBuffer[_bufferWriteIndex] = sample;
            _bufferWriteIndex = (_bufferWriteIndex + 1) % _targetSampleCount;
            sumSquares += sample * sample;
          }

          final instantRms = sqrt(sumSquares / (sampleCount > 0 ? sampleCount : 1));
          onRmsUpdate?.call(instantRms);

          // Fast Energy Trigger: if RMS exceeds gate and 350ms cooldown has elapsed
          final now = DateTime.now();
          if (instantRms >= rmsGateThreshold && now.difference(_lastInferenceTime).inMilliseconds > 350) {
            _lastInferenceTime = now;
            _dispatchInference();
          }
        });
      } catch (_) {
        _startSimulatedStream();
      }
    } else {
      _startSimulatedStream();
    }
  }

  void _dispatchInference() async {
    // Reconstruct ordered 15,600 samples from ring buffer
    final List<double> orderedBuffer = List<double>.filled(_targetSampleCount, 0.0);
    for (int i = 0; i < _targetSampleCount; i++) {
      orderedBuffer[i] = _rollingAudioBuffer[(_bufferWriteIndex + i) % _targetSampleCount];
    }

    final prediction = await ClassifierService.instance.classify(orderedBuffer);
    
    // Ignore ambient quiet noise from creating disruptive alerts
    if (prediction.label == "Ambient / Background Noise" && prediction.confidence < 0.70) {
      return;
    }

    await _handlePrediction(prediction);
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
