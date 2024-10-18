import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController(); // For user bio

  final _formKey = GlobalKey<FormState>();
  String? errorMessage;

  String? _selectedRole; // Variable to hold selected role
  final List<String> _roles = ['user', 'moderator']; // Available roles

  // Show loading dialog
  void _showLoadingSpinner(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing the dialog
      builder: (context) => Center(
        child: CircularProgressIndicator(), // Loading spinner
      ),
    );
  }

  // Dismiss loading dialog
  void _hideLoadingSpinner(BuildContext context) {
    Navigator.of(context).pop();
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        errorMessage = null;
      });

      // Show loading spinner
      _showLoadingSpinner(context);

      try {
        // Create a user with email and password
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        User? user = userCredential.user;

        if (user != null) {
          String userId = user.uid;

          // Define the additional user fields including the role
          await _database.ref('users/$userId').set({
            'userBio': _bioController.text, // User bio from text field
            'userCreatedAt': DateTime.now().toString(),
            'userEmail': user.email,
            'userName': _nameController.text, // Username from text field
            'userProfileImage': 'https://firebasestorage.googleapis.com/v0/b/conectivity-app.appspot.com/o/profile_images%2Fdefault_profile.png?alt=media&token=1f649470-3a12-45a3-90b7-eb045a37939c', // Placeholder image URL
            'userRole': _selectedRole, // Save the selected role
            'userStatus': 'active', // Default status for users
          });
          // Hide the loading spinner
          _hideLoadingSpinner(context);
          // Navigate to home screen after successful sign-up
          Navigator.pushReplacementNamed(context, '/home', arguments: {
            'userId': userId,
            'userName': _nameController.text,
          });
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          errorMessage = e.message ?? 'An error occurred. Please try again.';
        });
      } catch (e) {
        setState(() {
          errorMessage = 'An unexpected error occurred: ${e.toString()}';
        });
      }
    }
  }

  // Email validation
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an email';
    }
    final emailPattern = r'^[^@]+@[^@]+\.[^@]+$';
    if (!RegExp(emailPattern).hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  // Password validation
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // Name validation
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Create Account',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Let's Get Started!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Create an account to continue.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 40),

              // Name TextField
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: _validateName,
              ),
              SizedBox(height: 20),

              // Email TextField
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              SizedBox(height: 20),

              // Password TextField
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: _validatePassword,
              ),
              SizedBox(height: 20),

              // Bio TextField (optional)
              TextFormField(
                controller: _bioController,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit),
                ),
                keyboardType: TextInputType.text,
              ),
              SizedBox(height: 20),

              // Role Dropdown
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: InputDecoration(
                  labelText: 'Select Role',
                  border: OutlineInputBorder(),
                ),
                items: _roles.map((String role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedRole = newValue;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a role';
                  }
                  return null;
                },
              ),
              SizedBox(height: 40),

              // Sign Up Button
              ElevatedButton(
                onPressed: _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              if (errorMessage != null) ...[
                SizedBox(height: 20),
                Text(
                  errorMessage!,
                  style: TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],

              SizedBox(height: 30), // Space between button and login prompt
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account?",
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/sign-in');
                    },
                    child: Text(
                      "Sign In",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
