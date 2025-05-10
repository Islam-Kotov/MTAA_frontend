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
  List workouts = [];
  String? selectedLevel;
  bool isLoading = false;

  Future<void> fetchWorkouts(String level) async {
    setState(() {
      isLoading = true;
      selectedLevel = level;
      workouts = [];
    });

    final uri = Uri.parse('http://192.168.1.36:8000/api/predefined-workouts?level=$level');
    log('📡 Fetching $level workouts: $uri');

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final fixed = data.map((w) {
          w['image'] = (w['image'] as String)
              .replaceAll('localhost', '192.168.1.36:8000')
              .replaceAll('127.0.0.1', '192.168.1.36:8000');
          return w;
        }).toList();
        setState(() {
          workouts = fixed;
        });
      } else {
        log('❌ Failed to load workouts: ${response.statusCode}', error: response.body);
      }
    } catch (e) {
      log('❗ Error loading workouts', error: e);
    }

    setState(() => isLoading = false);
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(child: _levelButton('Beginner')),
                const SizedBox(width: 12),
                Expanded(child: _levelButton('Advanced')),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (selectedLevel != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '$selectedLevel Workouts',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : workouts.isEmpty
                ? const Center(child: Text('No workouts found for this level.'))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: workouts.length,
              itemBuilder: (context, index) {
                final workout = workouts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 3,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(14),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        workout['image'],
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
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${workout['duration']} | ${workout['calories']} | ${workout['exercise_count']} exercises',
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black54),
                    ),
                    onTap: () {
                      log('📦 Tapped workout ID: ${workout['id']}');
                      // TODO: перейти на WorkoutDetail
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _levelButton(String label) {
    final isActive = selectedLevel == label;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive
            ? const Color.fromRGBO(57, 132, 173, 1)
            : Colors.white,
        foregroundColor: isActive ? Colors.white : Colors.black87,
        elevation: 3,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () => fetchWorkouts(label),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}
