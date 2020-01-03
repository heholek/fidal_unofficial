import 'dart:async';

import 'package:fidal_unofficial/net/fidal_api.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventInfoStatus {
  final bool loading;
  final bool error;
  final EventInfo ei;

  EventInfoStatus.loading()
      : loading = true,
        error = false,
        ei = null;
  EventInfoStatus.error()
      : loading = false,
        error = true,
        ei = null;
  EventInfoStatus.successfull(this.ei)
      : loading = false,
        error = false;
}

class EventInfoWidget extends StatelessWidget {
  final EventInfo ei;

  EventInfoWidget(this.ei);

  static Row buildDetailsRow(IconData icon, String text) => Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
                child: Icon(icon, size: 28),
                padding: EdgeInsets.only(left: 3, right: 1)),
            Text(text, style: TextStyle(fontSize: 22))
          ]);

  @override
  Widget build(BuildContext context) {
    var detailsWrapContent = <Widget>[];
    if (ei.isSingleDay()) {
      detailsWrapContent.add(buildDetailsRow(
          Icons.date_range, DateFormat("EEE dd/MM").format(ei.getDay())));
    } else {
      var df = DateFormat("EEE dd/MM");
      detailsWrapContent.add(buildDetailsRow(Icons.date_range,
          df.format(ei.getStartDay()) + " - " + df.format(ei.getEndDay())));
    }

    detailsWrapContent.add(buildDetailsRow(Icons.location_on, ei.location));
    detailsWrapContent.add(buildDetailsRow(
        Icons.landscape, toBeginningOfSentenceCase(ei.type.toLowerCase())));
    detailsWrapContent.add(buildDetailsRow(
        Icons.lock, toBeginningOfSentenceCase(ei.level.toLowerCase())));
    detailsWrapContent.add(buildDetailsRow(Icons.pan_tool, ei.sex.toString()));
    if (ei.categories != null)
      detailsWrapContent
          .add(buildDetailsRow(Icons.category, ei.categories.join(", ")));
    if (ei.email != null)
      detailsWrapContent.add(buildDetailsRow(Icons.mail, ei.email));
    if (ei.website != null)
      detailsWrapContent.add(buildDetailsRow(Icons.web, ei.website.text));

    var sheetBody = <Widget>[];
    sheetBody.add(Wrap(
        children: detailsWrapContent,
        alignment: WrapAlignment.center,
        spacing: 4,
        runSpacing: 4,
        direction: Axis.horizontal));

    return Padding(
        child: Column(children: sheetBody), padding: EdgeInsets.all(8));
  }
}

void showEventBottomSheet(
    BuildContext context, FidalApi api, BasicEventInfo result) {
  var streamController = StreamController<EventInfoStatus>();
  api
      .eventInfo(result)
      .then((ei) => streamController.add(EventInfoStatus.successfull(ei)),
          onError: (e) {
    print(e);
    streamController.add(EventInfoStatus.error());
  });

  showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (builder) {
        var appBarContent = [
          Text(result.name, style: Theme.of(context).primaryTextTheme.title)
        ];

        if (result.desc != null)
          appBarContent.add(Text(result.desc,
              style: Theme.of(context).primaryTextTheme.subtitle));

        return Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Container(
              padding: EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                  color: Theme.of(context).accentColor,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16))),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: appBarContent)),
          Container(
              width: double.infinity,
              color: Colors.white,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: 200),
                child: StreamBuilder(
                    initialData: EventInfoStatus.loading(),
                    stream: streamController.stream,
                    builder: (context, snap) {
                      if (snap.data == null || snap.data.loading)
                        return Center(child: CircularProgressIndicator());

                      if (snap.data.error)
                        return Center(
                            child: Text("An error occurred!",
                                style: TextStyle(color: Colors.red)));

                      return EventInfoWidget(snap.data.ei);
                    }),
              ))
        ]);
      }).then((_) => streamController.close());
}
