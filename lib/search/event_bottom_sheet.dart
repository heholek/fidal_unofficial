import 'package:fidal_unofficial/net/fidal_api.dart';
import 'package:flutter/material.dart';

void showEventBottomSheet(BuildContext context, SearchResult result) {
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
              child: Column(
                children: <Widget>[
                  Text("AAAAAAAAAAAAAAAAAAAAA"),
                  Text("AAAAAAAAAAAAAAAAAAAAA"),
                  Text("AAAAAAAAAAAAAAAAAAAAA"),
                  Text("AAAAAAAAAAAAAAAAAAAAA"),
                  Text("AAAAAAAAAAAAAAAAAAAAA")
                ],
              )),
        ]);
      });
}
