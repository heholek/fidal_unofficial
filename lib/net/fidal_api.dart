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

class BasicEventInfo with WhenStartEndMixin {
  final DateTime _whenStart;
  final DateTime _whenEnd;
  final String level;
  final String name;
  final String desc;
  final String type;
  final String location;
  final String url;

  BasicEventInfo(this._whenStart, this._whenEnd,
      {this.url, this.level, this.name, this.type, this.location, this.desc});

  static int findNearestToToday(List<BasicEventInfo> list) {
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

  static BasicEventInfo parse(
      String year, html.Element elm, String Function(html.Element) descParser) {
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

    var desc = descParser(elm);
    if (desc != null && desc.trim().isEmpty) desc = null;

    return BasicEventInfo(whenStart, whenEnd,
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

class BasicAthleteInfo {
  final String name;
  final String surname;
  final String url;
  final String year;

  BasicAthleteInfo(this.name, this.surname, this.url, this.year);
}

class Athletes {
  final Map<String, List<BasicAthleteInfo>> map;

  Athletes(this.map);

  static Map<String, List<BasicAthleteInfo>> _parse(html.Element tab) {
    var map = Map<String, List<BasicAthleteInfo>>();
    String lastCategory;
    for (var elm in tab.children) {
      if (elm.localName == "h3") {
        lastCategory = RegExp(r'.*\s\((.*)\)').firstMatch(elm.text)[1];
        continue;
      }

      if (elm.localName == "table" && lastCategory != null) {
        List<BasicAthleteInfo> list = map[lastCategory];
        if (list == null) {
          list = List();
          map[lastCategory] = list;
        }

        var rows = elm.querySelectorAll("tbody tr");
        for (var row in rows) {
          var a = row.querySelector(".col1 a");
          list.add(BasicAthleteInfo(row.children[1].text, a.text,
              a.attributes["href"], row.children[2].text));
        }

        lastCategory = null;
      }
    }

    return map;
  }

  static Athletes parse(html.Element tab2, html.Element tab3) {
    var list = _parse(tab2);
    list.addAll(_parse(tab3));
    return Athletes(list);
  }
}

class ClubHistoryItem {
  final String year;
  final String name;
  final String president;

  ClubHistoryItem(this.year, this.name, this.president);

  static ClubHistoryItem parse(html.Element elm) {
    return ClubHistoryItem(
        elm.children[0].text, elm.children[1].text, elm.children[2].text);
  }
}

class ClubInfo {
  final String name;
  final String president;
  final String location;
  final String website;
  final int maleAthletes;
  final int femaleAthletes;
  final String region;
  final String province;
  final String phone;
  final String email;
  final Athletes athletes;
  final List<BasicEventInfo> events;
  final List<ClubHistoryItem> history;

  ClubInfo(
      this.name,
      this.location,
      this.website,
      this.president,
      this.maleAthletes,
      this.femaleAthletes,
      this.region,
      this.province,
      this.phone,
      this.email,
      this.athletes,
      this.events,
      this.history);

  static String substringAfterColon(String str) {
    int index = str.indexOf(":");
    return str.substring(index + 1).trim();
  }

  static ClubInfo parse(html.Document doc) {
    var clubData = doc.querySelector(".dati-societa");
    var moreClubData = clubData.querySelectorAll(".datiatleti tbody td");

    var emailSpan = moreClubData[2].querySelector("span");
    var email = emailSpan.nodes[0].text + '@' + emailSpan.nodes[2].text;

    var tab2 = doc.querySelector("#tab2 .tab-holder");
    var tab3 = doc.querySelector("#tab3 .tab-holder");
    var tab4 = doc.querySelector("#tab4 .tab-holder");
    var tab5 = doc.querySelector("#tab5 .tab-holder");

    var yearNow = DateTime.now().year.toString();
    List<BasicEventInfo> events = List();
    var eventRows = tab4.querySelectorAll("tbody tr");
    for (var row in eventRows)
      events.add(BasicEventInfo.parse(
          yearNow, row, (elm) => elm.children[3].firstChild.nodes[2].text));

    List<ClubHistoryItem> historyItems = List();
    var historyRows = tab5.querySelectorAll("tbody tr");
    for (var row in historyRows) historyItems.add(ClubHistoryItem.parse(row));

    return ClubInfo(
        clubData.children[0].text,
        substringAfterColon(clubData.children[1].text),
        clubData.children[3].querySelector("a").attributes["href"],
        substringAfterColon(clubData.children[5].text),
        int.parse(substringAfterColon(clubData.children[9].text)),
        int.parse(substringAfterColon(clubData.children[11].text)),
        substringAfterColon(moreClubData[0].text),
        substringAfterColon(moreClubData[1].text),
        substringAfterColon(moreClubData[3].text),
        email.trim(),
        Athletes.parse(tab2, tab3),
        events,
        historyItems);
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

  Future<List<BasicEventInfo>> search(SearchInfo si) async {
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
    List<BasicEventInfo> list = List();
    for (var item in items)
      list.add(BasicEventInfo.parse(
          si.year, item, (elm) => elm.children[3].children[2].text));
    return list;
  }

  Future<EventInfo> eventInfo(BasicEventInfo sr) async {
    String body = await _request(sr._urlPath());
    var doc = html.parse(body);
    return EventInfo.parse(doc);
  }

  Future<ClubInfo> clubInfo(String url) async {
    String body = await _request(Uri.parse(url).path);
    var doc = html.parse(body);
    return ClubInfo.parse(doc);
  }
}
