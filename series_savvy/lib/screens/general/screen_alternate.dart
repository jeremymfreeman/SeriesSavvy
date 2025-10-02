import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

//////////////////////////////////////////////////////////////////////////
// StateFUL widget which manages state. Simply initializes the state object.
//////////////////////////////////////////////////////////////////////////
class ScreenAlternate extends ConsumerStatefulWidget {
  static const routeName = '/alternative';

  @override
  ConsumerState<ScreenAlternate> createState() => _ScreenAlternateState();
}

class _ScreenAlternateState extends ConsumerState<ScreenAlternate> {
  Future<List<Map<String, dynamic>>> fetchFriendsReviews() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('app_user_profiles')
          .doc(user.uid)
          .get();

      final List<String> friendIds = List<String>.from(userDoc['following'] ?? []);

      if (friendIds.isEmpty) {
        return [];
      }

      final QuerySnapshot reviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('userId', whereIn: friendIds)
          .orderBy('timestamp', descending: true)
          .limit(6)
          .get();

      return reviewsSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchFriendsReviews(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading friends reviews: ${snapshot.error}', style: TextStyle(color: Colors.white)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No friends reviews found', style: TextStyle(color: Colors.white)));
          } else {
            final reviews = snapshot.data!;
            return ListView.builder(
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                final seriesId = review['seriesId'];
                final userId = review['userId'];
                return FutureBuilder<Map<String, dynamic>>(
                  future: fetchShowDetails(seriesId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error loading show details: ${snapshot.error}', style: TextStyle(color: Colors.white)));
                    } else {
                      final showDetails = snapshot.data ?? {};
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('app_user_profiles').doc(userId).get(),
                        builder: (context, userSnapshot) {
                          if (userSnapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          } else if (userSnapshot.hasError) {
                            return Center(child: Text('Error loading user details: ${userSnapshot.error}', style: TextStyle(color: Colors.white)));
                          } else {
                            final userData = userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
                            final userName = '${userData['first_name'] ?? 'Unknown'} ${userData['last_name'] ?? ''}';
                            return Card(
                              color: Color.fromARGB(255, 107, 124, 223), // Set the card color
                              margin: EdgeInsets.all(10),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          showDetails['name'] ?? 'Unknown Show',
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                        SizedBox(height: 5),
                                        Row(
                                          children: List.generate(5, (starIndex) {
                                            return Icon(
                                              starIndex < (review['rating'] ?? 0)
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              color: Colors.yellow,
                                            );
                                          }),
                                        ),
                                        SizedBox(height: 5),
                                        if (showDetails['poster_path'] != null)
                                          Image.network(
                                            'https://image.tmdb.org/t/p/w200${showDetails['poster_path']}',
                                            fit: BoxFit.cover,
                                            height: 150,
                                          ),
                                      ],
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              userName,
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                            ),
                                          ),
                                          SizedBox(height: 5),
                                          Text(
                                            review['review'] ?? 'No review',
                                            style: TextStyle(fontSize: 14, color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                      );
                    }
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}