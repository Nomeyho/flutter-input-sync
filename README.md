# How to synchronize input fields in Flutter

A Flutter application to show how to synchronize input values between multiple `TextField` widgets.

## Introduction
The problem:
> The values of two input fields (`TextField` widgets in Flutter) must be synchronized.
If the value of the first input changes, the second input must be updated.
And conversely, the first input must be updated when the value of the second input changes.

To illustrate the problem, I built a simple currency converter application.

### Layout
The layout is pretty straightforward. We have a title (`Text`) and two inputs fields
(`TextField`) wrapped in a `Column` widget. The first input field is used to enter the amount of euros
and the second one to enter the mount of USD.

<p align="center">
  <img height="200"
       src="https://github.com/Nomeyho/flutter-input-sync/raw/master/article/layout.png"
       alt="layout"
  />
</p>

```Dart
class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final rate = 1.12;user

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
                Text('Rate: €1 = \$$rate',
                    style: Theme.of(context).textTheme.title),
                SizedBox(height: 20),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: 'EUR', border: OutlineInputBorder()),
                ),
                SizedBox(height: 20),
                TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: 'USD', border: OutlineInputBorder()))
              ],
            ),
          ),
        ));
  }
}
```
## The problem
Most currency converters allow you to edit the value of a single currency at the time.
You typically have to *swap* the currencies if you want to make the reverse conversion.
They also often lack of reactivity. The converted value is not updated in real-time, as you are typing.
You have to click on a button to perform the conversion and display the amount in the target currency.

For this app, we need to have a **two-way** dataflow between the two inputs. This article describes
 a technique to solve those shortcomings with Flutter.

## Attempt #1 - TextInputController
As we need to be able to get and set the value of an input field, we have no other choice than using a `TextEditingController`.
The `onChange` callback would only allow us to get the value of the input field.
Let's create a controller for each input, attached a listener to each and pass them to the `TextField`s.
The listeners will be called whenever the value of the input field changes.

```Dart
class _HomePageState extends State<HomePage> {
  final _rate = 1.12;
  final _euroController = TextEditingController();
  final _usdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _euroController.addListener(this.onEuroChange);
    _usdController.addListener(this.onUSDChange);
  }

  onEuroChange() {

  }

  onUSDChange() {

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
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: 'EUR', border: OutlineInputBorder()),
                ),
                SizedBox(height: 20),
                TextField(
                    controller: _usdController,
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
      _usdController.dispose();
      _euroController.dispose();
      super.dispose();
    }
}
```

The listeners will contain the logic to synchronize the two inputs:
* `onEuroChange`:
    * get the value of the euro field (`_euroController.text`)
    * parse the value from `String` into a `double` (`double.tryParse`)
    * compute the USD amount by multiplying the amount of Euros by the conversion rate (around `1.12` today)
    * update the value of the USD field (`_usdController.value = TextEditingValue(...)`)
* `onUSDChange`:
    * get the value of the USD field (`_usdController.text`)
    * parse the value from `String` into a `double` (`double.tryParse`)
    * compute the amount of Euros by dividing the amount of USD by the conversion rate
    * update the value of the euro field (`_euroController.value = TextEditingValue(...)`)

```Dart
  onEuroChange() {
    final euro = double.tryParse(_euroController.text);

    if (euro != null) {
      final usd = euro * _rate;
      _usdController.value = TextEditingValue(text: usd.toStringAsFixed(2));
    }
  }

  onUSDChange() {
    final usd = double.tryParse(_usdController.text);

    if (usd != null) {
      final euro = usd / _rate;
      _euroController.value = TextEditingValue(text: euro.toStringAsFixed(2));
    }
  }
```

Result:
![cursor_issue](https://github.com/Nomeyho/flutter-input-sync/raw/master/article/1.gif "Cursor issue")


The cursor gets moved to the left of the input field, making it impossible to continue typing.
What's going on?
1. The `onEuroChange` is called when the euro input value changes
2. The listener updates the value of the other input
3. The `onUSDChange` listener is triggered because the USD amount was updated
4. In turn, the second listener sets the value of the Euro input. The loop breaks here
(the `onEuroChange` listener is not called again) because the input value is identical.
In appearance nothing changed, but the value of the input field was replaced by the same value!
This made the cursor position to be reset.

![schema](https://github.com/Nomeyho/flutter-input-sync/raw/master/article/schema.png "Schema")


## Attempt #2 - FocusNode
Ideally, only steps 1 and 2 should be executed.
The trick is to conditionally execute the listeners:
> A listener should only be executed if its corresponding input was focused.

In this example, it means that the `onEuroChange` would be executed because
the user was typing in it and the input therefore had the focus.
The `onUSDChange` would also be called but would immediately exit because it didn't have the focus.

Let's use the `FocusNode` object provided by Flutter to implement this solution.
This object allows us to control the Widget having the focus on the screen.

```Dart
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
```

Result:
![final](https://github.com/Nomeyho/flutter-input-sync/raw/master/article/2.gif "Final")


## Conclusion
Programmatically synchronizing multiple input fields can be tricky. In this article, we have seen
 a solution based on the `TextEditingController` and `FocusNode`. Dont forget to dispose those
 objects are using them.

 The code is available here:
[https://github.com/Nomeyho/flutter-input-sync](https://github.com/Nomeyho/flutter-input-sync)

## Bonus
How to set the initial value?
```Dart
@override
void initState() {
  ...
  _euroController.value = TextEditingValue(text: '1');
}
```

and add
```
autofocus: true,
```
to the first input to make sure that the listener is executed.

![autofocus](https://github.com/Nomeyho/flutter-input-sync/raw/master/article/3.gif "Autofocus")

