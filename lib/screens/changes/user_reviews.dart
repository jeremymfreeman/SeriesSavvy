import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'edit_review.dart'; // Import EditReviewScreen

class UserReviewScreen extends StatelessWidget {
  static const routeName = '/userReviews';

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
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('My Reviews', style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white), // Change back button color to white
      ),
      body: user != null
          ? StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reviews')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading reviews', style: TextStyle(color: Colors.white)));
                } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No reviews found', style: TextStyle(color: Colors.white)));
                } else {
                  final reviews = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      final data = review.data() as Map<String, dynamic>;
                      final seriesId = data['seriesId'];
                      final seasonNumber = data.containsKey('seasonNumber') ? data['seasonNumber'] : null;
                      final episodeNumber =data.containsKey('episodeNumber') ? data['episodeNumber'] : null;
                      return FutureBuilder<Map<String, dynamic>>(
                        future: fetchShowDetails(seriesId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return ListTile(
                              title: Text('Error loading show details', style: TextStyle(color: Colors.white)),
                            );
                          } else {
                            final showDetails = snapshot.data ?? {};
                            return Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 120,
                                      margin: EdgeInsets.all(10),
                                      child: Image.network(
                                        'https://image.tmdb.org/t/p/w200${showDetails['poster_path']}',
                                        fit: BoxFit.cover,
                                        height: 150,
                                      ),
                                    ),
                                    Expanded(
                                      child: ListTile(
                                      title: Row(
                                        children: List.generate(5, (starIndex) {
                                        return Icon(
                                          starIndex < (review['rating'] ?? 0)
                                            ? Icons.star
                                            : Icons.star_border,
                                          color: Colors.yellow,
                                        );
                                        }),
                                      ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              review['review'],
                                              style: TextStyle(color: Colors.white),
                                            ),
                                            if (seasonNumber != null && episodeNumber != null)
                                              Text(
                                                'Reviewed: Season $seasonNumber, Episode $episodeNumber',
                                                style: TextStyle(color: Colors.white),
                                              )
                                            else if (seasonNumber != null)
                                              Text(
                                                'Reviewed: Season $seasonNumber',
                                                style: TextStyle(color: Colors.white),
                                              )
                                            else
                                              Text(
                                                'Reviewed: Entire Show',
                                                style: TextStyle(color: Colors.white),
                                              ),
                                          ],
                                        ),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => EditReviewScreen(
                                                reviewId: review.id,
                                                initialReview: review['review'],
                                                initialRating: review['rating'],
                                                seriesId: seriesId,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                Divider(color: Colors.white),
                              ],
                            );
                          }
                        },
                      );
                    },
                  );
                }
              },
            )
          : Center(child: Text('Please log in to view your reviews', style: TextStyle(color: Colors.white))),
    );
  }
}