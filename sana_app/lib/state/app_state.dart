import 'package:flutter/material.dart';
import '../models/acoustic_event.dart';
import '../services/audio_capture_service.dart';
import '../services/classifier_service.dart';
import '../services/database_service.dart';
import '../services/apma_engine.dart';
import '../services/caspa_engine.dart';
import '../services/geofence_service.dart';

class AppState extends ChangeNotifier {
  bool _isMonitoring = false;
  double _currentRms = 0.0;
  AcousticEvent? _latestEvent;
  CaspaResult? _latestCaspa;
  List<AcousticEvent> _recentEvents = [];
  String _currentZone = 'Home';

  // APMA state
  Map<int, double> _hourlyDensity = {};
  List<AnomalyReport> _anomalies = [];
  List<SequenceRule> _sequenceRules = [];
  bool _isLoadingAnalytics = false;

  // Visual Strobe state for High/Medium alerts
  bool _isFlashingAlert = false;
  Color _flashColor = Colors.transparent;

  // Getters
  bool get isMonitoring => _isMonitoring;
  double get currentRms => _currentRms;
  AcousticEvent? get latestEvent => _latestEvent;
  CaspaResult? get latestCaspa => _latestCaspa;
  List<AcousticEvent> get recentEvents => _recentEvents;
  String get currentZone => _currentZone;
  Map<int, double> get hourlyDensity => _hourlyDensity;
  List<AnomalyReport> get anomalies => _anomalies;
  List<SequenceRule> get sequenceRules => _sequenceRules;
  bool get isLoadingAnalytics => _isLoadingAnalytics;
  bool get isFlashingAlert => _isFlashingAlert;
  Color get flashColor => _flashColor;

  AppState() {
    _init();
  }

  Future<void> _init() async {
    await ClassifierService.instance.initialize();
    await refreshJournal();
    await updateCurrentZone();
    await refreshAnalytics();

    AudioCaptureService.instance.onRmsUpdate = (rms) {
      _currentRms = rms;
      notifyListeners();
    };

    AudioCaptureService.instance.onDetection = (event, caspa) {
      _latestEvent = event;
      _latestCaspa = caspa;
      _recentEvents.insert(0, event);
      if (_recentEvents.length > 200) {
        _recentEvents.removeLast();
      }

      if (caspa.tier == 'HIGH') {
        _triggerScreenFlash(Colors.redAccent);
      } else if (caspa.tier == 'MEDIUM') {
        _triggerScreenFlash(Colors.amberAccent);
      }

      notifyListeners();
    };
  }

  void _triggerScreenFlash(Color color) {
    _isFlashingAlert = true;
    _flashColor = color.withValues(alpha: 0.35);
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 900), () {
      _isFlashingAlert = false;
      notifyListeners();
    });
  }

  Future<void> toggleMonitoring() async {
    if (_isMonitoring) {
      await AudioCaptureService.instance.stopListening();
      _isMonitoring = false;
    } else {
      await AudioCaptureService.instance.startListening();
      _isMonitoring = true;
    }
    notifyListeners();
  }

  Future<void> triggerTestSound(String soundClass) async {
    await AudioCaptureService.instance.injectManualSound(soundClass);
    await refreshAnalytics();
  }

  Future<void> updateCurrentZone() async {
    _currentZone = await GeofenceService.instance.determineCurrentZone();
    notifyListeners();
  }

  Future<void> refreshJournal({String? filterClass, String? filterTier}) async {
    _recentEvents = await DatabaseService.instance.filterEvents(
      soundClass: filterClass,
      priorityTier: filterTier,
    );
    notifyListeners();
  }

  Future<void> refreshAnalytics() async {
    _isLoadingAnalytics = true;
    notifyListeners();

    _hourlyDensity = await ApmaEngine.instance.computeHourlyDistribution();
    _anomalies = await ApmaEngine.instance.detectAnomalies();
    _sequenceRules = await ApmaEngine.instance.mineSequentialPatterns();

    _isLoadingAnalytics = false;
    notifyListeners();
  }

  Future<void> clearJournal() async {
    await DatabaseService.instance.clearAllEvents();
    _recentEvents.clear();
    _latestEvent = null;
    _latestCaspa = null;
    await refreshAnalytics();
    notifyListeners();
  }
}
