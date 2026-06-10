import 'dart:convert';

import 'package:aphasia_recovery/exceptions/http_exceptions.dart';
import 'package:aphasia_recovery/settings.dart';
import 'package:aphasia_recovery/utils/http/http_manager.dart';
import 'package:aphasia_recovery/utils/io/shared_pref.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 验证 P0 回归修复：LLM 诊断/修复接口必须经过 HttpClientManager，
/// 这样登录后保存的 Token 才会被自动塞进请求头。
/// 之前 llm_diagnose.dart / llm_repair.dart 用裸 http.post 直接调
/// /api/diagnose2, /api/repair，没带 Token 头，
/// 在 P0 移除拦截器白名单之后会一律 401。（/api/diagnose1 已下线）
///
/// 这里通过 HttpClientManager + 已保存的 Token 校验：
///   1) 请求被发到正确的 URL
///   2) Token 头被自动加上
///   3) 200 时 body 被反序列化成 Map
///   4) 401/403 时抛 HttpRequestException，statusCode 透传
Response _utf8Resp(String body, int code) => Response.bytes(
      utf8.encode(body),
      code,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

const _fakeToken = 'fake-jwt-token';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Client client;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'Token': _fakeToken});
    WrappedSharedPref.instance = null;
    HttpClientManager().enableTestMode();
    client = HttpClientManager().testClient!;
  });

  group('LLM diagnose / repair 鉴权布线', () {
    test('/api/diagnose2 携带 Token 头并解析出特征诊断结果', () async {
      when(client.post(
        Uri.parse('${HttpConstants.backendBaseUrl}/api/diagnose2'),
        body: jsonEncode({'conversation': 'PAR: 我...我叫小明'}),
        headers: argThat(
          containsPair('Token', _fakeToken),
          named: 'headers',
        ),
      )).thenAnswer((_) async => _utf8Resp(
          jsonEncode({
            'hasAphasia': true,
            'severity': '中度',
            'score': 4.5,
            'evidence': ['短而简化', '找词困难'],
          }),
          200));

      final data = await HttpClientManager().post(
        url: '${HttpConstants.backendBaseUrl}/api/diagnose2',
        body: jsonEncode({'conversation': 'PAR: 我...我叫小明'}),
      ) as Map<String, dynamic>;

      expect(data['hasAphasia'], true);
      expect(data['severity'], '中度');
      expect((data['score'] as num).toDouble(), closeTo(4.5, 1e-9));
      expect(data['evidence'], ['短而简化', '找词困难']);
    });

    test('/api/repair 携带 Token 头并解析出 repairedConversation', () async {
      when(client.post(
        Uri.parse('${HttpConstants.backendBaseUrl}/api/repair'),
        body: jsonEncode({'conversation': '原始对话'}),
        headers: argThat(
          containsPair('Token', _fakeToken),
          named: 'headers',
        ),
      )).thenAnswer((_) async => _utf8Resp(
            jsonEncode({'repairedConversation': '修复后的对话'}),
            200,
          ));

      final data = await HttpClientManager().post(
        url: '${HttpConstants.backendBaseUrl}/api/repair',
        body: jsonEncode({'conversation': '原始对话'}),
      ) as Map<String, dynamic>;

      expect(data['repairedConversation'], '修复后的对话');
    });

    test('/api/diagnose2 后端 401 → HttpRequestException(statusCode=401)',
        () async {
      when(client.post(
        Uri.parse('${HttpConstants.backendBaseUrl}/api/diagnose2'),
        body: anyNamed('body'),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => _utf8Resp(
            jsonEncode({'code': 401, 'message': '未登录'}),
            401,
          ));

      expect(
        () => HttpClientManager().post(
          url: '${HttpConstants.backendBaseUrl}/api/diagnose2',
          body: jsonEncode({'conversation': 'x'}),
        ),
        throwsA(
          isA<HttpRequestException>()
              .having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });

    test('/api/repair 后端 403 → HttpRequestException(statusCode=403)',
        () async {
      when(client.post(
        Uri.parse('${HttpConstants.backendBaseUrl}/api/repair'),
        body: anyNamed('body'),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => _utf8Resp(
            jsonEncode({'code': 403, 'message': '权限不足'}),
            403,
          ));

      expect(
        () => HttpClientManager().post(
          url: '${HttpConstants.backendBaseUrl}/api/repair',
          body: jsonEncode({'conversation': 'x'}),
        ),
        throwsA(
          isA<HttpRequestException>()
              .having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });
  });
}
