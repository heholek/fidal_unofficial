import 'package:fidal_unofficial/material_dropdown.dart';
import 'package:fidal_unofficial/net/fidal_api.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'page.dart';

class SearchFieldInputDecoration extends InputDecoration {
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

class SearchFields extends StatefulWidget {
  final SearchInfoChangedCallback siChanged;

  SearchFields({@required this.siChanged});

  @override
  State<StatefulWidget> createState() {
    return SearchFieldsState();
  }
}

class SearchFieldsState extends State<SearchFields> {
  String year;
  String month;
  String level;
  String region;
  String type;
  String category;

  void notifyCallback() {
    widget.siChanged.onSearchInfoChanged(
        SearchInfo(year, month, level, region, type, category));
  }

  static Map<String, String> genarateYearsMap() {
    int year = DateTime.now().year;
    Map<String, String> map = Map();
    for (int i = 0; i <= 10; i++) {
      int y = year - i;
      map[y.toString()] = y.toString();
    }
    return map;
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

  static Map<String, String> generateLevelsMap() {
    return {"": "Any", "COD": "National", "REG": "Regional"};
  }

  static Map<String, String> generateRegionsMap() {
    return {
      "": "Any",
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
      "": "Any",
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

  static String currentYear() {
    return DateTime.now().year.toString();
  }

  static String currentMonth() {
    return DateTime.now().month.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16.0,
        runSpacing: 8.0,
        direction: Axis.horizontal,
        children: <Widget>[
          Container(
              width: 80,
              child: DropdownField(
                selectedTextStyle: SearchFieldTextStyle(),
                items: genarateYearsMap(),
                initialValue: year == null ? currentYear() : year,
                decoration: SearchFieldInputDecoration(hintText: "Year"),
                onChanged: (newVal) {
                  setState(() {
                    year = newVal;
                  });
                  notifyCallback();
                },
              )),
          Container(
              width: 120,
              child: DropdownField(
                selectedTextStyle: SearchFieldTextStyle(),
                items: generateMonthsMap(),
                initialValue: month == null ? currentMonth() : month,
                decoration: SearchFieldInputDecoration(hintText: "Month"),
                onChanged: (newVal) {
                  setState(() {
                    month = newVal;
                  });
                  notifyCallback();
                },
              )),
          Container(
              width: 120,
              child: DropdownField(
                items: generateLevelsMap(),
                initialValue: level == null ? "" : level,
                selectedTextStyle: SearchFieldTextStyle(),
                decoration: SearchFieldInputDecoration(hintText: "Level"),
                onChanged: (newVal) {
                  setState(() {
                    level = newVal;
                  });
                  notifyCallback();
                },
              )),
          Container(
              width: 180,
              child: DropdownField(
                items: generateRegionsMap(),
                initialValue: region == null ? "" : region,
                selectedTextStyle: SearchFieldTextStyle(),
                decoration: SearchFieldInputDecoration(hintText: "Region"),
                onChanged: (newVal) {
                  setState(() {
                    region = newVal;
                  });
                  notifyCallback();
                },
              )),
          // TODO: Add types dropdown
          Container(
              width: 120,
              child: DropdownField(
                items: generateCategoriesMap(),
                initialValue: category == null ? "" : category,
                selectedTextStyle: SearchFieldTextStyle(),
                decoration: SearchFieldInputDecoration(hintText: "Category"),
                onChanged: (newVal) {
                  setState(() {
                    category = newVal;
                  });
                  notifyCallback();
                },
              ))
        ],
      ),
      color: Colors.blue,
    );
  }
}
