import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart'; // Import GoRouter
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Import FontAwesomeIcons
import 'add_show.dart'; // Import AddShowScreen
import 'create_review.dart'; // Import CreateReviewScreen
import 'episode_review.dart'; // Import the EpisodeReviewScreen

class ShowInspectScreen extends StatefulWidget {
  static const routeName = '/showInspect';

  final int seriesId;

  ShowInspectScreen({required this.seriesId});

  @override
  _ShowInspectScreenState createState() => _ShowInspectScreenState();
}

class _ShowInspectScreenState extends State<ShowInspectScreen> {
  int selectedSeason = 1;

  Future<Map<String, dynamic>> fetchShowDetails() async {
    final String url = "https://api.themoviedb.org/3/tv/${widget.seriesId}?language=en-US";
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

  Future<Map<String, dynamic>> fetchSeasonDetails(int seasonNumber) async {
    final String url = "https://api.themoviedb.org/3/tv/${widget.seriesId}/season/$seasonNumber?language=en-US";
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
      throw Exception('Failed to load season details');
    }
  }

  Future<String?> fetchTrailerUrl() async {
    final String url = "https://api.themoviedb.org/3/tv/${widget.seriesId}/videos?language=en-US";
    final String bearerToken = 'Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJhN2ZhMmEzYzdlNGY4MDY4NGNmN2M2MjI2NzdkOWZjZCIsIm5iZiI6MTczMTAxMjk4My41MTAzNzYsInN1YiI6IjY3MmQyMzU0ZGU1MTFlZDdkYTZhNWMzNiIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.UrRp3iLGVc9HPYtsJcJZkgjovspaTL-cXuKI1IR4rBM';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "accept": "application/json",
        "Authorization": bearerToken,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> videos = data['results'] ?? [];
      final trailer = videos.firstWhere((video) => video['type'] == 'Trailer', orElse: () => null);
      if (trailer != null) {
        return 'https://www.youtube.com/watch?v=${trailer['key']}';
      }
    }
    return null;
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'inspect_fab', // Unique heroTag
        shape: ShapeBorder.lerp(CircleBorder(), StadiumBorder(), 0.5),
        onPressed: () => GoRouter.of(context).push(AddShowScreen.routeName),
        splashColor: Theme.of(context).primaryColor,
        child: Icon(FontAwesomeIcons.plus),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchShowDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final show = snapshot.data ?? {};

            return Scaffold(
              appBar: AppBar(
                title: Text(
                  show['name'] ?? 'Show Inspect',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Color(0xFF5E59D9),
                iconTheme: IconThemeData(color: Colors.white), // Change back button color to white
                actions: [
                  IconButton(
                    icon: Icon(Icons.rate_review, color: Colors.white),
                    onPressed: () {
                      context.push(
                        CreateReviewScreen.routeName,
                        extra: widget.seriesId, // Pass the series_id to the CreateReviewScreen
                      );
                    },
                  ),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (show['poster_path'] != null)
                      Center(
                        child: Image.network(
                          'https://image.tmdb.org/t/p/w500${show['poster_path']}',
                          fit: BoxFit.cover,
                          height: 300,
                        ),
                      ),
                    SizedBox(height: 10),
                    Text(
                      show['overview'] ?? 'No overview available',
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Rating: ${show['vote_average'] != null ? (show['vote_average'] as num).toStringAsFixed(1) : 'N/A'}',
                      style: TextStyle(color: Colors.white),
                    ),
                    Text(
                      'Director: ${show['created_by'] != null && show['created_by'].isNotEmpty ? show['created_by'][0]['name'] : 'N/A'}',
                      style: TextStyle(color: Colors.white),
                    ),
                    Text(
                      'Released: ${show['first_air_date'] != null ? DateTime.parse(show['first_air_date']).year.toString() : 'N/A'}',
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: 10),
                    /* FutureBuilder<String?>(
                      future: fetchTrailerUrl(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        } else if (snapshot.hasData && snapshot.data != null) {
                          return ElevatedButton(
                            onPressed: () => _launchURL(snapshot.data!),
                            child: Text('Watch Trailer'),
                          );
                        } else {
                          return Container();
                        }
                      },
                    ), */
                    SizedBox(height: 10),
                    Text(
                      'Episodes',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    DropdownButton<int>(
                      value: selectedSeason,
                      items: List.generate(show['number_of_seasons'], (index) {
                        return DropdownMenuItem(
                          value: index + 1,
                          child: Text(
                            'Season ${index + 1}',
                            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        );
                      }),
                      onChanged: (value) {
                        setState(() {
                          selectedSeason = value!;
                        });
                      },
                    ),
                    FutureBuilder<Map<String, dynamic>>(
                      future: fetchSeasonDetails(selectedSeason),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        } else {
                          final seasonDetails = snapshot.data ?? {};
                          final episodes = seasonDetails['episodes'] ?? [];

                          return Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: episodes.map<Widget>((episode) {
                              return Container(
                                width: (MediaQuery.of(context).size.width - 42) / 2, // Adjust width to fit two items per row with spacing
                                child: Card(
                                  color: Color.fromARGB(255, 107, 124, 223),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'S${episode['season_number']}E${episode['episode_number']}',
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          episode['name'] ?? 'No title',
                                          style: TextStyle(color: Colors.white),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: 8), // Replace Spacer with SizedBox
                                        Align(
                                          alignment: Alignment.bottomRight,
                                          child: IconButton(
                                            icon: Icon(Icons.rate_review, color: Colors.blue),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => EpisodeReviewScreen(
                                                    seriesId: widget.seriesId,
                                                    seasonNumber: episode['season_number'],
                                                    episodeNumber: episode['episode_number'],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}