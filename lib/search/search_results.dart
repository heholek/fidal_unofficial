import 'package:fidal_unofficial/net/fidal_api.dart';
import 'package:fidal_unofficial/search/search_fields.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      if (index != -1) asc.scrollToIndex(index, preferPosition: AutoScrollPosition.middle);
      else asc.jumpTo(0);
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

  static Color getTypeColor(String type) {
    switch (type) {
      case "CROSS":
      case "TRAIL":
      case "MONTAGNA":
      case "MONTAGNA/TRAIL":
        return Colors.green;
      case "STRADA":
      case "MARCIA SU STRADA":
      case "ULTRAMARATONA":
        return Colors.grey;
      case "OUTDOOR":
        return Colors.red;
      case "INDOOR":
        return Colors.blue;
      case "":
      case "PIAZZA e altri ambiti":
      case "NORDIC WALKING":
        return Colors.black;
      default:
        throw Exception("Unknown type $type");
    }
  }

  static String formatDates(SearchResult sr) {
    if (sr.isSingleDay()) {
      return DateFormat("EEE dd/MM").format(sr.getDay());
    } else {
      var df = DateFormat("EEE dd/MM");
      return df.format(sr.getStartDay()) + " - " + df.format(sr.getEndDay());
    }
  }

  @override
  Widget build(BuildContext context) {
    var widgetBody = <Widget>[
      Text(sr.name, style: TextStyle(fontWeight: FontWeight.bold), maxLines: 2)
    ];

    if (sr.desc != null && sr.desc.length > 0) {
      widgetBody.add(Text(sr.desc,
          style: TextStyle(fontStyle: FontStyle.italic), maxLines: 2));
    }

    widgetBody.add(Padding(
        padding: EdgeInsets.only(top: 2),
        child: Row(children: <Widget>[
          Icon(Icons.location_on),
          Expanded(
              child: Text(sr.location,
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
          Icon(Icons.date_range),
          Expanded(
              child: Text(formatDates(sr),
                  maxLines: 1, overflow: TextOverflow.ellipsis))
        ])));

    return Padding(
        child: Row(children: <Widget>[
          Padding(
              child: Center(
                  child: Text(sr.level,
                      style: TextStyle(
                          fontSize: 32, color: getTypeColor(sr.type)))),
              padding: EdgeInsets.only(right: 12)),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widgetBody,
          ))
        ]),
        padding: EdgeInsets.all(8.0));
  }
}
