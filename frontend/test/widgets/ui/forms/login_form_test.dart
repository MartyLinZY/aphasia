// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:aphasia_recovery/settings.dart';
import 'package:aphasia_recovery/states/user_identity.dart';
import 'package:aphasia_recovery/utils/http/http_manager.dart';
import 'package:aphasia_recovery/widgets/ui/login.dart';
import 'package:aphasia_recovery/widgets/ui/patient/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';


import '../../../TestBase.dart';
import '../../../fake_data.dart' as fake;

void main() {
  // TODO(#17): prod LoginPage 已从 验证码登录 改为 密码登录——lib/widgets/ui/
  // login.dart:287 用 TextFormField labelText:'密码' 而非旧的 '验证码'，相应
  // 的 "获取验证码" 按钮 / "${fake.validateCode}" 自动填值流程都没了。本组
  // 两条 test 全部围绕旧 flow 锁定，需要照当前 password 流程整体重写。
  TestBase.runTestWithFullGlobalStates('Login Form basic test', const LoginPage(commonStyles: null,), skip: true, (WidgetTester tester) async {
    // await tester.pumpWidget(const MyApp());
    var validateCodeBtn = find.widgetWithText(ElevatedButton, "获取验证码");
    var usernameInput = find.widgetWithText(TextFormField, "手机号/邮箱");
    expect(usernameInput, findsOneWidget);
    expect(find.widgetWithText(TextFormField, "验证码"), findsOneWidget);
    expect(validateCodeBtn, findsOneWidget);
    expect(find.widgetWithText(TextButton, "快速体验测评>>"), findsOneWidget);

    await tester.tap(usernameInput);
    tester.testTextInput.enterText("identity");
    await tester.pump();
    expect(find.widgetWithText(TextFormField, "identity"), findsOneWidget);


    // Tap the '+' icon and trigger a frame.
    await tester.tap(validateCodeBtn);
    await tester.pump();

    // Verify that our counter has incremented.
    // expect(find.widgetWithText(TextFormField, "验证码"), findsNothing);
    expect(find.widgetWithText(TextFormField, fake.validateCode), findsOneWidget);

    var client = HttpClientManager().testClient!;
    when(client.post(Uri.parse('${HttpConstants.backendBaseUrl}/api/auth'), body: '{"identity": "${fake.identity}", "validateCode": "${fake.validateCode}"}'))
        .thenAnswer((realInvocation) async => Response('{"uid": "${fake.uid}", "token": "${fake.oldToken}"}', 200));
    var loginBtn = find.widgetWithText(ElevatedButton, "登录");
    await tester.tap(loginBtn);
    await tester.pumpAndSettle();

    var userIdentity = find.byType(MaterialApp).evaluate().first.read<UserIdentity>();
    expect(userIdentity.identity, "identity");

    expect(find.byType(HomePage), findsOneWidget);
  });

  TestBase.runTestWithFullGlobalStates('Login Form does not as entry test', const Placeholder(), skip: true, (WidgetTester tester) async {
    Navigator.push(find.byType(Placeholder).evaluate().first, MaterialPageRoute(builder: (context) => const LoginPage(isEntry: false, commonStyles: null,)));
    await tester.pumpAndSettle();

    var usernameInput = find.widgetWithText(TextFormField, "手机号/邮箱");
    await tester.tap(usernameInput);
    tester.testTextInput.enterText("identity");
    await tester.pump();
    expect(find.widgetWithText(TextFormField, "identity"), findsOneWidget);


    // Tap the '+' icon and trigger a frame.
    var validateCodeBtn = find.widgetWithText(ElevatedButton, "获取验证码");
    await tester.tap(validateCodeBtn);
    await tester.pump();

    expect(find.widgetWithText(TextFormField, fake.validateCode), findsOneWidget);

    var client = HttpClientManager().testClient!;
    when(client.post(Uri.parse('${HttpConstants.backendBaseUrl}/api/auth'), body: '{"identity": "${fake.identity}", "validateCode": "${fake.validateCode}"}'))
        .thenAnswer((realInvocation) async => Response('{"uid": "${fake.uid}", "token": "${fake.oldToken}"}', 200));
    var loginBtn = find.widgetWithText(ElevatedButton, "登录");
    await tester.tap(loginBtn);
    await tester.pumpAndSettle();

    var userIdentity = find.byType(MaterialApp).evaluate().first.read<UserIdentity>();
    expect(userIdentity.identity, "identity");

    expect(find.byType(HomePage), findsNothing);
    expect(find.byType(Placeholder), findsOneWidget);
  });
}
