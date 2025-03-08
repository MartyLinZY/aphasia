import 'dart:convert';

import 'package:aphasia_recovery/exceptions/http_exceptions.dart';
import 'package:aphasia_recovery/utils/http/http_mock.mocks.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

import '../io/shared_pref.dart';

/// 包装http相关方法，负责request/response的编解码和通用错误处理
class HttpClientManager {
  static final HttpClientManager _instance = HttpClientManager._();
  Client? testClient;
  bool _testMode = false;

  HttpClientManager._();

  factory HttpClientManager() {
    return _instance;
  }

  /// should only be used in tests
  void enableTestMode() {
    testClient ??= MockClient();
    _testMode = true;
  }

  Future<Map<String, String>> setTokenToHeaders(Map<String, String>? headers) async {
    headers ??= {};
    String? token = await WrappedSharedPref().retrieveToken();

    if (token != null) {
      headers['Token'] = token;
    }

    return headers;
  }

  Future<bool> saveToken(String? token) async {
    if (token != null) {
      return await WrappedSharedPref().saveToken(token);
    } else {
      return false;
    }
  }

  Future<dynamic> get({required String url, Map<String, String>? headers}) async {
    headers = await setTokenToHeaders(headers);

    Response response;
    if (_testMode) {
      response = await testClient!.get(Uri.parse(url), headers: headers);
    } else {
      response = await http.get(Uri.parse(url), headers: headers);
    }

    if (response.statusCode == 200) {
      saveToken(response.headers['Token']);

      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw HttpRequestException(message: utf8.decode(response.bodyBytes), response: response);
    }
  }

  Future<dynamic> post({required String url, required String body, Map<String, String>? headers, bool setToken = true}) async {
    if (setToken) {
      headers = await setTokenToHeaders(headers);
    }

    Response response;

    headers ??= {};
    headers['Content-type'] = "application/json";
    headers['Accept'] = "application/json";
    if (_testMode) {
      response = await testClient!.post(Uri.parse(url), body: body, headers: headers);
    } else {
      response = await http.post(Uri.parse(url),
        body: body,
        headers: headers,
      );
    }

    if (response.statusCode == 200) {
      saveToken(response.headers['Token']);

      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw HttpRequestException(message: utf8.decode(response.bodyBytes), response: response);
    }
  }

  Future<bool> delete({required String url, Map<String, String>? headers}) async {
    headers = await setTokenToHeaders(headers);

    Response response;

    if (_testMode) {
      response = await testClient!.delete(Uri.parse(url), headers: headers);
    } else {
      response = await http.delete(Uri.parse(url), headers: headers,);
    }

    if (response.statusCode == 200) {
      saveToken(response.headers['Token']);

      return true;
    } else {
      throw HttpRequestException(message: utf8.decode(response.bodyBytes), response: response);
    }
  }

  Future<bool> patch({required String url, required String body, Map<String, String>? headers}) async {
    headers = await setTokenToHeaders(headers);

    Response response;

    headers['Content-type'] = "application/json";
    headers['Accept'] = "application/json";
    if (_testMode) {
      response = await testClient!.patch(Uri.parse(url), body: body, headers: headers);
    } else {
      response = await http.patch(Uri.parse(url),
        body: body,
        headers: headers,
      );
    }

    if (response.statusCode == 200) {
      saveToken(response.headers['Token']);

      return true;
    } else {
      throw HttpRequestException(message: utf8.decode(response.bodyBytes), response: response);
    }
  }

  Future<dynamic> multipartRequest({required MultipartFile file, Map<String, String>? headers, required String authority, required String path}) async {
    headers = await setTokenToHeaders(headers);
    http.StreamedResponse response;

    final uri = Uri.http(authority, path);
    final request = http.MultipartRequest("POST", uri)
        ..files.add(file);

    request.headers.addAll(headers);

    response = await request.send();

    if (response.statusCode == 200) {
      saveToken(response.headers['Token']);

      return jsonDecode(utf8.decode(await response.stream.toBytes()));
    } else {
      throw HttpRequestException(message: utf8.decode(await response.stream.toBytes()), streamedResponse: response);
    }
  }
}