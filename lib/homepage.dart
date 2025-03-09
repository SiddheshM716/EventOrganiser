import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';
import 'addevent.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;
  String? profilePhoto, username, oneLine;
  List<Map<String, dynamic>> events = [];
  int _currentIndex = 0; // Track the selected index for the bottom navigation bar

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchEvents();
  }

  Future<void> fetchUserData() async {
    final user = supabase.auth.currentUser; // Get the signed-in user

    if (user == null) {
      print("No user signed in");
      return;
    }

    final response = await supabase
        .from('users')
        .select('profile_photo, username, one_line')
        .eq('id', user.id) // Use the user's ID instead of email
        .single();

    setState(() {
      profilePhoto = response['profile_photo'];
      username = response['username'];
      oneLine = response['one_line'];
    });
  }

  Future<void> fetchEvents() async {
    final user = supabase.auth.currentUser; // Get the signed-in user

    if (user == null) {
      print("No user signed in");
      return;
    }

    final response = await supabase
        .from('events')
        .select('poster, event_name, description')
        .eq('created_by', user.id); // Filter events by the user's ID

    setState(() {
      events = List<Map<String, dynamic>>.from(response);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: profilePhoto != null
                  ? NetworkImage(profilePhoto!)
                  : const AssetImage('assets/default_avatar.png') as ImageProvider,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(username ?? 'Loading...', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(oneLine ?? 'Loading...', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            )
          ],
        ),
        actions: [
          Transform.translate(
            offset: const Offset(-10, 0), // Move left by 10 pixels
            child: Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.mail, size: 36),
                  onPressed: () {},
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Your events', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                        child: Image.network(
                          event['poster'],
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event['event_name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 5),
                            Text(
                              event['description'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text('See more', style: TextStyle(color: Colors.blue)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Ensures equal spacing
        showSelectedLabels: false, // Hide labels
        showUnselectedLabels: false, // Hide labels
        currentIndex: _currentIndex, // Set the current index
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          // Handle navigation based on the tapped index
          if (index == 2) { // Index 2 corresponds to the "Add" button
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EventFormScreen()),
            );
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: SvgPicture.asset('assets/icons/home.svg', width: 30),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset('assets/icons/search.svg', width: 30),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset('assets/icons/add.svg', width: 30),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset('assets/icons/profile.svg', width: 30),
            label: '',
          ),
        ],
      ),
    );
  }
}
