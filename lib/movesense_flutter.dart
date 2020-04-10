import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

class Movesense {
  static const MethodChannel _mc = const MethodChannel('otter.works/movesense_whiteboard');
  // TODO: investigate JSONMessageCodec class to potentially simplify encoding/decoding
  static int serial;

  static Future<int> mdsConnect(String mac) async {
    int _serial = await _mc.invokeMethod('connect', {'mac':mac});
    serial = _serial;
    return _serial;
  }

  static Future<Null> mdsDisconnect(String mac) async {
    await _mc.invokeMethod('disconnect', {'mac': mac});
  }

  static Future<String> get info async {
    final String response = await _mc.invokeMethod('get', {'path':'suunto://$serial/Info'});
    return response;
  }

  static Future<String> get appInfo async {
    final String response = await _mc.invokeMethod('get', {'path':'suunto://$serial/Info/App'});
    return response;
  }

  static Future<String> get batteryLevel async {
    final String response = await _mc.invokeMethod('get', {'path':'suunto://$serial/System/Energy/Level'});
    return response;
  }

  static Future<int> get time async {
    final String response = await _mc.invokeMethod('get', {'path':'suunto://$serial/Time'});
    print(response); // apparently mdsLib already strips it down to content...
    final int utime = json.decode(response)['Content'];
    return utime;
  }

  static Future<String> get detailedTime async {
    final String response = await _mc.invokeMethod('get', {'path':'suunto://$serial/Time/Detailed'});
    return response;
  }

  static Future<Null> setTime(int utime) async {
    final String response = await _mc.invokeMethod('put', {
      'path':'suunto://$serial/Time',
      'contract': '{"value": ${utime}}', // the key `value` does not appear to be officially documented
    });
    print(response); // apparently mdsLib already strips it down to content...
  }

  static Future<Null> setVisualIndicator(int mode) async {
    final String response = await _mc.invokeMethod('put', {
      'path':'suunto://$serial/Ui/Ind/Visual',
      'contract': '{"newState": ${mode}}', // the key `newState` does not appear to be officially documented
    });
    print(response); // apparently mdsLib already strips it down to content...
  }

  static Future<String> get dataloggerConfiguraion async {
    final String response = await _mc.invokeMethod('get', {'path':'suunto://$serial/Mem/Datalogger/Config'});
    return response;
  }

  static Future<String> setDataLoggerConfiguration(String configJsonString) async {
    final String response = await _mc.invokeMethod('put', {
      'path':'suunto://$serial/Mem/Datalogger/Config',
      'contract': configJsonString,
    });
    return response;
  }

  static Future<String> get dataloggerState async {
    final String response = await _mc.invokeMethod('get', {'path':'suunto://$serial/Mem/Datalogger/State'});
    return response;
  }

  static Future<String> startDatalogger() async {
    final String response = await _mc.invokeMethod('put', {
      'path':'suunto://$serial/Mem/Datalogger/State',
      'contract':'{"newState": 3}'
    });
    return response;
  }

  static Future<String> stopDatalogger() async {
    final String response = await _mc.invokeMethod('put', {
      'path':'suunto://$serial/Mem/Datalogger/State',
      'contract':'{"newState": 2}'
    });
    return response;
  }

  static Future<String> get logbookEntries async {
    final String response = await _mc.invokeMethod('get', {'path': 'suunto://$serial/Mem/Logbook/Entries'});
    print(response);
    return response;
  }

  static Future<String> get newLogbookEntry async {
    final String response = await _mc.invokeMethod('post', {'path': 'suunto://$serial/Mem/Logbook/Entries'});
    print(response);
    return response;
  }

  static Future<String> deleteAllLogbookEntries() async { // there's no example to selectively delete a single entry
    final String response = await _mc.invokeMethod('delete', {'path': 'suunto://$serial/Mem/Logbook/Entries'});
    print(response);
    return response;
  }

  static Future<String> getLogbookEntry(int index) async { // use the MDS proxy to convert SBEM to JSON
    final String response = await _mc.invokeMethod('get', {'path': 'suunto://MDS/Logbook/$serial/ById/${index}/Data'});
    print(response);
    return response;
  }

}
