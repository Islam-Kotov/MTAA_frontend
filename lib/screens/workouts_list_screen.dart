import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:developer';

import 'workout_detail_screen.dart';

class WorkoutsListScreen extends StatefulWidget {
  final String categoryName;

  const WorkoutsListScreen({super.key, required this.categoryName});

  @override
  State<WorkoutsListScreen> createState() => _WorkoutsListScreenState();
}

class _WorkoutsListScreenState extends State<WorkoutsListScreen> {
  List workouts = [];
  List filteredWorkouts = [];
  Set<int> alreadyAdded = {};
  String? apiToken;
  String? selectedFilter;
  bool isLoading = true;
  bool isFiltering = false;

  final List<String> filters = [
    'for biceps',
    'for chest',
    'for shoulders',
    'for legs',
    'for back',
  ];

  @override
  void initState() {
    super.initState();
    loadTokenAndFetch();
  }

  Future<void> loadTokenAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');
    setState(() => apiToken = token);
    await Future.wait([fetchWorkouts(), fetchUserPlanIds()]);
  }

  Future<void> fetchUserPlanIds() async {
    if (apiToken == null) return;
    final uri = Uri.parse('http://192.168.1.36:8000/api/plan');
    try {
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $apiToken',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final ids = data.map<int>((e) => e['workout_id'] as int).toSet();
        setState(() => alreadyAdded = ids);
      } else {
        log('⚠️ Failed to fetch plan: ${response.statusCode}');
      }
    } catch (e) {
      log('❗ Error fetching user plan', error: e);
    }
  }

  Future<void> fetchWorkouts() async {
    final uri = Uri.parse(
        'http://192.168.1.36:8000/api/workouts?category=${Uri.encodeComponent(widget.categoryName)}');
    try {
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $apiToken',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          workouts = data;
          filteredWorkouts = data;
          isLoading = false;
        });
      } else {
        log('❌ Server error: ${response.statusCode}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      log('❗ Error fetching workouts', error: e);
      setState(() => isLoading = false);
    }
  }

  void applyFilter(String selected) {
    String? type = selected == '__clear__' ? null : selected;
    setState(() {
      selectedFilter = type;
      isFiltering = true;
    });

    Future.delayed(const Duration(milliseconds: 50), () {
      setState(() {
        filteredWorkouts = type == null
            ? workouts
            : workouts
            .where((w) =>
            (w['exercise_type']?.toLowerCase() ?? '')
                .contains(type.toLowerCase()))
            .toList();
        isFiltering = false;
      });
    });
  }

  void showAddDialog(int workoutId) {
    final setsController = TextEditingController();
    final repsController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add to My Plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: setsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Sets (1–100)'),
            ),
            TextField(
              controller: repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Repetitions (1–100)'),
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

              if (sets == null || reps == null || sets < 1 || sets > 100 || reps < 1 || reps > 100) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter values between 1 and 100')),
                );
                return;
              }

              Navigator.pop(context);
              addExerciseToPlan(workoutId, sets, reps);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> addExerciseToPlan(int workoutId, int sets, int reps) async {
    final uri = Uri.parse('http://192.168.1.36:8000/api/plan/add');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $apiToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'workout_id': workoutId,
          'sets': sets,
          'repetitions': reps,
        }),
      );

      if (response.statusCode == 200) {
        await fetchUserPlanIds();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Exercise added to your plan')),
        );
      } else {
        log('❌ Failed to add: ${response.statusCode}', error: response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add exercise')),
        );
      }
    } catch (e) {
      log('❗ Error adding exercise', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error adding exercise')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(207, 228, 242, 1),
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: const Color.fromRGBO(57, 132, 173, 1),
        elevation: 2,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by type',
            onSelected: applyFilter,
            itemBuilder: (context) => [
              ...filters.map((type) =>
                  PopupMenuItem(value: type, child: Text(type))),
              const PopupMenuDivider(),
              const PopupMenuItem(
                  value: '__clear__', child: Text('Clear filter')),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedFilter != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                'Filter: $selectedFilter',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.blueGrey,
                ),
              ),
            ),
          Expanded(
            child: isFiltering
                ? const Center(child: CircularProgressIndicator())
                : filteredWorkouts.isEmpty
                ? const Center(
                child: Text('No workouts found for this filter.'))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredWorkouts.length,
              itemBuilder: (context, index) {
                final workout = filteredWorkouts[index];
                final imageUrl = workout['exercise_photo'];
                final heroTag =
                    'exercise-image-${workout['id']}';

                return TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration:
                  Duration(milliseconds: 400 + index * 100),
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  ),
                  child: Card(
                    margin:
                    const EdgeInsets.only(bottom: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WorkoutDetailScreen(
                              workoutId: workout['id'],
                              heroTag: heroTag,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: ListTile(
                        contentPadding:
                        const EdgeInsets.all(14),
                        leading: Hero(
                          tag: heroTag,
                          child: ClipRRect(
                            borderRadius:
                            BorderRadius.circular(8),
                            child: imageUrl != null
                                ? Image.network(
                              imageUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) =>
                                  Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors
                                        .grey.shade300,
                                    child: const Icon(Icons
                                        .image_not_supported),
                                  ),
                            )
                                : Container(
                              width: 60,
                              height: 60,
                              color:
                              Colors.grey.shade300,
                              child: const Icon(Icons
                                  .image_not_supported),
                            ),
                          ),
                        ),
                        title: Text(
                          workout['exercise_name'] ?? 'Unnamed',
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          workout['exercise_type'] ?? '',
                          style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            alreadyAdded.contains(workout['id'])
                                ? Icons.check_circle
                                : Icons.add_circle,
                            size: 32,
                            color:
                            alreadyAdded.contains(workout['id'])
                                ? Colors.green
                                : Colors.blue,
                          ),
                          onPressed: () =>
                              showAddDialog(workout['id']),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
