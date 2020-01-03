import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:html/dom.dart' as html;
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RankingsSearchInfo {
  final String year;
  final String type;
  final String sex;
  final String category;
  final String speciality;
  final String extraction;
  final String wind;
  final String region;
  final String nationality;
  final String limit;
  final String clubCode;

  RankingsSearchInfo(
      this.year,
      this.type,
      this.sex,
      this.category,
      this.speciality,
      this.extraction,
      this.wind,
      this.region,
      this.nationality,
      this.limit,
      this.clubCode);
}

class RankingsHeader {
  final String speciality;
  final String year;
  final String category;
  final String type;
  final String wind;
  final String region;
  final String nationality;

  RankingsHeader(this.speciality, this.year, this.category, this.type,
      this.wind, this.region, this.nationality);

  static RankingsHeader parse(html.Element elm) {
    var items = elm.querySelectorAll("tbody td");
    return RankingsHeader(
        items[0].text,
        items[1].nodes[2].text,
        items[2].nodes[2].text,
        items[3].nodes.length > 2 ? items[3].nodes[2].text : null,
        items[4].nodes[2].text,
        items[5].nodes[2].text,
        items[6].nodes[2].text);
  }
}

class RankingsEntry {
  final String performance;
  final String wind;
  final LinkedString athlete;
  final String yearOfBirth;
  final String category;
  final LinkedString club;
  final String placing;
  final String location;
  final DateTime when;

  RankingsEntry(this.performance, this.wind, this.athlete, this.yearOfBirth,
      this.category, this.club, this.placing, this.location, this.when);

  static RankingsEntry parse(String year, html.Element elm) {
    var category = elm.children[3].firstChild;
    var whenStr = elm.children[7].firstChild.text.trim();
    return RankingsEntry(
        elm.children[0].text.trim(),
        elm.children[1].text.trim(),
        LinkedString.parse(elm.children[2]),
        category.text,
        category.attributes["title"],
        LinkedString.parse(elm.children[4]),
        elm.children[5].text.trim(),
        elm.children[6].text.trim(),
        DateFormat("dd/MM/yyyy").parse(whenStr + '/' + year));
  }
}

class Rankings {
  final String title;
  final String desc;
  final Map<RankingsHeader, List<RankingsEntry>> map;

  Rankings(this.title, this.desc, this.map);

  static Rankings parse(String year, html.Document doc) {
    var elm = doc.querySelector("#content .text-holder");
    if (elm == null) return null;

    var map = Map<RankingsHeader, List<RankingsEntry>>();
    var r = Rankings(
        elm.querySelector("h1").text, elm.querySelector("h4").text, map);

    RankingsHeader lastHeader;
    for (var child in elm.children) {
      if (child.localName == "table") {
        lastHeader = RankingsHeader.parse(child);
        continue;
      }

      if (child.localName == "div" && lastHeader != null) {
        var list = map[lastHeader];
        if (list == null) {
          list = List<RankingsEntry>();
          map[lastHeader] = list;
        }

        for (var row in child.querySelectorAll("tbody tr")) {
          if (row.children.length < 8) continue;
          list.add(RankingsEntry.parse(year, row));
        }

        lastHeader = null;
      }
    }

    return r;
  }
}

class EventSearchInfo {
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

  EventSearchInfo.defaultSearchInfo()
      : this.year = currentYear(),
        this.month = currentMonth(),
        this.level = "",
        this.region = "",
        this.type = "",
        this.category = "",
        this.federal = false;

