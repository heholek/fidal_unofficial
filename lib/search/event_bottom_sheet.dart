import 'dart:async';

import 'package:fidal_unofficial/net/fidal_api.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Padding(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(ei.title),
              Text("Some data"),
              Text("Other data"),
            ]),
        padding: EdgeInsets.all(8));
  }
}

void showEventBottomSheet(
    BuildContext context, FidalApi api, SearchResult result) {
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
        return Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          AppBar(
            title: Text(result.name),
            automaticallyImplyLeading: false,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16))),
          ),
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
