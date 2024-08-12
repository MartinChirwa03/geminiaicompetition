import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isDarkMode = false;
  String _userName = '';
  String _userEmail = '';
  String _profileImagePath = '';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userData = await _firestore.collection('users').doc(user.uid).get();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        _userName = userData['name'];
        _userEmail = user.email ?? '';
        _profileImagePath = prefs.getString('profileImagePath') ?? '';
      });
    }
  }

  Future<void> _changePassword() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: _userEmail,
          password: _currentPasswordController.text,
        );
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(_newPasswordController.text);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password updated successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update password: $e')),
      );
    }
  }

  Future<void> _updateProfileName() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'name': _nameController.text,
        });
        setState(() {
          _userName = _nameController.text;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile name updated successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile name: $e')),
      );
    }
  }

  Future<void> _updateProfilePicture() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      try {
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String fileName = path.basename(image.path);
        final String localPath = path.join(appDir.path, fileName);

        // Copy the picked image to the app's local storage
        final File localImage = await File(image.path).copy(localPath);

        // Save the local path to SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('profileImagePath', localPath);

        setState(() {
          _profileImagePath = localPath;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile picture updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile picture: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/_151c3c61-5faf-4976-8dcf-f18daa3d5aa0.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: Colors.black.withOpacity(0.3),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _updateProfilePicture,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: _profileImagePath.isNotEmpty
                              ? FileImage(File(_profileImagePath))
                              : null,
                          backgroundColor: Colors.white,
                          child: _profileImagePath.isEmpty
                              ? Icon(Icons.person, size: 50, color: Colors.blue)
                              : null,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text('Name: $_userName', style: TextStyle(color: Colors.white)),
                    Text('Email: $_userEmail', style: TextStyle(color: Colors.white)),
                    SizedBox(height: 20),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'New Name',
                        labelStyle: TextStyle(color: Colors.white),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      style: TextStyle(color: Colors.white),
                    ),
                    ElevatedButton(
                      onPressed: _updateProfileName,
                      child: Text('Update Profile Name'),
                      //style: ElevatedButton.styleFrom(primary: Colors.blue),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _currentPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        labelStyle: TextStyle(color: Colors.white),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      obscureText: true,
                      style: TextStyle(color: Colors.white),
                    ),
                    TextField(
                      controller: _newPasswordController,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        labelStyle: TextStyle(color: Colors.white),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      obscureText: true,
                      style: TextStyle(color: Colors.white),
                    ),
                    ElevatedButton(
                      onPressed: _changePassword,
                      child: Text('Change Password'),
                      //style: ElevatedButton.styleFrom(//primary: Colors.blue),
                    ),
                    SizedBox(height: 20),
                    SwitchListTile(
                      title: Text('Dark Mode', style: TextStyle(color: Colors.white)),
                      value: _isDarkMode,
                      onChanged: (bool value) {
                        setState(() {
                          _isDarkMode = value;
                        });
                        // Here you would typically update your app's theme
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}