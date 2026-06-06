import 'dart:convert';

import 'package:aphasia_recovery/models/exam/category.dart';
import 'package:aphasia_recovery/models/exam/exam_recovery.dart';
import 'package:aphasia_recovery/models/exam/sub_category.dart';
import 'package:aphasia_recovery/models/question/question.dart';
import 'package:aphasia_recovery/models/rules.dart';
import 'package:aphasia_recovery/settings.dart';
import 'package:aphasia_recovery/states/question_set_states.dart';
import 'package:aphasia_recovery/states/user_identity.dart';
import 'package:aphasia_recovery/utils/http/http_manager.dart';
import 'package:aphasia_recovery/widgets/ui/doctor/doctor_all_exams.dart';
import 'package:aphasia_recovery/widgets/ui/doctor/doctor_exam_edit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aphasia_recovery/utils/io/shared_pref.dart';

import '../../TestBase.dart';
import '../../fake_data.dart' as fake;

/// 构造两份带 category/subCategory/questions 的 fake 套题（未发布，可编辑）。
({ExamQuestionSet a, ExamQuestionSet b}) _buildFakeExams() {
  final examA = ExamQuestionSet(
      id: fake.examId1, name: "测试套题1", description: "测试套题描述1");
  final catA = QuestionCategory(description: "套题1第一个大项");
  catA.subCategories.add(QuestionSubCategory(description: "子项1"));
  catA.subCategories[0].questions.add(
      AudioQuestion(id: "3", evalRule: EvalAudioQuestionByKeywordsMatchesCount()));
  catA.subCategories[0].questions.add(ChoiceQuestion(
      id: "4", alias: "题目2", evalRule: EvalChoiceQuestionByCorrectChoiceCount()));
  examA.categories.add(catA);

  final examB = ExamQuestionSet(
      id: fake.examId2, name: "测试套题2", description: "测试套题描述2");
  final catB = QuestionCategory(description: "套题2第一个大项");
  catB.subCategories.add(QuestionSubCategory(description: "子项1"));
  catB.subCategories[0].questions.add(
      CommandQuestion(id: "5", evalRule: EvalCommandQuestionByCorrectActionCount()));
  catB.subCategories[0].questions.add(
      WritingQuestion(id: "6", evalRule: EvalWritingQuestionByCorrectKeywordCount()));
  examB.categories.add(catB);

  return (a: examA, b: examB);
}

/// 把两份 fake 套题装到 GET /api/doctors/{uid}/exams 这个 stub 上。
///
/// prod `HttpClientManager.get` 会先经 `setTokenToHeaders` 把 headers 至少
/// 设成 `{}`（非 null），mockito 生成的 stub 必须用 `anyNamed('headers')`
/// 接住——否则 stub 不命中，mock 返回 _FakeResponse，FutureBuilder 进 hasError，
/// 屏上只剩 "加载中"。参照 test/models/exam_recovery_test.dart 的写法。
void _stubExamsListGet(ExamQuestionSet a, ExamQuestionSet b) {
  final client = HttpClientManager().testClient!;
  when(client.get(
    Uri.parse("${HttpConstants.backendBaseUrl}/api/doctors/${fake.uid}/exams"),
    headers: anyNamed('headers'),
  )).thenAnswer((_) async => Response.bytes(
      utf8.encode(jsonEncode([a.toJson(), b.toJson()])), 200));
}

/// 把 DoctorAllExamsListPage 挂到 ChangeNotifierProvider<UserIdentity> 下，
/// role=2 模拟医生身份。
Widget _buildPageUnderTest() {
  return ChangeNotifierProvider<UserIdentity>(
    create: (_) => UserIdentity(
        identity: fake.identity, uid: fake.uid, token: "fake", role: 2),
    child: const DoctorAllExamsListPage(commonStyles: null),
  );
}

