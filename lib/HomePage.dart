import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _rate = 1.12;
  final _euroController = TextEditingController();
  final _usdController = TextEditingController();
  final _euroFocusNode = FocusNode();
  final _usdFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _euroController.addListener(this.onEuroChange);
    _usdController.addListener(this.onUSDChange);
    _euroController.value = TextEditingValue(text: '1');
  }

  onEuroChange() {
    if (_euroFocusNode.hasFocus) {
      final euro = double.tryParse(_euroController.text);

      if (euro != null) {
        final usd = euro * _rate;
        _usdController.value = TextEditingValue(text: usd.toStringAsFixed(2));
      }
    }
  }

  onUSDChange() {
    if (_usdFocusNode.hasFocus) {
      final usd = double.tryParse(_usdController.text);

      if (usd != null) {
        final euro = usd / _rate;
        _euroController.value = TextEditingValue(text: euro.toStringAsFixed(2));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Container(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text('Rate: €1 = \$$_rate',
                    style: Theme.of(context).textTheme.title),
                SizedBox(height: 20),
                TextField(
                  controller: _euroController,
                  focusNode: _euroFocusNode,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: 'EUR', border: OutlineInputBorder()),
                ),
                SizedBox(height: 20),
                TextField(
                    controller: _usdController,
                    focusNode: _usdFocusNode,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: 'USD', border: OutlineInputBorder()))
              ],
            ),
          ),
        ));
  }

  @override
  void dispose() {
    _usdFocusNode.dispose();
    _euroFocusNode.dispose();
    _usdController.dispose();
    _euroController.dispose();
    super.dispose();
  }
}
