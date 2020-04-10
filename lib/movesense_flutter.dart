import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

class Movesense {
  static const MethodChannel _mc = const MethodChannel('otter.works/movesense_whiteboard');
  // TODO: consider separate MethodChannel for get,put,post,delete
  // TODO: investicate JSONMessageCodec class to potentially simplify encoding/decoding

  static Future<Null> mdsConnect(int serial, String mac) async {
    final int response = await _mc.invokeMethod('connect', {'serial':serial, 'mac':mac});
    if( response != 200 ) {
      print("native plugin did not accept movesense serial number: $serial");
    }
  }

  static Future<Null> mdsDisconnect() async {
    final int response = await _mc.invokeMethod('disconnect');
    if( response != 200 ) {
      print("native plugin did not disconnect");
    }
  }

  static Future<String> get info async {
    final String response = await _mc.invokeMethod('get', {'path':'/Info'});
    return response;
  }

  static Future<String> get appInfo async {
    final String response = await _mc.invokeMethod('get', {'path':'/Info/App'});
    return response;
  }

  static Future<String> get batteryLevel async {
    final String response = await _mc.invokeMethod('get', {'path':'/System/Energy/Level'});
    return response;
  }

  static Future<int> get time async {
    final String response = await _mc.invokeMethod('get', {'path':'/Time'});
    print(response); // apparently mdsLib already strips it down to content...
    final int utime = json.decode(response)['Content'];
    return utime;
  }

  static Future<String> get detailedTime async {
    final String response = await _mc.invokeMethod('get', {'path':'/Time/Detailed'});
    return response;
  }

  static Future<Null> setTime(int utime) async {
    final String response = await _mc.invokeMethod('put', {
      'path':'/Time',
      'parameters': '{"value": ${utime}}', // the key `value` does not appear to be officially documented
    });
    print(response); // apparently mdsLib already strips it down to content...
  }

  static Future<Null> setVisualIndicator(int mode) async {
    final String response = await _mc.invokeMethod('put', {
      'path':'/Ui/Ind/Visual',
      'parameters': '{"newState": ${mode}}', // the key `newState` does not appear to be officially documented
    });
    print(response); // apparently mdsLib already strips it down to content...
  }

  static Future<String> get dataloggerConfiguraion async {
    final String response = await _mc.invokeMethod('get', {'path':'/Mem/Datalogger/Config'});
    return response;
  }

  static Future<String> setDataLoggerConfiguration(String configJsonString) async {
    final String response = await _mc.invokeMethod('put', {
      'path':'/Mem/Datalogger/Config',
      'parameters': configJsonString,
    });
    return response;
  }

  static Future<String> get dataloggerState async {
    final String response = await _mc.invokeMethod('get', {'path':'/Mem/Datalogger/State'});
    return response;
  }

  static Future<String> startDatalogger() async {
    final String response = await _mc.invokeMethod('put', {
      'path':'/Mem/Datalogger/State',
      'parameters':'{"newState": 3}'
    });
    return response;
  }

  static Future<String> stopDatalogger() async {
    final String response = await _mc.invokeMethod('put', {
      'path':'/Mem/Datalogger/State',
      'parameters':'{"newState": 2}'
    });
    return response;
  }

  static Future<String> get logbookEntries async {
    final String response = await _mc.invokeMethod('get', {'path': '/Mem/Logbook/Entries'});
    print(response);
    return response;
  }

  static Future<String> getogbookEntry(int index) async {
    final String response = await _mc.invokeMethod('get', {'path': '/Mem/Logbook/Entries/${index}'});
    print(response);
    return response;
  }
/*
there are also URIs in the sample that access and manipulate with a different prefix:

    private static final String URI_MDS_LOGBOOK_ENTRIES = "suunto://MDS/Logbook/{0}/Entries";
    private static final String URI_MDS_LOGBOOK_DATA= "suunto://MDS/Logbook/{0}/ById/{1}/Data";
*/


}
