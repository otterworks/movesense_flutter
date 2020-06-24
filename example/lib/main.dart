import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:convert';

import 'package:pretty_json/pretty_json.dart';

import 'package:movesense_flutter/movesense_flutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: ThemeData.light(),
    darkTheme: ThemeData.dark(),
    home: Find()
  );
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
                onTap: () => Movesense.connect(devices[index]).whenComplete(() => Navigator.push(context, MaterialPageRoute(builder: (context) => Connect()))),
              )
            ),
          );
        }
      },
    ),
  );
}

class Connect extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Movesense Info:'),
      leading: BackButton(
        onPressed: () => Movesense.disconnect().whenComplete(() => Navigator.pop(context)),
      ),
    ),
    body: Padding(
      padding: const EdgeInsets.all(8.0),
      child: FutureBuilder(
        future: Movesense.info,
        builder: (BuildContext c, AsyncSnapshot<String> s) {
          if (s.hasData) {
            var jd = json.decode(s.data);
            return Text(prettyJson(jd['Content'], indent: 2));
          } else if (s.hasError) {
            return Text('ERROR:\n${s.error}');
          } else {
            return Center(child: new CircularProgressIndicator());
          }
        }
      ),
    ),
  );
}