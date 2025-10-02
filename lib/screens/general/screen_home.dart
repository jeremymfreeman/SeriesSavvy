// -----------------------------------------------------------------------
// Filename: screen_home.dart
// Original Author: Dan Grissom
// Creation Date: 10/31/2024
// Copyright: (c) 2024 CSC322
// Description: This file contains the screen for a dummy home screen
//               history screen.

//////////////////////////////////////////////////////////////////////////
// Imports
//////////////////////////////////////////////////////////////////////////

// Flutter imports

// Flutter external package imports
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// App relative file imports
import '../changes/add_show.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../changes/show_inspect.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

//////////////////////////////////////////////////////////////////////////
// StateFUL widget which manages state. Simply initializes the state object.
//////////////////////////////////////////////////////////////////////////
class ScreenHome extends ConsumerStatefulWidget {
  static const routeName = '/home';

  @override
  ConsumerState<ScreenHome> createState() => _ScreenHomeState();
}

//////////////////////////////////////////////////////////////////////////
// The actual STATE which is managed by the above widget.
//////////////////////////////////////////////////////////////////////////
///
///
  Future<Map<String, dynamic>> fetchPopularTVShows() async {
    final String url = "https://api.themoviedb.org/3/trending/tv/week?language=en-US";
    final String apiKey = 'a7fa2a3c7e4f80684cf7c622677d9fcd';
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
      throw Exception('Failed to load popular TV shows');
    }
  }
  //////////////////////////////////////////////////////////////////////////
// The pulling for popular tv shows is managed by the above widget.
//////////////////////////////////////////////////////////////////////////

  Future<Map<String, dynamic>> fetchTopRatedTVShows() async {
    final String url = "https://api.themoviedb.org/3/tv/top_rated?language=en-US&page=1";
    final String apiKey = 'a7fa2a3c7e4f80684cf7c622677d9fcd';
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
      throw Exception('Failed to load top-rated TV shows');
    }
  }
    //////////////////////////////////////////////////////////////////////////
// The pulling for top rated tv shows is managed by the above widget.
//////////////////////////////////////////////////////////////////////////
///

  Future<Map<String, dynamic>> fetchShowDetails(int seriesId) async {
    final String url = "https://api.themoviedb.org/3/tv/$seriesId?language=en-US";
    final String apiKey = 'a7fa2a3c7e4f80684cf7c622677d9fcd';
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
     //////////////////////////////////////////////////////////////////////////
// The pulling for the recent acitivity
//////////////////////////////////////////////////////////////////////////
///

class _ScreenHomeState extends ConsumerState<ScreenHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_fab', // Unique heroTag
        shape: ShapeBorder.lerp(CircleBorder(), StadiumBorder(), 0.5),
        onPressed: () => GoRouter.of(context).push(AddShowScreen.routeName),
        splashColor: Theme.of(context).primaryColor,
        child: Icon(FontAwesomeIcons.plus),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Popular Right Now',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              FutureBuilder<Map<String, dynamic>>(
                future: fetchPopularTVShows(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    final List<dynamic> shows = snapshot.data?['results'] ?? [];

                    return Container(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: shows.length,
                        itemBuilder: (context, index) {
                          final show = shows[index];
                          return GestureDetector(
                            onTap: () {
                              context.push(
                                ShowInspectScreen.routeName,
                                extra: show['id'], // Pass the series_id to the ShowInspectScreen
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
                          );
                        },
                      ),
                    );
                  }
                },
              ),
             /*  Text(
                'Popular With Friends',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              // Add content here
              SizedBox(height: 20), */
              Text(
                'Shows You Might Like',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              FutureBuilder<Map<String, dynamic>>(
                future: fetchTopRatedTVShows(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    final List<dynamic> shows = snapshot.data?['results'] ?? [];

                    return Container(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: shows.length,
                        itemBuilder: (context, index) {
                          final show = shows[index];
                          return GestureDetector(
                            onTap: () {
                              context.push(
                                ShowInspectScreen.routeName,
                                extra: show['id'], // Pass the series_id to the ShowInspectScreen
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
                          );
                        },
                      ),
                    );
                  }
                },
              ),
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
            
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No recent reviews found'));
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
                                return Center(child: Text('No Recent Activity'));
                              } else {
                                final showDetails = snapshot.data ?? {};
                                return GestureDetector(
                                  onTap: () {
                                    context.push(
                                      ShowInspectScreen.routeName,
                                      extra: seriesId,
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