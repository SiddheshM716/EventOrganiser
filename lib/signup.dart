import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isOtpSent = false;

  Future<void> signUp() async {
  try {
    // Check if the user already exists in the database
    final response = await Supabase.instance.client
        .from('users')
        .select()
        .eq('email', _emailController.text)
        .maybeSingle(); // Fetch a single user if exists

    if (response != null) {
      // User already exists
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User already exists. Please log in.')),
      );
      return;
    }

    // If user doesn't exist, proceed with OTP authentication
    await Supabase.instance.client.auth.signInWithOtp(
      email: _emailController.text,
      shouldCreateUser: true,
    );
    setState(() => _isOtpSent = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('OTP sent to your email. Please verify.')),
    );
  } catch (e) {
    print('Sign-up error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error during sign-up. Please try again.')),
    );
  }
}

  Future<void> verifyOtp() async {
    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        email: _emailController.text,
        token: _otpController.text,
        type: OtpType.email,
      );

      if (response.session != null && response.user != null) {
        await Supabase.instance.client.from('users').upsert({
          'id': response.user!.id,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'username': _usernameController.text,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OTP Verified! Welcome!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } catch (e) {
      print('OTP Verification error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP verification failed. Please try again.')),
      );
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.indigo, Colors.blueAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Organiser Sign Up",
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(_emailController, "Email", Icons.email),
                      if (!_isOtpSent) ...[
                        _buildTextField(_phoneController, "Phone Number", Icons.phone),
                        _buildTextField(_usernameController, "Username", Icons.person),
                        const SizedBox(height: 15),
                        _buildButton("Send OTP", signUp),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => LoginScreen()),
                            );
                          },
                          child: Text("Already have an account? Log in", style: GoogleFonts.poppins(fontSize: 16)),
                        ),
                      ] else ...[
                        _buildTextField(_otpController, "Enter OTP", Icons.lock),
                        const SizedBox(height: 15),
                        _buildButton("Verify OTP", verifyOtp),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        style: GoogleFonts.poppins(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue),
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 14),
          backgroundColor: Colors.blueAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(text, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => AuthScreen()),
      (route) => false, // Removes all previous routes from the stack
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Welcome to the app!',
          style: GoogleFonts.poppins(fontSize: 20),
        ),
      ),
    );
  }
}

