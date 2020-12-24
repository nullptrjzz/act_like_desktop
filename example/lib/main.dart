import 'package:act_like_desktop/widgets/draggable_panel.dart';
import 'package:act_like_desktop/widgets/tab_panel.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: DraggablePanel(
      size: Size(800, 600),
      draggableSides: DraggableSides.all(isDraggable: true),
      child: Container(
          color: Colors.grey,
          child: TabPage(
            tabs: [
              Container(
                color: Colors.yellow,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Tab1'),
              ),
              Container(
                color: Colors.lightBlue,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Tab2, a bit longer'),
              ),
              Container(
                color: Colors.lightGreen,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Tab3 is here'),
              ),
            ],
            pages: [
              Container(
                child: Center(
                  child: Text('1'),
                ),
              ),
              Container(
                child: Center(
                  child: Text('2'),
                ),
              ),
              Container(
                child: Center(
                  child: Text('3'),
                ),
              ),
            ],
          )),
    ));
  }
}
