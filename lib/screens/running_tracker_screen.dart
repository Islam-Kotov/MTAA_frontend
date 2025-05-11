import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:pedometer/pedometer.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sensors_plus/sensors_plus.dart';

class RunningTrackerScreen extends StatefulWidget {
  const RunningTrackerScreen({super.key});

  @override
  State<RunningTrackerScreen> createState() => _RunningTrackerScreenState();
}

class _RunningTrackerScreenState extends State<RunningTrackerScreen> {
  int _steps = 0;
  double _distance = 0.0;
  String _elapsedTime = "00:00";
  String _accelerationText = "X: 0.0, Y: 0.0, Z: 0.0";
  bool _showMotivation = false;

  final Location _location = Location();
  LocationData? _lastLocation;
  StreamSubscription<LocationData>? _locationSubscription;
  StreamSubscription<StepCount>? _stepSubscription;
  StreamSubscription? _accelerometerSubscription;

  GoogleMapController? _mapController;
  LatLng _currentLatLng = const LatLng(0, 0);
  final Set<Polyline> _polylines = {};
  final List<LatLng> _routeCoords = [];

  Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  Timer? _motivationTimer;
  bool _isRunning = false;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    final permissionStatus = await _location.hasPermission();
    debugPrint("🔍 Permission status: $permissionStatus");

    if (permissionStatus == PermissionStatus.denied) {
      final request = await _location.requestPermission();
      debugPrint("📡 Permission requested: $request");
      if (request != PermissionStatus.granted) return;
    }

    final currentLocation = await _location.getLocation();
    debugPrint("📍 Current location: ${currentLocation.latitude}, ${currentLocation.longitude}");

    if (!mounted) return;
    setState(() {
      _currentLatLng = LatLng(currentLocation.latitude!, currentLocation.longitude!);
      _isMapReady = true;
    });

    _startStepCounting();
    _startAccelerometer();
  }

  void _startStepCounting() {
    _stepSubscription = Pedometer.stepCountStream.listen((event) {
      debugPrint("👣 Step event: ${event.steps}");
      if (!mounted) return;
      setState(() => _steps = event.steps);
    }, onError: (e) => debugPrint("❌ Step counter error: $e"));
  }

  void _startAccelerometer() {
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      final ax = event.x.toStringAsFixed(2);
      final ay = event.y.toStringAsFixed(2);
      final az = event.z.toStringAsFixed(2);

      if (!mounted) return;
      setState(() => _accelerationText = "X: $ax, Y: $ay, Z: $az");

      final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (!_isRunning && magnitude > 14.0) {
        debugPrint("🏃 Motion detected via accelerometer, starting run");
        _startRun();
      }

      if (_isRunning && magnitude > 14.5) {
        if (!mounted) return;
        setState(() => _showMotivation = true);
        _motivationTimer?.cancel();
        _motivationTimer = Timer(const Duration(seconds: 10), () {
          if (mounted) setState(() => _showMotivation = false);
        });
      }
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
        if (!mounted) return;
        setState(() {
          _distance += d;
          _routeCoords.add(newLatLng);
          _polylines
            ..clear()
            ..add(Polyline(
              polylineId: const PolylineId("route"),
              points: _routeCoords,
              color: Colors.blue,
              width: 5,
            ));
        });
        _mapController?.animateCamera(CameraUpdate.newLatLng(newLatLng));
      }
      _lastLocation = newLocation;
      if (!mounted) return;
      setState(() => _currentLatLng = newLatLng);
    }, onError: (e) => debugPrint("❌ Location tracking error: $e"));
  }

  void _startRun() {
    if (_isRunning) return;
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
    _motivationTimer?.cancel();
  }

  void _resetRun() {
    debugPrint("🔁 Resetting run");
    _isRunning = false;
    _stopwatch.reset();
    _locationSubscription?.cancel();
    _motivationTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _steps = 0;
      _distance = 0.0;
      _elapsedTime = "00:00";
      _routeCoords.clear();
      _polylines.clear();
      _showMotivation = false;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_stopwatch.isRunning && mounted) {
        setState(() => _elapsedTime = _formatDuration(_stopwatch.elapsed));
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
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);

  @override
  void dispose() {
    _timer?.cancel();
    _locationSubscription?.cancel();
    _stepSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _motivationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Running Tracker'),
      ),
      body: !_isMapReady
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_showMotivation)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Colors.orange.shade200,
                    child: const Text(
                      "🏃‍♂️ Keep going! Maintain your pace!",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
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
                      _infoTile("🎯 Accel", _accelerationText),
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
                      ),
                    ],
                  ),
                ),
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