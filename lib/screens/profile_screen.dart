import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'all_screens.dart';

Future<Uint8List> showPrivate(String photo_url) async {
  final url = Uri.parse(photo_url);

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('api_token');

  final response = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  return response.bodyBytes;
}

Future<Map<String, dynamic>?> getProfile() async {
  final url = Uri.parse('http://192.168.1.36:8000/api/profile');

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('api_token');

  final response = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data;
  } else {
    print('Failed to load profile: ${response.body}');
    return null;
  }
}

Future<bool> logout() async {
  final url = Uri.parse('http://192.168.1.36:8000/api/logout');

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('api_token');

  final response = await http.delete(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    print('${response.body}');
    return true;
  } else {
    print('${response.body}');
    return false;
  }
}

Future<bool> resetPassword(String email, String currentPassword, String newPassword) async {
  final url = Uri.parse('http://192.168.1.36:8000/api/reset-password');

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('api_token');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'email': email,
      'old_password': currentPassword,
      'new_password': newPassword,
    }),
  );

  if (response.statusCode == 200) {
    print('${response.body}');
    return true;
  } else {
    print('${response.body}');
    return false;
  }
}

Future<bool> deleteAccount(String password) async {
  final url = Uri.parse('http://192.168.1.36:8000/api/delete');

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('api_token');

  final response = await http.delete(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'password': password,
    }),
  );

  if (response.statusCode == 200) {
    print('${response.body}');
    return true;
  } else {
    print('${response.body}');
    return false;
  }
}

Future<bool> saveProfile(String weight, String height, String birthdate) async {
  final url = Uri.parse('http://192.168.1.36:8000/api/profile');

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('api_token');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'weight': weight,
      'height': height,
      'birthdate': birthdate,
    }),
  );

  if (response.statusCode == 200) {
    print('${response.body}');
    return true;
  } else {
    print('${response.body}');
    return false;
  }
}

Future<bool> saveProfilePhoto(XFile image) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('api_token');

  final request = http.MultipartRequest(
    'POST',
    Uri.parse('http://192.168.1.36:8000/api/profile-photo'),
  );

  request.headers['Authorization'] = 'Bearer $token';
  request.files.add(await http.MultipartFile.fromPath('photo', image.path));

  final response = await request.send();
  final responseBody = await http.Response.fromStream(response);

  if (response.statusCode == 200) {
    print('${responseBody.body}');
    return true;
  } else {
    print('${responseBody.body}');
    return false;
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreen();
}

