import 'package:aphasia_recovery/deprecated/exam_entry.dart';
import 'package:aphasia_recovery/deprecated/user_info.dart';
import 'package:aphasia_recovery/widgets/ui/login.dart';
import 'package:aphasia_recovery/widgets/ui/patient/exam_record_history.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../TestBase.dart';

void main() {
  TestBase.runTestWithFullGlobalStates('ExamPatientPage smoke test', const ExamEntryPatientPage(), (WidgetTester tester) async {
    var userInfo = find.byType(ExamEntryPatientPage).evaluate().first.read<UserInfo>();

    userInfo.role = 1;
    await tester.pump();

    expect(find.widgetWithText(InkWell, "我要自测"), findsOneWidget);
    expect(find.widgetWithText(InkWell, "我有医生的测评编号"), findsOneWidget);

    var historyBtn = find.widgetWithText(ElevatedButton, "我做过的测评记录");
    expect(historyBtn, findsOneWidget);
    expect(find.byIcon(Icons.history), findsOneWidget);

    await tester.tap(historyBtn);
    await tester.pumpAndSettle();

    expect(find.byType(ExamRecordHistoryPage), findsOneWidget);
  });

  TestBase.runTestWithFullGlobalStates('ExamEntryDoctorPage smoke test', const ExamEntryDoctorPage(), (WidgetTester tester) async {
    var userInfo = find.byType(ExamEntryDoctorPage).evaluate().first.read<UserInfo>();

    userInfo.role = 2;
    await tester.pump();
    expect(find.widgetWithText(InkWell, "体验内置测评流程"), findsOneWidget);
    expect(find.widgetWithText(InkWell, "搜索其他医生创建的测评方案"), findsOneWidget);


    var myExamBtn = find.widgetWithText(ElevatedButton, "我创建的测评方案");
    expect(myExamBtn, findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);

    await tester.tap(myExamBtn);
    await tester.pumpAndSettle();

    // 未登录情况下
    expect(find.byType(LoginPage), findsOneWidget);

    // TODO: 登录情况下
    // expect(find.byType(DoctorExamsManagementPage), findsOneWidget);
    // await tester.pageBack();
    // await tester.pumpAndSettle();
    //
    // expect(find.byType(ExamEntryDoctorPage), findsOneWidget);
  });
}