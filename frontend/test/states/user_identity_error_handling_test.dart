import 'dart:convert';

import 'package:aphasia_recovery/exceptions/http_exceptions.dart';
import 'package:aphasia_recovery/settings.dart';
import 'package:aphasia_recovery/states/user_identity.dart';
import 'package:aphasia_recovery/utils/http/http_manager.dart';
import 'package:aphasia_recovery/utils/io/shared_pref.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fake_data.dart' as fake;

/// 把字符串响应封装成支持中文的 UTF-8 Response。
Response _utf8Resp(String body, int code) =>
    Response.bytes(utf8.encode(body), code, headers: {'content-type': 'application/json; charset=utf-8'});

/// 验证 UserIdentity 在新统一 ApiResponse 体下，
/// 把 400/401/403/404/409 都解析为 AuthBusinessException 并提取后端 message。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Client client;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    WrappedSharedPref.instance = null;
    HttpClientManager().enableTestMode();
    client = HttpClientManager().testClient!;
  });

  test('login 成功路径返回 UserIdentity', () async {
    final body = jsonEncode({
      'identity': fake.identity,
      'uid': fake.uid,
      'token': fake.oldToken,
      'role': 1,
    });
    when(client.post(
      Uri.parse('${HttpConstants.backendBaseUrl}/api/auth'),
      body: '',
      headers: argThat(
          allOf(
            containsPair('identity', fake.identity),
            containsPair('password', fake.validateCode),
          ),
          named: 'headers'),
    )).thenAnswer((_) async => _utf8Resp(body, 200));

    final identity = await UserIdentity.login(
      identity: fake.identity,
      password: fake.validateCode,
    );

    expect(identity.identity, fake.identity);
    expect(identity.uid, fake.uid);
    expect(identity.token, fake.oldToken);
    expect(identity.isPatient, true);
  });

  test('login 错误密码 → AuthBusinessException 含后端 message', () async {
    when(client.post(
      Uri.parse('${HttpConstants.backendBaseUrl}/api/auth'),
      body: '',
      headers: argThat(
          allOf(
            containsPair('identity', fake.identity),
            containsPair('password', 'WRONG'),
          ),
          named: 'headers'),
    )).thenAnswer((_) async =>
        _utf8Resp(jsonEncode({'code': 400, 'message': '用户密码错误'}), 400));

    expect(
      () => UserIdentity.login(identity: fake.identity, password: 'WRONG'),
      throwsA(
        isA<AuthBusinessException>()
            .having((e) => e.statusCode, 'statusCode', 400)
            .having((e) => e.message, 'message', '用户密码错误'),
      ),
    );
  });

  test('login 用户不存在 → AuthBusinessException 含 message', () async {
    when(client.post(
      Uri.parse('${HttpConstants.backendBaseUrl}/api/auth'),
      body: '',
      headers: argThat(
          allOf(
            containsPair('identity', '__nope__'),
            containsPair('password', 'x'),
          ),
          named: 'headers'),
    )).thenAnswer((_) async =>
        _utf8Resp(jsonEncode({'code': 400, 'message': '用户不存在'}), 400));

    expect(
      () => UserIdentity.login(identity: '__nope__', password: 'x'),
      throwsA(
        isA<AuthBusinessException>()
            .having((e) => e.message, 'message', '用户不存在'),
      ),
    );
  });

  test('login 5xx → 透传 HttpRequestException', () async {
    when(client.post(
      Uri.parse('${HttpConstants.backendBaseUrl}/api/auth'),
      body: '',
      headers: anyNamed('headers'),
    )).thenAnswer((_) async => _utf8Resp('boom', 500));

    expect(
      () => UserIdentity.login(identity: fake.identity, password: fake.validateCode),
      throwsA(isA<HttpRequestException>().having((e) => e.statusCode, 'statusCode', 500)),
    );
  });

  test('register 用户已存在(409) → AuthBusinessException', () async {
    when(client.post(
      Uri.parse('${HttpConstants.backendBaseUrl}/api/register'),
      body: anyNamed('body'),
      headers: anyNamed('headers'),
    )).thenAnswer((_) async =>
        _utf8Resp(jsonEncode({'code': 409, 'message': '用户已存在'}), 409));

    expect(
      () => UserIdentity.register({
        'identity': fake.identity,
        'password': 'abc1234',
        'role': 2,
      }),
      throwsA(
        isA<AuthBusinessException>()
            .having((e) => e.statusCode, 'statusCode', 409)
            .having((e) => e.message, 'message', '用户已存在'),
      ),
    );
  });

  test('register 校验失败(400) → AuthBusinessException 含字段信息', () async {
    when(client.post(
      Uri.parse('${HttpConstants.backendBaseUrl}/api/register'),
      body: anyNamed('body'),
      headers: anyNamed('headers'),
    )).thenAnswer((_) async => _utf8Resp(
        jsonEncode({'code': 400, 'message': 'role role必须为1或2'}), 400));

    expect(
      () => UserIdentity.register({
        'identity': fake.identity,
        'password': 'abc1234',
        'role': 99,
      }),
      throwsA(
        isA<AuthBusinessException>()
            .having((e) => e.message, 'message', contains('role')),
      ),
    );
  });

  test('register 成功路径返回 UserIdentity', () async {
    final body = jsonEncode({
      'identity': 'newdoc',
      'uid': 'u-new',
      'token': fake.oldToken,
      'role': 2,
    });
    when(client.post(
      Uri.parse('${HttpConstants.backendBaseUrl}/api/register'),
      body: anyNamed('body'),
      headers: anyNamed('headers'),
    )).thenAnswer((_) async => _utf8Resp(body, 200));

    final identity = await UserIdentity.register({
      'identity': 'newdoc',
      'password': 'abc1234',
      'role': 2,
    });

    expect(identity.identity, 'newdoc');
    expect(identity.isDoctor, true);
  });

  test('authWithToken 无 saved token → null', () async {
    final result = await UserIdentity.authWithToken();
    expect(result, isNull);
  });

  test('authWithToken token 过期 (400) → null（业务错误自动登出）', () async {
    SharedPreferences.setMockInitialValues({'Token': 'stale-token'});
    WrappedSharedPref.instance = null;

    when(client.post(
      Uri.parse('${HttpConstants.backendBaseUrl}/api/auth'),
      body: '',
      headers: argThat(
          containsPair('Token', 'stale-token'),
          named: 'headers'),
    )).thenAnswer((_) async =>
        _utf8Resp(jsonEncode({'code': 400, 'message': 'token过期'}), 400));

    final result = await UserIdentity.authWithToken();
    expect(result, isNull);
  });
}
