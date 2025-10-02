import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfileAddFavShowScreen extends StatefulWidget {
  static const routeName = '/addShow';

  @override
  _ProfileAddFavShowScreenState createState() => _ProfileAddFavShowScreenState();
}

class _ProfileAddFavShowScreenState extends State<ProfileAddFavShowScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];

  Future<void> _searchShows(String query) async {
    final String url = "https://api.themoviedb.org/3/search/tv?query=$query&language=en-US";
    final String bearer = 'Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJhN2ZhMmEzYzdlNGY4MDY4NGNmN2M2MjI2NzdkOWZjZCIsIm5iZiI6MTczMTAxMjk4My41MTAzNzYsInN1YiI6IjY3MmQyMzU0ZGU1MTFlZDdkYTZhNWMzNiIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.UrRp3iLGVc9HPYtsJcJZkgjovspaTL-cXuKI1IR4rBM';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "accept": "application/json",
        "Authorization": bearer,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _searchResults = data['results'] ?? [];
      });
    } else {
      throw Exception('Failed to load search results');
    }
  }

  Future<void> addFavoriteShow(int seriesId) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await FirebaseFirestore.instance.collection('fav_shows').add({
        'seriesId': seriesId,
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Show added to favorites!')),
      );

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Favorite Show',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search for a show',
                labelStyle: TextStyle(color: Colors.white),
                filled: true,
                fillColor: Color.fromARGB(255, 107, 124, 223),
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: (query) {
                if (query.isNotEmpty) {
                  _searchShows(query);
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
                ? Center(child: Text('No shows available', style: TextStyle(color: Colors.white)))
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2 / 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final show = _searchResults[index];
                      final posterPath = show['poster_path'];
                      return GestureDetector(
                        onTap: () {
                          addFavoriteShow(show['id']);
                        },
                        child: posterPath != null
                            ? Image.network(
                                'https://image.tmdb.org/t/p/w200$posterPath',
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Colors.grey,
                                child: Center(
                                  child: Icon(Icons.image_not_supported, color: Colors.white),
                                ),
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}