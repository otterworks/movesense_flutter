import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movesense_flutter/movesense_flutter.dart';

void main() {
  const MethodChannel channel = MethodChannel('movesense_flutter');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });
}
