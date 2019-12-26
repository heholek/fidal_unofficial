import 'package:flutter/material.dart';

class DropdownField extends StatefulWidget {
  final Map<String, String> items;
  final String initialValue;
  final InputDecoration decoration;
  final TextStyle selectedTextStyle;
  final void Function(String) onChanged;

  DropdownField(
      {Key key,
      @required this.items,
      @required this.selectedTextStyle,
      @required this.initialValue,
      @required this.decoration,
      this.onChanged})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _DropdownFieldState();
  }
}

class _DropdownFieldState extends State<DropdownField> {
  String val;

  @override
  Widget build(BuildContext context) {
    DropdownField widget = context.widget as DropdownField;
    if (val == null) val = widget.initialValue;
  
    return DropdownButtonFormField<String>(
      value: val,
      isDense: true,
      decoration: widget.decoration,
      iconEnabledColor: widget.selectedTextStyle.color,
      items: widget.items.keys.map((String value) {
        return new DropdownMenuItem<String>(
          value: value,
          child: new Text(widget.items[value]),
        );
      }).toList(),
      selectedItemBuilder: (_) {
        return widget.items.keys.map((String value) {
          return new DropdownMenuItem<String>(
            value: value,
            child: new Text(
              widget.items[value],
              style: widget.selectedTextStyle,
            ),
          );
        }).toList();
      },
      onChanged: (newVal) {
        widget.onChanged(newVal);

        setState(() {
          val = newVal;
        });
      },
    );
  }
}
