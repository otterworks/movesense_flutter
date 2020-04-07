import 'dart:async';

import 'package:flutter/services.dart';

class Operation {
  static const GET = "get";
  static const PUT = "put";
  static const POST = "post";
  static const DELETE = "delete";
}

class StatusCode {
  static const SUCCESS = 200;
  static const CREATED = 201;
  static const NO_CONTENT = 204;
}

class WhiteboardResponse { // every response has a code and a payload
  StatusCode status;
  String responseString;
  Operation operation;
  String uri;
  String content; // JSON?
  int queryTimeMilliseconds;
  int queryTimeNanoseconds;
}

class MovesenseFlutter {
  static const MethodChannel _mc = const MethodChannel('otter.works/movesense_whiteboard');
  // TODO: consider separate MethodChannel for get,put,post,delete

  static Future<int> get getTime async {
    final WhiteboardResponse response = await _mc.invokeMethod('get', {'path':'/Time'});
    print(response.content); // TODO: decode content to get utime
    final int utime = 0;
    return utime;
  }

  static Future<Null> setTime(int utime) async {
    final WhiteboardResponse response = await _mc.invokeMethod('put', {'path':'/Time/$utime'});
    if ( response.status != StatusCode.SUCCESS ) {
      print("setting time unsuccessful: `$response`");
    }
  }


}
