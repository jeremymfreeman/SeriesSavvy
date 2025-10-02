import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'show_inspect.dart'; // Import ShowInspectScreen

class WatchlistScreen extends StatelessWidget {
  static const routeName = '/watchlist';

  Future<List<Map<String, dynamic>>> fetchWatchlist() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('watchlist')
          .where('userId', isEqualTo: user.uid)
          .get();

      List<Map<String, dynamic>> watchlist = [];
      for (var doc in snapshot.docs) {
        final seriesId = doc['seriesId'];
        final showDetails = await fetchShowDetails(seriesId);
        watchlist.add(showDetails);
      }
      return watchlist;
    } else {
      throw Exception('User not logged in');
    }
  }

  Future<Map<String, dynamic>> fetchShowDetails(int seriesId) async {
    final String url = "https://api.themoviedb.org/3/tv/$seriesId?language=en-US";
    // final String apiKey = 'a7fa2a3c7e4f80684cf7c622677d9fcd';
    final String bearerToken = 'Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJhN2ZhMmEzYzdlNGY4MDY4NGNmN2M2MjI2NzdkOWZjZCIsIm5iZiI6MTczMTAxMjk4My41MTAzNzYsInN1YiI6IjY3MmQyMzU0ZGU1MTFlZDdkYTZhNWMzNiIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.UrRp3iLGVc9HPYtsJcJZkgjovspaTL-cXuKI1IR4rBM';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "accept": "application/json",
        "Authorization": bearerToken,
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load show details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Watchlist',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF5E59D9),
        iconTheme: IconThemeData(color: Colors.white), // Change back button color to white
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchWatchlist(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading watchlist'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No shows in your watchlist'));
          } else {
            final watchlist = snapshot.data!;
            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2 / 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: watchlist.length,
              itemBuilder: (context, index) {
                final show = watchlist[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ShowInspectScreen(seriesId: show['id']),
                      ),
                    );
                  },
                  child: Image.network(
                    'https://image.tmdb.org/t/p/w200${show['poster_path']}',
                    fit: BoxFit.cover,
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}