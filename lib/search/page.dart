import 'package:fidal_unofficial/net/fidal_api.dart';
import 'package:flutter/material.dart';

import 'search_fields.dart';
import 'search_results.dart';

class SearchPage extends StatelessWidget {
  final FidalApi _api;

  SearchPage(this._api);

  @override
  Widget build(BuildContext context) {
    ValueNotifier<SearchInfo> searchInfoNotifier = ValueNotifier(null);
    SearchResultsWidget sr = SearchResultsWidget(_api, searchInfoNotifier);
		SearchFieldsWidget sf = SearchFieldsWidget(searchInfoNotifier);

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
