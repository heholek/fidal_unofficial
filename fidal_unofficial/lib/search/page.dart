import 'package:fidal_unofficial/net/fidal_api.dart';
import 'package:flutter/material.dart';

import 'search_fields.dart';
import 'search_results.dart';

abstract class SearchInfoChangedCallback {
  void onSearchInfoChanged(SearchInfo si);
}

class SearchPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var sr = SearchResults();

    return Scaffold(
      appBar: AppBar(
        title: Text('Search!!'),
        elevation: 0,
      ),
      body: Column(
        children: <Widget>[SearchFields(siChanged: sr), sr],
      ),
    );
  }
}
