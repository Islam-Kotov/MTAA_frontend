import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:developer';
import 'workout_detail_screen.dart';

class WorkoutsListScreen extends StatefulWidget {
  final String categoryName;
  final String? selectedDay;

  const WorkoutsListScreen({
    super.key,
    required this.categoryName,
    this.selectedDay,
  });

  @override
  State<WorkoutsListScreen> createState() => _WorkoutsListScreenState();
}

class _WorkoutsListScreenState extends State<WorkoutsListScreen> {
  List workouts = [];
  List filteredWorkouts = [];
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
    await fetchWorkouts();
  }

  Future<void> fetchWorkouts() async {
    final uri = Uri.parse(
      'http://192.168.1.36:8000/api/workouts?category=${Uri.encodeComponent(widget.categoryName)}',
    );
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
        log('Server error: ${response.statusCode}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      log('Error fetching workouts', error: e);
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
            .where((w) => (w['exercise_type']?.toLowerCase() ?? '').contains(type.toLowerCase()))
            .toList();
        isFiltering = false;
      });
    });
  }

  void showAddDialog(int workoutId) {
    if (widget.selectedDay == null) return;

    final setsController = TextEditingController();
    final repsController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add to ${widget.selectedDay}'),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final sets = int.tryParse(setsController.text);
              final reps = int.tryParse(repsController.text);

              if (sets == null || reps == null || sets < 1 || sets > 100 || reps < 1 || reps > 100) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter valid values (1–100)')),
                );
                return;
              }

              Navigator.pop(context);
              addToWeeklyPlan(workoutId, sets, reps);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> addToWeeklyPlan(int workoutId, int sets, int reps) async {
    if (widget.selectedDay == null) return;

    final uri = Uri.parse('http://192.168.1.36:8000/api/weekly-plan/add');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $apiToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'day_of_week': widget.selectedDay,
          'workout_id': workoutId,
          'sets': sets,
          'repetitions': reps,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exercise added to weekly plan')),
        );
      } else {
        log('Failed to add to weekly plan', error: response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add exercise')),
        );
      }
    } catch (e) {
      log('Error sending request', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by type',
            onSelected: applyFilter,
            itemBuilder: (context) => [
              ...filters.map((type) => PopupMenuItem(value: type, child: Text(type))),
              const PopupMenuDivider(),
              const PopupMenuItem(value: '__clear__', child: Text('Clear filter')),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 600;

          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              if (selectedFilter != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text('Filter: $selectedFilter', style: theme.textTheme.bodyLarge),
                ),
              Expanded(
                child: isFiltering
                    ? const Center(child: CircularProgressIndicator())
                    : Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 700 : double.infinity,
                    ),
                    child: ListView.builder(
                      itemCount: filteredWorkouts.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final workout = filteredWorkouts[index];
                        final imageUrl = workout['exercise_photo'];
                        final heroTag = 'exercise-image-${workout['id']}';

                        return Card(
                          color: theme.cardColor,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 4,
                          child: ListTile(
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
                            contentPadding: const EdgeInsets.all(14),
                            leading: Hero(
                              tag: heroTag,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: imageUrl != null
                                    ? Image.network(
                                  imageUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.broken_image, color: Colors.black54),
                                  ),
                                )
                                    : Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.image_not_supported, color: Colors.black54),
                                ),
                              ),
                            ),
                            title: Text(
                              workout['exercise_name'] ?? 'Unnamed',
                              style: theme.textTheme.titleMedium,
                            ),
                            subtitle: Text(
                              workout['exercise_type'] ?? '',
                              style: theme.textTheme.bodySmall,
                            ),
                            trailing: widget.selectedDay != null
                                ? IconButton(
                              icon: const Icon(Icons.add_circle, size: 32, color: Colors.blue),
                              onPressed: () => showAddDialog(workout['id']),
                            )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