  EventSearchInfo(this.year, this.month, this.level, this.region, this.type,
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

  static LinkedString parseFromMap(Map<String, html.Element> map, String key) {
    var val = map[key];
    if (val == null) return null;
    return parse(val);
  }

  static LinkedString parse(html.Element elm) {
    var a = elm.querySelector("a");
    if (a != null)
      return LinkedString(a.text.trim(), a.attributes["href"]);
    else
      return LinkedString(elm.text.trim(), null);
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
        LinkedString.parseFromMap(map, "ORGANIZZATORE"),
        LinkedString.parseFromMap(map, "ORGANIZZAZIONE"),
        optText(map, "EMAIL"),
        LinkedString.parseFromMap(map, "SITO WEB"),
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
        lastCategory = RegExp(r'.*\((.*)\)').firstMatch(elm.text)[1];
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

  static Athletes parse(
      html.Element tab1, html.Element tab2, html.Element tab3) {
    var map = Map<String, List<BasicAthleteInfo>>();
    if (tab1 != null) map.addAll(_parse(tab1));
    if (tab2 != null) map.addAll(_parse(tab2));
    if (tab3 != null) map.addAll(_parse(tab3));
    return Athletes(map);
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

    var tab1 = doc.querySelector("#tab1 .tab-holder");
    var tab2 = doc.querySelector("#tab2 .tab-holder");
    var tab3 = doc.querySelector("#tab3 .tab-holder");
    var tab4 = doc.querySelector("#tab4 .tab-holder");
    var tab5 = doc.querySelector("#tab5 .tab-holder");

    var yearNow = DateTime.now().year.toString();
    List<BasicEventInfo> events = List();
    var eventRows = tab4.querySelectorAll("tbody tr");
    for (var row in eventRows)
      events.add(BasicEventInfo.parse(yearNow, row, (elm) {
        var nodes = elm.children[3].firstChild.nodes;
        if (nodes.length < 3)
          return null;
        else
          return nodes[2].text;
      }));

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
        Athletes.parse(tab1, tab2, tab3),
        events,
        historyItems);
  }
}

class AtheltePerformance {
  final DateTime when;
  final String type;
  final String chrono;
  final String category;
  final String placing;
  final String val;
  final String wind;
  final String location;

  AtheltePerformance(this.when, this.type, this.chrono, this.category,
      this.placing, this.val, this.wind, this.location);

  static AtheltePerformance _parse(html.Element row) {
    var whenStr = row.children[1].text + '/' + row.children[0].text;

    return AtheltePerformance(
        DateFormat("dd/MM/yyyy").parse(whenStr),
        row.children[2].firstChild.text,
        row.children[3].firstChild.text,
        row.children[4].firstChild.text,
        row.children[5].text,
        row.children[6].text.trim(),
        row.children[7].text,
        row.children[8].text);
  }

  static Map<String, List<AtheltePerformance>> parse(html.Element tab2) {
    var map = Map<String, List<AtheltePerformance>>();
    String lastSpecialty;
    for (var row in tab2.children) {
      if (row.localName == "h2") {
        lastSpecialty = row.text;
        continue;
      }

      if (row.localName == "div" && lastSpecialty != null) {
        List<AtheltePerformance> list = map[lastSpecialty];
        if (list == null) {
          list = List();
          map[lastSpecialty] = list;
        }

        for (var perf in row.querySelectorAll("tbody tr"))
          list.add(AtheltePerformance._parse(perf));

        lastSpecialty = null;
      }
    }

    return map;
  }
}

class AthleteHistoryItem {
  final String year;
  final String reason;
  final String category;
  final LinkedString club;

  AthleteHistoryItem(this.year, this.reason, this.category, this.club);

  static AthleteHistoryItem _parse(html.Element row) {
    return AthleteHistoryItem(row.children[0].text, row.children[1].text,
        row.children[2].text, LinkedString.parse(row.children[3]));
  }

  static List<AthleteHistoryItem> parse(html.Element tab6) {
    var list = List<AthleteHistoryItem>();
    var rows = tab6.querySelectorAll("tbody tr");
    for (var row in rows) list.add(_parse(row));
    return list;
  }
}

class AthleteInfo {
  final String name;
  final LinkedString club;
  final DateTime birthday;
  final Map<String, List<AtheltePerformance>> performances;
  final List<AthleteHistoryItem> history;

  AthleteInfo(
      this.name, this.club, this.birthday, this.performances, this.history);

