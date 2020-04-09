import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

class WhiteboardResponse { // every response has a code and a payload
  int response;
  String responseString;
  String operation;
  String uri;
  Map<String, dynamic> content; // another JSON, but different for each path
  int queryTimeMilliseconds;
  int queryTimeNanoseconds;

  WhiteboardResponse({
    this.response,
    this.responseString,
    this.operation,
    this.uri,
    this.content,
    this.queryTimeMilliseconds,
    this.queryTimeNanoseconds,
  });

  WhiteboardResponse.fromJson(Map<String, dynamic> jsonMap):
    response = jsonMap['response'],
    responseString = jsonMap['responsestring'],
    operation = jsonMap['operation'],
    uri = jsonMap['uri'],
    content = jsonMap['content'],
    queryTimeMilliseconds = jsonMap['querytimems'],
    queryTimeNanoseconds = jsonMap['querytimens'];

  WhiteboardResponse.fromJsonString(String jsonString):
    this.fromJson(json.decode(jsonString));

}

class MovesenseFlutter {
  static const MethodChannel _mc = const MethodChannel('otter.works/movesense_whiteboard');
  // TODO: consider separate MethodChannel for get,put,post,delete

  static Future<String> get info async {
    final WhiteboardResponse response = await _mc.invokeMethod('get', {'path':'/Info'});
    return response.content;
  }

  static Future<String> get appInfo async {
    final WhiteboardResponse response = await _mc.invokeMethod('get', {'path':'/Info/App'});
    return response.content;
  }

  static Future<String> get batteryLevel async {
    final WhiteboardResponse response = await _mc.invokeMethod('get', {'path':'/System/Energy/Level'});
    return response.content;
  }

  static Future<int> get getTime async {
    final WhiteboardResponse response = await _mc.invokeMethod('get', {'path':'/Time'});
    int utime = 0;
    print(response.content);
    if(response.status == 200 ) {
      utime = int.parse(response.content);
    }
    return utime;
  }

  static Future<String> get getDetailedTime async {
    final WhiteboardResponse response = await _mc.invokeMethod('get', {'path':'/Time/Detailed'});
    return response.content;
  }

  static Future<Null> setTime(int utime) async {
    final WhiteboardResponse response = await _mc.invokeMethod('put', {'path':'/Time', 'type':'int64', 'value':utime}); // the key `value` does not appear to be officially documented
    if ( response.status != 200 ) {
      print("setting time unsuccessful: `$response`");
    }
  }

  static Future<Null> setVisualIndicator(int mode) async {
    final WhiteboardResponse response = await _mc.invokeMethod('put', {'path':'/Ui/Ind/Visual', 'type':'uint16', 'newState':mode}); // the key `newState` does not appear to be officially documented
    if ( response.status != 200 ) {
      print("setting time unsuccessful: `$response`");
    }
  }



}
