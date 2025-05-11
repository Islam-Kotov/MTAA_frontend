import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/all_screens.dart';

final ThemeData lightTheme = ThemeData(
  scaffoldBackgroundColor: const Color.fromRGBO(207, 228, 242, 1),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color.fromRGBO(57, 132, 173, 1),
  ),
  brightness: Brightness.light,
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: Color.fromRGBO(57, 132, 173, 1),
    onPrimary: Colors.white,
    secondary: Color.fromRGBO(111, 167, 204, 1),
    onSecondary: Colors.white,
    background: Color.fromRGBO(207, 228, 242, 1),
    onBackground: Colors.black,
    surface: Colors.white,
    onSurface: Colors.black,
    error: Colors.red,
    onError: Colors.white,
    primaryContainer: Color.fromRGBO(145, 193, 232, 1),
    secondaryContainer: Color.fromRGBO(111, 167, 204, 1),
  ),
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.blue,
  scaffoldBackgroundColor: Colors.black,
);

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      theme: lightTheme,
      darkTheme: ThemeData.dark(),
      themeMode: themeNotifier.themeMode,
      home: const AuthorizationScreen(),
    );
    // return MaterialApp(
    //   home: FillProfileInfoScreen(),
    // );
  }
}