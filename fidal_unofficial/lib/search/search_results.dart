import 'package:fidal_unofficial/net/fidal_api.dart';
import 'package:fidal_unofficial/search/search_fields.dart';
import 'package:flutter/material.dart';

class SearchResults extends StatefulWidget {
  final FidalApi _api;
  final ValueNotifier<SearchInfo> _searchInfoNotifier;

  SearchResults(this._api, this._searchInfoNotifier);

  @override
  State<StatefulWidget> createState() {
    return SearchResultsState(_searchInfoNotifier, _api);
  }
}

class SearchResultsState extends State<SearchResults> {
  List<SearchResult> data;
  bool error = false;

  SearchResultsState(ValueNotifier<SearchInfo> searchInfoNotifier, FidalApi api) {
    searchInfoNotifier.addListener(() {
      Future<List<SearchResult>> future = api.search(searchInfoNotifier.value);
      future.then((List<SearchResult> result) {
        setState(() {
          error = false;
          data = result;
        });
      }, onError: (e) {
        print(e);
        setState(() {
          data = null;
          error = true;
        });
      });
    });
  }

  @override 
  void initState() {
    super.initState();
    widget._searchInfoNotifier.value = SearchFieldsState.defaultSearchInfo();
  }

  @override
  Widget build(BuildContext context) {
    if (error) {
      return Center(
          child:
              Text("An error occurred!", style: TextStyle(color: Colors.red)));
    }

    if (data == null || data.length == 0) {
      return Center(child: Text("No data to display."));
    }

    return ListView.builder(
        itemCount: data.length,
        itemBuilder: (BuildContext context, int i) {
          SearchResult sr = data[i];
          return Padding(
              child: Column(
                children: <Widget>[
                  Text(sr.name, style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    sr.desc,
                    style: TextStyle(fontStyle: FontStyle.italic),
                  )
                ],
              ),
              padding: EdgeInsets.all(8.0));
        });
  }
}
