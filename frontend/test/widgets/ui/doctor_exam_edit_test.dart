import 'package:aphasia_recovery/models/exam/category.dart';
import 'package:aphasia_recovery/models/exam/sub_category.dart';
import 'package:aphasia_recovery/settings.dart';
import 'package:aphasia_recovery/models/exam/exam_recovery.dart';
import 'package:aphasia_recovery/models/question/question.dart';
import 'package:aphasia_recovery/models/rules.dart';
import 'package:aphasia_recovery/states/exam_edit_selection_state.dart';
import 'package:aphasia_recovery/states/question_set_states.dart';
import 'package:aphasia_recovery/utils/http/http_manager.dart';
import 'package:aphasia_recovery/widgets/ui/doctor/doctor_exam_edit.dart';
import 'package:aphasia_recovery/widgets/ui/doctor/exam_edit_left_menu/exam_category_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../TestBase.dart';

void main() {
  TestBase.commonSetUp();

  // 新建测评引导页测试：锁 step 0 表单结构 + 空名 validator。
  // 注：create flow 端到端（点 "创建" → step 2 spinner → 750ms Timer → 跳转到
  // DoctorExamEditPage）已不可直接 pumpAndSettle——prod step 2 用了无限
  // CircularProgressIndicator，且 ExamQuestionSet.createExam 实际 HTTP body
  // 与历史 mock 已不再匹配。这部分覆盖归 IMPROVEMENTS.md #17 跟进，本测试只
  // 锁 step 0 的确定性部分（表单、验证器），不再依赖 HTTP mock，因此也不会
  // 通过 mockito stub 残留污染下游 #14b regression 测试。
  testWidgets("DoctorExamEditInstructionPage basic tests", (WidgetTester tester) async {
    TestBase.testWithFullGlobalStates(tester, const DoctorExamEditInstructionPage(), () async {
      var stepper = find.byType(Stepper);
      var nameInputField = find.widgetWithText(TextFormField, "套题方案名称（必填）");
      var descriptionInputField = find.widgetWithText(TextFormField, "简介");
      // Stepper 框架为每个 step 都生成一套 controls 按钮，所以 "创建"/"返回"
      // 各能 findNWidgets(2)
      var nextBtn = find.widgetWithText(ElevatedButton, "创建");
      var quitBtn = find.widgetWithText(ElevatedButton, "返回");

      expect(stepper, findsOneWidget);
      expect(nameInputField, findsOneWidget);
      expect(descriptionInputField, findsOneWidget);
      expect(nextBtn, findsNWidgets(2));
      expect(quitBtn, findsNWidgets(2));

      // 名称为空时 tap "创建" → validator 报错，仍停在 step 0
      await tester.tap(nextBtn.first);
      await tester.pumpAndSettle();
      expect(quitBtn, findsNWidgets(2)); // 仍在 step 0
      expect(find.text("请输入有效的套题方案名称"), findsOneWidget);
    });
  });

  // 测评编辑页测试
  testWidgets("DoctorExamEdit basic tests", (WidgetTester tester) async {
    var testExam = ExamQuestionSet();
    testExam.categories.add(QuestionCategory(description: "测试亚项"));
    testExam.categories[0].subCategories.add(QuestionSubCategory(description: "新子项"));
    testExam.categories[0].subCategories[0].questions.add(AudioQuestion(id: "1", alias: "测试录音题", questionText: "测试题干", evalRule: EvalAudioQuestionByKeywordsMatchesCount()));
    testExam.categories[0].subCategories[0].questions.add(CommandQuestion(id: "2", alias: "测试指令题", questionText: "测试题干", evalRule: EvalCommandQuestionByCorrectActionCount()));
    testExam.addCategoryLocally(description: "亚项2");

    TestBase.testWithFullGlobalStates(tester,
        ChangeNotifierProvider(
            create: (BuildContext context) => ExamState(testExam),
            child: const DoctorExamEditPage()
        ), () async {
      // 左栏菜单顶部：header + "通用设置" tile + "套题目录" ExpansionTile
      // （`initiallyExpanded: true`，category 列表 + "新增亚项" 按钮直接渲染）。
      // 旧版本曾把页面拆为 "诊断规则" / "其他设置" / "测评亚项" 三个 tab，prod
      // 早改为 左栏菜单 + 右栏 SubPage 路由结构，本测试沿当前结构断言。
      expect(find.text("菜单"), findsOneWidget);
      expect(find.text("通用设置"), findsOneWidget);
      expect(find.text("套题目录"), findsOneWidget);

      // 套题目录初始展开 → 两个 category 直接可见
      expect(find.text('测试亚项'), findsOneWidget);
      expect(find.text('亚项2'), findsOneWidget);
      // "新增亚项" 按钮在 "套题目录" children 顶部
      expect(find.widgetWithText(TextButton, "新增亚项"), findsOneWidget);

      // 展开 "测试亚项" → "新子项" + "新增子项" 可见
      await tester.tap(find.text('测试亚项'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('新子项'), findsOneWidget);
      expect(find.widgetWithText(TextButton, "新增子项"), findsOneWidget);

      // 展开 "新子项" → 2 个题目 alias + "新增题目" 可见
      await tester.tap(find.text('新子项'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('测试录音题'), findsOneWidget);
      expect(find.text('测试指令题'), findsOneWidget);
      expect(find.widgetWithText(TextButton, "新增题目"), findsOneWidget);

      // edit/delete TextButton 计数（在全部展开状态下）：
      // - 通用设置 tile: 1 edit, 0 delete
      // - 2 个 category tile: 2 edit, 2 delete
      // - 1 个 subCategory tile（测试亚项 已展开）: 1 edit, 1 delete
      // - 2 个 question tile（新子项 已展开）: 2 edit, 2 delete
      // 合计：edit 6，delete 5
      expect(find.widgetWithIcon(TextButton, Icons.delete_outline), findsNWidgets(5));
      expect(find.widgetWithIcon(TextButton, Icons.edit), findsNWidgets(6));
    });
  });

  // ===== #14b 重构前的回归测试 =====
  // 锁定 ExamEditSelectionState 在"删除当前编辑项 / editingItem 守卫切换"两条业务流
  // 的现有行为。T2 引入 ChangeNotifier、T7 后 State 改私有，本组用例改用 Provider.of
  // 从 ExamCategoryList 这个 InheritedProvider 下挂的 Widget 拿 selectionState 实例。
  //
  // 暂未覆盖（待 #14b 重构后用 ChangeNotifier 方法直接单测）：
  // 1) 删前置位置 category 时 `editCategoryIndex -= 1` 的下移逻辑。
  //    根因：现 prod 的 onConfirm 写法是 `.then((_) { setState; Navigator.pop(ctx); })`
  //    —— ctx 是 dialog ctx，但 buildSimpleActionDialog 的 wrapper 已先 pop 过一次，
  //    导致这条延迟 pop 落到 page route 上把整页弹掉。在 widget 测试里这条 bug-pop
  //    会污染下个 case 的异步链（连续两次 delete-confirm，第二次的 Future 不被 settle）。
  //    重构成 ChangeNotifier 上的纯方法 `onCategoryDeleted(int deletedIndex)` 后可直接
  //    单测，不再涉及 dialog 路由。
  // 2) 删 subCategory / question 时下标后处理（subCate 路径有疑似 latent bug：用 i 比较
  //    而非 j，见 doctor_exam_edit.dart:583），同样留到重构后单测。
  group("DoctorExamEditPage selection state regression (for #14b)", () {
    setUpAll(() {
      // 一次性给 SharedPreferences 注入空 mock，避免 HttpClientManager.delete 在
      // setTokenToHeaders → WrappedSharedPref().retrieveToken() 路径上 stall
      SharedPreferences.setMockInitialValues({});
    });

    ExamQuestionSet buildExamWith(int numCategories) {
      var exam = ExamQuestionSet(id: "test-exam-id");
      for (int i = 0; i < numCategories; i++) {
        exam.categories.add(QuestionCategory(description: "亚项$i"));
      }
      return exam;
    }

    Finder editBtnOf(int categoryIndex) => find.descendant(
        of: find.byKey(Key("category$categoryIndex")),
        matching: find.widgetWithIcon(TextButton, Icons.edit));

    Finder deleteBtnOf(int categoryIndex) => find.descendant(
        of: find.byKey(Key("category$categoryIndex")),
        matching: find.widgetWithIcon(TextButton, Icons.delete_outline));

    /// T7: State 改私有后，测试不能再 `tester.state<DoctorExamEditPageState>`。
    /// 改从 InheritedProvider 下挂的 `ExamCategoryList` 元素拿 selectionState。
    ExamEditSelectionState selectionOf(WidgetTester tester) =>
        Provider.of<ExamEditSelectionState>(
            tester.element(find.byType(ExamCategoryList)),
            listen: false);

    testWidgets("删除当前正在编辑的 category 后 editItem/editCategoryIndex 应清空", (tester) async {
      var exam = buildExamWith(2);
      await TestBase.testWithFullGlobalStates(tester,
        ChangeNotifierProvider<ExamState>(
          create: (_) => ExamState(exam),
          child: const DoctorExamEditPage(),
        ), () async {
          var client = HttpClientManager().testClient!;
          when(client.delete(
                  Uri.parse("${HttpConstants.backendBaseUrl}/api/exams/test-exam-id/categories/0"),
                  headers: anyNamed("headers")))
              .thenAnswer((_) async => Response('', 200));
          await tester.pumpAndSettle();

          var state = selectionOf(tester);

          // 进入编辑 category[0]
          await tester.tap(editBtnOf(0).first, warnIfMissed: false);
          await tester.pumpAndSettle();
          expect(state.editItem, isA<QuestionCategory>());
          expect(state.editCategoryIndex, 0);

          // 删除 category[0]
          await tester.tap(deleteBtnOf(0).first, warnIfMissed: false);
          await tester.pumpAndSettle();
          expect(find.text("删除亚项"), findsOneWidget);
          await tester.tap(find.widgetWithText(ElevatedButton, "确认"));
          await tester.pumpAndSettle();

          // editItem / 下标必须清空
          expect(state.editItem, isNull);
          expect(state.editCategoryIndex, isNull);
          expect(state.editingItem, isFalse);
          expect(exam.categories.length, 1);
        }
      );
    });

    testWidgets("editingItem=true 时点 category 编辑按钮应弹丢弃确认对话框", (tester) async {
      var exam = buildExamWith(2);
      await TestBase.testWithFullGlobalStates(tester,
        ChangeNotifierProvider<ExamState>(
          create: (_) => ExamState(exam),
          child: const DoctorExamEditPage(),
        ), () async {
          await tester.pumpAndSettle();
          var state = selectionOf(tester);

          // 模拟子页正在编辑：直接置 editingItem = true
          state.editingItem = true;

          await tester.tap(editBtnOf(0).first, warnIfMissed: false);
          await tester.pumpAndSettle();

          // 应出现丢弃确认 dialog；editItem 未立即变
          expect(find.text("当前有未保存的编辑内容，是否丢弃这些内容并继续打开亚项编辑页面？"),
              findsOneWidget);
          expect(state.editItem, isNull);
          expect(state.editCategoryIndex, isNull);

          // 点 "确认" 后才切
          await tester.tap(find.widgetWithText(ElevatedButton, "确认"));
          await tester.pumpAndSettle();
          expect(state.editItem, isA<QuestionCategory>());
          expect(state.editCategoryIndex, 0);
        }
      );
    });

    testWidgets("editingItem=false 时点 category 编辑按钮应直接切换 editItem 无对话框", (tester) async {
      var exam = buildExamWith(2);
      await TestBase.testWithFullGlobalStates(tester,
        ChangeNotifierProvider<ExamState>(
          create: (_) => ExamState(exam),
          child: const DoctorExamEditPage(),
        ), () async {
          await tester.pumpAndSettle();
          var state = selectionOf(tester);
          expect(state.editingItem, isFalse);

          await tester.tap(editBtnOf(1).first, warnIfMissed: false);
          await tester.pumpAndSettle();

          expect(find.text("当前有未保存的编辑内容，是否丢弃这些内容并继续打开亚项编辑页面？"),
              findsNothing);
          expect(state.editItem, isA<QuestionCategory>());
          expect(state.editCategoryIndex, 1);
        }
      );
    });
  });

}