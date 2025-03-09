import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'signup.dart';
import "homepage.dart";
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://wikofpppwglxphlbogrt.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indpa29mcHBwd2dseHBobGJvZ3J0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA5MDAxNDgsImV4cCI6MjA1NjQ3NjE0OH0.OfcIem2a9IbvFnxdLeajJzkCVtu_enb5NN3JWShtl0A',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Supabase Auth',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AuthCheck(), // Check session on startup
    );
  }
}

class AuthCheck extends StatefulWidget {
  @override
  _AuthCheckState createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkUserSession());
  }

  void _checkUserSession() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null && session.user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator()), // Show loading spinner while checking
    );
  }
}
