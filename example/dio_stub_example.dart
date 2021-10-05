import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio_stub/dio_stub.dart';
import 'package:test/test.dart';

// Checkout tests for more examples
void main() async {
  Dio dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
  DioStub dioStub = DioStub(client: dio);
  
  final responseMap = {'test': 'ok'};

  dioStub.stub('/test', (options) {
    return StubResponse(jsonEncode(responseMap), 200);
  });

  final response = await dio.get('/test');
  expect(responseMap, response.data);
}
