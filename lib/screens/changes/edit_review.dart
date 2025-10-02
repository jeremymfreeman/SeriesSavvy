import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditReviewScreen extends StatefulWidget {
  static const routeName = '/editReview';

  final String reviewId;
  final String initialReview;
  final double initialRating;
  final int seriesId;

  EditReviewScreen({
    required this.reviewId,
    required this.initialReview,
    required this.initialRating,
    required this.seriesId,
  });

  @override
  _EditReviewScreenState createState() => _EditReviewScreenState();
}

class _EditReviewScreenState extends State<EditReviewScreen> {
  final TextEditingController _reviewController = TextEditingController();
  double _rating = 0;
  Map<String, dynamic>? _showDetails;

  @override
  void initState() {
    super.initState();
    _reviewController.text = widget.initialReview;
    _rating = widget.initialRating;
    _fetchShowDetails();
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

  void _updateReview() async {
    final review = _reviewController.text;

    if (review.isNotEmpty && _rating > 0) {
      await FirebaseFirestore.instance.collection('reviews').doc(widget.reviewId).update({
        'rating': _rating,
        'review': review,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Review updated successfully!')),
      );

      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please provide a rating and a review.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _showDetails != null ? _showDetails!['name'] : 'Edit Review',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white), // Change back button color to white
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: Colors.green),
            onPressed: _updateReview,
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
              initialRating: _rating,
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
              'Edit your review',
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