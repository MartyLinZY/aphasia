import 'package:aphasia_recovery/deprecated/user_info.dart';
import 'package:aphasia_recovery/deprecated/doctor_recovery_management.dart';
import 'package:aphasia_recovery/deprecated/recovery_entry.dart';
import 'package:aphasia_recovery/deprecated/patient_starred_recovery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../TestBase.dart';

void main() {
  TestBase.runTest('RecoveryEntryPatientPage smoke test', ChangeNotifierProvider(
      create: (context) => UserInfo(),
      child: const RecoveryEntryPatientPage()
  ), (WidgetTester tester) async {
    var userInfo = find.byType(RecoveryEntryPatientPage).evaluate().first.read<UserInfo>();

    userInfo.role = 1;
    await tester.pump();
    expect(find.widgetWithText(InkWell, "使用系统内置康复方案"), findsOneWidget);
    expect(find.widgetWithText(InkWell, "我有医生的康复方案编号"), findsOneWidget);
    expect(find.byIcon(Icons.star), findsOneWidget);

    var starBtn = find.widgetWithText(ElevatedButton, "我收藏的康复方案");
    expect(starBtn, findsOneWidget);

    await tester.tap(starBtn);
    await tester.pumpAndSettle();

    expect(find.byType(PatientStarredRecoveryPage), findsOneWidget);
  });

  TestBase.runTest('RecoveryEntryDoctorPage smoke test', ChangeNotifierProvider(
      create: (context) => UserInfo(),
      child: const RecoveryEntryDoctorPage()
  ), (WidgetTester tester) async {
    var userInfo = find.byType(RecoveryEntryDoctorPage).evaluate().first.read<UserInfo>();

    userInfo.role = 2;
    await tester.pump();

    expect(find.widgetWithText(InkWell, "查看系统内置康复方案"), findsOneWidget);
    expect(find.widgetWithText(InkWell, "搜索其他医生创建的康复方案"), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);

    var myRecoveryBtn = find.widgetWithText(ElevatedButton, "我创建的康复方案");
    expect(myRecoveryBtn, findsOneWidget);

    await tester.tap(myRecoveryBtn);
    await tester.pumpAndSettle();

    expect(find.byType(DoctorRecoveryManagementPage), findsOneWidget);
  });
}