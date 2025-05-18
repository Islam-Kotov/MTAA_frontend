import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'friends_screen.dart';
import 'leaderboard_screen.dart';

Timer? _pingTimer;

void startPingSocketConnection() {
  _pingTimer?.cancel(); // Cancel if already running
  _pingTimer = Timer.periodic(const Duration(seconds: 10), (Timer timer) {
    getCurrentChallenge();
  });
}

void stopPingSocketConnection() {
  _pingTimer?.cancel();
  _pingTimer = null;
}

Future<void> getCurrentChallenge() async {
  final url = Uri.parse('http://192.168.1.36:8000/api/getCurrentChallenge');
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('api_token');

  await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late final WebSocketChannel channel;

  @override
  void initState() {
    super.initState();
    startPingSocketConnection();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    channel = WebSocketChannel.connect(
      Uri.parse('ws://192.168.1.36:8080/app/cfdjqmnqx0vggflribbd?protocol=7&client=js&version=1.0&format=json'),
    );

    channel.sink.add(jsonEncode({
      'event': 'pusher:subscribe',
      'data': {'channel': 'challenges'}
    }));

    getCurrentChallenge();
  }

  @override
  void dispose() {
    _controller.dispose();
    channel.sink.close();
    super.dispose();
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      minimumSize: const Size(double.infinity, 80),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Friends button
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ElevatedButton.icon(
                      style: _buttonStyle(),
                      icon: const Icon(Icons.people_outline),
                      label: Text('Friends', style: textStyle.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsScreen()));
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ElevatedButton.icon(
                      style: _buttonStyle(),
                      icon: const Icon(Icons.leaderboard),
                      label: Text('Leaderboard', style: textStyle.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen()));
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      decoration: BoxDecoration(
                        color: colors.onPrimary,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Text(
                              'Daily challenge',
                              style: textStyle.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                            ),
                            StreamBuilder(
                              stream: channel.stream,
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  try {
                                    final jsonData = jsonDecode(snapshot.data as String);
                                    final innerData = jsonData['data'];
                                    final decoded = innerData is String ? jsonDecode(innerData) : innerData;
                                    final challenge = decoded['challenge'];
                                    final message = challenge != null ? challenge['description'] : 'No message available';
                                    return Text(message);
                                  } catch (_) {
                                    return const Text('Error parsing message');
                                  }
                                } else if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}');
                                } else {
                                  return const Text('Waiting for data...');
                                }
                              },
                            ),
                          ],
                        )
                      ),
                    ),
                  ),
                ],
              ),
            )
          ),
        ),
      )
    );
  }
}
