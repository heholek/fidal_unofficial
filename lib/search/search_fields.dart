import 'dart:async';

import 'package:fidal_unofficial/material_dropdown.dart';
import 'package:fidal_unofficial/net/fidal_api.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'search_results.dart';

class SearchFieldInputDecoration extends InputDecoration { // TODO: Add field name in decoration
  SearchFieldInputDecoration({String hintText})
      : super(
            hintText: hintText,
            contentPadding: EdgeInsets.all(8.0),
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white30)),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white)));
}

class SearchFieldTextStyle extends TextStyle {
  SearchFieldTextStyle() : super(color: Colors.white);
}

class YearDropdownWidget extends StatefulWidget {
  final String initialValue;
  final Function(String) onChanged;

  YearDropdownWidget({this.initialValue, this.onChanged});

  @override
  State<StatefulWidget> createState() {
    return YearDropdownState(year: initialValue);
  }
}

class YearDropdownState extends State<YearDropdownWidget> {
  String year;
  Map<String, String> values;

  YearDropdownState({this.year});

  static Map<String, String> genarateYearsMapTemp() {
    int year = DateTime.now().year;
    Map<String, String> map = Map();
    for (int i = 0; i <= 10; i++) {
      int y = year - i;
      map[y.toString()] = y.toString();
    }
    return map;
  }

  static Future<Map<String, String>> generateYearsMap() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    int yearNow = DateTime.now().year;
    int minYear = prefs.containsKey("fidalSearch_minYear")
        ? int.tryParse(prefs.getString("fidalSearch_minYear"))
        : null;
    int maxYear = prefs.containsKey("fidalSearch_maxYear")
        ? int.tryParse(prefs.getString("fidalSearch_maxYear"))
        : null;

    if (minYear == null) minYear = yearNow - 9;
    if (maxYear == null) maxYear = yearNow;
    if (maxYear < yearNow) maxYear = yearNow;

    Map<String, String> map = Map();
    for (int i = maxYear; i >= minYear; i--) map[i.toString()] = i.toString();
    return map;
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      generateYearsMap().then((Map<String, String> map) {
        setState(() {
          values = map;
        });
      });
    });

    return Container(
        width: 80,
        child: DropdownField(
          selectedTextStyle: SearchFieldTextStyle(),
          items: values == null ? genarateYearsMapTemp() : values,
          initialValue: widget.initialValue,
          decoration: SearchFieldInputDecoration(hintText: "Anno"),
          onChanged: (newVal) {
            widget.onChanged(newVal);
            setState(() {
              year = newVal;
            });
          },
        ));
  }
}

class SearchFieldsWidget extends StatefulWidget {
  final StreamController<SearchStatus> streamController;

  SearchFieldsWidget(this.streamController);

  @override
  State<StatefulWidget> createState() {
    return SearchFieldsState();
  }
}

class SearchFieldsState extends State<SearchFieldsWidget> {
  String year = SearchInfo.currentYear();
  String month = SearchInfo.currentMonth();
  String level = "";
  String region = "";
  String type = "";
  String category = "";
  bool federal = false;

  void notifySearchInfoUpdated() {
    widget.streamController.add(SearchStatus.startSearch(
        SearchInfo(year, month, level, region, type, category, federal)));
  }

  static Map<String, String> generateMonthsMap() {
    var df = new DateFormat("MMMM");
    Map<String, String> map = Map();
    for (int i = 1; i <= 12; i++) {
      var dt = DateTime(0, i);
      map[i.toString()] = df.format(dt);
    }
    return map;
  }

  static Map<String, String> generateTypesMap(String level) {
    if (level == "" || level == "COD") {
      return {
        "": "--",
        "2": "Cross",
        "3": "Indoor",
        "8": "Marcia su strada",
        "11": "Montagna",
        "4": "Montagna/trail",
        "13": "Nordic walking",
        "5": "Outdoor",
        "10": "Piazza e altri ambiti",
        "6": "Strada",
        "12": "Trail",
        "7": "Ultramaratona",
        "9": "Ultramaratona/trail"
      };
    } else {
      return {
        "": "--",
        "2": "Cross",
        "3": "Indoor",
        "4": "Montagna",
        "5": "Pista",
        "6": "Strada",
        "7": "Trail"
      };
    }
  }

