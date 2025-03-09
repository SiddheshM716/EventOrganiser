import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:io';
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to the app!',
              style: GoogleFonts.poppins(fontSize: 20),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EventFormScreen()), // Navigate to Event Form
                );
              },
              child: Text('Create Event'),
            ),
          ],
        ),
      ),
    );
  }
}


class EventFormScreen extends StatefulWidget {
  @override
  _EventFormScreenState createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseClient supabase = Supabase.instance.client;
  
  String? userId;
  String? posterUrl;

  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _maxTeamSizeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _fetchUserId();
  }

  Future<void> _fetchUserId() async {
    final session = supabase.auth.currentSession;
    if (session != null) {
      setState(() {
        userId = session.user.id;
      });
    }
  }

  Future<void> _pickDateTime(bool isStart) async {
    DateTime now = DateTime.now();
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        DateTime finalDateTime = DateTime(
          pickedDate.year, pickedDate.month, pickedDate.day,
          pickedTime.hour, pickedTime.minute
        );
        setState(() {
          if (isStart) {
            _startDate = finalDateTime;
          } else {
            _endDate = finalDateTime;
          }
        });
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final session = supabase.auth.currentSession;
    if (session == null) {
      print("User is not authenticated");
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) return;

    final File file = File(image.path);
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

    try {
      await supabase.storage.from('posters').upload(fileName, file);
      final String publicUrl = supabase.storage.from('posters').getPublicUrl(fileName);
      setState(() {
        posterUrl = publicUrl;
      });
    } catch (e) {
      print("Image upload failed: $e");
    }
  }

  Future<void> _submitEvent() async {
    if (_formKey.currentState!.validate() && userId != null && _startDate != null && _endDate != null && posterUrl != null) {
      try {
        await supabase.from('events').insert({
          'event_name': _eventNameController.text,
          'event_start': _startDate!.toIso8601String(),
          'event_end': _endDate!.toIso8601String(),
          'poster': posterUrl,
          'venue': _venueController.text,
          'max_team_size': int.tryParse(_maxTeamSizeController.text) ?? 1,
          'category': _categoryController.text,
          'description': _descriptionController.text,
          'created_by': userId,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Event created successfully!')),
        );
        Navigator.pop(context);
      } catch (e) {
        print("Error submitting event: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create event. Please try again.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields and ensure the poster is uploaded.')),
      );
    }
  }
Future<double> _getImageDimensions(String imageUrl) async {
  final Completer<double> completer = Completer();
  final Image image = Image.network(imageUrl);
  image.image.resolve(ImageConfiguration()).addListener(
    ImageStreamListener((ImageInfo info, bool _) {
      final double aspectRatio = info.image.width / info.image.height;
      completer.complete(aspectRatio);
    }),
  );
  return completer.future;
}
  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('Create Event')),
    body: Padding(
      padding: EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Image Picker
              posterUrl == null
                  ? ElevatedButton(
                      onPressed: _pickAndUploadImage,
                      child: Text('Select Poster'),
                    )
                  : FutureBuilder(
                      future: _getImageDimensions(posterUrl!), // Get image dimensions
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return CircularProgressIndicator();
                        }
                        final double aspectRatio = snapshot.data!;
                        final double width = 200 * aspectRatio;

                        return GestureDetector(
                          onTap: _pickAndUploadImage,
                          child: Image.network(
                            posterUrl!,
                            width: width,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
              SizedBox(height: 20),

              // Event Name & Other Fields
              _buildTextField(_eventNameController, 'Event Name'),
              _buildTextField(_venueController, 'Venue'),
              _buildTextField(_categoryController, 'Category'),
              _buildTextField(_maxTeamSizeController, 'Max Team Size', keyboardType: TextInputType.number),
              _buildTextField(_descriptionController, 'Description', maxLines: 3),

              // Event Schedule Box
              Container(
                padding: EdgeInsets.all(10),
                margin: EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Event Schedule',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Divider(color: Colors.grey),
                    _buildDateTile('Start Date & Time', _startDate, () => _pickDateTime(true)),
                    _buildDateTile('End Date & Time', _endDate, () => _pickDateTime(false)),
                  ],
                ),
              ),

              SizedBox(height: 20),

              ElevatedButton(
                onPressed: _submitEvent,
                child: Text('Submit Event'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildTextField(TextEditingController controller, String label, {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: (value) => value!.isEmpty ? 'Enter $label' : null,
      ),
    );
  }

  Widget _buildDateTile(String title, DateTime? date, VoidCallback onTap) {
    return ListTile(
      title: Text(date == null ? title : '${DateFormat.yMd().add_jm().format(date)}'),
      trailing: Icon(Icons.calendar_today),
      onTap: onTap,
    );
  }
}
