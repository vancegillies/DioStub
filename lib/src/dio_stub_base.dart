import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path_tree/path_tree.dart';

typedef StubHandler = FutureOr<StubResponse> Function(RequestOptions);

class DioStub implements HttpClientAdapter {
  bool closed = false;

  PathTree<StubHandler> stubs = PathTree<StubHandler>();

  final _pathVarMapping = <String, int>{};

  int? _pathGlobVarMapping;

  String? _pathGlobVarName;

  DioStub({Dio? client}) {
    if (client != null) {
      overrideAdapterFor(client);
    }
  }

  overrideAdapterFor(Dio client) {
    client.httpClientAdapter = this;
  }

  void stub(
    String path,
    StubHandler handler, [
    Iterable<String> methods = const ['*'],
  ]) {
    stubs.addPath(path, handler, tags: methods);
    setPathParams(path);
  }

  void setPathParams(String path) {
    final pathSegments = pathToSegments(path);
    for (int i = 0; i < pathSegments.length; i++) {
      String seg = pathSegments.elementAt(i);
      if (seg.startsWith(':')) {
        if (i == pathSegments.length - 1 && seg.endsWith('*')) {
          _pathGlobVarMapping = i;
          _pathGlobVarName = seg.substring(1, seg.length - 1);
        } else {
          seg = seg.substring(1);
          if (seg.isNotEmpty) _pathVarMapping[seg] = i;
        }
      }
    }
  }

  Map<String, dynamic> extractPathParams(List<String> requestPathSegments) {
    final pathParams = <String, dynamic>{};
    for (String pathParam in _pathVarMapping.keys) {
      var index = _pathVarMapping[pathParam];
      if (index == null || index > requestPathSegments.length - 1) continue;
      pathParams[pathParam] = requestPathSegments[_pathVarMapping[pathParam]!];
    }
    if (_pathGlobVarMapping != null) {
      pathParams[_pathGlobVarName!] = requestPathSegments.skip(_pathGlobVarMapping!).join('/');
    }

    return pathParams;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? _,
    Future? __,
  ) async {
    return handleStubbedRequest(
      makeStubOptions(options),
      getStub(options),
    ).then((response) => covertToResponse(response)).catchError((error) => throw DioError(requestOptions: options));
  }

  StubHandler getStub(RequestOptions options) {
    final stub = stubs.match(pathToSegments(options.path), options.method);
    if (stub == null) throw MissingStubError();
    return stub;
  }

  RequestOptions makeStubOptions(RequestOptions options) {
    return options.copyWith(extra: {
      ...options.extra,
      ...{
        'X-WEBMOCK': true,
        'pathParams': extractPathParams(options.uri.pathSegments),
      }
    });
  }

  ResponseBody covertToResponse(StubResponse response) {
    return ResponseBody.fromString(
      response.body,
      response.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  Future<StubResponse> handleStubbedRequest(
    RequestOptions options,
    StubHandler stub,
  ) async {
    late StubResponse response;
    if (stub is Future<StubResponse> Function(RequestOptions)) {
      response = await stub(options);
    } else if (stub is StubResponse Function(RequestOptions)) {
      response = stub(options);
    } else {
      throw IncorrectStubError();
    }
    return response;
  }

  @override
  void close({bool force = false}) {
    closed = true;
  }
}

class MissingStubError extends Error {}

class IncorrectStubError extends Error {}

extension RequestOptionsX on RequestOptions {
  dynamic pathParam(String key) {
    if (extra['X-WEBMOCK']) {
      return extra['pathParams'][key];
    }
    throw Exception('pathParam method only works in WebMock stubs');
  }
}

class StubResponse {
  String body;
  int statusCode;

  StubResponse(this.body, this.statusCode);
}
