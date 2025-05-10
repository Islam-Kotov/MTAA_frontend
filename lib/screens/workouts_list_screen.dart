import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  bool isLoading = true;
  bool isFiltering = false;
  String? selectedFilter;

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
    fetchWorkouts();
  }

  Future<void> fetchWorkouts() async {
    final uri = Uri.parse(
        'http://192.168.1.36:8000/api/workouts?category=${Uri.encodeComponent(widget.categoryName)}');
    log('📡 Fetching workouts from: $uri');

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        log('✅ Workouts fetched: ${data.length} items');
        setState(() {
          workouts = data;
          filteredWorkouts = data;
          isLoading = false;
        });
      } else {
        log('❌ Server error: ${response.statusCode}', error: response.body);
        setState(() => isLoading = false);
      }
    } catch (e) {
      log('❗ Exception while fetching workouts', error: e);
      setState(() => isLoading = false);
    }
  }

  void applyFilter(String selected) {
    String? type = selected == '__clear__' ? null : selected;

    setState(() {
      selectedFilter = type;
      isFiltering = true;
      filteredWorkouts = [];
    });

    Future.delayed(const Duration(milliseconds: 50), () {
      setState(() {
        if (type == null) {
          filteredWorkouts = workouts;
        } else {
          filteredWorkouts = workouts
              .where((w) => (w['exercise_type']?.toLowerCase() ?? '')
              .contains(type.toLowerCase()))
              .toList();
        }
        isFiltering = false;
      });
    });
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
              ...filters.map((type) => PopupMenuItem(
                value: type,
                child: Text(type),
              )),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: '__clear__',
                child: Text('Clear filter'),
              ),
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
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        log('🟢 Tapped workout ID: ${workout['id']}');
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
                              errorBuilder: (context,
                                  error, stackTrace) {
                                log('⚠️ Image load error: $imageUrl',
                                    error: error);
                                return Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors
                                      .grey.shade300,
                                  child: const Icon(Icons
                                      .broken_image),
                                );
                              },
                            )
                                : Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons
                                  .image_not_supported),
                            ),
                          ),
                        ),
                        title: Text(
                          workout['exercise_name'] ?? 'Unnamed',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          workout['exercise_type'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.black54,
                          ),
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
