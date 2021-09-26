# DioStub

I had an idea to stub methods like handling requests on the server side, so I could make a simulator to handle many requests and mock all of them with what everdata I wanted. So I made DioStub

This package is version a work in progress and probably won't have active development, it was made to solve my very specific problem. That said anyone is welcome to make PRs or fork

## Features

- Simple interface to add stub methods
- Stub methods have access to path params

## Usage
Using DioStub is simple just construct an DioStub instance with the dio client you wish to stub

** Note: Internaly DioStub overides Dio's HttpClientAdapter so all request go through DioStub. if you use a route that isnt stubbed dio with throw an Error

```dart
Dio dio = Dio();
DioStub dioStub = DioStub(dio: dio);

dioStub.stub('/test', (options) {
    return StubResponse(jsonEncode({'some': 'response'}), 200);
});
```

DioStub uses the same path param processing as Jaguar and injects the path params into a key in the "extra" of RequestOptions. but there is a helper extension

```dart
dioStub.stub('/test/:id', (options) {
    final id = options.pathParam('id');
    return StubResponse(jsonEncode({'test': id}), 200);
});
```

### Credits

#### Jaguar-Dart:
- path_tree package
- route matching logic.
