import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/Attendance/LocationModel.dart';
import '../../utils/constants.dart';
import '../../utils/haversine.dart';

/// SAMS-PACK-309 — GPS permission and UMPSA campus geofence verification.
class LocationVerification extends ChangeNotifier {
  final FirebaseFirestore _db;
  bool _isDisposed = false;

  LocationVerification({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  bool _hasPermission = false;
  bool _isOnCampus = false;
  bool _isChecking = false;
  String? _statusMessage;
  LocationModel? _activeLocation;
  double? _currentLatitude;
  double? _currentLongitude;
  double? _lastDistanceMeters;

  bool get hasPermission => _hasPermission;
  bool get isOnCampus => _isOnCampus;
  bool get isChecking => _isChecking;
  String? get statusMessage => _statusMessage;
  LocationModel? get activeLocation => _activeLocation;
  double? get currentLatitude => _currentLatitude;
  double? get currentLongitude => _currentLongitude;
  double? get lastDistanceMeters => _lastDistanceMeters;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  /// Requests and verifies GPS permissions from the user.
  Future<bool> checkGPSPermission() async {
    _isChecking = true;
    notifyListeners();

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _hasPermission = false;
        _statusMessage = 'Location services are disabled';
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission()
            .timeout(const Duration(seconds: 10));
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        _hasPermission = false;
        _statusMessage = 'Location permission denied';
        return false;
      }

      _hasPermission = true;
      _statusMessage = 'GPS permission granted';
      return true;
    } catch (e) {
      _statusMessage = 'Permission check failed: $e';
      return false;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  /// Loads campus geofences from Firestore, with hardcoded fallbacks if empty.
  Future<List<LocationModel>> _loadAllActiveCampusLocations() async {
    try {
      final snapshot = await _db
          .collection(FirestoreCollections.locations)
          .where('is_active', isEqualTo: true)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => LocationModel.fromMap(doc.data())).toList();
      }
    } catch (e) {
      debugPrint('SAMS_DEBUG: Firestore locations fetch failed, using fallbacks.');
    }

    // Fallback Hardcoded UMPSA Locations (Ensures functionality even if Firestore is empty)
    return [
      const LocationModel(
        locationId: 'LOC_PEKAN',
        campusName: 'UMPSA Pekan',
        centerLatitude: 3.5437,
        centerLongitude: 103.4288,
        allowedMeter: 2000.0, // Increased tolerance for testing
        isActive: true,
      ),
      const LocationModel(
        locationId: 'LOC_GAMBANG',
        campusName: 'UMPSA Gambang',
        centerLatitude: 3.7169,
        centerLongitude: 103.1232,
        allowedMeter: 1500.0,
        isActive: true,
      ),
    ];
  }

  /// Verifies if the student's current GPS position is within the UMPSA campus area.
  Future<bool> verifyCurrentLocation() async {
    if (_isChecking) return false;
    _isChecking = true;
    _isOnCampus = false;
    _lastDistanceMeters = null;
    notifyListeners();

    try {
      if (!_hasPermission) {
        final granted = await checkGPSPermission();
        if (!granted) return false;
      }

      // Get position with high accuracy and timeout protection
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      _currentLatitude = position.latitude;
      _currentLongitude = position.longitude;

      // Verify against UMPSA Campus Geofences
      final campuses = await _loadAllActiveCampusLocations();
      debugPrint('SAMS_DEBUG: Checking against ${campuses.length} UMPSA geofences.');

      double minDistance = double.infinity;
      LocationModel? closestCampus;

      for (final campus in campuses) {
        final dist = haversineDistanceMeters(
          lat1: position.latitude,
          lon1: position.longitude,
          lat2: campus.centerLatitude,
          lon2: campus.centerLongitude,
        );

        if (dist < minDistance) {
          minDistance = dist;
          closestCampus = campus;
        }

        if (dist <= campus.allowedMeter) {
          _isOnCampus = true;
          _activeLocation = campus;
          _lastDistanceMeters = dist;
          _statusMessage = 'On Campus (Verified) — ${campus.campusName}';
          debugPrint('SAMS_DEBUG: Location Verified inside ${campus.campusName}');
          return true;
        }
      }

      // If not in any campus
      _activeLocation = closestCampus;
      _lastDistanceMeters = minDistance;
      _statusMessage = closestCampus != null
          ? 'Outside campus — ${minDistance.toStringAsFixed(0)}m from ${closestCampus.campusName}'
          : 'Outside defined campus area.';
      
      debugPrint('SAMS_DEBUG: ${_statusMessage}');

      return false;
    } catch (e) {
      _statusMessage = 'Location verification failed: $e';
      debugPrint('SAMS_ERROR: verifyCurrentLocation: $e');
      return false;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }
}
