import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EpisodeSelectScreen extends StatefulWidget {
  static const routeName = '/episodeSelect';

  final int seriesId;
  final int seasonNumber;

  EpisodeSelectScreen({required this.seriesId, required this.seasonNumber});

  @override
  _EpisodeSelectScreenState createState() => _EpisodeSelectScreenState();
}

class _EpisodeSelectScreenState extends State<EpisodeSelectScreen> {
  List<dynamic> _episodes = [];
  late int _selectedSeasonNumber;
  List<int> _seasons = [];

  @override
  void initState() {
    super.initState();
    _selectedSeasonNumber = widget.seasonNumber;
    _fetchSeasons();
  }

  Future<void> _fetchSeasons() async {
    final String url = "https://api.themoviedb.org/3/tv/${widget.seriesId}?language=en-US";
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
        _seasons = List<int>.from(data['seasons'].map((season) => season['season_number']).where((number) => number != 0));
        _fetchSeasonEpisodes();
      });
    } else {
      throw Exception('Failed to load seasons');
    }
  }

  Future<void> _fetchSeasonEpisodes() async {
    final String url = "https://api.themoviedb.org/3/tv/${widget.seriesId}/season/$_selectedSeasonNumber?language=en-US";
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
        _episodes = data['episodes'] ?? [];
      });
    } else {
      throw Exception('Failed to load season episodes');
    }
  }

  Future<Map<String, dynamic>> _fetchEpisodeImages(int episodeNumber) async {
    final String url = "https://api.themoviedb.org/3/tv/${widget.seriesId}/season/$_selectedSeasonNumber/episode/$episodeNumber/images";
    final String bearer = 'Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJhN2ZhMmEzYzdlNGY4MDY4NGNmN2M2MjI2NzdkOWZjZCIsIm5iZiI6MTczMTAxMjk4My41MTAzNzYsInN1YiI6IjY3MmQyMzU0ZGU1MTFlZDdkYTZhNWMzNiIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.UrRp3iLGVc9HPYtsJcJZkgjovspaTL-cXuKI1IR4rBM';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "accept": "application/json",
        "Authorization": bearer,
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load episode images');
    }
  }

  Future<void> addFavoriteEpisode(int episodeNumber) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await FirebaseFirestore.instance.collection('fav_episodes').add({
        'seriesId': widget.seriesId,
        'seasonNumber': _selectedSeasonNumber,
        'episodeNumber': episodeNumber,
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Episode added to favorites!', style: TextStyle(color: Colors.white))),
      );

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Episode',
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
            child: DropdownButton<int>(
              value: _selectedSeasonNumber,
              items: _seasons.map((season) {
                return DropdownMenuItem(
                  value: season,
                  child: Text('Season $season', style: TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSeasonNumber = value!;
                  _fetchSeasonEpisodes();
                });
              },
            ),
          ),
          Expanded(
            child: _episodes.isEmpty
                ? Center(child: CircularProgressIndicator())
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2 / 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _episodes.length,
                    itemBuilder: (context, index) {
                      final episode = _episodes[index];
                      return FutureBuilder<Map<String, dynamic>>(
                        future: _fetchEpisodeImages(episode['episode_number']),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(child: Text('Error loading images'));
                          } else {
                            final images = snapshot.data?['stills'] ?? [];
                            final imageUrl = images.isNotEmpty
                                ? 'https://image.tmdb.org/t/p/w200${images[0]['file_path']}'
                                : null;
                            return GestureDetector(
                              onTap: () {
                                addFavoriteEpisode(episode['episode_number']);
                              },
                              child: Card(
                                color: Color.fromARGB(255, 107, 124, 223),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: imageUrl != null
                                          ? Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              color: Colors.grey[300],
                                              child: Center(
                                                child: Text(
                                                  'No Image',
                                                  style: TextStyle(color: Colors.white),
                                                ),
                                              ),
                                            ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'Episode ${episode['episode_number']}',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Text(
                                        episode['name'] ?? 'No title',
                                        style: TextStyle(fontSize: 16, color: Colors.white),
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
    );
  }
}