import 'dart:async';

import 'package:fidal_unofficial/net/fidal_api.dart';
import 'package:flutter/material.dart';

import 'search_fields.dart';
import 'search_results.dart';

class SearchPage extends StatelessWidget {
  final FidalApi _api;
  final StreamController<SearchStatus> _streamController;

  SearchPage(this._api)
      : _streamController = StreamController<SearchStatus>.broadcast();

  @override
  Widget build(BuildContext context) {
    SearchResultsWidget sr = SearchResultsWidget(_api, _streamController);
    SearchFieldsWidget sf = SearchFieldsWidget(_streamController);

    return Scaffold(
      appBar: AppBar(
        title: Text('Search!!'),
        elevation: 0,
      ),
      body: Column(
        children: <Widget>[sf, Expanded(child: sr)],
      ),
    );
  }
}
