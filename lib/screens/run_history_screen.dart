import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/semantics.dart';
import 'run_map_screen.dart';

class RunHistoryScreen extends StatefulWidget {
  const RunHistoryScreen({super.key});

  @override
  State<RunHistoryScreen> createState() => _RunHistoryScreenState();
}

class _RunHistoryScreenState extends State<RunHistoryScreen> {
  List<dynamic> _runs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchRuns();
  }

  Future<void> _fetchRuns() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');
    if (token == null) return;

    final response = await http.get(
      Uri.parse('http://192.168.1.36:8000/api/runs'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _runs = json.decode(response.body);
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      debugPrint("Failed to load runs: ${response.body}");
    }
  }

  String _formatDuration(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '${min}m ${sec}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Run History')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _runs.isEmpty
          ? const Center(child: Text('No runs found.'))
          : LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 700;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _runs.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isTablet ? 2 : 1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isTablet ? 2.8 : 2.2,
            ),
            itemBuilder: (context, index) {
              final run = _runs[index];
              final startedAt = DateTime.parse(run['started_at']);
              final formattedDate = DateFormat.yMMMd().add_Hm().format(startedAt);
              final label =
                  'Run on $formattedDate, Distance ${(run['distance'] / 1000).toStringAsFixed(2)} kilometers, Duration ${_formatDuration(run['duration'])}, Average speed ${run['avg_speed'].toStringAsFixed(2)} kilometers per hour, Steps ${run['steps']}${run['route'] != null ? ", tap to view route on map" : ""}';

              return Semantics(
                button: true,
                label: label,
                child: ExcludeSemantics(
                  child: InkWell(
                    onTap: () {
                      if (run['route'] != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RunMapScreen(
                              routeJson: jsonEncode(run['route']),
                            ),
                          ),
                        );
                      }
                    },
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formattedDate,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text("Distance: ${(run['distance'] / 1000).toStringAsFixed(2)} km"),
                            Text("Duration: ${_formatDuration(run['duration'])}"),
                            Text("Avg Speed: ${run['avg_speed'].toStringAsFixed(2)} km/h"),
                            Text("Steps: ${run['steps']}"),
                            if (run['route'] != null)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  "Tap to view route on map",
                                  style: TextStyle(fontSize: 14, color: Colors.blue),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
