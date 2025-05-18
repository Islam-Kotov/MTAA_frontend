import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'all_screens.dart';

Future<bool> loginUser(String email, String password) async {
  final url = Uri.parse('http://192.168.1.36:8000/api/auth/login');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'email': email,
      'password': password,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final token = data['token'];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_token', token);
    return true;
  } else {
    return false;
  }
}

class AuthorizationScreen extends StatefulWidget {
  const AuthorizationScreen({super.key});

  @override
  State<AuthorizationScreen> createState() => _AuthorizationScreenState();
}

class _AuthorizationScreenState extends State<AuthorizationScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color.fromRGBO(207, 228, 242, 1),
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 600) {
                return _buildTabletLayout();
              } else {
                return _buildMobileLayout();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        child: Column(
          children: [
            const Text('FitLife',
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Image.asset('assets/images/dumbell_icon.png', height: 120),
            const SizedBox(height: 32),
            _buildFormContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Image.asset('assets/images/dumbell_icon.png', width: 350),
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                width: 350,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white.withOpacity(0.9),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('FitLife',
                        style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildFormContent(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            hintText: 'Enter e-mail...',
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(vertical: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: 'Enter password...',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 20),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(57, 132, 173, 1),
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () async {
            final success = await loginUser(
              _emailController.text,
              _passwordController.text,
            );
            if (!mounted) return;

            if (success) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Login failed')),
              );
            }
          },
          child: const Text('Login',
              style: TextStyle(fontSize: 24, color: Colors.black)),
        ),
        const SizedBox(height: 16),
        const Text("Don't have an account?",
            style: TextStyle(fontSize: 18, color: Colors.black)),
        const SizedBox(height: 8),
        FilledButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(57, 132, 173, 1),
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const RegistrationScreen()),
            );
          },
          child: const Text('Create an account',
              style: TextStyle(fontSize: 20, color: Colors.black)),
        ),
        const SizedBox(height: 8),
        FilledButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(57, 132, 173, 1),
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          },
          child: const Text('Offline mode',
              style: TextStyle(fontSize: 20, color: Colors.black)),
        ),
      ],
    );
  }
}
