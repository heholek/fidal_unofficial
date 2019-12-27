import 'package:fidal_unofficial/net/fidal_api.dart';
import 'package:fidal_unofficial/search/search_fields.dart';
import 'package:flutter/material.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class SearchResultsWidget extends StatefulWidget {
  final FidalApi _api;
  final ValueNotifier<SearchInfo> _searchInfoNotifier;

  SearchResultsWidget(this._api, this._searchInfoNotifier);

  @override
  State<StatefulWidget> createState() {
    return SearchResultsState(_searchInfoNotifier, _api);
  }
}

class SearchResultsState extends State<SearchResultsWidget> {
  List<SearchResult> data;
  bool error = false;
  AutoScrollController asc;

  SearchResultsState(
      ValueNotifier<SearchInfo> searchInfoNotifier, FidalApi api) {
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
    asc = AutoScrollController(
        suggestedRowHeight: 48, // TODO: Change when layout is done
        viewportBoundaryGetter: () =>
            Rect.fromLTRB(0, 0, 0, MediaQuery.of(context).padding.bottom),
        axis: Axis.vertical);
    widget._searchInfoNotifier.value = SearchFieldsState.defaultSearchInfo();
  }

  void onAfterBuild(BuildContext context) {
    if (asc != null && data != null && asc.hasClients) {
      int index = SearchResult.findNearestToToday(data);
      asc.scrollToIndex(index, preferPosition: AutoScrollPosition.middle);
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => onAfterBuild(context));

    if (error) {
      return Center(
          child:
              Text("An error occurred!", style: TextStyle(color: Colors.red)));
    }

    if (data == null || data.length == 0) {
      return Center(child: Text("No data to display."));
    }

    return ListView.separated(
        scrollDirection: Axis.vertical,
        separatorBuilder: (context, i) => Divider(color: Colors.black38),
        controller: asc,
        itemCount: data.length,
        itemBuilder: (context, i) {
          return AutoScrollTag(
              index: i,
              controller: asc,
              key: ValueKey(i),
              child: SearchResultItemWidget(data[i]));
        });
  }
}

class SearchResultItemWidget extends StatelessWidget {
  final SearchResult sr;

  SearchResultItemWidget(this.sr);

  @override
  Widget build(BuildContext context) {
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
  }
}