void main() {
  TestBase.commonSetUp();

  // prod HttpClientManager.get 走 setTokenToHeaders → WrappedSharedPref
  // → SharedPreferences.getInstance()；test 环境不 mock 会卡死或 throw。
  //
  // 同时清掉上一轮 testClient 上残留的 stub（HttpClientManager singleton
  // 的 testClient ??= MockClient() 只创建一次，stub 跨 testWidgets 累积，
  // 导致前一 test 的 mock state 干扰下一 test）。
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // WrappedSharedPref 缓存了第一次 SharedPreferences.getInstance() 的
    // Future——后续 setMockInitialValues 不再生效。强制 nil singleton 让
    // 下一 test 重新拿。
    WrappedSharedPref.instance = null;
    // 强制下一次 enableTestMode 创建新的 MockClient（清干净上一 test 的
    // stub 累积），然后重挂 login stub。
    HttpClientManager().testClient = null;
    TestBase.commonSetUp();
  });

  // 历史背景（#17）：上一版断言锁的是已经被 prod 重命名 / 重构掉的文案与控件
  // 类型（"测评列表"→"套题列表"、ElevatedButton→自定义 _buildActionButton
  // InkWell、_DoctorExamsListPageState 字段名等）。下面这一组按当前 prod
  // doctor_all_exams.dart 逐项重写，分成 4 个独立 testWidgets 便于定位失败。

  testWidgets("DoctorAllExamsListPage 渲染基本结构", (tester) async {
    final exams = _buildFakeExams();
    _stubExamsListGet(exams.a, exams.b);

    await TestBase.testWithFullGlobalStates(tester, _buildPageUnderTest(),
        () async {
      await tester.pumpAndSettle();

      expect(find.byType(DoctorAllExamsListPage), findsOneWidget);
      expect(find.text("套题列表"), findsOneWidget);
      expect(find.text("新建"), findsOneWidget);

      // 左侧 ListView 含 2 个 exam ListTile
      expect(find.byType(ListView), findsWidgets);
      expect(find.text("测试套题1"), findsOneWidget);
      expect(find.text("测试套题2"), findsOneWidget);

      // 右侧默认提示（没选中 exam 时）
      expect(find.text("点击左侧套题查看详情"), findsOneWidget);
    });
  });

  testWidgets("DoctorAllExamsListPage 选中 exam 显示 ExamDetailCard 与题目目录",
      (tester) async {
    final exams = _buildFakeExams();
    _stubExamsListGet(exams.a, exams.b);

    await TestBase.testWithFullGlobalStates(tester, _buildPageUnderTest(),
        () async {
      await tester.pumpAndSettle();

      // 点左侧 exam1，右侧应显示 ExamDetailCard
      await tester.tap(find.text("测试套题1"), warnIfMissed: false);
      await tester.pumpAndSettle();

      // ExamDetailCard 头部不再有 "测评名称：" 前缀，只展示纯 exam.name
      // （在 titleLarge 中），所以原 "套题名称：测试套题1" 断言已不适用。
      expect(find.byType(ExamDetailCard), findsOneWidget);
      // exam.name 在两处出现：左侧 ListTile + 右侧 ExamDetailCard 标题
      expect(find.text("测试套题1"), findsNWidgets(2));

      // 套题元信息：ID + 发布状态。注意 prod _buildInfoItem 把 label 拼了一个
      // 尾空格："$label " → 渲染出来是 "套题ID: "（带空格），别少。
      expect(find.text("套题ID: "), findsOneWidget);
      expect(find.text("未发布"), findsOneWidget);

      // 题目目录区
      expect(find.text("题目目录"), findsOneWidget);

      // 展开 category → subCategory（顺序: category 默认收起，需要点）
      final categoryTile =
          find.widgetWithText(ExpansionTile, "1. 套题1第一个大项");
      expect(categoryTile, findsOneWidget);
      await tester.tap(categoryTile);
      await tester.pumpAndSettle();

      // "1. 子项1" 同时出现在父 category ExpansionTile（作为后代）和子
      // subCategory ExpansionTile（作为标题）里——widgetWithText 会同时命中
      // 两个，取 .last 锁内层（子 ExpansionTile）。
      final subCategoryTile = find.widgetWithText(ExpansionTile, "1. 子项1").last;
      expect(subCategoryTile, findsOneWidget);
      await tester.tap(subCategoryTile);
      await tester.pumpAndSettle();

      // ListTile 内的题目展示：leading "1."/title alias 或 默认题型名
      // 现 prod 把序号放 leading 单独 Text，因此 widgetWithText(ListTile, "1. 录音作答题")
      // 这种"序号+名称"合并字串的 finder 不再成立——分开断言。
      expect(find.text("录音作答题"), findsOneWidget);
      expect(find.text("题目2"), findsOneWidget); // ChoiceQuestion alias
    });
  });

  testWidgets("DoctorAllExamsListPage 编辑按钮跳 DoctorExamEditPage",
      (tester) async {
    final exams = _buildFakeExams();
    _stubExamsListGet(exams.a, exams.b);

    await TestBase.testWithFullGlobalStates(tester, _buildPageUnderTest(),
        () async {
      await tester.pumpAndSettle();

      await tester.tap(find.text("测试套题2"), warnIfMissed: false);
      await tester.pumpAndSettle();

      // "编辑" 现 prod 是自定义 _buildActionButton（InkWell+Material），不再是
      // ElevatedButton——find.text 定位即可（"编辑" 在此页只此一处）。
      final editLabel = find.text("编辑");
      expect(editLabel, findsOneWidget);
      await tester.tap(editLabel);
      await tester.pumpAndSettle();

      final editPage = find.byType(DoctorExamEditPage);
      expect(editPage, findsOneWidget);
      // ExamState 透传 exam.id
      expect(editPage.evaluate().first.read<ExamState>().exam.id, fake.examId2);
    });
  });

  testWidgets("DoctorAllExamsListPage 删除二次确认 dialog 机制（取消 + 错误输入）",
      (tester) async {
    final exams = _buildFakeExams();
    _stubExamsListGet(exams.a, exams.b);

    await TestBase.testWithFullGlobalStates(tester, _buildPageUnderTest(),
        () async {
      await tester.pumpAndSettle();

      await tester.tap(find.text("测试套题2"), warnIfMissed: false);
      await tester.pumpAndSettle();

      // 点 "删除" 弹 dialog；自定义 _buildActionButton InkWell + label
      await tester.tap(find.text("删除"));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      // 二次确认 dialog 头部 + 输入框 + 取消/确认删除 按钮（已从 ElevatedButton
      // 改为 TextButton，且不再带 confirm/cancel Key——按文案定位）
      expect(find.text("二次确认"), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.widgetWithText(TextButton, "取消"), findsOneWidget);
      expect(find.widgetWithText(TextButton, "确认删除"), findsOneWidget);

      // 点取消 → dialog 关闭
      await tester.tap(find.widgetWithText(TextButton, "取消"));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);

      // 再次打开 dialog，输入错误内容（非 "立即删除"）→ 点确认 → SnackBar 提示
      await tester.tap(find.text("删除"));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), "随便输");
      await tester.tap(find.widgetWithText(TextButton, "确认删除"));
      await tester.pump(); // SnackBar 是动画，pump 一次让它入场即可

      expect(find.text("输入内容不匹配，删除操作已取消"), findsOneWidget);
      // dialog 此时未关（只有匹配的 "立即删除" 才会 pop），仍可见
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });

  // TODO(#17 后续): 真正的 "立即删除" 成功路径还没覆盖——需要再 stub DELETE
  //   /api/exams/{id} → 200 + GET refresh 那次 second-fetch（ExamQuestionSet.
  //   getByDoctorUserId 会再发一次 GET），细节较多，单独跟进。
}
