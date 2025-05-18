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
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
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
        _controller.forward(from: 0);
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
    ).then((_) async {
      setState(() => isLoading = true);
      await fetchWeeklyPlanData();
    });
  }

  Widget buildDayCard(String day, int index, double width) {
    final theme = Theme.of(context);
    final info = dayData[day];
    final title = info?['title'] as String?;
    final hasExercises = info?['hasExercises'] == true;
    final description = info?['description'] ?? '';
    final scheduledTime = info?['scheduled_time'];
    final baseTextColor = hasExercises
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withOpacity(0.6);

    final displayText = title != null && title.trim().isNotEmpty
        ? '$day — $title'
        : '$day — No title set';

    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(0.1 * index, (0.1 * index + 0.5).clamp(0.0, 1.0),
              curve: Curves.easeOut),
        ),
      ),
      child: GestureDetector(
        onTap: () => navigateToDayDetail(day),
        child: SizedBox(
          width: width,
          child: Card(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            elevation: 5,
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayText,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: baseTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 24),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        description,
                        style: TextStyle(fontSize: 14, color: baseTextColor),
                      ),
                    ),
                  Text(
                    scheduledTime != null
                        ? 'Scheduled at: $scheduledTime'
                        : 'No time set',
                    style: TextStyle(fontSize: 14, color: baseTextColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final crossAxisCount = isTablet ? 2 : 1;
    final itemWidth = MediaQuery.of(context).size.width / crossAxisCount - 32;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Weekly Plan'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (int i = 0; i < weekDays.length; i++)
              buildDayCard(weekDays[i], i, itemWidth),
          ],
        ),
      ),
    );
  }
}