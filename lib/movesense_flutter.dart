import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

class Movesense {
  static const MethodChannel _wb = const MethodChannel('otter.works/movesense/whiteboard');
  // TODO: investigate JSONMessageCodec class to potentially simplify encoding/decoding
  static const EventChannel _scan = const EventChannel('otter.works/movesense/scan');
  static const EventChannel _connection = const EventChannel('otter.works/movesense/connection');
  static int serial;

  static Stream get scan {
    return _scan.receiveBroadcastStream().transform(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          List<BleDevice> devices = [];
          final decoded = json.decode(data);
          decoded.forEach((k, v) => devices.add(BleDevice(name: v, mac: k)));
          sink.add(devices);
        },
        handleError: (error, stackTrace, sink) {
          sink.addError('error in Movesense scan StreamTransformer: $error');
        },
        handleDone: (sink) {
          sink.close();
        },
      )
    );
  }

  static Stream connection(BleDevice device) {
    return _connection.receiveBroadcastStream(device.mac).transform(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          final String msg = data.toString();
          print(msg);
          if ((msg == 'connecting') || (msg == 'disconnected')) {
            serial = null;
          } else if (msg.startsWith('connected to MAC:')) {
            serial = int.tryParse(msg.split(':').last.trim());
            print('$serial');
          } else {
            sink.addError('Movesense connect StreamTransformer does not recognize data: $data');
          }
//          sink.add(serial.toString());
          sink.add(msg);
        },
        handleError: (error, stackTrace, sink) {
          sink.addError('error in Movesense connect StreamTransformer: $error');
        },
        handleDone: (sink) {
          sink.close();
        }
      )
    );
  }  

  static Future<String> get info async {
    final String response = await _wb.invokeMethod('get', {'path':'suunto://$serial/Info'});
    return response;
  }

  static Future<String> get appInfo async {
    final String response = await _wb.invokeMethod('get', {'path':'suunto://$serial/Info/App'});
    return response;
  }

  static Future<String> get batteryLevel async {
    final String response = await _wb.invokeMethod('get', {'path':'suunto://$serial/System/Energy/Level'});
    return response;
  }

  static Future<int> get time async {
    final String response = await _wb.invokeMethod('get', {'path':'suunto://$serial/Time'});
    print(response); // apparently mdsLib already strips it down to content...
    final int utime = json.decode(response)['Content'];
    return utime;
  }

  static Future<String> get detailedTime async {
    final String response = await _wb.invokeMethod('get', {'path':'suunto://$serial/Time/Detailed'});
    return response;
  }

  static Future<Null> setTime(int utime) async {
    final String response = await _wb.invokeMethod('put', {
      'path':'suunto://$serial/Time',
      'contract': '{"value": $utime}', // the key `value` does not appear to be officially documented
    });
    print(response); // apparently mdsLib already strips it down to content...
  }

  static Future<Null> setVisualIndicator(int mode) async {
    final String response = await _wb.invokeMethod('put', {
      'path':'suunto://$serial/Ui/Ind/Visual',
      'contract': '{"newState": $mode}', // the key `newState` does not appear to be officially documented
    });
    print(response); // apparently mdsLib already strips it down to content...
  }

  static Future<String> get dataloggerConfiguraion async {
    final String response = await _wb.invokeMethod('get', {'path':'suunto://$serial/Mem/Datalogger/Config'});
    return response;
  }

  static Future<String> setDataLoggerConfiguration(String configJsonString) async {
    final String response = await _wb.invokeMethod('put', {
      'path':'suunto://$serial/Mem/Datalogger/Config',
      'contract': configJsonString,
    });
    return response;
  }

  static Future<String> get dataloggerState async {
    final String response = await _wb.invokeMethod('get', {'path':'suunto://$serial/Mem/Datalogger/State'});
    return response;
  }

  static Future<String> startDatalogger() async {
    final String response = await _wb.invokeMethod('put', {
      'path':'suunto://$serial/Mem/Datalogger/State',
      'contract':'{"newState": 3}'
    });
    return response;
  }

  static Future<String> stopDatalogger() async {
    final String response = await _wb.invokeMethod('put', {
      'path':'suunto://$serial/Mem/Datalogger/State',
      'contract':'{"newState": 2}'
    });
    return response;
  }

  static Future<List<LogbookEntry>> get logbookEntries async {
    final String response = await _wb.invokeMethod('get', {'path': 'suunto://MDS/Logbook/$serial/Entries'});
    Map<String, dynamic> decoded = json.decode(response);
    LogbookEntries entries = LogbookEntries.fromJson(decoded);
    assert(entries != null);
    print("${entries.toJson()}");
    return entries.elements;
  }

  static Future<int> get newLogbookEntry async {
    final String response = await _wb.invokeMethod('post', {'path': 'suunto://$serial/Mem/Logbook/Entries'});
    print(response);
    return json.decode(response)["Content"];
  }

  static Future<String> deleteAllLogbookEntries() async { // there's no example to selectively delete a single entry
    final String response = await _wb.invokeMethod('delete', {'path': 'suunto://$serial/Mem/Logbook/Entries'});
    print(response);
    return response;
  }

  static Future<String> getLogbookEntry(int index) async { // use the MDS proxy to convert SBEM to JSON
    final String response = await _wb.invokeMethod('get', {'path': 'suunto://MDS/Logbook/$serial/ById/$index/Data'});
    print(response);
    return response;
  }

}

class BleDevice {
  String name;
  String mac;

  BleDevice({this.name, this.mac});

  BleDevice.fromJson(Map<String, dynamic> json) {
    name = json['Name'];
    mac = json['Mac'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['Name'] = this.name;
    data['Mac'] = this.mac;
    return data;
  }
}

class BleDeviceList {
  List<BleDevice> elements;

  BleDeviceList({this.elements});

  BleDeviceList.fromJson(Map<String, dynamic> json) {
    if (json['elements'] != null) {
      elements = new List<BleDevice>();
      json['elements'].forEach((v) {
        elements.add(new BleDevice.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.elements != null) {
      data['elements'] = this.elements.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class LogbookEntry {
  int id;
  int modificationTimestamp;
  int size;

  LogbookEntry({this.id, this.modificationTimestamp, this.size});

  LogbookEntry.fromJson(Map<String, dynamic> json) {
    id = json['Id'];
    modificationTimestamp = json['ModificationTimestamp'];
    size = json['Size'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['Id'] = this.id;
    data['ModificationTimestamp'] = this.modificationTimestamp;
    data['Size'] = this.size;
    return data;
  }
}

class LogbookEntries {
  List<LogbookEntry> elements;

  LogbookEntries({this.elements});

  LogbookEntries.fromJson(Map<String, dynamic> json) {
    if (json['elements'] != null) {
      elements = new List<LogbookEntry>();
      json['elements'].forEach((v) {
        elements.add(new LogbookEntry.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.elements != null) {
      data['elements'] = this.elements.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