  static AthleteInfo parse(html.Element elm) {
    var header = elm.children[1].children[0];
    var birthday = DateFormat("dd-MM-yyyy").parse(header.nodes[6].text.trim());

    var tab2 = elm.querySelector("#tab2 .tab-holder");
    var tab6 = elm.querySelector("#tab6 .tab-holder");

    return AthleteInfo(
        header.children[0].text,
        LinkedString.parse(header.children[1]),
        birthday,
        AtheltePerformance.parse(tab2),
        AthleteHistoryItem.parse(tab6));
  }
}

abstract class SearchResult {
  SearchResultType type();

  static List<SearchResult> parse(html.Document doc) {
    var tab1 = doc.querySelector("#tab1"); // Events
    var tab2 = doc.querySelector("#tab2"); // Clubs
    var tab4 = doc.querySelector("#tab4"); // Athletes

    var list = List<SearchResult>();
    if (tab1 != null) list.addAll(EventSearchResult.parse(tab1));
    if (tab2 != null) list.addAll(ClubSearchResult.parse(tab2));
    if (tab4 != null) list.addAll(AtheleteSearchResult.parse(tab4));
    return list;
  }
}

enum SearchResultType { EVENT, ATHLETE, CLUB }

class EventSearchResult extends SearchResult {
  final LinkedString name;
  final String location;
  final DateTime whenStart;

  EventSearchResult(this.name, this.location, this.whenStart);

  @override
  SearchResultType type() => SearchResultType.EVENT;

  static List<EventSearchResult> parse(html.Element tab) {
    var list = List<EventSearchResult>();
    for (var row in tab.querySelectorAll("tbody tr")) {
      var when = DateFormat("dd/MM/yyyy").parse(row.children[3].text);
      list.add(EventSearchResult(LinkedString.parse(row.children[1]),
          row.children[2].text.trim(), when));
    }
    return list;
  }
}

class ClubSearchResult extends SearchResult {
  final LinkedString name;
  final String region;
  final String city;

  ClubSearchResult(this.name, this.region, this.city);

  @override
  SearchResultType type() => SearchResultType.CLUB;

  static List<ClubSearchResult> parse(html.Element tab) {
    var list = List<ClubSearchResult>();
    for (var row in tab.querySelectorAll("tbody tr")) {
      list.add(ClubSearchResult(LinkedString.parse(row.children[1]),
          row.children[2].text.trim(), row.children[3].text.trim()));
    }
    return list;
  }
}

class AtheleteSearchResult extends SearchResult {
  final LinkedString name;
  final LinkedString club;
  final String category;

  AtheleteSearchResult(this.name, this.club, this.category);

  @override
  SearchResultType type() => SearchResultType.ATHLETE;

  static List<AtheleteSearchResult> parse(html.Element tab) {
    var list = List<AtheleteSearchResult>();
    for (var row in tab.querySelectorAll("tbody tr")) {
      list.add(AtheleteSearchResult(LinkedString.parse(row.children[1]),
          LinkedString.parse(row.children[2]), row.children[3].text.trim()));
    }
    return list;
  }
}

class _RankingsDataSupplier {
  final FidalApi _api;
  static const String _PREFS_KEY_PREFIX = "fidalDataSupplierCache_";
  static const String _PREFS_KEY_CREATED_PREFIX =
      "fidalDataSupplierCache_created_";

  _RankingsDataSupplier(this._api);

  static String _buildCacheKey(String year,
      [String type, String sex, String category]) {
    var key = year;
    if (type != null) {
      key += ",$type";
      if (sex != null) {
        key += ",$sex";
        if (category != null) {
          key += ",$category";
        }
      }
    }
    return key;
  }

  void _putCache(Map<String, String> data, String year,
      [String type, String sex, String category]) async {
    var prefs = await SharedPreferences.getInstance();
    var key = _buildCacheKey(year, type, sex, category);

    await prefs.setString(_PREFS_KEY_PREFIX + key, jsonEncode(data));
    await prefs.setInt(
        _PREFS_KEY_CREATED_PREFIX + key, DateTime.now().millisecondsSinceEpoch);
  }

