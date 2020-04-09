import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
    super.dispose();
    bt.stopScan();
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
                onTap: () => Navigator.push(context,
                  MaterialPageRoute(
                    builder: (context) => Connect(r.device)
                  ),
                ),
              ),
            ),
          ).toList(),
      ), 
    );
  }
}

class Connect extends StatelessWidget {
  Connect(this.device, {Key key}) : super(key: key);

  final BluetoothDevice device;

  Future<String> _getDeviceInfo() async {
    int serial = int.parse(device.name.split(" ")[1]);
    String mac = device.id.toString();
    await MovesenseFlutter.mdsConnect(serial, mac);
    return MovesenseFlutter.info;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text("${device.name}"),
      leading: IconButton(
        icon: Icon(Icons.first_page),
        onPressed: () async {
          await MovesenseFlutter.mdsDisconnect();
          Navigator.pop(context);
        },
      ),
    ),
    body: Padding(
      padding: const EdgeInsets.all(8.0),
      child: FutureBuilder(
        future: _getDeviceInfo(),
        builder: (BuildContext c, AsyncSnapshot<String> s) {
          switch (s.connectionState) {
            case ConnectionState.none:
            case ConnectionState.active:
            case ConnectionState.waiting:
              return Center(child: new CircularProgressIndicator());
            case ConnectionState.done: {
              if (s.hasError) {
                return Text(
                  '${s.error}',
                  style: TextStyle(color: Colors.red),
                );
              } else if (s.hasData) {
                return Text(
                  prettyJson(json.decode(s.data), indent: 2),
                );
              } else {
                return Text(
                  '...not sure how we got here...',
                  style: TextStyle(color: Colors.red),
                );
              }
            }
          }
        }
      ),
    ),
  );
}
