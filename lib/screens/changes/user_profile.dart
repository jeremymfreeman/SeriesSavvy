import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'show_inspect.dart'; // Import ShowInspectScreen
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserProfileScreen extends StatelessWidget {
  final String userId;

  UserProfileScreen({required this.userId});

  Future<Map<String, dynamic>> _fetchUserProfile() async {
    if (userId.isEmpty) {
      throw Exception('User ID is empty');
    }

    final DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('app_user_profiles').doc(userId).get();
    if (!userDoc.exists) {
      throw Exception('User not found');
    }

    final userData = userDoc.data() as Map<String, dynamic>;
    print('Fetched user data: $userData'); // Log the user data to debug
    return userData;
  }

  Future<void> _followUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final currentUserDoc = FirebaseFirestore.instance.collection('app_user_profiles').doc(currentUser.uid);
      await currentUserDoc.update({
        'following': FieldValue.arrayUnion([userId])
      });
    }
  }

  Future<List<Map<String, dynamic>>> fetchFavoriteShows() async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('fav_shows')
        .where('userId', isEqualTo: userId)
        .get();

    List<Map<String, dynamic>> favShows = [];
    for (var doc in snapshot.docs) {
      final seriesId = doc['seriesId'];
      final showDetails = await fetchShowDetails(seriesId);
      showDetails['docId'] = doc.id; // Add this line to include the document ID
      favShows.add(showDetails);
    }
    return favShows;
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

  Future<List<Map<String, dynamic>>> fetchFavoriteEpisodes() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('fav_episodes')
          .where('userId', isEqualTo: userId)
          .get();

      if (snapshot.docs.isEmpty) {
        print('No favorite episodes found for user: $userId');
        return [];
      }

      List<Map<String, dynamic>> favEpisodes = [];
      for (var doc in snapshot.docs) {
        final seriesId = doc['seriesId'];
        final seasonNumber = doc['seasonNumber'];
        final episodeNumber = doc['episodeNumber'];
        final showDetails = await fetchShowDetails(seriesId);
        showDetails['seasonNumber'] = seasonNumber;
        showDetails['episodeNumber'] = episodeNumber;
        favEpisodes.add(showDetails);
      }
      return favEpisodes;
    } catch (e) {
      print('Error fetching favorite episodes for user $userId: $e');
      throw Exception('Failed to load favorite episodes');
    }
  }

  Future<List<Map<String, dynamic>>> fetchUserRecentReviews() async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('reviews')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(10)
        .get();

    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Loading...'),
            ),
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Error'),
            ),
            body: Center(child: Text('Error loading user profile')),
          );
        } else {
            final user = snapshot.data!;
            return Scaffold(
              appBar: AppBar(
              title: Text('${user['first_name'] ?? 'Unknown'} ${user['last_name'] ?? ''}', style: TextStyle(fontSize: 24, color: Colors.white)),
              actions: [
                StatefulBuilder(
                builder: (context, setState) {
                  bool isFollowing = user['followers']?.contains(FirebaseAuth.instance.currentUser?.uid) ?? false;
                  return IconButton(
                  icon: Icon(Icons.person_add, color: isFollowing ? Colors.green : Colors.white),
                  onPressed: () async {
                    final currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser != null) {
                    final currentUserDoc = FirebaseFirestore.instance.collection('app_user_profiles').doc(currentUser.uid);
                    if (isFollowing) {
                      await currentUserDoc.update({
                      'following': FieldValue.arrayRemove([userId])
                      });
                    } else {
                      await currentUserDoc.update({
                      'following': FieldValue.arrayUnion([userId])
                      });
                    }
                    setState(() {
                      isFollowing = !isFollowing;
                    });
                    }
                  },
                  );
                },
                ),
              ],
              ),
              body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
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
                        itemCount: favShows.length,
                        itemBuilder: (context, index) {
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
                            ],
                          );
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
                        itemCount: favEpisodes.length,
                        itemBuilder: (context, index) {
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
                            ],
                          );
                        },
                      ),
                    );
                  }
                },
              ),
              SizedBox(height: 20),
              Text(
                'Recent Activity',
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
      );
    }
  }