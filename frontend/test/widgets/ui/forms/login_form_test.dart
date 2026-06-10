import 'dart:convert';

import 'package:aphasia_recovery/settings.dart';
import 'package:aphasia_recovery/utils/http/http_manager.dart';
import 'package:aphasia_recovery/utils/io/shared_pref.dart';
import 'package:aphasia_recovery/widgets/ui/doctor/doctor_exams_management.dart';
import 'package:aphasia_recovery/widgets/ui/login.dart';
import 'package:aphasia_recovery/widgets/ui/patient/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../TestBase.dart';
import '../../../fake_data.dart' as fake;

/// 把 POST /api/auth stub 成返回带 [role] 的 UserIdentity payload。
///
/// 现 prod `UserIdentity.login` 经 `HttpClientManager.post(body:'', headers:
/// {identity,password}, setToken:false)` 调用——body 为空串、身份信息走
/// headers，所以 stub 必须用 `anyNamed('body') + anyNamed('headers')`，
/// 不能再像旧测试那样写死 body 字串字面量。
void _stubAuthPost({required int role}) {
  final client = HttpClientManager().testClient!;
  when(client.post(
    Uri.parse('${HttpConstants.backendBaseUrl}/api/auth'),
    body: anyNamed('body'),
    headers: anyNamed('headers'),
  )).thenAnswer((_) async => Response(
        jsonEncode({
          "identity": fake.identity,
          "uid": fake.uid,
          "token": fake.token,
          "role": role,
        }),
        200,
      ));
}

void main() {
  TestBase.commonSetUp();

  // 与 doctor_all_exams_test 同款三件套：① SharedPreferences mock 重置；
  // ② WrappedSharedPref singleton 强制重建（不重建则它缓存了首次
  // getInstance() 的 Future，下一 test setMockInitialValues 失效）；
  // ③ HttpClientManager.testClient 清空让 enableTestMode 重新 new
  // MockClient，避免跨 test 累积 stub。
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    WrappedSharedPref.instance = null;
    HttpClientManager().testClient = null;
    TestBase.commonSetUp();
  });

  // 历史背景（#17）：原 2 条 skip:true 测试围绕"验证码 + 获取验证码按钮 +
  // fake.validateCode 自动填值"旧 flow 锁定，prod 已切到密码登录、获取验证码
  // 按钮被删、登录走 UserIdentity.login(identity, password)（参见
  // lib/widgets/ui/login.dart:287、lib/states/user_identity.dart:79）。
  // 本组按当前 prod 全部重写。

  testWidgets(
      "LoginPage 密码登录 happy path（医生 role=2 → DoctorExamsManagementPage）",
      (tester) async {
    _stubAuthPost(role: 2);

    await TestBase.testWithFullGlobalStates(
        tester, const LoginPage(commonStyles: null), () async {
      await tester.pumpAndSettle();

      // 现 prod 用 _buildInputField/_buildPasswordField 渲两个 TextFormField，
      // labelText 分别 "手机号/邮箱" 与 "密码"。
      final usernameField = find.widgetWithText(TextFormField, "手机号/邮箱");
      final passwordField = find.widgetWithText(TextFormField, "密码");
      expect(usernameField, findsOneWidget);
      expect(passwordField, findsOneWidget);
      // 旧 "获取验证码" 按钮已彻底删除
      expect(find.widgetWithText(ElevatedButton, "获取验证码"), findsNothing);
      // 登录 / 立即注册 两个按钮（注册替代了"快速体验测评>>"）
      expect(find.widgetWithText(ElevatedButton, "登录"), findsOneWidget);
      expect(find.widgetWithText(TextButton, "立即注册"), findsOneWidget);

      // _validateUsername 要求有效手机号或邮箱
      await tester.enterText(usernameField, "13800138000");
      await tester.enterText(passwordField, "abc123");
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, "登录"));
      await tester.pumpAndSettle();

      // 登录成功 → pushReplacement → LoginPage 应消失、DoctorExamsManagementPage
      // 应渲出（其内部子树是否完整加载不属于本测试关心范围——本测试只锁登录
      // 路由分发契约 + role 分支）。
      expect(find.byType(LoginPage), findsNothing);
      expect(find.byType(DoctorExamsManagementPage), findsOneWidget);
    });
  });

  testWidgets(
      "LoginPage 密码登录 happy path（患者 role=1 → HomePage）",
      (tester) async {
    _stubAuthPost(role: 1);

    await TestBase.testWithFullGlobalStates(
        tester, const LoginPage(commonStyles: null), () async {
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, "手机号/邮箱"), "patient@example.com");
      await tester.enterText(
          find.widgetWithText(TextFormField, "密码"), "abc123");
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, "登录"));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsNothing);
      expect(find.byType(HomePage), findsOneWidget);
    });
  });

  testWidgets(
      "LoginPage isEntry=false 登录后 Navigator.pop 回上一路由（不替换）",
      (tester) async {
    _stubAuthPost(role: 1);

    // 用一个 base Scaffold 作为初始路由，往上 push 一个 isEntry=false 的
    // LoginPage——成功登录后 prod 走 Navigator.pop 回到 base，不再 push 任何
    // 后续页面。
    await TestBase.testWithFullGlobalStates(tester,
        const Scaffold(body: Center(child: Text("__base_route__"))), () async {
      final baseCtx =
          tester.element(find.text("__base_route__"));
      Navigator.push(
        baseCtx,
        MaterialPageRoute(
            builder: (_) => const LoginPage(isEntry: false, commonStyles: null)),
      );
      await tester.pumpAndSettle();

      // LoginPage 已进入路由栈
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text("__base_route__"), findsNothing);

      await tester.enterText(
          find.widgetWithText(TextFormField, "手机号/邮箱"), "13800138000");
      await tester.enterText(
          find.widgetWithText(TextFormField, "密码"), "abc123");
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, "登录"));
      await tester.pumpAndSettle();

      // pop 回 base 路由，应无 LoginPage / HomePage / DoctorExamsManagementPage
      expect(find.byType(LoginPage), findsNothing);
      expect(find.byType(HomePage), findsNothing);
      expect(find.byType(DoctorExamsManagementPage), findsNothing);
      expect(find.text("__base_route__"), findsOneWidget);
    });
  });
}
