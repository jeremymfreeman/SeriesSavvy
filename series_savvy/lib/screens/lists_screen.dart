import 'package:flutter/material.dart';

class ListsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lists'),
      ),
      body: Center(
        child: Text('Create custom lists of your favorite series.'),
      ),
    );
  }
}
