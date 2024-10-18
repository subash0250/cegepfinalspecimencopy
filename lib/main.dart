import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/sign_in_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/home_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    print("Firebase Initialized"); // Debugging statement
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
      initialRoute: '/',
      routes: {
        '/': (context) => AuthWrapper(), // Use AuthWrapper for authentication flow
        '/sign-in': (context) => SignInScreen(),
        '/sign-up': (context) => SignUpScreen(),
        '/home': (context) => HomeScreen(),
        '/forgot-password': (context) => ForgotPasswordScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Debugging statement
        print("Auth state changed: ${snapshot.connectionState}, user: ${snapshot.data}");

        if (snapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen(); // Show splash screen while loading
        } else if (snapshot.hasData) {
          return HomeScreen(); // User is signed in
        } else {
          return SignInScreen(); // User is not signed in
        }
      },
    );
  }
}
