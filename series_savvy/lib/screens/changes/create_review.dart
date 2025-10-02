import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreateReviewScreen extends StatefulWidget {
  static const routeName = '/createReview';

  final int seriesId;

  CreateReviewScreen({required this.seriesId});

  @override
  _CreateReviewScreenState createState() => _CreateReviewScreenState();
}

class _CreateReviewScreenState extends State<CreateReviewScreen> {
  final TextEditingController _reviewController = TextEditingController();
  double _rating = 0;
  Map<String, dynamic>? _showDetails;
  bool _isOnWatchlist = false;
  String? _watchlistDocId;

  @override
  void initState() {
    super.initState();
    _fetchShowDetails();
    _checkIfOnWatchlist();
  }

  Future<void> _fetchShowDetails() async {
    final String url = "https://api.themoviedb.org/3/tv/${widget.seriesId}?language=en-US";
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
      setState(() {
        _showDetails = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load show details');
    }
  }

  Future<void> _checkIfOnWatchlist() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('watchlist')
          .where('seriesId', isEqualTo: widget.seriesId)
          .where('userId', isEqualTo: user.uid)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _isOnWatchlist = true;
          _watchlistDocId = snapshot.docs.first.id;
        });
      }
    }
  }

  void _submitReview() async {
    final review = _reviewController.text;
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && review.isNotEmpty && _rating > 0) {
      await FirebaseFirestore.instance.collection('reviews').add({
        'seriesId': widget.seriesId,
        'userId': user.uid,
        'rating': _rating,
        'review': review,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Review submitted successfully!')),
      );

      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please provide a rating and a review.')),
      );
    }
  }

  void _toggleWatchlist() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      if (_isOnWatchlist) {
        // Remove from watchlist
        await FirebaseFirestore.instance.collection('watchlist').doc(_watchlistDocId).delete();

        setState(() {
          _isOnWatchlist = false;
          _watchlistDocId = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Removed from watchlist!', style: TextStyle(color: Colors.white))),
        );
      } else {
        // Add to watchlist
        final docRef = await FirebaseFirestore.instance.collection('watchlist').add({
          'seriesId': widget.seriesId,
          'userId': user.uid,
          'timestamp': FieldValue.serverTimestamp(),
        });

        setState(() {
          _isOnWatchlist = true;
          _watchlistDocId = docRef.id;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added to watchlist!', style: TextStyle(color: Colors.white))),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to modify watchlist.', style: TextStyle(color: Colors.white))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _showDetails != null ? _showDetails!['name'] : 'Write a Review',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white), // Change back button color to white
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: Colors.green),
            onPressed: _submitReview,
          ),
          IconButton(
            icon: Icon(
                Icons.access_time,
              color: _isOnWatchlist ? Colors.green : Colors.white,
            ),
            onPressed: _toggleWatchlist,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_showDetails != null && _showDetails!['poster_path'] != null)
              Center(
                child: Image.network(
                  'https://image.tmdb.org/t/p/w500${_showDetails!['poster_path']}',
                  fit: BoxFit.cover,
                  height: 300,
                ),
              ),
            SizedBox(height: 20),
            Text(
              'Rate the Show',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            SizedBox(height: 10),
            RatingBar.builder(
              initialRating: 0,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                setState(() {
                  _rating = rating;
                });
              },
            ),
            SizedBox(height: 20),
            Text(
              'Write your review',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _reviewController,
              maxLines: 5,
              style: TextStyle(color: Colors.white), // Set text color to white
              decoration: InputDecoration(
                filled: true,
                fillColor: Color.fromARGB(255, 107, 124, 223), // Set background color of the text box
                border: OutlineInputBorder(),
                hintText: 'Type your review here',
                hintStyle: TextStyle(color: Colors.white54), // Set hint text color to a lighter white
              ),
            ),
          ],
        ),
      ),
    );
  }
}