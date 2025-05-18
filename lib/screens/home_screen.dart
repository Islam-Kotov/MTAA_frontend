import 'package:flutter/material.dart';
import 'package:semestral_project/screens/all_screens.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // _initFirebaseMessaging();
  }

  // Future<void> _initFirebaseMessaging() async {
  //   FirebaseMessaging messaging = FirebaseMessaging.instance;
  //   await messaging.requestPermission(
  //     alert: true,
  //     badge: true,
  //     sound: true,
  //   );

  //   // Get the device token
  //   String? token = await messaging.getToken();
  //   print("FCM Token: $token");

  //   // Listen to messages when the app is in foreground
  //   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //     print('Got a message in foreground!');
  //     if (message.notification != null) {
  //       print('Title: ${message.notification!.title}');
  //       print('Body: ${message.notification!.body}');
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('${message.notification!.body}')),
  //       );
  //     }
  //   });
  // }

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
