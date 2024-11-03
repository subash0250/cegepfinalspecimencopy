import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Screens/Admin/AdminHomeScreen.dart';
import 'Screens/moderator/ModeratorHomeScreen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/home_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print("Firebase Initialization Error: $e");
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Connectify',
      theme: ThemeData(primarySwatch: Colors.purple),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => SplashScreen(),
        '/auth-wrapper': (context) => AuthWrapper(),
        '/sign-in': (context) => SignInScreen(),
        '/sign-up': (context) => SignUpScreen(),
        '/home': (context) => HomeScreen(),
        '/forgot-password': (context) => ForgotPasswordScreen(),
      },
    );
  }
}
class AuthWrapper extends StatelessWidget {
  final DatabaseReference _userRef = FirebaseDatabase.instance.ref('users');

  Future<String?> _getUserRole(String uid) async {
    try {
      final snapshot = await _userRef.child(uid).once();
      if (snapshot.snapshot.exists) {
        final userData = snapshot.snapshot.value as Map<dynamic, dynamic>;
        return userData['userRole'] as String?;
      }
    } catch (e) {
      print("Error fetching user role: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
          if (snapshot.hasData) {
          final User? user = snapshot.data;
          return FutureBuilder<String?>(
            future: _getUserRole(user!.uid),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return SplashScreen();
              } else if (roleSnapshot.hasData) {
                switch (roleSnapshot.data) {
                  case 'admin':
                    return AdminHomeScreen();
                  case 'moderator':
                    return Moderatorhomescreen();
                  default:
                    return HomeScreen();
                }
              }
              else {
                return SignInScreen();
              }
            },
          );
        } else {
          return SignInScreen();
        }
      },
    );
  }
}