import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:pedometer/pedometer.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'run_history_screen.dart';

class RunningTrackerScreen extends StatefulWidget {
  const RunningTrackerScreen({super.key});

  @override
  State<RunningTrackerScreen> createState() => _RunningTrackerScreenState();
}

class _RunningTrackerScreenState extends State<RunningTrackerScreen> {
  int _steps = 0;
  int? _initialStepCount;
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
    if (permissionStatus == PermissionStatus.denied) {
      final request = await _location.requestPermission();
      if (request != PermissionStatus.granted) return;
    }

    final currentLocation = await _location.getLocation();
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
      if (!mounted) return;
      if (_initialStepCount == null) {
        _initialStepCount = event.steps;
      }
      setState(() => _steps = event.steps - _initialStepCount!);
    });
  }

  void _startAccelerometer() {
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (!mounted) return;
      setState(() => _accelerationText = "X: ${event.x.toStringAsFixed(2)}, Y: ${event.y.toStringAsFixed(2)}, Z: ${event.z.toStringAsFixed(2)}");
      if (!_isRunning && magnitude > 14.0) _startRun();
      if (_isRunning && magnitude > 14.5) {
        setState(() => _showMotivation = true);
        _motivationTimer?.cancel();
        _motivationTimer = Timer(const Duration(seconds: 10), () {
          if (mounted) setState(() => _showMotivation = false);
        });
      }
    });
  }

  void _startLocationTracking() async {
    await _location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 1000,
      distanceFilter: 1,
    );

    _locationSubscription = _location.onLocationChanged.listen((newLocation) {
      final newLatLng = LatLng(newLocation.latitude!, newLocation.longitude!);
      if (_isRunning && _lastLocation != null) {
        final d = _calculateDistance(_lastLocation!, newLocation);
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
    });
  }

  void _startRun() {
    if (_isRunning) return;
    _isRunning = true;
    _stopwatch.start();
    _startTimer();
    _startLocationTracking();
  }

  void _stopRun() {
    _isRunning = false;
    _stopwatch.stop();
    _locationSubscription?.cancel();
    _motivationTimer?.cancel();
    _submitRun();
  }

  void _resetRun() {
    _isRunning = false;
    _stopwatch.reset();
    _locationSubscription?.cancel();
    _motivationTimer?.cancel();
    _initialStepCount = null;
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

  Future<void> _submitRun() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');
    if (token == null) return;

    final seconds = _stopwatch.elapsed.inSeconds;
    if (seconds == 0 || _distance == 0.0) return;

    final avgSpeed = (_distance / 1000) / (seconds / 3600);
    final startTime = DateTime.now().subtract(_stopwatch.elapsed).toIso8601String();

    final routeJson = _routeCoords
        .map((coord) => {'lat': coord.latitude, 'lng': coord.longitude})
        .toList();

    final response = await http.post(
      Uri.parse('http://192.168.1.36:8000/api/runs'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: json.encode({
        "distance": _distance,
        "steps": _steps,
        "duration": seconds,
        "avg_speed": avgSpeed,
        "started_at": startTime,
        "route": routeJson,
      }),
    );

    if (response.statusCode == 201) {
      _resetRun();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Run saved successfully!')),
      );
    } else {
      debugPrint("Failed to save run: ${response.body}");
    }
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

  String _averageSpeedText() {
    final seconds = _stopwatch.elapsed.inSeconds;
    if (seconds < 5 || _distance < 5.0) return "0.00 km/h";
    final hours = seconds / 3600;
    final km = _distance / 1000;
    final speed = km / hours;
    return "${speed.toStringAsFixed(2)} km/h";
  }

  double _calculateDistance(LocationData last, LocationData current) {
    const R = 6371000;
    final dLat = _degToRad(current.latitude! - last.latitude!);
    final dLon = _degToRad(current.longitude! - last.longitude!);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(last.latitude!)) *
            cos(_degToRad(current.latitude!)) *
            sin(dLon / 2) *
            sin(dLon / 2);
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
      appBar: AppBar(title: const Text('Running Tracker')),
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
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          SizedBox(
            height: 300,
            child: GoogleMap(
              initialCameraPosition:
              CameraPosition(target: _currentLatLng, zoom: 16),
              onMapCreated: (controller) => _mapController = controller,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              polylines: _polylines,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoTile("Time", _elapsedTime),
                    _infoTile("Distance",
                        "${(_distance / 1000).toStringAsFixed(2)} km"),
                    _infoTile("Avg Speed", _averageSpeedText()),
                    _infoTile("Steps", "$_steps"),
                    _infoTile("Accel", _accelerationText),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed:
                          _isRunning ? _stopRun : _startRun,
                          child:
                          Text(_isRunning ? 'Stop' : 'Start'),
                        ),
                        ElevatedButton(
                          onPressed: _resetRun,
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton.icon(
                        icon: const Icon(Icons.history),
                        label: const Text('View Run History'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                const RunHistoryScreen()),
                          );
                        },
                      ),
                    )
                  ],
                ),
              ),
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
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value,
              style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
