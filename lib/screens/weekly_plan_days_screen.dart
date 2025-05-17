import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:developer';
import 'weekly_plan_detail_screen.dart';

class WeeklyPlanDaysScreen extends StatefulWidget {
  const WeeklyPlanDaysScreen({super.key});

  @override
  State<WeeklyPlanDaysScreen> createState() => _WeeklyPlanDaysScreenState();
}

class _WeeklyPlanDaysScreenState extends State<WeeklyPlanDaysScreen>
    with SingleTickerProviderStateMixin {
  final List<String> weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  late AnimationController _controller;
  Map<String, Map<String, dynamic>> dayData = {};
  bool isLoading = true;
  String? token;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    loadTokenAndFetch();
  }

  Future<void> loadTokenAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('api_token');

    if (token == null) {
      log('No token found');
      setState(() => isLoading = false);
      return;
    }

    await fetchWeeklyPlanData();
  }

  Future<void> fetchWeeklyPlanData() async {
    final uri = Uri.parse('http://192.168.1.36:8000/api/weekly-plan');
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final Map<String, Map<String, dynamic>> result = {};

      for (var item in data) {
        final day = item['day'];
        result[day] = {
          'title': item['title'],
          'description': item['description'],
          'scheduled_time': item['scheduled_time'],
          'hasExercises': (item['workouts'] as List).isNotEmpty
        };
      }

      setState(() {
        dayData = result;
        isLoading = false;
        _controller.forward();
      });
    } else {
      log('Failed to load weekly plan: ${response.statusCode}');
      setState(() => isLoading = false);
    }
  }

  void navigateToDayDetail(String day) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WeeklyPlanDetailScreen(dayOfWeek: day),
      ),
    ).then((_) => fetchWeeklyPlanData());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget buildAnimatedDayTile(String day, int index) {
    final theme = Theme.of(context);
    final info = dayData[day];
    final title = info?['title'] as String?;
    final hasExercises = info?['hasExercises'] == true;
    final description = info?['description'] ?? '';
    final scheduledTime = info?['scheduled_time'];

    final displayText = title != null && title.trim().isNotEmpty
        ? '$day — $title'
        : '$day — No title set';

    final color = hasExercises ? Colors.black : Colors.grey.shade500;

    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            0.1 * index,
            (0.1 * index + 0.5).clamp(0.0, 1.0),
            curve: Curves.easeOut,
          ),
        ),
      ),
      child: GestureDetector(
        onTap: () => navigateToDayDetail(day),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 5,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shadowColor: theme.shadowColor.withOpacity(0.15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayText,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 26),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        description.isNotEmpty
                            ? description
                            : 'No description set',
                        style: TextStyle(fontSize: 14, color: color),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        scheduledTime != null
                            ? 'Scheduled at: $scheduledTime'
                            : 'No time set',
                        style: TextStyle(fontSize: 14, color: color),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Weekly Plan'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: weekDays.length,
        itemBuilder: (context, index) {
          final day = weekDays[index];
          return buildAnimatedDayTile(day, index);
        },
      ),
    );
  }
}
