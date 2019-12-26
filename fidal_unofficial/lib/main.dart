import 'package:fidal_unofficial/net/fidal_api.dart';
import 'package:flutter/material.dart';


import 'search/page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final FidalApi _api;

  MyApp() : _api = FidalApi();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FIDAL',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SearchPage(_api),
    );
  }
}

