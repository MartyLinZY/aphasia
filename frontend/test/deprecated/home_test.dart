import 'package:aphasia_recovery/deprecated/exam_entry.dart';
import 'package:aphasia_recovery/deprecated/user_info.dart';
import 'package:aphasia_recovery/deprecated/global_states_provider.dart';
import 'package:aphasia_recovery/widgets/ui/patient/history.dart';
import 'package:aphasia_recovery/widgets/ui/login.dart';
import 'package:aphasia_recovery/widgets/ui/patient/home.dart';
import 'package:aphasia_recovery/deprecated/recovery_entry.dart';
import 'package:aphasia_recovery/widgets/ui/patient/search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:provider/provider.dart';

import '../TestBase.dart';

void main() {
  TestBase.runTestWithFullGlobalStates('HomePage smoke test', const HomePage(commonStyles: null,), (WidgetTester tester) async {
     expect(find.byType(NavigationRail), findsOneWidget);

     var userInfo = find.byType(HomePage).evaluate().first.read<UserInfo>();
     userInfo.role = 1;
     await tester.pump();

     var examTab = find.text("测评");
     expect(examTab, findsOneWidget);
     await tester.tap(examTab, warnIfMissed: false);
     await tester.pump();
     expect(find.byType(ExamEntryPatientPage), findsOneWidget);

     userInfo.role = 2;
     await tester.pump();
     expect(find.byType(ExamEntryDoctorPage), findsOneWidget);

     userInfo.role = 1;
     var recoveryTab = find.text("康复");
     expect(recoveryTab, findsOneWidget);
     await tester.tap(recoveryTab, warnIfMissed: false);
     await tester.pump();
     expect(find.byType(RecoveryEntryPatientPage), findsOneWidget);

     userInfo.role = 2;
     await tester.pump();
     expect(find.byType(RecoveryEntryDoctorPage), findsOneWidget);


     var searchTab  = find.text("搜索");
     expect(searchTab, findsOneWidget);
     await tester.tap(searchTab, warnIfMissed: false);
     await tester.pump();
     expect(find.byType(SearchPage), findsOneWidget);

     var meTab = find.text("我");
     expect(meTab, findsOneWidget);
     await tester.tap(meTab, warnIfMissed: false);
     await tester.pump();
     expect(find.byType(HistoryPage), findsOneWidget);

     var exitBtn = find.widgetWithText(ElevatedButton, "退出登录");
     expect(exitBtn, findsOneWidget);

     await tester.tap(exitBtn);
     await tester.pump();

     expect(find.text("确认要退出当前账号吗"), findsOneWidget);
     var confirmBtn = find.widgetWithText(ElevatedButton, "确认");
     var cancelBtn = find.widgetWithText(ElevatedButton, "取消");

     expect(confirmBtn, findsOneWidget);
     expect(cancelBtn, findsOneWidget);

     await tester.tap(confirmBtn);
     await tester.pump();

     expect(find.byType(LoginPage), findsOneWidget);
  });
}