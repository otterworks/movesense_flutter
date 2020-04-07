import 'dart:async';

import 'package:flutter/services.dart';

class WhiteboardResponse { // every response has a code and a payload
  int status;
  String responseString;
  String operation;
  String uri;
  String content; // JSON?
  int queryTimeMilliseconds;
  int queryTimeNanoseconds;
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

  static Future<int> get getTime async {
    final WhiteboardResponse response = await _mc.invokeMethod('get', {'path':'/Time'});
    print(response.content); // TODO: decode content to get utime
    final int utime = 0;
    return utime;
  }

  static Future<Null> setTime(int utime) async {
    final WhiteboardResponse response = await _mc.invokeMethod('put', {'path':'/Time/$utime'});
    if ( response.status != 200 ) {
      print("setting time unsuccessful: `$response`");
    }
  }


}
