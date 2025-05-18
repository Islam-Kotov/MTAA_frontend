import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'workout_categories_screen.dart';
import 'workout_detail_screen.dart';

class WeeklyPlanDetailScreen extends StatefulWidget {
  final String dayOfWeek;

  const WeeklyPlanDetailScreen({super.key, required this.dayOfWeek});

  @override
  State<WeeklyPlanDetailScreen> createState() => _WeeklyPlanDetailScreenState();
}

class _WeeklyPlanDetailScreenState extends State<WeeklyPlanDetailScreen> {
  List<dynamic> workouts = [];
  Set<int> completedIds = {};
  String? apiToken;
  bool isLoading = false;
  String title = '';
  String description = '';
  String? scheduledTime;

  final titleController = TextEditingController();
  final descController = TextEditingController();
  final timeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchDayPlan();
  }

  Future<void> fetchDayPlan() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');
    if (token == null) return;

    apiToken = token;
    final uri = Uri.parse('http://192.168.1.36:8000/api/weekly-plan');
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final current = data.firstWhere((d) => d['day'] == widget.dayOfWeek, orElse: () => null);

      setState(() {
        workouts = current?['workouts'] ?? [];
        title = current?['title'] ?? '';
        description = current?['description'] ?? '';
        scheduledTime = current?['scheduled_time'];
        titleController.text = title;
        descController.text = description;
        timeController.text = scheduledTime ?? '';
        isLoading = false;
        completedIds.clear();
      });
    } else {
      log('Failed to load: ${response.statusCode}');
      setState(() => isLoading = false);
    }
  }

  Future<void> updateMeta() async {
    if (apiToken == null) return;
    final uri = Uri.parse('http://192.168.1.36:8000/api/weekly-plan/update-meta');
    final response = await http.patch(uri,
      headers: {
        'Authorization': 'Bearer $apiToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'day_of_week': widget.dayOfWeek,
        'title': titleController.text.trim(),
        'description': descController.text.trim(),
        'scheduled_time': timeController.text.trim(),
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Updated successfully')),
      );
      fetchDayPlan();
    } else {
      log('Update failed: ${response.body}');
    }
  }

  Future<void> updateExercise(int workoutId, int sets, int reps) async {
    final uri = Uri.parse('http://192.168.1.36:8000/api/weekly-plan/add');
    final response = await http.post(uri,
      headers: {
        'Authorization': 'Bearer $apiToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'day_of_week': widget.dayOfWeek,
        'workout_id': workoutId,
        'sets': sets,
        'repetitions': reps,
      }),
    );

    if (response.statusCode == 200) {
      fetchDayPlan();
    } else {
      log('Update failed: ${response.statusCode}');
    }
  }

  Future<void> removeWorkout(int workoutId) async {
    final uri = Uri.parse('http://192.168.1.36:8000/api/weekly-plan/remove');
    final response = await http.delete(uri,
      headers: {
        'Authorization': 'Bearer $apiToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'day_of_week': widget.dayOfWeek,
        'workout_id': workoutId,
      }),
    );

    if (response.statusCode == 200) {
      fetchDayPlan();
    } else {
      log('Remove failed: ${response.body}');
    }
  }

  void showEditDialog(int workoutId, int currentSets, int currentReps) {
    final setsController = TextEditingController(text: currentSets.toString());
    final repsController = TextEditingController(text: currentReps.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Sets & Reps'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: setsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sets')),
            TextField(controller: repsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Repetitions')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final sets = int.tryParse(setsController.text);
              final reps = int.tryParse(repsController.text);
              if (sets != null && reps != null) {
                updateExercise(workoutId, sets, reps);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void showMetaDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Day Info'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
              TextField(controller: timeController, decoration: const InputDecoration(labelText: 'Scheduled Time')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              updateMeta();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void toggleCompleted(int workoutId) {
    setState(() {
      completedIds.contains(workoutId) ? completedIds.remove(workoutId) : completedIds.add(workoutId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.dayOfWeek),
        actions: [IconButton(onPressed: showMetaDialog, icon: const Icon(Icons.edit))],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isWide)
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _buildMetaPanel(),
              ),
            ),
          Expanded(
            flex: 5,
            child: workouts.isEmpty
                ? const Center(child: Text('No exercises yet.'))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: workouts.length,
              itemBuilder: (context, index) {
                final item = workouts[index];
                final isCompleted = completedIds.contains(item['workout_id']);

                return Card(
                  elevation: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WorkoutDetailScreen(
                            workoutId: item['workout_id'],
                            heroTag: 'exercise-image-${item['workout_id']}',
                          ),
                        ),
                      );
                    },
                    contentPadding: const EdgeInsets.all(20),
                    title: Text(
                      item['exercise_name'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? Colors.grey : null,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text(
                      'Sets: ${item['sets']} | Reps: ${item['repetitions']}',
                      style: TextStyle(
                        fontSize: 16,
                        color: isCompleted ? Colors.grey : null,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    trailing: Wrap(
                      spacing: 10,
                      children: [
                        IconButton(
                          icon: Icon(
                            isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
                            color: isCompleted ? Colors.green : Colors.grey,
                          ),
                          onPressed: () => toggleCompleted(item['workout_id']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => showEditDialog(item['workout_id'], item['sets'], item['repetitions']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => removeWorkout(item['workout_id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Exercises'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WorkoutCategoriesScreen(selectedDay: widget.dayOfWeek),
            ),
          );
          fetchDayPlan();
        },
      ),
    );
  }

  Widget _buildMetaPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title.isNotEmpty ?
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('Title: $title', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ) :
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('No Title', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ),
        scheduledTime != null && scheduledTime!.isNotEmpty ?
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('Scheduled Time: $scheduledTime', style: const TextStyle(fontSize: 16)),
          ) :
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('No Scheduled Time', style: const TextStyle(fontSize: 16)),
          ),
        description.isNotEmpty ?
          Text(description, style: const TextStyle(fontSize: 14)) :
          Text("No Description", style: const TextStyle(fontSize: 14))
      ],
    );
  }
}
