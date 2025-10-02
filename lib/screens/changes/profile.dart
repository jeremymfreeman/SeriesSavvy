import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_add_fav_show.dart'; // Import ProfileAddFavShowScreen
import 'show_inspect.dart'; // Import ShowInspectScreen
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'profile_add_fav_episode.dart' as favEpisode; // Import ProfileAddFavEpisodeScreen

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<List<Map<String, dynamic>>> fetchFavoriteShows() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('fav_shows')
          .where('userId', isEqualTo: user.uid)
          .get();

      List<Map<String, dynamic>> favShows = [];
      for (var doc in snapshot.docs) {
        final seriesId = doc['seriesId'];
        final showDetails = await fetchShowDetails(seriesId);
        showDetails['docId'] = doc.id; // Add this line to include the document ID
        favShows.add(showDetails);
      }
      return favShows;
    } else {
      throw Exception('User not logged in');
    }
  }

  Future<Map<String, dynamic>> fetchShowDetails(int seriesId) async {
    final String url = "https://api.themoviedb.org/3/tv/$seriesId?language=en-US";
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

  Future<void> deleteFavoriteShow(String docId) async {
    await FirebaseFirestore.instance.collection('fav_shows').doc(docId).delete();
  }

  
  Future<List<Map<String, dynamic>>> fetchFavoriteEpisodes() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('fav_episodes')
          .where('userId', isEqualTo: user.uid)
          .get();

      List<Map<String, dynamic>> favEpisodes = [];
      for (var doc in snapshot.docs) {
        final seriesId = doc['seriesId'];
        final seasonNumber = doc['seasonNumber'];
        final episodeNumber = doc['episodeNumber'];
        final showDetails = await fetchShowDetails(seriesId);
        showDetails['seasonNumber'] = seasonNumber;
        showDetails['episodeNumber'] = episodeNumber;
        showDetails['docId'] = doc.id; // Add this line to include the document ID
        favEpisodes.add(showDetails);
      }
      return favEpisodes;
    } else {
      throw Exception('User not logged in');
    }
  }




  Future<Map<String, dynamic>> fetchEpisodeDetails(int episodeId) async {
    final String url = "https://api.themoviedb.org/3/tv/episode/$episodeId?language=en-US";
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
      throw Exception('Failed to load episode details');
    }
  }

  Future<void> deleteFavoriteEpisode(String docId) async {
    await FirebaseFirestore.instance.collection('fav_episodes').doc(docId).delete();
  }

  Future<List<Map<String, dynamic>>> fetchUserRecentReviews() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } else {
      throw Exception('User not logged in');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Profile', style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white), // Change back button color to white
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Favorite Shows',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchFavoriteShows(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error loading favorite shows', style: TextStyle(color: Colors.white)));
                  } else {
                    final favShows = snapshot.data ?? [];
                    return Container(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 4, // Always show 4 slots
                        itemBuilder: (context, index) {
                          if (index < favShows.length) {
                            final show = favShows[index];
                            return Stack(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ShowInspectScreen(seriesId: show['id']),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 120,
                                    margin: EdgeInsets.only(right: 10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Image.network(
                                          'https://image.tmdb.org/t/p/w200${show['poster_path']}',
                                          fit: BoxFit.cover,
                                          height: 190,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () async {
                                      await deleteFavoriteShow(show['docId']);
                                      setState(() {});
                                    },
                                    child: CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.red,
                                      child: Icon(Icons.close, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }  else {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProfileAddFavShowScreen(),
                                      ),
                                    ).then((_) {
                                      setState(() {});
                                    });
                                  },
                              child: Container(
                                width: 120,
                                margin: EdgeInsets.only(right: 10),
                                color: Colors.grey[300],
                                child: Center(
                                  child: Icon(Icons.add, size: 50, color: Colors.black),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  }
                },
              ),
              SizedBox(height: 20),
                  Text(
                    'Favorite Episodes',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                   FutureBuilder<List<Map<String, dynamic>>>(
                    future: fetchFavoriteEpisodes(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error loading favorite episodes', style: TextStyle(color: Colors.white)));
                      } else {
                        final favEpisodes = snapshot.data ?? [];
                        return Container(
                          height: 200,
                          child: ListView.builder(
                           scrollDirection: Axis.horizontal,
                        itemCount: 4, // Always show 4 slots
                            itemBuilder: (context, index) {
                              if (index < favEpisodes.length) {
                                final episode = favEpisodes[index];
                                return Stack(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ShowInspectScreen(seriesId: episode['id']),
                                          ),
                                        );
                                      },
                                        child: Container(
                                        width: 120,
                                        margin: EdgeInsets.only(right: 10),

                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Image.network(
                                                'https://image.tmdb.org/t/p/w200${episode['poster_path']}',
                                                fit: BoxFit.cover,
                                                height: 179,
                                              ),
                                                Positioned(
                                                bottom: 0,
                                                right: 0,
                                                child: Container(
                                                  color: Color.fromARGB(255, 107, 124, 223),
                                                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                  child: Text(
                                                  'S${episode['seasonNumber']}EP${episode['episodeNumber']}',
                                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                                  ),
                                                ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () async {
                                          if (episode['docId'] != null) {
                                            await deleteFavoriteEpisode(episode['docId']);
                                            setState(() {});
                                          }
                                        },
                                        child: CircleAvatar(
                                          radius: 12,
                                          backgroundColor: Colors.red,
                                          child: Icon(Icons.close, size: 16, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => favEpisode.ProfileAddFavEpisodeScreen())).then((_) {
                                      setState(() {});
                                    });
                                  },
                                  child: Container(
                                    width: 120,
                                    margin: EdgeInsets.only(right: 10),
                                    color: Colors.grey[300],
                                    child: Center(
                                      child: Icon(Icons.add, size: 50, color: Colors.black),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      }
                    },
                  ),
              SizedBox(height: 20),
              Text(
                'Your Recent Activity',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              FutureBuilder<List<Map<String, dynamic>>>( 
                future: fetchUserRecentReviews(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error loading recent reviews', style: TextStyle(color: Colors.white)));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No recent reviews found', style: TextStyle(color: Colors.white)));
                  } else {
                    final reviews = snapshot.data!;
                    return Container(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: reviews.length,
                        itemBuilder: (context, index) {
                          final review = reviews[index];
                          final seriesId = review['seriesId'];
                          return FutureBuilder<Map<String, dynamic>>(
                            future: fetchShowDetails(seriesId),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Center(child: CircularProgressIndicator());
                              } else if (snapshot.hasError) {
                                return Center(child: Text('Error loading show details', style: TextStyle(color: Colors.white)));
                              } else {
                                final showDetails = snapshot.data ?? {};
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ShowInspectScreen(seriesId: seriesId),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 120,
                                    margin: EdgeInsets.only(right: 10),
                                    child: Column(
                                      children: [
                                        if (showDetails['poster_path'] != null)
                                          Image.network(
                                            'https://image.tmdb.org/t/p/w200${showDetails['poster_path']}',
                                            fit: BoxFit.cover,
                                            height: 190,
                                          ),
                                        SizedBox(height: 5),
                                      ],
                                    ),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}