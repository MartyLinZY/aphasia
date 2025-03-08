
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
  TestBase.runTestWithFullGlobalStates("DoctorExamsManagementPage smoke test", const DoctorExamsManagementPage(commonStyles: null,), (WidgetTester tester) async {
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

  TestBase.runTest("DoctorExamsManagementPage after login test",
    ChangeNotifierProvider(
      create: (context) => UserIdentity(identity: "identity", uid: "1", token: "fakeToken", role: 2),
      child: const DoctorExamsManagementPage(commonStyles: null,)
    ), (WidgetTester tester) async {

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