  Future<Map<String, String>> _hitCache(String year,
      [String type, String sex, String category]) async {
    var prefs = await SharedPreferences.getInstance();

    var key = _buildCacheKey(year, type, sex, category);
    var value = prefs.getString(_PREFS_KEY_PREFIX + key);
    if (value == null || value.isEmpty) return null;

    var createdAt = prefs.getInt(_PREFS_KEY_CREATED_PREFIX + key);
    if (DateTime.now().millisecondsSinceEpoch - createdAt > 12 * 3600 * 1000) {
      await prefs.remove(_PREFS_KEY_PREFIX + key);
      await prefs.remove(_PREFS_KEY_CREATED_PREFIX + key);
      return null;
    }

    return jsonDecode(value) as Map<String, String>;
  }

  Future<Map<String, String>> lookup(String year,
      [String type, String sex, String category]) async {
    var params = {"anno": year};
    if (type != null) params["tipo_attivita"] = type;
    if (type != null && sex != null) params["sesso"] = sex;
    if (type != null && sex != null && category != null)
      params["categoria"] = category;

    var cache = _hitCache(year, type, sex, category);
    if (cache != null) return cache;

    var result = jsonDecode(await _api._request("/datasupplier.php", params))
        as Map<String, String>;
    _putCache(result, year, type, sex, category);
    return result;
  }
}

class FidalApi {
  static const String PREFS_MIN_YEAR_KEY = "fidalEventSearch_minYear";
  static const String PREFS_MAX_YEAR_KEY = "fidalEventSearch_maxYear";
  static final String _domain = "www.fidal.it";
  final http.Client _client;
  _RankingsDataSupplier _rds;

  FidalApi() : _client = http.Client() {
    _rds = _RankingsDataSupplier(this);
  }

  Future<String> _request(String path, [Map<String, String> params]) async {
    var uri = Uri.http(_domain, path, params);

    print(uri.toString());

    var resp = await _client.get(uri);
    if (resp.statusCode == 200)
      return resp.body;
    else
      throw HttpException("Bad status code: ${resp.statusCode}!", uri: uri);
  }

  static void _checkMinMaxYear(html.Document doc) async {
    var sel = doc.querySelector("#calendario #anno");

    var pref = await SharedPreferences.getInstance();
    await pref.setString(PREFS_MIN_YEAR_KEY,
        sel.children[sel.children.length - 1].attributes["value"]);
    await pref.setString(
        PREFS_MAX_YEAR_KEY, sel.children[0].attributes["value"]);
  }

  Future<Rankings> rankings(RankingsSearchInfo si) async {
    String body = await _request("/graduatorie.php", {
      "anno": si.year,
      "tipo_attivita": si.type,
      "sesso": si.sex,
      "categoria": si.category,
      "gara": si.speciality,
      "tipologia_estrazione": si.extraction,
      "vento": si.wind,
      "regione": si.region,
      "nazionalita": si.nationality,
      "limite": si.limit,
      "societa": si.clubCode,
      "submit": "Invia"
    });

    return Rankings.parse(si.year, html.parse(body));
  }

  Future<Map<String, dynamic>> rankingsDataSupplier(String year,
      [String type, String sex, String category]) async {
    return await _rds.lookup(year, type, sex, category);
  }

  Future<List<SearchResult>> siteSearch(String keyword) async {
    String body =
        await _request("/result.php", {"cerca": keyword, "id_sito": "1"});
    return SearchResult.parse(html.parse(body));
  }

  Future<List<BasicEventInfo>> eventSearch(EventSearchInfo si) async {
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
    _checkMinMaxYear(doc);

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

  Future<AthleteInfo> athleteInfo(String url) async {
    String body = await _request(Uri.parse(url).path);
    var doc = html.parse(body);
    return AthleteInfo.parse(doc.querySelector("#content .text-holder"));
  }
}