class _ProfileScreen extends State<ProfileScreen> {
  Map<String, dynamic>? profileData;
  Uint8List? profileImageBytes;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    final data = await getProfile();
    setState(() {
      profileData = data;
      isLoading = false;
    });
    if (data != null && data['photo_url'] != null) {
      final avatar = await showPrivate(data['photo_url']);
      setState(() {
        profileImageBytes = avatar;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (profileData == null) {
      return Scaffold(
        body: Center(child: Text('Failed to load profile.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color.fromRGBO(57, 132, 173, 1),
      ),
      backgroundColor: Color.fromRGBO(207, 228, 242, 1),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Color.fromRGBO(145, 193, 232, 1),
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 55,
                  backgroundImage: profileImageBytes != null
                    ? MemoryImage(profileImageBytes!)
                    : null,
                  child: profileImageBytes == null
                    ? Icon(Icons.person, size: 40)
                    : null,
                ),
                Text(
                  profileData!['name'] ?? '',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold
                  )
                ),
                SizedBox(height: 4),
                Text(
                  profileData!['email'] ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54
                  )
                ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Color.fromRGBO(111, 167, 204, 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text(
                            '${profileData!['weight']}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54
                            )
                          ),
                          Text(
                            'Weight',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54
                            )
                          )
                        ],
                      ),
                      Container(
                        height: 60,
                        width: 1,
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      Column(
                        children: [
                          Text(
                            '${profileData!['height']}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54
                            )
                          ),
                          Text(
                            'Height',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54
                            )
                          )
                        ],
                      ),
                      Container(
                        height: 60,
                        width: 1,
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      Column(
                        children: [
                          Text(
                            '${profileData!['birthdate']}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54
                            )
                          ),
                          Text(
                            'Birthdate',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54
                            )
                          )
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          SizedBox(height: 10),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 20,
              children: [
                Card(
                  color: Colors.white,
                  child: ListTile(
                    leading: Icon(Icons.person_outline_sharp, size: 32, color: Colors.black),
                    title: Text(
                      'My profile',
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.black,
                      ),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MyProfilePage()),
                      ).then((_) {
                        fetchProfile();
                      });
                    },
                  )
                ),
                Card(
                  color: Colors.white,
                  child: ListTile(
                    leading: Icon(Icons.settings, size: 32, color: Colors.black),
                    title: Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.black,
                      ),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
                    onTap: () {
                        Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SettingsPage()),
                      );
                    },
                  )
                ),
                Card(
                  color: Colors.white,
                  child: ListTile(
                    leading: Icon(Icons.logout_sharp, size: 32, color: Colors.black),
                    title: Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.black,
                      ),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
                    onTap: () async {
                      final success = await logout();

                      if (!mounted) return; // Prevent using context if widget is disposed

                      if (success) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const AuthorizationScreen()),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Logout failed')),
                        );
                      }
                    },
                  )
                ),
              ],
            ),
          ),
        ],
      )
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(207, 228, 242, 1),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color.fromRGBO(57, 132, 173, 1),
      ),
      body: Column(
        children: [
          ListTile(
            leading: Icon(Icons.notifications, size: 32, color: Colors.black),
            title: Text(
              'Notifications',
              style: TextStyle(
                fontSize: 22,
                color: Colors.black,
              ),
            ),
            trailing: NotificationsSwitch(),
          ),
          ListTile(
            leading: Icon(Icons.dark_mode_outlined, size: 32, color: Colors.black),
            title: Text(
              'Dark mode',
              style: TextStyle(
                fontSize: 22,
                color: Colors.black,
              ),
            ),
            trailing: DarkmodeSwitch(),
          ),
          ListTile(
            leading: Icon(Icons.password_sharp, size: 32, color: Colors.black),
            title: Text(
              'Reset the password',
              style: TextStyle(
                fontSize: 22,
                color: Colors.black,
              ),
            ),
            trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
            onTap: () async {
              showDialog(
                context: context,
                builder: (context) {
                  return PasswordResetDialog();
                },
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_outline_sharp, size: 32, color: Colors.black),
            title: Text(
              'Delete account',
              style: TextStyle(
                fontSize: 22,
                color: Colors.black,
              ),
            ),
            trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
            onTap: () async {
              showDialog(
                context: context,
                builder: (context) {
                  return DeleteAccountDialog();
                },
              );
            },
          ),
        ],
      )
    );
  }
}

class PasswordResetDialog extends StatefulWidget {
  const PasswordResetDialog({super.key});

  @override
  _PasswordResetDialogState createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<PasswordResetDialog> {
  final emailController = TextEditingController();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset Password'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
            ),
            TextField(
              controller: currentPasswordController,
              obscureText: _obscureCurrentPassword,
              decoration: InputDecoration(
                labelText: 'Current Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCurrentPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureCurrentPassword = !_obscureCurrentPassword;
                    });
                  },
                ),
              ),
            ),
            TextField(
              controller: newPasswordController,
              obscureText: _obscureNewPassword,
              decoration: InputDecoration(
                labelText: 'New Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final email = emailController.text;
            final currentPassword = currentPasswordController.text;
            final newPassword = newPasswordController.text;

            final success = await resetPassword(email, currentPassword, newPassword);
            
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password reset successfully')),
              );
              Navigator.of(context).pop(); // Close the dialog
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password reset failed')),
              );
            }
          },
          child: const Text('Reset'),
        ),
      ],
    );
  }
}

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  _DeleteAccountDialogState createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset Password'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final password = passwordController.text;

            final success = await deleteAccount(password);

            if (!mounted) return; // Prevent using context if widget is disposed
            
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deleted successfully')),
              );
              // Navigator.of(context).pop(); // Close the dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AuthorizationScreen()),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deletion failed')),
              );
            }
          },
          child: const Text('Delete'),
        ),
      ],
    );
  }
}

class NotificationsSwitch extends StatefulWidget {
  const NotificationsSwitch({super.key});

  @override
  State<NotificationsSwitch> createState() => _NotificationsSwitchState();
}

class _NotificationsSwitchState extends State<NotificationsSwitch> {
  bool notificationsOn = false;

