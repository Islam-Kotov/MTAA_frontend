import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with TickerProviderStateMixin {
  bool isLoading = true;
  List<dynamic> friends = [];
  List<dynamic> incomingRequests = [];
  List<dynamic> outgoingRequests = [];
  String? _emailInput;
  bool _isSending = false;

  double _opacityFriends = 0.0;
  double _opacityIncoming = 0.0;
  double _opacityOutgoing = 0.0;
  double _opacityButton = 0.0;

  @override
  void initState() {
    super.initState();
    fetchFriendsData();

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _opacityFriends = 1.0);
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _opacityIncoming = 1.0);
    });
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) setState(() => _opacityOutgoing = 1.0);
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _opacityButton = 1.0);
    });
  }

  Future<void> fetchFriendsData() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');

    if (token == null) {
      setState(() => isLoading = false);
      return;
    }

    final response = await http.get(
      Uri.parse('http://147.175.162.111:8000/api/friends'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        friends = data['friends'] ?? [];
        incomingRequests = data['incoming_requests'] ?? [];
        outgoingRequests = data['outgoing_requests'] ?? [];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      print('Error fetching friends: ${response.body}');
    }
  }

  Future<void> respondToRequest(int id, String action) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');
    if (token == null) return;

    final uri = Uri.parse('http://147.175.162.111:8000/api/friends/$action/$id');
    final response = await http.post(uri, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      fetchFriendsData();
    } else {
      print('Error: ${response.body}');
    }
  }

  Future<void> removeFriend(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');
    if (token == null) return;

    final uri = Uri.parse('http://147.175.162.111:8000/api/friends/remove/$id');
    final response = await http.delete(uri, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      fetchFriendsData();
    } else {
      print('Error: ${response.body}');
    }
  }

  void _showAddFriendDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Add Friend'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Enter the email of the user you want to add:'),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (value) => _emailInput = value,
                    decoration: InputDecoration(
                      hintText: 'user@example.com',
                      filled: true,
                      fillColor: const Color.fromRGBO(240, 246, 255, 1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isSending ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: _isSending
                      ? null
                      : () async {
                    if (_emailInput == null || !_emailInput!.contains('@')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid email.')),
                      );
                      return;
                    }

                    setStateDialog(() => _isSending = true);

                    final prefs = await SharedPreferences.getInstance();
                    final token = prefs.getString('api_token');
                    if (token == null) return;

                    final response = await http.post(
                      Uri.parse('http://147.175.162.111:8000/api/friends/send'),
                      headers: {
                        'Authorization': 'Bearer $token',
                        'Accept': 'application/json',
                        'Content-Type': 'application/json',
                      },
                      body: json.encode({'email': _emailInput}),
                    );

                    setStateDialog(() => _isSending = false);

                    if (response.statusCode == 200) {
                      Navigator.of(context).pop();
                      fetchFriendsData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Friend request sent')),
                      );
                    } else {
                      final message = json.decode(response.body)['message'] ?? 'Error';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(message)),
                      );
                    }
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Send'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStyledSection(
      IconData icon, String title, List<dynamic> users, String section, double opacity) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      opacity: opacity,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(blurRadius: 8, offset: Offset(0, 4), color: Theme.of(context).shadowColor),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            users.isEmpty
                ? const Text('No entries', style: TextStyle())
                : Column(
              children: users.map((u) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const Icon(Icons.person_outline),
                    title: Text(u['name'] ?? 'Unknown'),
                    subtitle: Text(u['email'] ?? ''),
                    trailing: section == 'friends'
                        ? IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => removeFriend(u['id']),
                      tooltip: 'Remove friend',
                    )
                        : section == 'incoming'
                        ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          onPressed: () => respondToRequest(u['id'], 'accept'),
                          tooltip: 'Accept',
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () => respondToRequest(u['id'], 'decline'),
                          tooltip: 'Decline',
                        ),
                      ],
                    )
                        : const Icon(Icons.mail_outline),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final content = Column(
      children: [
        _buildStyledSection(Icons.people, 'Friends', friends, 'friends', _opacityFriends),
        const SizedBox(height: 20),
        _buildStyledSection(Icons.person_add, 'Incoming Requests', incomingRequests, 'incoming', _opacityIncoming),
        const SizedBox(height: 20),
        _buildStyledSection(Icons.outbox, 'Outgoing Requests', outgoingRequests, 'outgoing', _opacityOutgoing),
        const SizedBox(height: 30),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          opacity: _opacityButton,
          child: ElevatedButton.icon(
            onPressed: _showAddFriendDialog,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Add Friend'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 5,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Friends'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isTablet ? 700 : double.infinity,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(child: content),
              ),
            ),
          );
        },
      ),
    );
  }
}
