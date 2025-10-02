import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'create_review.dart';

class AddShowScreen extends StatefulWidget {
  static const routeName = '/addShow';

  @override
  _AddShowScreenState createState() => _AddShowScreenState();
}

class _AddShowScreenState extends State<AddShowScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];

  Future<List<dynamic>> _searchMovies(String query) async {
    final String url = "https://api.themoviedb.org/3/search/tv?query=$query&language=en-US";
    final String bearerToken =
        'Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJhN2ZhMmEzYzdlNGY4MDY4NGNmN2M2MjI2NzdkOWZjZCIsIm5iZiI6MTczMTAxMjk4My41MTAzNzYsInN1YiI6IjY3MmQyMzU0ZGU1MTFlZDdkYTZhNWMzNiIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.UrRp3iLGVc9HPYtsJcJZkgjovspaTL-cXuKI1IR4rBM';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "accept": "application/json",
        "Authorization": bearerToken,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'] ?? [];
    } else {
      throw Exception('Failed to load search results');
    }
  }

  Future<Map<String, dynamic>> fetchShowDetails(int seriesId) async {
    final String url = "https://api.themoviedb.org/3/tv/$seriesId?language=en-US";
    final String bearerToken =
        'Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJhN2ZhMmEzYzdlNGY4MDY4NGNmN2M2MjI2NzdkOWZjZCIsIm5iZiI6MTczMTAxMjk4My41MTAzNzYsInN1YiI6IjY3MmQyMzU0ZGU1MTFlZDdkYTZhNWMzNiIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.UrRp3iLGVc9HPYtsJcJZkgjovspaTL-cXuKI1IR4rBM';

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

  void _onSearchChanged() async {
    final query = _searchController.text;
    if (query.isNotEmpty) {
      final results = await _searchMovies(query);
      setState(() {
        _searchResults = results;
      });
    } else {
      setState(() {
        _searchResults = [];
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Show',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search for a show',
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color.fromARGB(255, 107, 124, 223),
                hintText: 'Type your search here',
                hintStyle: TextStyle(color: Colors.white54),
                suffixIcon: Icon(Icons.search, color: Colors.white),
              ),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final show = _searchResults[index];
                  return FutureBuilder<Map<String, dynamic>>(
                    future: fetchShowDetails(show['id']),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return ListTile(
                          title: Text('Error loading show details'),
                        );
                      } else {
                        final showDetails = snapshot.data ?? {};
                        return Card(
                          color: Color.fromARGB(255, 107, 124, 223), // Set the card color
                          child: Container(
                            height: 160,
                            child: Row(
                              children: [
                                Container(
                                  margin: EdgeInsets.all(10),
                                  child: show['poster_path'] != null
                                      ? CachedNetworkImage(
                                          imageUrl: 'https://image.tmdb.org/t/p/w200${show['poster_path']}',
                                          fit: BoxFit.cover,
                                          height: 150,
                                          placeholder: (context, url) => CircularProgressIndicator(),
                                          errorWidget: (context, url, error) => Icon(Icons.error),
                                        )
                                      : null,
                                ),
                                Expanded(
                                  child: ListTile(
                                    title: Text(
                                      show['name'] ?? 'No title',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Release Year: ${show['first_air_date']?.split('-')[0] ?? 'Unknown'}',
                                          style: TextStyle(color: Colors.white, fontSize: 16),
                                        ),
                                        Text(
                                          'Seasons: ${showDetails['number_of_seasons']?.toString() ?? 'Unknown'}',
                                          style: TextStyle(color: Colors.white, fontSize: 16),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      context.push(
                                        CreateReviewScreen.routeName,
                                        extra: show['id'],
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}