  static Map<String, String> generateLevelsMap() {
    return {"": "--", "COD": "Nazionale", "REG": "Regionale"};
  }

  static Map<String, String> generateRegionsMap() {
    return {
      "": "--",
      "ABRUZZO": "Abruzzo",
      "ALTOADIGE": "Alto Adige",
      "BASILICATA": "Basilicata",
      "CALABRIA": "Calabria",
      "CAMPANIA": "Campania",
      "EMILIAROMAGNA": "Emilia Romagna",
      "FRIULIVENEZIAGIULIA": "Friuli Venezia Giulia",
      "LAZIO": "Lazio",
      "LIGURIA": "Liguria",
      "LOMBARDIA": "Lombardia",
      "MARCHE": "Marche",
      "MOLISE": "Molise",
      "PIEMONTE": "Piemonte",
      "PUGLIA": "Puglia",
      "SARDEGNA": "Sardegna",
      "SICILIA": "Sicilia",
      "TOSCANA": "Toscana",
      "TRENTINO": "Trentino",
      "UMBRIA": "Umbria",
      "VALLEDAOSTA": "Valledaosta",
      "VENETO": "Veneto"
    };
  }

  static Map<String, String> generateCategoriesMap() {
    return {
      "": "--",
      "ESO": "Esordienti",
      "RAG": "Ragazzi",
      "CAD": "Cadetti",
      "ALL": "Allievi",
      "JUN": "Juniores",
      "PRO": "Promesse",
      "SEN": "Seniores",
      "MAS": "Master"
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
      color: Theme.of(context).accentColor,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8.0,
        runSpacing: 8.0,
        direction: Axis.horizontal,
        children: <Widget>[
          YearDropdownWidget(
              initialValue: year,
              onChanged: (newVal) {
                setState(() {
                  year = newVal;
                });
                notifySearchInfoUpdated();
              }),
          Container(
              width: 120,
              child: DropdownField(
                selectedTextStyle: SearchFieldTextStyle(),
                items: generateMonthsMap(),
                initialValue: month,
                decoration: SearchFieldInputDecoration(hintText: "Mese"),
                onChanged: (newVal) {
                  setState(() {
                    month = newVal;
                  });
                  notifySearchInfoUpdated();
                },
              )),
          Container(
              width: 120,
              child: DropdownField(
                items: generateLevelsMap(),
                initialValue: level,
                selectedTextStyle: SearchFieldTextStyle(),
                decoration: SearchFieldInputDecoration(hintText: "Livello"),
                onChanged: (newVal) {
                  setState(() {
                    level = newVal;
                  });
                  notifySearchInfoUpdated();
                },
              )),
          Container(
              width: 180,
              child: DropdownField(
                items: generateRegionsMap(),
                initialValue: region,
                selectedTextStyle: SearchFieldTextStyle(),
                decoration: SearchFieldInputDecoration(hintText: "Regione"),
                onChanged: (newVal) {
                  setState(() {
                    region = newVal;
                  });
                  notifySearchInfoUpdated();
                },
              )),
          Container(
              width: 180,
              child: DropdownField(
                items: generateTypesMap(level),
                initialValue: type,
                selectedTextStyle: SearchFieldTextStyle(),
                decoration: SearchFieldInputDecoration(hintText: "Tipologia"),
                onChanged: (newVal) {
                  setState(() {
                    type = newVal;
                  });
                  notifySearchInfoUpdated();
                },
              )),
          Container(
              width: 120,
              child: DropdownField(
                items: generateCategoriesMap(),
                initialValue: category,
                selectedTextStyle: SearchFieldTextStyle(),
                decoration: SearchFieldInputDecoration(hintText: "Categoria"),
                onChanged: (newVal) {
                  setState(() {
                    category = newVal;
                  });
                  notifySearchInfoUpdated();
                },
              )),
          Container(
              width: 160,
              child: Theme(
                data: Theme.of(context)
                    .copyWith(unselectedWidgetColor: Colors.white),
                child: CheckboxListTile(
                    title: Text("Camp. federale", style: SearchFieldTextStyle()),
                    value: federal,
                    checkColor: Theme.of(context).accentColor,
                    activeColor: Colors.white,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (newVal) {
                      setState(() {
                        federal = newVal;
                      });
                      notifySearchInfoUpdated();
                    }),
              ))
        ],
      ),
    );
  }
}
