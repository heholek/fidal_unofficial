import 'package:fidal_unofficial/material_dropdown.dart';
import 'package:fidal_unofficial/net/fidal_api.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

class SearchFieldsWidget extends StatefulWidget {
  final ValueNotifier<SearchInfo> searchInfoNotifier;

  SearchFieldsWidget(this.searchInfoNotifier);

  @override
  State<StatefulWidget> createState() {
    return SearchFieldsState();
  }
}

class SearchFieldsState extends State<SearchFieldsWidget> {
  String year = currentYear();
  String month = currentMonth();
  String level = "";
  String region = "";
  String type = "";
  String category = "";
  bool federal = false;

  static SearchInfo defaultSearchInfo() {
    return SearchInfo(currentYear(), currentMonth(), "", "", "", "", false);
  }

  void notifyCallback() {
    widget.searchInfoNotifier.value =
        SearchInfo(year, month, level, region, type, category, federal);
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

  static Map<String, String> generateTypesMap(String level) {
    if (level == "" || level == "COD") {
      return {
        "": "Any",
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
        "": "Any",
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
      padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
      color: Theme.of(context).accentColor,
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
                initialValue: year,
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
                initialValue: month,
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
                initialValue: level,
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
                initialValue: region,
                selectedTextStyle: SearchFieldTextStyle(),
                decoration: SearchFieldInputDecoration(hintText: "Region"),
                onChanged: (newVal) {
                  setState(() {
                    region = newVal;
                  });
                  notifyCallback();
                },
              )),
          Container(
              width: 180,
              child: DropdownField(
                items: generateTypesMap(level),
                initialValue: type,
                selectedTextStyle: SearchFieldTextStyle(),
                decoration: SearchFieldInputDecoration(hintText: "Type"),
                onChanged: (newVal) {
                  setState(() {
                    type = newVal;
                  });
                  notifyCallback();
                },
              )),
          Container(
              width: 120,
              child: DropdownField(
                items: generateCategoriesMap(),
                initialValue: category,
                selectedTextStyle: SearchFieldTextStyle(),
                decoration: SearchFieldInputDecoration(hintText: "Category"),
                onChanged: (newVal) {
                  setState(() {
                    category = newVal;
                  });
                  notifyCallback();
                },
              )),
          Container(
              width: 160,
              child: Theme(
                data: Theme.of(context)
                    .copyWith(unselectedWidgetColor: Colors.white),
                child: CheckboxListTile(
                    title: Text("Federal", style: SearchFieldTextStyle()),
                    value: federal,
                    checkColor: Theme.of(context).accentColor,
                    activeColor: Colors.white,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (newVal) {
                      setState(() {
                        federal = newVal;
                      });
                      notifyCallback();
                    }),
              ))
        ],
      ),
    );
  }
}
