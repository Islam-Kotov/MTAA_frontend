import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:developer';

import 'workout_detail_screen.dart';
import 'workout_categories_screen.dart';

class MyOwnPlanScreen extends StatefulWidget {
  const MyOwnPlanScreen({super.key});

  @override
  State<MyOwnPlanScreen> createState() => _MyOwnPlanScreenState();
}

class _MyOwnPlanScreenState extends State<MyOwnPlanScreen> {
  List<dynamic> exercises = [];
  bool isLoading = false;
  String? apiToken;

  @override
  void initState() {
    super.initState();
    fetchPlan();
  }

  Future<void> fetchPlan() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');

    if (token == null) {
      log('❌ No token found');
      setState(() => isLoading = false);
      return;
    }

    apiToken = token;

    final uri = Uri.parse('http://192.168.1.36:8000/api/plan');
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        exercises = data;
        isLoading = false;
      });
    } else {
      log('❌ Failed to fetch plan: ${response.statusCode}');
      setState(() => isLoading = false);
    }
  }

  Future<void> removeExercise(int workoutId) async {
    final uri = Uri.parse('http://192.168.1.36:8000/api/plan/remove/$workoutId');
    final response = await http.delete(uri, headers: {
      'Authorization': 'Bearer $apiToken',
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      fetchPlan();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Exercise removed')),
      );
    } else {
      log('❌ Failed to remove: ${response.statusCode}');
    }
  }

  void showUpdateDialog(int workoutId, int currentSets, int currentReps) {
    final setsController = TextEditingController(text: currentSets.toString());
    final repsController = TextEditingController(text: currentReps.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Update Exercise'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: setsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Sets'),
            ),
            TextField(
              controller: repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Reps'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final sets = int.tryParse(setsController.text);
              final reps = int.tryParse(repsController.text);
              if (sets != null && reps != null) {
                updateExercise(workoutId, sets, reps);
                Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> updateExercise(int workoutId, int sets, int reps) async {
    final uri = Uri.parse('http://192.168.1.36:8000/api/plan/update');
    final response = await http.put(uri,
        headers: {
          'Authorization': 'Bearer $apiToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'workout_id': workoutId,
          'sets': sets,
          'repetitions': reps,
        }));

    if (response.statusCode == 200) {
      fetchPlan();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Exercise updated')),
      );
    } else {
      log('❌ Failed to update: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(207, 228, 242, 1),
      appBar: AppBar(
        title: const Text('My Custom Plan'),
        backgroundColor: const Color.fromRGBO(57, 132, 173, 1),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : exercises.isEmpty
          ? const Center(
        child: Text(
          'Your custom workout plan is empty.\nTap the + button to add exercises.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.black54),
        ),
      )
          : ListView.builder(
        itemCount: exercises.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final item = exercises[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 6,
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkoutDetailScreen(
                    workoutId: item['id'],
                    heroTag: 'exercise-image-${item['id']}',
                  ),
                ),
              ),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['exercise_name'],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sets: ${item['sets']}    Reps: ${item['repetitions']}',
                            style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit,
                              color: Colors.orange),
                          onPressed: () => showUpdateDialog(
                            item['id'],
                            item['sets'],
                            item['repetitions'],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.red),
                          onPressed: () =>
                              removeExercise(item['id']),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 6,
        ),
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Exercises',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const WorkoutCategoriesScreen(),
            ),
          );
          fetchPlan();
        },
      ),
    );
  }
}
