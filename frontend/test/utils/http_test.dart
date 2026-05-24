import 'dart:convert';

import 'package:aphasia_recovery/settings.dart';
import 'package:aphasia_recovery/exceptions/http_exceptions.dart';
import 'package:aphasia_recovery/utils/http/http_manager.dart';
import 'package:aphasia_recovery/utils/io/shared_pref.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../http_mock.mocks.dart';

void main() {
  // HttpClientManager 在 get/post 内部会读取 token，会调用 SharedPreferences。
  // 测试中必须先初始化 Binding 并注入 mock，否则报 "Binding has not yet been initialized"。
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    WrappedSharedPref.instance = null;
  });

  test("http request get tests", () async {
    HttpClientManager httpManager = HttpClientManager();
    httpManager.enableTestMode();
    final testClient = httpManager.testClient!;

    // success
    // HttpClientManager.get 总会传 headers（即使为空 map），因此使用
    // anyNamed('headers') 匹配，避免 MissingStubError。
    when(testClient.get(
      Uri.parse("${HttpConstants.backendBaseUrl}/api/test"),
      headers: anyNamed('headers'),
    )).thenAnswer((realInvocation) async => Response('{"result": "ok"}', 200));

    var jsonData = await httpManager.get(url: "${HttpConstants.backendBaseUrl}/api/test") as Map<String, dynamic>;
    expect(jsonData['result'], "ok");

    when(testClient.get(
      Uri.parse("${HttpConstants.backendBaseUrl}/api/test"),
      headers: anyNamed('headers'),
    )).thenAnswer((realInvocation) async => Response('[{"result": "ok1"}, {"result": "ok2"}]', 200));

    List<dynamic> jsonData2 = await httpManager.get(url: "${HttpConstants.backendBaseUrl}/api/test") as List;
    expect(jsonData2.length, 2);
    expect(jsonData2[0]['result'], "ok1");
    expect(jsonData2[1]['result'], "ok2");

    // fail
    when(testClient.get(
      Uri.parse("${HttpConstants.backendBaseUrl}/api/test"),
      headers: anyNamed('headers'),
    )).thenAnswer((realInvocation) async  {
      var fakeRequest = Request("get", Uri.parse("${HttpConstants.backendBaseUrl}/api/test"));
      var response = Response.bytes(utf8.encode('请求的资源不存在'), 404, request: fakeRequest);
      return response;
    });

    expect(() async => await httpManager.get(url: "${HttpConstants.backendBaseUrl}/api/test") as Map<String, dynamic>,
        throwsA(isA<Exception>()));

    try {
      await httpManager.get(url: "${HttpConstants.backendBaseUrl}/api/test") as Map<String, dynamic>;
    } on HttpRequestException catch(e) {
      expect(e.message, "请求的资源不存在");
      expect(e.response?.statusCode ?? e.streamedResponse?.statusCode, 404);
      expect(e.toString(), "Http get ${HttpConstants.backendBaseUrl}/api/test failed with 404: 请求的资源不存在");
    }
  });


  test("http request post tests", () async {
    HttpClientManager httpManager = HttpClientManager();
    httpManager.enableTestMode();
    final testClient = httpManager.testClient!;

    // success
    when(testClient.post(
      Uri.parse("${HttpConstants.backendBaseUrl}/api/test"),
      body: '"content": "content"',
      headers: anyNamed('headers'),
    )).thenAnswer((realInvocation) async => Response('{"result": "ok"}', 200));

    var jsonData = await httpManager.post(url: "${HttpConstants.backendBaseUrl}/api/test", body: '"content": "content"') as Map<String, dynamic>;
    expect(jsonData['result'], "ok");

    // fail
    when(testClient.post(
      Uri.parse("${HttpConstants.backendBaseUrl}/api/test"),
      body: '"content": "content"',
      headers: anyNamed('headers'),
    )).thenAnswer((realInvocation) async  {
      var fakeRequest = Request("post", Uri.parse("${HttpConstants.backendBaseUrl}/api/test"));
      var response = Response.bytes(utf8.encode('目标地址不存在'), 404, request: fakeRequest);
      return response;
    });

    expect(() async => await httpManager.post(url: "${HttpConstants.backendBaseUrl}/api/test", body: '"content": "content"') as Map<String, dynamic>,
        throwsA(isA<Exception>()));

    try {
      await httpManager.post(url: "${HttpConstants.backendBaseUrl}/api/test", body: '"content": "content"') as Map<String, dynamic>;
    } on HttpRequestException catch(e) {
      expect(e.message, "目标地址不存在");
      expect(e.response?.statusCode ?? e.streamedResponse?.statusCode, 404);
      expect(e.toString(), "Http post ${HttpConstants.backendBaseUrl}/api/test failed with 404: 目标地址不存在");
    }
  });
}