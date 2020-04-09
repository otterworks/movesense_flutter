import 'package:flutter/material.dart';
import 'dart:async';

import 'package:movesense_flutter/movesense_flutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _info = 'Unknown';

  Future<void> getDeviceInfo() async {
    String whiteboardResponse = await MovesenseFlutter.info;
    if(!mounted) return;
    setState(() => _info = whiteboardResponse);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('movesense_flutter plugin example app'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Center(
              child: IconButton(
                icon: Icon(Icons.info_outline),
                onPressed: getDeviceInfo,
              ),
            ),
            Center(
              child: Text("Whiteboard Response:\n$_info\n")
            )
          ],
        ),
      ),
    );
  }
}