  @override
  Widget build(BuildContext context) {
    return Switch(
      // This bool value toggles the switch.
      value: notificationsOn,
      activeColor: Color.fromRGBO(111, 167, 204, 1),
      onChanged: (bool value) {
        // This is called when the user toggles the switch.
        setState(() {
          notificationsOn = value;
        });
      },
    );
  }
}

class DarkmodeSwitch extends StatefulWidget {
  const DarkmodeSwitch({super.key});

  @override
  State<DarkmodeSwitch> createState() => _DarkmodeSwitchState();
}

class _DarkmodeSwitchState extends State<DarkmodeSwitch> {
  bool darkmodeOn = false;

  @override
  Widget build(BuildContext context) {
    return Switch(
      // This bool value toggles the switch.
      value: darkmodeOn,
      activeColor: Color.fromRGBO(111, 167, 204, 1),
      onChanged: (bool value) {
        // This is called when the user toggles the switch.
        setState(() {
          darkmodeOn = value;
        });
      },
    );
  }
}

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  Map<String, dynamic>? profileData;
  Uint8List? profileImageBytes;
  File? newProfileImage;

  bool isLoading = true;

  final birthdateController = TextEditingController();
  final weightController = TextEditingController();
  final heightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    final data = await getProfile();
    setState(() {
      profileData = data;
      isLoading = false;
    });
    if (data != null && data['photo_url'] != null) {
      final avatar = await showPrivate(data['photo_url']);
      setState(() {
        profileImageBytes = avatar;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (profileData == null) {
      return Scaffold(
        body: Center(child: Text('Failed to load profile.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My profile'),
        backgroundColor: const Color.fromRGBO(57, 132, 173, 1),
      ),
      backgroundColor: Color.fromRGBO(207, 228, 242, 1),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            width: double.infinity,
            color: Color.fromRGBO(145, 193, 232, 1), // Light blue background
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 55,
                  backgroundImage: profileImageBytes != null
                    ? MemoryImage(profileImageBytes!)
                    : null,
                  child: profileImageBytes == null
                    ? Icon(Icons.person, size: 40)
                    : null,
                ),
                Text(
                  profileData!['name'] ?? '',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold
                  )
                ),
                SizedBox(height: 4),
                Text(
                  profileData!['email'] ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54
                  )
                ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Color.fromRGBO(111, 167, 204, 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text(
                            '${profileData!['weight']}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54
                            )
                          ),
                          Text(
                            'Weight',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54
                            )
                          )
                        ],
                      ),
                      Container(
                        height: 60, // adjust as needed
                        width: 1,
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      Column(
                        children: [
                          Text(
                            '${profileData!['height']}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54
                            )
                          ),
                          Text(
                            'Height',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54
                            )
                          )
                        ],
                      ),
                      Container(
                        height: 60, // adjust as needed
                        width: 1,
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      Column(
                        children: [
                          Text(
                            '${profileData!['birthdate']}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54
                            )
                          ),
                          Text(
                            'Birthdate',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54
                            )
                          )
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: weightController,
                        decoration: InputDecoration(labelText: 'Weight'),
                      ),
                      SizedBox(height: 14),
                      TextField(
                        controller: heightController,
                        decoration: InputDecoration(labelText: 'Height'),
                      ),
                      SizedBox(height: 14),
                      TextField(
                        controller: birthdateController,
                        decoration: InputDecoration(labelText: 'Birthdate'),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(source: ImageSource.gallery);

                        if (pickedFile != null) {
                          final success = await saveProfilePhoto(pickedFile);

                          print('Uploading file: ${pickedFile.path}');
                          // print('File exists: ${await pickedFile.exists()}');
                          print('Length: ${await pickedFile.length()} bytes');

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Profile photo updated successfully')),
                            );
                            fetchProfile();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Profile photo update failed')),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No image selected')),
                          );
                        }
                      },
                      child: const Text('Upload photo'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final weight = weightController.text;
                        final height = heightController.text;
                        final birthdate = birthdateController.text;

                        final success = await saveProfile(weight, height, birthdate);
                        
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile updated successfully')),
                          );
                          fetchProfile();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile update failed')),
                          );
                        }
                      },
                      child: const Text('Update profile'),
                    ),
                  ],
                )
              ],
            ),
          ),
          SizedBox(height: 70),
        ],
      )
    );
  }
}