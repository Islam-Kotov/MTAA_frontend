import 'package:flutter/material.dart';
import 'package:semestral_project/screens/all_screens.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  late final WebSocketChannel channel;

  @override
  void initState() {
    super.initState();

    channel = WebSocketChannel.connect(
      Uri.parse('ws://192.168.1.36:8080/app/cfdjqmnqx0vggflribbd?protocol=7&client=js&version=1.0&format=json'),
    );

    channel.sink.add(jsonEncode(
      {
        'event': 'pusher:subscribe',
        'data': {
          'channel': 'test'
        }
      }
    ));

    channel.stream.listen((message) {
      final data = jsonDecode(message);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data.toString()),
            ),
          );
        }
      });
    });
  }

  int _selectedIndex = 0;

  final List<Widget> _screens = [
    MyPlanScreen(),
    WorkoutCategoriesScreen(),
    CommunityScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        iconSize: 30,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: 'My plan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_gymnastics_outlined),
            label: 'Workouts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_sharp),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}