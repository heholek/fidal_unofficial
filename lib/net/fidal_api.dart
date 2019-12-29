import 'dart:async';
import 'dart:core';
import 'dart:io';

import 'package:html/parser.dart' as html;
import 'package:html/dom.dart' as html;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchInfo {
  final String year;
  final String month;
  final String level;
  final String region;
  final String type;
  final String category;
  final bool federal;

  static String currentYear() {
    return DateTime.now().year.toString();
  }

  static String currentMonth() {
    return DateTime.now().month.toString();
  }

  SearchInfo.defaultSearchInfo()
      : this.year = currentYear(),
        this.month = currentMonth(),
        this.level = "",
        this.region = "",
        this.type = "",
        this.category = "",
        this.federal = false;

  SearchInfo(this.year, this.month, this.level, this.region, this.type,
      this.category, this.federal);
}

mixin WhenStartEndMixin {
  DateTime _whenStart;
  DateTime _whenEnd;

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

class SearchResult with WhenStartEndMixin {
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
      if (now.year != list[i]._whenStart.year ||
          now.month != list[i]._whenStart.month) continue;

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

    var level = elm.children[2].firstChild.text;
    if (level == "R" &&
        elm.children[2].firstChild.attributes["title"].contains("OPEN"))
      level += "*";

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

    var desc = elm.children[3].children[2].text;
    if (desc.trim().isEmpty) desc = null;

    return SearchResult(whenStart, whenEnd,
        level: level,
        type: elm.children[4].text,
        location: elm.children[5].text,
        name: a.text,
        url: a.attributes["href"],
        desc: desc);
  }

  String _urlPath() {
    var regexp = RegExp(r'\/(\d*)$');

    var uri = Uri.parse(url);
    if (!regexp.hasMatch(uri.path)) return uri.path;

    if (level == "R" || level == "R*" || level == "P")
      return uri.path.replaceAllMapped(regexp, (m) => "/REG${m[1]}");
    else
      return uri.path.replaceAllMapped(regexp, (m) => "/COD${m[1]}");
  }
}

enum EventSex { MALE, FEMALE, BOTH }

class ApprovedRoute {
  final bool yesNo;
  final String type;

  ApprovedRoute(this.yesNo, this.type);

  static ApprovedRoute parse(html.Element elm) {
    if (elm == null) return null;

    var m = RegExp(r'(.*)\s\(Tipologia\s(.*)\)').firstMatch(elm.text.trim());
    var type = m[2];
    if (type == "-") type = null;
    return ApprovedRoute(m[1] == "Si", type);
  }
}

class LinkedString {
  final String text;
  final String url;

  LinkedString(this.text, this.url);

  static LinkedString parse(Map<String, html.Element> map, String key) {
    var val = map[key];
    if (val == null) return null;

    var a = val.querySelector("a");
    if (a != null)
      return LinkedString(a.text.trim(), a.attributes["href"]);
    else
      return LinkedString(val.text.trim(), null);
  }
}

class EventInfo with WhenStartEndMixin {
  final String title;
  final String desc;
  final DateTime _whenStart;
  final DateTime _whenEnd;
  final String type;
  final String level;
  final String location;
  final List<String> categories;
  final String email;
  final LinkedString website;
  final EventSex sex;
  final String authority;
  final LinkedString organizer;
  final LinkedString organization;
  final ApprovedRoute approvedRoute;
  final List<String> infoUrls;
  final List<String> attachmentUrls;
  final String resultsUrl;

  EventInfo(
      this.title,
      this.desc,
      this._whenStart,
      this._whenEnd,
      this.type,
      this.authority,
      this.level,
      this.organizer,
      this.organization,
      this.email,
      this.website,
      this.sex,
      this.location,
      this.categories,
      this.approvedRoute,
      this.resultsUrl,
      this.infoUrls,
      this.attachmentUrls);

  static Map<String, html.Element> _mapElements(List<html.Element> elms) {
    var map = Map<String, html.Element>();
    for (var elm in elms) {
      if (elm.children.length != 2) continue;
      map[elm.children[0].text.toUpperCase()] = elm.children[1];
    }
    return map;
  }

