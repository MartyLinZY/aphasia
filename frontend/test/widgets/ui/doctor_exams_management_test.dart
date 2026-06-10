import 'dart:convert';

import 'package:aphasia_recovery/settings.dart';
import 'package:aphasia_recovery/states/user_identity.dart';
import 'package:aphasia_recovery/utils/http/http_manager.dart';
import 'package:aphasia_recovery/utils/io/shared_pref.dart';
import 'package:aphasia_recovery/widgets/ui/doctor/doctor_all_exams.dart';
import 'package:aphasia_recovery/widgets/ui/doctor/doctor_exams_management.dart';
import 'package:aphasia_recovery/widgets/ui/llm_service/llm_service_intro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../TestBase.dart';
import '../../fake_data.dart' as fake;

/// 把 GET /doctors/{uid}/exams 与 /doctors/{uid}/recoveries 都 stub 成空列表
/// （DoctorAllExamsListPage 不管 isRecovery 切到哪边都不会卡 "加载中"）。
void _stubExamsAndRecoveriesEmpty() {
  final client = HttpClientManager().testClient!;
  for (final path in const ["exams", "recoveries"]) {
    when(client.get(
      Uri.parse("${HttpConstants.backendBaseUrl}/api/doctors/${fake.uid}/$path"),
      headers: anyNamed('headers'),
    )).thenAnswer(
        (_) async => Response.bytes(utf8.encode("[]"), 200));
  }
}

/// 注入 role=2（医生）的 UserIdentity，包一层 ChangeNotifierProvider。
Widget _wrapManagementPage() {
  return ChangeNotifierProvider<UserIdentity>(
    create: (_) => UserIdentity(
        identity: fake.identity, uid: fake.uid, token: "fake", role: 2),
    child: const DoctorExamsManagementPage(commonStyles: null),
  );
}

void main() {
  TestBase.commonSetUp();

  // 状态隔离三件套（同 doctor_all_exams_test / login_form_test 那套）。
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    WrappedSharedPref.instance = null;
    HttpClientManager().testClient = null;
    TestBase.commonSetUp();
  });

  // 历史背景（#17）：
  // 原 smoke test 写法是"直接渲染 DoctorExamsManagementPage 期望被 auth
  // gateway 拦下去 LoginPage"，但 auth gateway 实际在 MyApp 顶层（参见
  // lib/widgets/my_app.dart:79 FutureBuilder(future: loginFuture)），不在
  // ManagementPage 内部——该断言对当前 prod 不成立。
  // 原 after-login test 期待 tap "我的康复方案" 跳 DoctorExamDraftsPage，
  // 但 prod 现把"我的康复方案"复用同一 DoctorAllExamsListPage 仅传
  // isRecovery=true（DoctorExamDraftsPage 已 deprecated 移到 lib/deprecated/
  // 下，不再被引用）。
  // 本组按当前 prod _navItems 的 3 个 NavigationRail 入口 + selectedIndex
  // 切换契约整段重写。

  testWidgets("DoctorExamsManagementPage 渲染 3 个 nav + 默认选 DoctorAllExamsListPage",
      (tester) async {
    _stubExamsAndRecoveriesEmpty();

    await TestBase.testWithFullGlobalStates(tester, _wrapManagementPage(),
        () async {
      await tester.pumpAndSettle();

      expect(find.byType(DoctorExamsManagementPage), findsOneWidget);

      // 3 个 NavigationRailDestination 标签
      expect(find.text("我的测评方案"), findsOneWidget);
      expect(find.text("我的康复方案"), findsOneWidget);
      expect(find.text("人工智能服务"), findsOneWidget);

      // 默认 selectedIndex = 0 → DoctorAllExamsListPage(isRecovery: false)
      final allExamsPage = find.byType(DoctorAllExamsListPage);
      expect(allExamsPage, findsOneWidget);
      final isRecovery =
          (allExamsPage.evaluate().first.widget as DoctorAllExamsListPage)
              .isRecovery;
      expect(isRecovery, isFalse);
    });
  });

  testWidgets(
      "DoctorExamsManagementPage 点 '我的康复方案' 切到 DoctorAllExamsListPage(isRecovery=true)",
      (tester) async {
    _stubExamsAndRecoveriesEmpty();

    await TestBase.testWithFullGlobalStates(tester, _wrapManagementPage(),
        () async {
      await tester.pumpAndSettle();

      await tester.tap(find.text("我的康复方案"));
      await tester.pumpAndSettle();

      // 仍然是 DoctorAllExamsListPage（prod 把"我的康复方案"复用同一页面），
      // 但 isRecovery=true——这是 DoctorExamDraftsPage 被 deprecated 之后
      // prod 真正的实现，原断言期待 DoctorExamDraftsPage 早已失配。
      final pageWidgets = find.byType(DoctorAllExamsListPage);
      expect(pageWidgets, findsOneWidget);
      final isRecovery =
          (pageWidgets.evaluate().first.widget as DoctorAllExamsListPage)
              .isRecovery;
      expect(isRecovery, isTrue);
    });
  });

  testWidgets(
      "DoctorExamsManagementPage 点 '人工智能服务' 切到 LLMServiceIntroPage",
      (tester) async {
    _stubExamsAndRecoveriesEmpty();

    await TestBase.testWithFullGlobalStates(tester, _wrapManagementPage(),
        () async {
      await tester.pumpAndSettle();

      await tester.tap(find.text("人工智能服务"));
      await tester.pumpAndSettle();

      expect(find.byType(LLMServiceIntroPage), findsOneWidget);
      expect(find.byType(DoctorAllExamsListPage), findsNothing);
    });
  });
}
