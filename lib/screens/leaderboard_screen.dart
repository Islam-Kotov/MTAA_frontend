import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<dynamic> leaderboard = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLeaderboard();
  }

  Future<void> fetchLeaderboard() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');
    if (token == null) return;

    final response = await http.get(
      Uri.parse('http://192.168.1.36:8000/api/leaderboard/friends'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        leaderboard = jsonDecode(response.body);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  String _formatDuration(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '${min} min ${sec} sec';
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(title: const Text('Friends Leaderboard')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : leaderboard.isEmpty
          ? const Center(child: Text('No leaderboard data available.'))
          : Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isTablet ? 700 : double.infinity),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: leaderboard.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final entry = leaderboard[index];
              final name = entry['name'] ?? 'Unknown';
              final distance = (entry['distance']).toStringAsFixed(2);
              final startedAt = DateTime.parse(entry['started_at']);
              final dateFormatted = DateFormat.yMMMd().add_Hm().format(startedAt);
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Distance: ${distance} km\nDuration: ${_formatDuration(entry['duration'])}"),
                  trailing: Text(dateFormatted, style: const TextStyle(fontSize: 12)),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}