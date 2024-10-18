import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  File? _profileImage;
  String? userProfileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserProfile() async {
    User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      String userId = currentUser.uid;
      DatabaseReference userRef = _database.ref('users/$userId');

      userRef.once().then((DatabaseEvent event) {
        if (event.snapshot.exists) {
          Map<dynamic, dynamic> userData = event.snapshot.value as Map;

          setState(() {
            _nameController.text = userData['userName'] ?? 'Unknown';
            userProfileImageUrl = userData['userProfileImage'] ?? 'assets/images/default_avatar.png';
          });
        }
      }).catchError((error) {
        print('Error loading user data: $error');
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _profileImage = File(pickedImage.path);
      });
    }
  }

  Future<String> _uploadProfileImage(File image) async {
    User? currentUser = _auth.currentUser;
    String userId = currentUser!.uid;

    String fileName = path.basename(image.path);
    Reference storageRef = _storage.ref().child('profile_images/$userId/$fileName');

    UploadTask uploadTask = storageRef.putFile(image);

    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  void _saveProfile() async {
    final updatedName = _nameController.text;

    if (updatedName.isNotEmpty) {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        String userId = currentUser.uid;
        DatabaseReference userRef = _database.ref('users/$userId');

        _showLoadingSpinner(context);

        userRef.update({
          'userName': updatedName,
        });

        if (_profileImage != null) {
          try {
            String imageUrl = await _uploadProfileImage(_profileImage!);
            userRef.update({
              'userProfileImage': imageUrl,
            });
            setState(() {
              userProfileImageUrl = imageUrl;
            });
            _hideLoadingSpinner(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Profile updated successfully')),
            );
          } catch (e) {
            _hideLoadingSpinner(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error updating profile image: $e')),
            );
          }
        } else {
          _hideLoadingSpinner(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile updated without image')),
          );
        }
      }
    }
  }

  void _showLoadingSpinner(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _hideLoadingSpinner(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : (userProfileImageUrl != null
                    ? NetworkImage(userProfileImageUrl!)
                    : AssetImage('assets/images/default_avatar.png'))
                as ImageProvider,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.black54,
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(color: Colors.black),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Save Profile',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
