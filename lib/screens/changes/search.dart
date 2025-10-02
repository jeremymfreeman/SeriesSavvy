import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_profile.dart'; // Import UserProfileScreen

class SearchUserScreen extends StatefulWidget {
  static const routeName = '/searchUser';

  @override
  _SearchUserScreenState createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

  Future<void> _searchUsers(String query) async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('app_user_profiles')
          .where('email_lowercase', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('email_lowercase', isLessThanOrEqualTo: query.toLowerCase() + '\uf8ff')
          .get();

      setState(() {
        _searchResults = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['uid'] = doc.id; // Ensure the document ID is included in the data
          return data;
        }).toList();
      });

      if (_searchResults.isEmpty) {
        print('No users found with the email: $query');
      } else {
        print('Found users: $_searchResults');
      }
    } catch (e) {
      print('Error searching users: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Users', style: TextStyle(color: Colors.white)), // Change text color to white
        iconTheme: IconThemeData(color: Colors.white), // Change back button color to white
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search for a user by email',
                labelStyle: TextStyle(color: Colors.white), // Change text color to white
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search, color: Colors.white), // Change icon color to white
                fillColor: Color.fromARGB(255, 107, 124, 223),
              ),
              style: TextStyle(color: Colors.white), // Change input text color to white
              onChanged: (query) {
                if (query.isNotEmpty) {
                  _searchUsers(query);
                } else {
                  setState(() {
                    _searchResults = [];
                  });
                }
              },
            ),
          ),
          Expanded(
            child: _searchResults.isEmpty
                ? Center(child: Text('No users found', style: TextStyle(color: Colors.white))) // Change text color to white
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      final firstName = user['first_name'] ?? 'Unknown';
                      final lastName = user['last_name'] ?? 'User';
                      final email = user['email'] ?? 'No email';
                      final uid = user['uid'] ?? '';

                      return ListTile(
                        title: Text('$firstName $lastName', style: TextStyle(color: Colors.white)), // Change text color to white
                        subtitle: Text(email, style: TextStyle(color: Colors.white)), // Change text color to white
                        onTap: () {
                          if (uid.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserProfileScreen(userId: uid),
                              ),
                            );
                          } else {
                            print('User ID is empty');
                          }
                        },
                      );
                      
                    },
                  ),
          ),
        ],
      ),
    );
  }
}