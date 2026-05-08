import 'dart:async';
import 'dart:convert';

import 'package:aphasia_recovery/exceptions/http_exceptions.dart';
import 'package:aphasia_recovery/utils/http/http_manager.dart';
import 'package:aphasia_recovery/utils/io/shared_pref.dart';
import 'package:flutter/foundation.dart';

import '../settings.dart';

/// 后端业务错误（含校验失败）抛出的 HTTP 状态码集合。
/// 修改前后端响应规范后，401/403 仅由拦截器/鉴权使用，
/// 业务错误统一走 GlobalExceptionHandler，返回 400/404/409 等。
const _businessErrorStatusCodes = <int>{400, 401, 403, 404, 409};

/// 自定义异常：表示一次"业务侧失败"（用户已存在 / 密码错 / 用户不存在 / token 过期…）。
/// 区别于网络故障与服务端 5xx。
class AuthBusinessException implements Exception {
  final int statusCode;
  final String message;
  AuthBusinessException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class UserIdentity extends ChangeNotifier {
  final String _identity;
  final String _uid;
  final String _token;

  /// 1表示患者，2表示医生
  final int _role;

  String get identity => _identity;

  String get uid => _uid;

  String get token => _token;

  bool get isPatient => _role == 1;
  bool get isDoctor => _role == 2;

  UserIdentity({required String identity, required String uid, required String token, required int role})
      : _identity = identity,
        _uid = uid,
        _token = token,
        _role = role;

  static Future<UserIdentity?> authWithToken() async {
    String? savedToken = await WrappedSharedPref().retrieveToken();
    if (savedToken == null) {
      return null;
    }

    try {
      Map<String, dynamic> jsonData = await HttpClientManager().post(
          url: '${HttpConstants.backendBaseUrl}/api/auth',
          body: '',
          headers: {"Token": savedToken});
      UserIdentity identity = UserIdentity(
          identity: jsonData['identity'],
          uid: jsonData['uid'],
          token: jsonData['token'],
          role: jsonData['role']);

      await WrappedSharedPref().saveToken(identity.token);

      return identity;
    } on HttpRequestException catch (e) {
      if (_businessErrorStatusCodes.contains(e.statusCode)) {
        // token 过期或失效，回到登录页
        return null;
      }
      rethrow;
    }
  }

  static Future<UserIdentity> login({required String identity, required String password}) async {
    try {
      Map<String, dynamic> jsonData = await HttpClientManager().post(
          url: '${HttpConstants.backendBaseUrl}/api/auth',
          body: '',
          headers: {"identity": identity, "password": password},
          setToken: false);

      UserIdentity userIdentity = UserIdentity(
          identity: jsonData['identity'],
          uid: jsonData['uid'],
          token: jsonData['token'],
          role: jsonData['role']);

      await WrappedSharedPref().saveToken(userIdentity.token);

      return userIdentity;
    } on HttpRequestException catch (e) {
      throw _toAuthBusinessException(e, fallback: '登录失败');
    }
  }

  static Future<void> logout() async {
    await WrappedSharedPref().deleteToken();
  }

  static Future<UserIdentity> register(Map<String, dynamic> registerInfo) async {
    try {
      Map<String, dynamic> jsonData = await HttpClientManager()
          .post(url: '${HttpConstants.backendBaseUrl}/api/register', body: jsonEncode(registerInfo));

      UserIdentity identity = UserIdentity(
          identity: jsonData['identity'],
          uid: jsonData['uid'],
          token: jsonData['token'],
          role: jsonData['role']);

      await WrappedSharedPref().saveToken(identity.token);

      return identity;
    } on HttpRequestException catch (e) {
      throw _toAuthBusinessException(e, fallback: '注册失败');
    }
  }

  /// 把一次 [HttpRequestException] 转换为 [AuthBusinessException]，
  /// 优先使用后端 ApiResponse 中的 message，否则退化为 fallback 文案。
  /// 非业务错误状态码会按原样 rethrow，由上层统一处理网络/服务端异常。
  static AuthBusinessException _toAuthBusinessException(HttpRequestException e, {required String fallback}) {
    if (!_businessErrorStatusCodes.contains(e.statusCode)) {
      throw e;
    }
    return AuthBusinessException(e.statusCode, _extractServerMessage(e) ?? fallback);
  }

  static String? _extractServerMessage(HttpRequestException e) {
    final raw = e.message;
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['message'] is String) {
        final msg = decoded['message'] as String;
        return msg.isEmpty ? null : msg;
      }
    } catch (_) {
      // 旧接口可能返回纯文本，忽略解析异常
    }
    return raw;
  }
}
