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

  static Future<int> get getTime async {
    final String response = await _mc.invokeMethod('get', {'path':'/Time'});
    print(response); // apparently mdsLib already strips it down to content...
    final int utime = json.decode(response)['Content'];
    return utime;
  }

  static Future<String> get getDetailedTime async {
    final String response = await _mc.invokeMethod('get', {'path':'/Time/Detailed'});
    return response;
  }

  static Future<Null> setTime(int utime) async {
    final String response = await _mc.invokeMethod('put', {'path':'/Time', 'type':'int64', 'value':utime}); // the key `value` does not appear to be officially documented
    print(response); // apparently mdsLib already strips it down to content...
  }

  static Future<Null> setVisualIndicator(int mode) async {
    final String response = await _mc.invokeMethod('put', {'path':'/Ui/Ind/Visual', 'type':'uint16', 'newState':mode}); // the key `newState` does not appear to be officially documented
    print(response); // apparently mdsLib already strips it down to content...
  }



}
