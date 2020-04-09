import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue/flutter_blue.dart';
import 'package:pretty_json/pretty_json.dart';

import 'package:movesense_flutter/movesense_flutter.dart';

final FlutterBlue bt = FlutterBlue.instance; // global so we can access from any page/route

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: Find(title: 'movesense_flutter plugin example app')
    );
  }
}


class Find extends StatefulWidget {
  Find({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _FindState createState() => _FindState();
}

class _FindState extends State<Find> {

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar (
      title: Text("Find Movesense Devices"),
      backgroundColor: Theme.of(context).colorScheme.primaryVariant,
    ),
    body: RefreshIndicator(
      onRefresh: _refresh, 
      child: _deviceListView(),
    ),
  );
  

  @override
  void dispose() {
    bt.stopScan();
    super.dispose();
  }

  Future<Null> _refresh() async {
    bt.startScan(timeout: Duration(seconds: 3)).catchError((e) => print("error starting Bluetooth scan: $e"));
  }

  Widget _deviceListView() {
    return StreamBuilder<List<ScanResult>>(
      initialData: [],
      stream: bt.scanResults,
      builder: (c, snapshot) => ListView(
        children: snapshot.data.map(
            (r) => Card(
              child: ListTile(
                title: Text(r.device.name),
                subtitle: Text(r.device.id.toString()),
                onTap: () async {
                  int serial = int.parse(r.device.name.split(" ")[1]);
                  String mac = r.device.id.toString();
                  await MovesenseFlutter.mdsConnect(serial, mac); // TODO: display spinning something...
                  Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Connected(r.device)),
                  );
                },
              ),
            ),
          ).toList(),
      ), 
    );
  }
}

class Connected extends StatefulWidget {
  final BluetoothDevice device;
  const Connected(this.device);
  @override
  _Connected createState() => _Connected();
}

class _Connected extends State<Connected> {
  String _info = '{"state":"Unknown"}';

  @override
  void initState() {
    super.initState();
  }

  Future<void> getDeviceInfo() async {
    String whiteboardResponse = await MovesenseFlutter.info;
    if(!mounted) return;
    setState(() => _info = whiteboardResponse);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("connected to ${widget.device.name}"),
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
              child: Column(
                children: <Widget>[
                  Text("Whiteboard Response:"),
                  Text(prettyJson(json.decode(_info), indent: 2)),
                ],
              )
            )
          ],
        ),
      );
  }
}
