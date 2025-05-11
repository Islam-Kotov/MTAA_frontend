import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:pedometer/pedometer.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RunningTrackerScreen extends StatefulWidget {
  const RunningTrackerScreen({super.key});

  @override
  State<RunningTrackerScreen> createState() => _RunningTrackerScreenState();
}

class _RunningTrackerScreenState extends State<RunningTrackerScreen> {
  int _steps = 0;
  StreamSubscription<StepCount>? _stepSubscription;

  final Location _location = Location();
  StreamSubscription<LocationData>? _locationSubscription;
  LocationData? _lastLocation;
  double _distance = 0.0;

  Stopwatch _stopwatch = Stopwatch();
  late Timer _timer;
  String _elapsedTime = "00:00";

  bool _isRunning = false;
  bool _isMapReady = false;

  GoogleMapController? _mapController;
  LatLng _currentLatLng = const LatLng(0, 0);
  final Set<Polyline> _polylines = {};
  final List<LatLng> _routeCoords = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final permissionStatus = await _location.hasPermission();
    debugPrint("🔍 Permission status: $permissionStatus");

    if (permissionStatus == PermissionStatus.denied) {
      final request = await _location.requestPermission();
      debugPrint("📡 Permission requested: $request");

      if (request != PermissionStatus.granted) {
        debugPrint("❌ Permission not granted");
        return;
      }
    }

    final currentLocation = await _location.getLocation();
    debugPrint("📍 Current location: ${currentLocation.latitude}, ${currentLocation.longitude}");

    setState(() {
      _currentLatLng = LatLng(currentLocation.latitude!, currentLocation.longitude!);
      _isMapReady = true;
    });

    _startStepCounting();
  }

  void _startStepCounting() {
    _stepSubscription = Pedometer.stepCountStream.listen((event) {
      debugPrint("👣 Step event: ${event.steps}");
      if (_isRunning) {
        setState(() {
          _steps = event.steps;
        });
      }
    }, onError: (e) {
      debugPrint("❌ Step counter error: $e");
    });
  }

  void _startLocationTracking() {
    _locationSubscription = _location.onLocationChanged.listen((newLocation) {
      debugPrint("📡 New location: ${newLocation.latitude}, ${newLocation.longitude}");
      final newLatLng = LatLng(newLocation.latitude!, newLocation.longitude!);
      if (_isRunning && _lastLocation != null) {
        final d = _calculateDistance(
          _lastLocation!.latitude!,
          _lastLocation!.longitude!,
          newLocation.latitude!,
          newLocation.longitude!,
        );
        setState(() {
          _distance += d;
          _routeCoords.add(newLatLng);
          _polylines.clear();
          _polylines.add(Polyline(
            polylineId: const PolylineId("route"),
            points: _routeCoords,
            color: Colors.blue,
            width: 5,
          ));
        });
        _mapController?.animateCamera(CameraUpdate.newLatLng(newLatLng));
      }
      _lastLocation = newLocation;
      setState(() => _currentLatLng = newLatLng);
    }, onError: (e) {
      debugPrint("❌ Location tracking error: $e");
    });
  }

  void _startRun() {
    debugPrint("▶️ Starting run");
    _isRunning = true;
    _stopwatch.start();
    _startTimer();
    _startLocationTracking();
  }

  void _stopRun() {
    debugPrint("⏹ Stopping run");
    _isRunning = false;
    _stopwatch.stop();
    _locationSubscription?.cancel();
  }

  void _resetRun() {
    debugPrint("🔁 Resetting run");
    setState(() {
      _isRunning = false;
      _steps = 0;
      _distance = 0.0;
      _elapsedTime = "00:00";
      _routeCoords.clear();
      _polylines.clear();
    });
    _stopwatch.reset();
    _locationSubscription?.cancel();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_stopwatch.isRunning) {
        final elapsed = _stopwatch.elapsed;
        setState(() {
          _elapsedTime = _formatDuration(elapsed);
        });
      }
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);

  @override
  void dispose() {
    _timer.cancel();
    _locationSubscription?.cancel();
    _stepSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(207, 228, 242, 1),
      appBar: AppBar(
        title: const Text('Running Tracker'),
        backgroundColor: const Color.fromRGBO(57, 132, 173, 1),
      ),
      body: !_isMapReady
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          SizedBox(
            height: 300,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentLatLng,
                zoom: 16,
              ),
              onMapCreated: (controller) => _mapController = controller,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              polylines: _polylines,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoTile("⏱ Time", _elapsedTime),
                _infoTile("📏 Distance", "${(_distance / 1000).toStringAsFixed(2)} km"),
                _infoTile("👟 Steps", "$_steps"),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _isRunning ? _stopRun : _startRun,
                      child: Text(_isRunning ? 'Stop' : 'Start'),
                    ),
                    ElevatedButton(
                      onPressed: _resetRun,
                      child: const Text('Reset'),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
