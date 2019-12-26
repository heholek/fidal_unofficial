import 'package:flutter/material.dart';

import 'search_fields.dart';
import 'search_results.dart';

class SearchPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search!!'),
        elevation: 0,
      ),
      body: Column(
        children: <Widget>[ SearchFields(), SearchResults()],
      ),
    );
  }
}
