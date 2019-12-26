import 'package:fidal_unofficial/net/fidal_api.dart';
import 'package:flutter/material.dart';

import 'page.dart';

class SearchResults extends StatefulWidget implements SearchInfoChangedCallback {
  @override
  State<StatefulWidget> createState() {
    return SearchResultsState();
  }

  @override
  void onSearchInfoChanged(SearchInfo si) {
    // TODO: implement onSearchInfoChanged
  }
}

class SearchResultsState extends State<SearchResults> {
  @override
  Widget build(BuildContext context) {
    return Expanded(child: ListView(),);
  }
}
