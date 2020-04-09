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
  // TODO: investicate JSONMessageCodec class to potentially simplify encoding/decoding

  static Future<Null> pluginSerial(int serial) async {
    final int response = await _mc.invokeMethod('plugin', {'serial':serial});
    if( response != 200 ) {
      print("native plugin did not accept movesense serial number: $serial");
    }
  }

  static Future<String> get info async {
    final String response = await _mc.invokeMethod('get', {'path':'/Info'});
    final WhiteboardResponse wr = WhiteboardResponse.fromJsonString(response);
    if( wr.response == 200 ) {
      return json.encode(wr.content); // re-encode for now...
    } else {
      return wr.responseString;
    }
  }

  static Future<String> get appInfo async {
    final String response = await _mc.invokeMethod('get', {'path':'/Info/App'});
    final WhiteboardResponse wr = WhiteboardResponse.fromJsonString(response);
    if( wr.response == 200 ) {
      return json.encode(wr.content); // re-encode for now...
    } else {
      return wr.responseString;
    }
  }

  static Future<String> get batteryLevel async {
    final String response = await _mc.invokeMethod('get', {'path':'/System/Energy/Level'});
    return response;
  }

  static Future<int> get getTime async {
    final String response = await _mc.invokeMethod('get', {'path':'/Time'});
    final WhiteboardResponse wr = WhiteboardResponse.fromJsonString(response);
    int utime = 0;
    print("content: ${wr.content}, type: ${wr.content.runtimeType}");
    if(wr.response == 200 ) {
      utime = 1e6.toInt(); // .parse(response.content);
    }
    return utime;
  }

  static Future<String> get getDetailedTime async {
    final String response = await _mc.invokeMethod('get', {'path':'/Time/Detailed'});
    final WhiteboardResponse wr = WhiteboardResponse.fromJsonString(response);
    if(wr.response == 200 ) {
      return json.encode(wr.content);
    } else {
      return wr.responseString;
    }
  }

  static Future<Null> setTime(int utime) async {
    final String response = await _mc.invokeMethod('put', {'path':'/Time', 'type':'int64', 'value':utime}); // the key `value` does not appear to be officially documented
    final WhiteboardResponse wr = WhiteboardResponse.fromJsonString(response);
    if ( wr.response != 200 ) {
      print("setting time unsuccessful: `$response`");
    }
  }

  static Future<Null> setVisualIndicator(int mode) async {
    final String response = await _mc.invokeMethod('put', {'path':'/Ui/Ind/Visual', 'type':'uint16', 'newState':mode}); // the key `newState` does not appear to be officially documented
    final WhiteboardResponse wr = WhiteboardResponse.fromJsonString(response);
    if ( wr.response != 200 ) {
      print("setting time unsuccessful: `$response`");
    }
  }



}
