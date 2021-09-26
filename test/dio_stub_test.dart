import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:dio_stub/dio_stub.dart';

void main() {
  group('DioStub', () {
    late Dio dio;
    late DioStub dioStub;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
      dioStub = DioStub(dio: dio);
    });

    test(' - it stubs a simple route', () async {
      final responseMap = {'test': 'ok'};

      dioStub.stub('/test', (options) {
        return StubResponse(jsonEncode(responseMap), 200);
      });

      final response = await dio.get('/test');
      expect(responseMap, response.data);
    });

    test(' - it stubs a route with path params', () async {
      dioStub.stub('/test/:id', (options) {
        final id = options.pathParam('id');
        return StubResponse(jsonEncode({'test': id}), 200);
      });

      final response = await dio.get('/test/1234');
      expect({'test': '1234'}, response.data);
    });

    test(' - it stubs a route with 2 path params', () async {
      dioStub.stub('/test/:id/books/:bookId', (options) {
        final id = options.pathParam('id');
        final bookId = options.pathParam('bookId');
        return StubResponse(jsonEncode({'id': id, 'bookId': bookId}), 200);
      });

      final response = await dio.get('/test/1234/books/5678');
      expect({'id': '1234', 'bookId': '5678'}, response.data);
    });

    test(' - it stubs a route with a Future returned', () async {
      dioStub.stub('/test', (options) async {
        await Future.delayed(Duration(milliseconds: 200));
        return StubResponse(jsonEncode({'test': 'waited for Future'}), 200);
      });

      final response = await dio.get('/test');
      expect({'test': 'waited for Future'}, response.data);
    });

    test(' - it stubs a route for only GET', () async {
      dioStub.stub('/test', (options) {
        return StubResponse(jsonEncode({'test': 'only GET works'}), 200);
      }, ['GET']);

      final responseGet = await dio.get('/test');
      expect({'test': 'only GET works'}, responseGet.data);
      final responsePost = dio.post('/test');
      expect(responsePost, throwsA(TypeMatcher<DioError>()));
    });

    test(' - it stubs a route for only GET, POST', () async {
      dioStub.stub('/test', (options) {
        return StubResponse(
            jsonEncode({'test': "${options.method} works"}), 200);
      }, ['GET', 'POST']);

      final responseGet = await dio.get('/test');
      expect({'test': 'GET works'}, responseGet.data);
      final responsePost = await dio.post('/test');
      expect({'test': 'POST works'}, responsePost.data);
      final responsePatch = dio.patch('/test');
      expect(responsePatch, throwsA(TypeMatcher<DioError>()));
    });

    test(' - it stubs a route and throws when returning a 400', () async {
      dioStub.stub('/test', (options) {
        return StubResponse(jsonEncode({'error': 'error'}), 400);
      });

      final response = dio.get('/test');
      expect(response, throwsA(TypeMatcher<DioError>()));
    });

    test(' - it stubs a route and uses dio interceptors', () async {
      List<String> testInfo = [];

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            testInfo.add('onRequest');
            handler.next(options);
          },
          onResponse: (options, handler) {
            testInfo.add('onResponse');
            handler.next(options);
          },
        ),
      );

      dioStub.stub('/test', (options) {
        testInfo.add('fromStub');
        return StubResponse(jsonEncode({'test': 'ok'}), 200);
      });

      final response = await dio.get('/test');
      expect(response.data, {'test': 'ok'});
      expect(testInfo, ['onRequest', 'fromStub', 'onResponse']);
    });
  });
}
