import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue/flutter_blue.dart';
import 'package:pretty_json/pretty_json.dart';

import 'package:movesense_flutter/movesense_flutter.dart';

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

  final FlutterBlue bt = FlutterBlue.instance;
  String _connectingTo;

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

  void _connect(BluetoothDevice device) async {
    String mac = device.id.toString();
    setState(() => _connectingTo = mac);
    final int serial = await Movesense.mdsConnect(mac);
    print("connected to Movesense with serial # $serial");
    setState(() => _connectingTo = null);
    Navigator.push(context,
      MaterialPageRoute(
        builder: (context) => Connect(device)
      ),
    );
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
                subtitle: _connectingTo == r.device.id.toString() ? LinearProgressIndicator() : Text(r.device.id.toString()), // there's probably a cleaner way to do this...
                onTap: () => _connect(r.device),
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text("${device.name}"),
      leading: IconButton(
        icon: Icon(Icons.first_page),
        onPressed: () async {
          await Movesense.mdsDisconnect(device.id.toString());
          Navigator.pop(context);
        },
      ),
    ),
    body: Padding(
      padding: const EdgeInsets.all(8.0),
      child: FutureBuilder(
        future: Movesense.info,
        builder: (BuildContext c, AsyncSnapshot<String> s) {
          switch (s.connectionState) {
            case ConnectionState.done:
              var jd = json.decode(s.data);
              return Text(prettyJson(jd['Content'], indent: 2));
              break;
            case ConnectionState.none:
            case ConnectionState.active:
            case ConnectionState.waiting:
              return Center(child: new CircularProgressIndicator());
              break;
            default:
              return Center(child: Icon(Icons.warning));
          }
        }
      ),
    ),
  );
}
