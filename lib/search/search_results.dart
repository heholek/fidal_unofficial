import 'dart:async';

import 'package:fidal_unofficial/net/fidal_api.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class SearchResultsWidget extends StatelessWidget {
  final FidalApi _api;
  final StreamController<SearchStatus> streamController;
  AutoScrollController asc;

  SearchResultsWidget(this._api, this.streamController) {
    streamController.stream.listen((status) {
      if (status.loading) {
        _api.search(status.info).then(
            (result) => streamController.add(SearchStatus.successfull(result)),
            onError: (e) {
          print(e);
          streamController.add(SearchStatus.error());
        });
      } else if (status.data != null && asc.hasClients) {
        var index = SearchResult.findNearestToToday(status.data);
        if (index == -1) asc.jumpTo(0);
        else asc.scrollToIndex(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    streamController.add(SearchStatus.startSearch(SearchInfo.defaultSearchInfo()));

    asc = AutoScrollController(
        suggestedRowHeight: 76,
        viewportBoundaryGetter: () =>
            Rect.fromLTRB(0, 0, 0, MediaQuery.of(context).padding.bottom),
        axis: Axis.vertical);

    return StreamBuilder<SearchStatus>(
        initialData: null,
        stream: streamController.stream,
        builder: (context, snap) {
          if (snap.data == null || snap.data.loading)
            return Center(child: CircularProgressIndicator());

          SearchStatus ss = snap.data;
          if (ss.error) {
            return Center(
                child: Text("An error occurred!",
                    style: TextStyle(color: Colors.red)));
          } else {
            if (ss.data.length == 0)
              return Center(child: Text("No data to display."));

            return ListView.separated(
                scrollDirection: Axis.vertical,
                separatorBuilder: (context, i) =>
                    Divider(color: Colors.black38, height: 2.0),
                controller: asc,
                itemCount: ss.data.length,
                itemBuilder: (context, i) {
                  return AutoScrollTag(
                      index: i,
                      controller: asc,
                      key: ValueKey(i),
                      child: SearchResultItemWidget(ss.data[i]));
                });
          }
        });
  }
}

class SearchStatus {
  final bool error;
  final bool loading;
  final SearchInfo info;
  final List<SearchResult> data;

  SearchStatus.startSearch(this.info)
      : this.error = false,
        this.loading = true,
        this.data = null;

  SearchStatus.error()
      : this.error = true,
        this.loading = false,
        this.info = null,
        this.data = null;

  SearchStatus.successfull(this.data)
      : this.error = false,
        this.info = null,
        this.loading = false;
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
        throw ArgumentError("Unknown type $type");
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

    return InkWell(
        onTap: () {},
        child: Padding(
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
            padding: EdgeInsets.all(8.0)));
  }
}
