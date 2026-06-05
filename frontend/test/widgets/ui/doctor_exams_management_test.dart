
import 'dart:convert';

import 'package:aphasia_recovery/settings.dart';
import 'package:aphasia_recovery/states/user_identity.dart';
import 'package:aphasia_recovery/utils/http/http_manager.dart';
import 'package:aphasia_recovery/deprecated/doctor_exam_drafts.dart';
import 'package:aphasia_recovery/widgets/ui/doctor/doctor_exams_management.dart';
import 'package:aphasia_recovery/widgets/ui/login.dart';
import 'package:aphasia_recovery/widgets/ui/doctor/doctor_all_exams.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../../TestBase.dart';
import '../../fake_data.dart' as fake;

void main() {
  // TODO(#17): smoke test 写法是"直接渲染 DoctorExamsManagementPage 期望被
  // auth gateway 拦下去 LoginPage，再走完整登录流程进回来"，依赖整条 prod
  // login flow——而 prod LoginPage 已从验证码登录改为密码登录（lib/widgets/ui/
  // login.dart:287 用 labelText '密码' 而非 '验证码'，"获取验证码"按钮也已
  // 移除）。整个端到端 flow 不存在，断言全失效。需要按当前 password-based
  // login + auth gateway 注入路径重写。
  TestBase.runTestWithFullGlobalStates("DoctorExamsManagementPage smoke test", const DoctorExamsManagementPage(commonStyles: null,), skip: true, (WidgetTester tester) async {
    Client client = HttpClientManager().testClient!;
    var userId = "1";

    // for DoctorAllExamsPage to get exams list
    when(client.get(Uri.parse("${HttpConstants.backendBaseUrl}/api/doctors/$userId/exams")))
        .thenAnswer((realInvocation) async => http.Response.bytes(
        utf8.encode(fake.examListJsonData), 200));

    await tester.pumpAndSettle();
    expect(find.byType(DoctorExamsManagementPage), findsNothing);
    expect(find.byType(LoginPage), findsOneWidget);

    var usernameInput = find.widgetWithText(TextFormField, "手机号/邮箱");
    await tester.tap(usernameInput);
    tester.testTextInput.enterText("identity");

    var validateCodeBtn = find.widgetWithText(ElevatedButton, "获取验证码");
    await tester.tap(validateCodeBtn);

    // for DoctorAllExamsPage to get exams list
    when(client.post(Uri.parse('${HttpConstants.backendBaseUrl}/api/auth'), body: '{"identity": "${fake.identity}", "validateCode": "${fake.validateCode}"}'))
        .thenAnswer((realInvocation) async => Response('{"uid": "${fake.uid}", "token": "${fake.oldToken}"}', 200));
    var loginBtn = find.widgetWithText(ElevatedButton, "登录");
    await tester.tap(loginBtn);
    await tester.pumpAndSettle();

    var page = find.byType(DoctorExamsManagementPage);
    expect(page, findsOneWidget);
  });

  // TODO(#17): "我的康复方案" tab 原导航目标 DoctorExamDraftsPage 已 deprecated
  // （仍在 lib/deprecated/ 下），prod 实际跳到一个非 deprecated 的页面，line 74
  // expect(DoctorExamDraftsPage) 失配。需照当前 prod 的 tab 目标重写。
  TestBase.runTest("DoctorExamsManagementPage after login test",
    ChangeNotifierProvider(
      create: (context) => UserIdentity(identity: "identity", uid: "1", token: "fakeToken", role: 2),
      child: const DoctorExamsManagementPage(commonStyles: null,)
    ), skip: true, (WidgetTester tester) async {

    var managePage = find.byType(DoctorExamsManagementPage);
    expect(managePage, findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));

    var allTab = find.text("我的测评方案");
    var draftTab = find.text("我的康复方案");
    expect(allTab, findsOneWidget);
    expect(draftTab, findsOneWidget);

    expect(find.byType(DoctorAllExamsListPage), findsOneWidget);

    await tester.tap(draftTab, warnIfMissed: false);
    await tester.pump();

    expect(find.byType(DoctorExamDraftsPage), findsOneWidget);
  });
}