  static String optText(Map<String, html.Element> map, String key) {
    var val = map[key];
    return val == null ? null : val.text.trim();
  }

  static List<String> parseMultipleLinks(html.Element elm) {
    var list = List<String>();
    if (elm == null) return list;

    for (var link in elm.querySelectorAll("a"))
      list.add(link.attributes["href"]);
    return list;
  }

  static EventInfo parse(html.Document doc) {
    var title = doc.querySelector(".section .text-holder > h1").text;
    var desc = doc.querySelector(".section .text-holder > label").text;

    var map = _mapElements(doc
        .querySelector(
            ".section .text-holder .common_section > .table-responsive > table > tbody")
        .children);

    var whenStr = map["DATA SVOLGIMENTO"].text.trim();
    var whenStart;
    var whenEnd;
    if (whenStr.contains(" - ")) {
      var df = DateFormat("dd/MM/yyyy");
      var split = whenStr.split(" - ");
      whenStart = df.parse(split[0]);
      whenEnd = df.parse(split[1]);
    } else {
      whenStart = DateFormat("dd/MM/yyyy").parse(whenStr);
      whenEnd = null;
    }

    EventSex sex;
    var sexStr = map["SESSO"].text.trim();
    switch (sexStr) {
      case "M":
        sex = EventSex.MALE;
        break;
      case "F":
        sex = EventSex.FEMALE;
        break;
      case "M/F":
        sex = EventSex.BOTH;
        break;
      default:
        throw ArgumentError("Unknown sex $sexStr");
    }

    var categories;
    if (map.containsKey("CATEGORIA")) {
      categories = List<String>();
      for (var m in RegExp(r'[\n\s]*(.{3}) - .*?')
          .allMatches(map["CATEGORIA"].text)) categories.add(m[1]);
    }

    var resultsUrl;
    var results = map["ISCRITTI/RISULTATI"];
    if (results != null)
      resultsUrl = results.querySelector("a").attributes["href"];

    return EventInfo(
        title,
        desc.trim().isEmpty ? null : desc.trim(),
        whenStart,
        whenEnd,
        map["TIPOLOGIA"].text,
        optText(map, "ENTE"),
        map["LIVELLO"].text,
        LinkedString.parse(map, "ORGANIZZATORE"),
        LinkedString.parse(map, "ORGANIZZAZIONE"),
        optText(map, "EMAIL"),
        LinkedString.parse(map, "SITO WEB"),
        sex,
        map["LOCALITÀ"].querySelector("a").text,
        categories,
        ApprovedRoute.parse(map["PERCORSO OMOLOGATO"]),
        resultsUrl,
        parseMultipleLinks(map["INFORMAZIONI"]),
        parseMultipleLinks(map["ALLEGATI"]));
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

  static void checkMinMaxYear(html.Document doc) async {
    var sel = doc.querySelector("#calendario #anno");

    var pref = await SharedPreferences.getInstance();
    await pref.setString("fidalSearch_minYear",
        sel.children[sel.children.length - 1].attributes["value"]);
    await pref.setString(
        "fidalSearch_maxYear", sel.children[0].attributes["value"]);
  }

  Future<List<SearchResult>> search(SearchInfo si) async {
    String body = await _request("/calendario.php", {
      "anno": si.year,
      "mese": si.month,
      "livello": si.level,
      "new_regione": si.region,
      "new_tipo": si.type,
      "new_categoria": si.category,
      "new_campionati": si.federal ? "1" : "0",
      "submit": "Invia"
    });

    if (body.contains(
        "Non sono disponibili manifestazioni con i filtri selezionati"))
      return List(0);

    var doc = html.parse(body);
    checkMinMaxYear(doc);

    var items = doc.querySelectorAll(".table_btm tbody tr");
    List<SearchResult> list = List();
    for (var item in items) list.add(SearchResult.parse(si.year, item));
    return list;
  }

  Future<EventInfo> eventInfo(SearchResult sr) async {
    String body = await _request(sr._urlPath());
    var doc = html.parse(body);
    return EventInfo.parse(doc);
  }
}
