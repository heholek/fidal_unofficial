import 'dart:async';
import 'dart:core';
import 'dart:io';

import 'package:html/parser.dart' as html;
import 'package:html/dom.dart' as html;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class SearchInfo {
  final String year;
  final String month;
  final String level;
  final String region;
  final String type;
  final String category;
  final bool federal;

  SearchInfo(
      this.year, this.month, this.level, this.region, this.type, this.category, this.federal);
}

class SearchResult {
  final DateTime _whenStart;
  final DateTime _whenEnd;
  final String level;
  final String name;
  final String desc;
  final String type;
  final String location;
  final String url;

  SearchResult(this._whenStart, this._whenEnd,
      {this.url, this.level, this.name, this.type, this.location, this.desc});

  static int findNearestToToday(List<SearchResult> list) {
    DateTime now = DateTime.now();

    int nearest = -1;
    int diff = -1;
    for (int i = 0; i < list.length; i++) {
      int d = (now.millisecondsSinceEpoch -
              list[i]._whenStart.millisecondsSinceEpoch)
          .abs();
      if (nearest == -1) {
        nearest = i;
        diff = d;
        continue;
      }

      if (d < diff) {
        nearest = i;
        diff = d;
      }
    }

    return nearest;
  }

  static SearchResult parse(String year, html.Element elm) {
    var when = elm.children[1].firstChild.text;
    var a = elm.children[3].firstChild;

    DateFormat df = DateFormat("dd/MM/yyyy");

    var whenStart;
    var whenEnd;
    if (when.contains("-")) {
      List<String> split = when.split('-');
      var whenEndStr = split[1];
      var whenStartStr = split[0] + '/' + whenEndStr.split('/')[1];
      whenStart = df.parse(whenStartStr + '/' + year);
      whenEnd = df.parse(whenEndStr + '/' + year);
    } else {
      whenStart = df.parse(when + '/' + year);
      whenEnd = null;
    }

    return SearchResult(whenStart, whenEnd,
        level: elm.children[2].firstChild.text,
        type: elm.children[4].text,
        location: elm.children[5].text,
        name: a.text,
        url: a.attributes["href"],
        desc: elm.children[3].children[2].text);
  }

  DateTime getDay() {
    assert(isSingleDay());
    return _whenStart;
  }

  DateTime getStartDay() {
    assert(!isSingleDay());
    return _whenStart;
  }

  DateTime getEndDay() {
    assert(!isSingleDay());
    return _whenEnd;
  }

  bool isSingleDay() {
    return _whenEnd == null;
  }
}

class FidalApi {
  static final String _domain = "www.fidal.it";
  final http.Client _client;

  FidalApi() : _client = http.Client();

  Future<String> _request(String path, [Map<String, String> params]) async {
    var uri = Uri.http(_domain, path, params);

    print(uri.toString());

    var resp = await _client.get(uri);
    if (resp.statusCode == 200)
      return resp.body;
    else
      throw HttpException("Bad status code: ${resp.statusCode}!", uri: uri);
  }

  Future<List<SearchResult>> search(SearchInfo si) async {
    String body = await _request("/calendario.php", {
      "anno": si.year,
      "mese": si.month,
      "livello": si.level,
      "regione": si.region,
      "new_tipo": si.type,
      "new_categoria": si.category,
      "new_campionati": si.federal ? "1" : "0",
      "submit": "Invia"
    });

    if (body.contains("Non sono disponibili manifestazioni con i filtri selezionati"))
      return List(0);

    var items = html.parse(body).querySelectorAll(".table_btm tbody tr");

    List<SearchResult> list = List();
    for (var item in items) list.add(SearchResult.parse(si.year, item));
    return list;
  }
}
