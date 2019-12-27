import 'dart:async';
import 'dart:ui';

import 'package:fidal_unofficial/net/fidal_api.dart';
import 'package:flutter/material.dart';

import 'search_fields.dart';
import 'search_results.dart';

class SearchPage extends StatelessWidget {
  final FidalApi _api;
  final StreamController<SearchStatus> _streamController;

  SearchPage(this._api)
      : _streamController = StreamController<SearchStatus>.broadcast();

  static TextSpan coloredSquare(Color color) {
    return new TextSpan(
        text: '\u25A0', style: TextStyle(color: color, fontSize: 22));
  }

  static TextSpan bigLetter(String char) {
    return new TextSpan(text: char, style: TextStyle(fontSize: 24));
  }

  @override
  Widget build(BuildContext context) {
    SearchResultsWidget sr = SearchResultsWidget(_api, _streamController);
    SearchFieldsWidget sf = SearchFieldsWidget(_streamController);

    return Scaffold(
      appBar: AppBar(
        title: Text('Search!!'),
        elevation: 0,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.help),
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                        title: Text("Help"),
                        actions: <Widget>[
                          FlatButton(
                            child: Text("OK"),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          )
                        ],
                        content: RichText(
                            text: TextSpan(
                                style: TextStyle(
                                    fontSize: 18, color: Colors.black),
                                children: <TextSpan>[
                              // Colors
                              coloredSquare(Colors.green),
                              TextSpan(
                                  text:
                                      ' Ultramaratona/Trail, Montagna, Cross\n'),
                              coloredSquare(Colors.grey),
                              TextSpan(
                                  text:
                                      ' Marcia su strada, Ultramaratona, Strada\n'),
                              coloredSquare(Colors.red),
                              TextSpan(text: ' Outdoor\n'),
                              coloredSquare(Colors.blue),
                              TextSpan(text: ' Indoor\n\n'),
                              // Letters
                              bigLetter('R'),
                              TextSpan(text: 'egionale\n'),
                              bigLetter('R*'),
                              TextSpan(text: 'egionale open\n'),
                              bigLetter('B'),
                              TextSpan(text: 'ronze\n'),
                              bigLetter('S'),
                              TextSpan(text: 'ilver\n'),
                              bigLetter('P'),
                              TextSpan(text: 'rovinciale\n'),
                              bigLetter('G'),
                              TextSpan(text: 'old\n'),
                              bigLetter('N'),
                              TextSpan(text: 'azionale\n')
                            ])));
                  });
            },
          )
        ],
      ),
      body: Column(
        children: <Widget>[
          Material(child: sf, elevation: 4.0),
          Expanded(child: sr)
        ],
      ),
    );
  }
}
