import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:io';


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
