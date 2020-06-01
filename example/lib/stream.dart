import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:convert';

import 'package:pretty_json/pretty_json.dart';

import 'package:movesense_flutter/movesense_flutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: Find()
    );
  }
}

class Find extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar (
      title: Text("Find Movesense Devices"),
      backgroundColor: Theme.of(context).colorScheme.primaryVariant,
    ),
    body: StreamBuilder(
      stream: Movesense.scan,
      builder: (context, snapshot) {
        if(snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if(!snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Movesense scan results empty so far...'),
          );
        } else {
          List<BleDevice> devices = snapshot.data;
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: devices.length,
            itemBuilder: (context, index) => Card(
              child: ListTile(
                title: Text(devices[index].name),
                subtitle: Text("MAC: ${devices[index].mac}"),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => Connect(devices[index]))),
              )
            ),
          );
        }
      },
    ),
  );
}

class Connect extends StatelessWidget {
  Connect(this.device, {Key key}) : super(key: key);

  final BleDevice device;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text("${device.name}"),),
    body: StreamBuilder(
      stream: Movesense.connection(device),
      builder: (context, snapshot) {
        if(snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Error: ${snapshot.error}'),
          );
        } else if(!snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          );
        } else if((snapshot.data == 'connecting') || (snapshot.data == 'disconnected')) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(snapshot.data),
          );
        } else if(snapshot.data.toString().startsWith('connected to MAC: ${device.mac} serial #: ')) { //, serial # ${device.name.split(' ').last}') {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: displayMovesenseInfo(),
          );
        } else {
          return Text("This really shouldn't happen:\n${snapshot.data}");
        }
      },
    ),
  );

  Widget displayMovesenseInfo() {
    return FutureBuilder(
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
            return Center(child: CircularProgressIndicator());
            break;
          default:
            return Center(child: Icon(Icons.warning));
        }
      }
    );
  }
}
