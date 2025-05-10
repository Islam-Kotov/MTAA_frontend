import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';

class PredefinedLevelsScreen extends StatefulWidget {
  const PredefinedLevelsScreen({super.key});

  @override
  State<PredefinedLevelsScreen> createState() => _PredefinedLevelsScreenState();
}

class _PredefinedLevelsScreenState extends State<PredefinedLevelsScreen> {
  List beginnerWorkouts = [];
  List advancedWorkouts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPredefinedWorkouts();
  }

  Future<void> fetchPredefinedWorkouts() async {
    await Future.wait([
      fetchByLevel('Beginner'),
      fetchByLevel('Advanced'),
    ]);

    setState(() => isLoading = false);
  }

  Future<void> fetchByLevel(String level) async {
    final uri = Uri.parse('http://10.0.2.2:8000/api/predefined-workouts?level=$level');
    log('📡 Fetching $level workouts: $uri');

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          if (level == 'Beginner') {
            beginnerWorkouts = data;
          } else {
            advancedWorkouts = data;
          }
        });
      } else {
        log('❌ Error loading $level workouts', error: response.body);
      }
    } catch (e) {
      log('❗ Exception loading $level workouts', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(207, 228, 242, 1),
      appBar: AppBar(
        title: const Text('Prepared Workouts'),
        backgroundColor: const Color.fromRGBO(57, 132, 173, 1),
        elevation: 2,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Beginner',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                )),
            const SizedBox(height: 12),
            ...beginnerWorkouts.map<Widget>((w) => _buildWorkoutCard(w)).toList(),

            const SizedBox(height: 24),
            const Text('Advanced',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                )),
            const SizedBox(height: 12),
            ...advancedWorkouts.map<Widget>((w) => _buildWorkoutCard(w)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(Map workout) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 3,
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            workout['image'] ?? '',
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 60,
              height: 60,
              color: Colors.grey.shade300,
              child: const Icon(Icons.image_not_supported),
            ),
          ),
        ),
        title: Text(
          workout['title'] ?? 'No title',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${workout['duration']} | ${workout['calories']} | ${workout['exercise_count']} exercises',
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        onTap: () {
          log('📦 Tapped predefined workout ID: ${workout['id']}');
          // TODO: Navigate to detail screen
        },
      ),
    );
  }
}
