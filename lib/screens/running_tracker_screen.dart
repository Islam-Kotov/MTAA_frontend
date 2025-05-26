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
import 'package:semestral_project/utils.dart';

class RunningTrackerScreen extends StatefulWidget {
  final bool isTesting; // Added for test mode

  const RunningTrackerScreen({
    super.key,
    this.isTesting = false, //  default is false
  });

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
  bool _gpsEnabled = true;

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

    if (widget.isTesting) {
      // Immediately render full UI in test mode
      setState(() {
        _gpsEnabled = true;
        _isMapReady = true;
        _isRunning = false;
        _currentLatLng = const LatLng(48.0, 17.0); // dummy value to avoid map failure
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
    }
  }


  Future<void> _initialize() async {
    if (widget.isTesting) {
      setState(() {
        _gpsEnabled = true;
        _isMapReady = true;
        _isRunning = false;
      });
      return;
    }

    final permissionStatus = await _location.hasPermission();
    if (permissionStatus == PermissionStatus.denied) {
      final request = await _location.requestPermission();
      if (request != PermissionStatus.granted) {
        setState(() => _gpsEnabled = false);
        return;
      }
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
    await _location.changeSettings(accuracy: LocationAccuracy.high, interval: 1000, distanceFilter: 1);
    _locationSubscription = _location.onLocationChanged.listen((newLocation) {
      final newLatLng = LatLng(newLocation.latitude!, newLocation.longitude!);
      if (_isRunning && _lastLocation != null) {
        final d = calculateDistance(
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
    });
  }

  void _startRun() {
    if (_isRunning) return;
    _resetRun();
    _isRunning = true;
    _stopwatch.start();
    _startTimer();
    _startLocationTracking();
  }

  void _stopRun() async {
    _isRunning = false;
    _stopwatch.stop();
    _locationSubscription?.cancel();
    _motivationTimer?.cancel();

    // if (_distance == 0.0) {
    //   _resetRun();
    //   return;
    // }

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Save run?"),
        content: const Text("Do you want to save this run?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Yes")),
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("No")),
        ],
      ),
    );

    if (shouldSave == true) {
      await _submitRun();
    } else {
      _resetRun();
    }
  }

  void _resetRun() {
    _stopwatch.reset();
    _locationSubscription?.cancel();
    _motivationTimer?.cancel();
    _initialStepCount = null;
    if (!mounted) return;
    setState(() {
      _isRunning = false;
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
    if (seconds == 0 || _distance == 0.0) {
      debugPrint("Run has 0 distance or 0 time — still submitting.");
    }

    final avgSpeed = (_distance / 1000) / (seconds / 3600);
    final startTime = DateTime.now().subtract(_stopwatch.elapsed).toIso8601String();
    final routeJson = _routeCoords.map((coord) => {'lat': coord.latitude, 'lng': coord.longitude}).toList();

    final response = await http.post(
      Uri.parse('http://147.175.162.111:8000/api/runs'),
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
      if (!mounted) return;
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
        setState(() => _elapsedTime = formatDuration(_stopwatch.elapsed));
      }
    });
  }

  String _averageSpeedText() {
    return calculateAverageSpeed(_distance, _stopwatch.elapsed);
  }

  // double _calculateDistance(LocationData last, LocationData current) {
  //   const R = 6371000;
  //   final dLat = _degToRad(current.latitude! - last.latitude!);
  //   final dLon = _degToRad(current.longitude! - last.longitude!);
  //   final a = sin(dLat / 2) * sin(dLat / 2) +
  //       cos(_degToRad(last.latitude!)) *
  //           cos(_degToRad(current.latitude!)) *
  //           sin(dLon / 2) *
  //           sin(dLon / 2);
  //   final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  //   return R * c;
  // }
  //
  // double _degToRad(double deg) => deg * (pi / 180);

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Running Tracker')),
      body: !_gpsEnabled
          ? Center(
        child: Text(
          'Please enable GPS to start your run.',
          style: theme.textTheme.bodyLarge,
        ),
      )
          : !_isMapReady
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 700;
          return Column(
            children: [
              if (_showMotivation)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.orange.shade200,
                  child: const Text(
                    "Keep going! Maintain your pace!",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              Expanded(
                child: isTablet
                    ? Row(
                  children: [
                    Expanded(
                      flex: 3,
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
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildTrackerCard(theme),
                      ),
                    ),
                  ],
                )
                    : SingleChildScrollView(
                  child: Column(
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
                        child: _buildTrackerCard(theme),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTrackerCard(ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _infoTile("Time", _elapsedTime),
            _infoTile("Distance", "${(_distance / 1000).toStringAsFixed(2)} km"),
            _infoTile("Average Speed", _averageSpeedText()),
            _infoTile("Steps", "$_steps"),
            _infoTile("Acceleration", _accelerationText),
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
            const SizedBox(height: 20),
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.history),
                label: const Text('View Run History'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RunHistoryScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}