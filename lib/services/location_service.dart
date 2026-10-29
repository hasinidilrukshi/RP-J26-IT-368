import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

enum LocationStatus { searching, ready, serviceOff, denied, deniedForever, error }

/// Gets the GPS position AUTOMATICALLY when the app opens and keeps it fresh,
/// so the tourist never has to do anything for the location to be sent.
class LocationService extends ChangeNotifier {
  LocationService._();
  static final LocationService instance = LocationService._();

  Position? _position;
  LocationStatus _status = LocationStatus.searching;
  StreamSubscription<Position>? _sub;
  bool _starting = false;

  Position? get position => _position;
  LocationStatus get status => _status;
  bool get hasFix => _position != null;

  /// Human-readable status for the location chip.
  String get statusText {
    switch (_status) {
      case LocationStatus.searching:
        return _position == null
            ? 'Finding your location…'
            : 'Location found ±${_position!.accuracy.toStringAsFixed(0)} m';
      case LocationStatus.ready:
        return 'Location ready ±${_position!.accuracy.toStringAsFixed(0)} m';
      case LocationStatus.serviceOff:
        return 'GPS is off – tap to turn on';
      case LocationStatus.denied:
        return 'Location not allowed – tap to allow';
      case LocationStatus.deniedForever:
        return 'Location blocked – tap to open settings';
      case LocationStatus.error:
        return _position == null
            ? 'Location not available – tap to retry'
            : 'Using last known location';
    }
  }

  void _set(LocationStatus s) {
    _status = s;
    notifyListeners();
  }

  void _update(Position p) {
    // keep the new point if it is the first one, more accurate, or newer
    final old = _position;
    if (old == null ||
        p.accuracy <= old.accuracy * 1.5 ||
        p.timestamp.difference(old.timestamp).inSeconds > 30) {
      _position = p;
    }
    _status = LocationStatus.ready;
    notifyListeners();
  }

  /// Called once in main(). Safe to call again (e.g. after the user turns GPS on).
  Future<void> start() async {
    if (_starting) return;
    _starting = true;
    try {
      _set(LocationStatus.searching);

      if (!await Geolocator.isLocationServiceEnabled()) {
        _set(LocationStatus.serviceOff);
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        _set(LocationStatus.deniedForever);
        return;
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.unableToDetermine) {
        _set(LocationStatus.denied);
        return;
      }

      // 1) last known point -> something to send immediately
      if (!kIsWeb) {
        try {
          final last = await Geolocator.getLastKnownPosition();
          if (last != null) {
            _position = last;
            notifyListeners();
          }
        } catch (_) {/* not supported on some platforms */}
      }

      // 2) a fresh, accurate fix
      try {
        final p = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 20),
          ),
        );
        _update(p);
      } catch (_) {
        if (_position == null) {
          _set(LocationStatus.error);
        }
      }

      // 3) keep it updated while the app is open (tourist may be moving)
      await _sub?.cancel();
      _sub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 15,
        ),
      ).listen(_update, onError: (_) {
        if (_position == null) _set(LocationStatus.error);
      });
    } catch (_) {
      _set(LocationStatus.error);
    } finally {
      _starting = false;
    }
  }

  /// Waits a short time for a first GPS fix (used when SOS is pressed
  /// before the GPS is ready). Never waits longer than [max].
  Future<Position?> waitForFix(
      {Duration max = const Duration(seconds: 6)}) async {
    if (_position != null) return _position;
    if (_status != LocationStatus.searching) return null;
    final done = Completer<Position?>();
    void listener() {
      if (_position != null && !done.isCompleted) done.complete(_position);
    }

    addListener(listener);
    final result = await done.future
        .timeout(max, onTimeout: () => _position);
    removeListener(listener);
    return result;
  }

  /// What to do when the tourist taps the location chip.
  Future<void> fix() async {
    switch (_status) {
      case LocationStatus.serviceOff:
        await Geolocator.openLocationSettings();
        break;
      case LocationStatus.deniedForever:
        await Geolocator.openAppSettings();
        break;
      default:
        break;
    }
    await start();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
