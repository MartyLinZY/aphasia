import 'dart:convert';
import 'dart:math';

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
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../fake_data.dart' as fake;
import '../../TestBase.dart';

void main() {
  TestBase.commonSetUp();

  // 新建测评引导页测试
  testWidgets("DoctorExamEditInstructionPage basic tests", (WidgetTester tester) async {
    TestBase.testWithFullGlobalStates(tester, const DoctorExamEditInstructionPage(), () async {
      // 第一步
      var stepper = find.byType(Stepper);
      var nameInputField = find.widgetWithText(TextFormField, "测评方案名称（必填）");
      var descriptionInputField = find.widgetWithText(TextFormField, "简介");
      var nextBtn = find.widgetWithText(ElevatedButton, "创建");
      var quitBtn = find.widgetWithText(ElevatedButton, "返回");

      expect(stepper, findsOneWidget);
      expect(nameInputField, findsOneWidget);
      expect(descriptionInputField, findsOneWidget);
      expect(nextBtn, findsNWidgets(2)); // 框架会为每个step都生成一组按钮，step index改变时同时改变每个step下的按钮
      expect(quitBtn, findsNWidgets(2));

      // 名称为空时创建测评
      await tester.tap(nextBtn.first);
      await tester.pumpAndSettle();
      expect(quitBtn, findsNWidgets(2));
      expect(find.text("请输入测评方案名称"), findsOneWidget);

      // 创建测评
      var examName = "我的测评方案";
      var examDesc = "";

      await tester.enterText(nameInputField, examName);
      await tester.pumpAndSettle();

      var exam = fake.exam();
      exam.categories.add(fake.category());
      exam.categories[0].subCategories.add(fake.subCate());

      int fakeId = Random(0).nextInt(1000000000);
      var client = HttpClientManager().testClient!;
      when(client.post(Uri.parse("${HttpConstants.backendBaseUrl}/api/exams"), body: jsonEncode(ExamQuestionSet(name: examName, description: examDesc).toJson())))
          .thenAnswer((realInvocation) async => http.Response.bytes(
          utf8.encode(jsonEncode(exam.toJson()..['id']=fakeId.toString())), 200));

      await tester.tap(nextBtn.first);
      await tester.pump();
      expect(quitBtn, findsNothing);

      // 模板 - 暂时不实现
      // var backBtn = find.widgetWithText(ElevatedButton, "上一步");
      // var skipBtn = find.widgetWithText(ElevatedButton, "不使用模板");
      // var templateExamIdField = find.widgetWithText(ElevatedButton, "模板测评方案ID");
      //
      // expect(backBtn, findsNWidgets(3));
      // expect(nextBtn, findsNWidgets(3));
      // expect(skipBtn, findsNWidgets(3));
      // expect(templateExamIdField, findsOneWidget);

      // 等待创建
      var waitingText = find.text("创建中，请稍候");
      expect(waitingText, findsOneWidget);

      // 播放加载动画并等待创建完毕
      await tester.pumpAndSettle();

      expect(waitingText, findsNothing);
      expect(find.byType(DoctorExamEditPage), findsOneWidget);
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
      final client = HttpClientManager().testClient!;

      // when(client.get(Uri.parse("${HttpConstants.backendBaseUrl}/api/doctors/${fake.uid}/exams")))
      //     .thenAnswer((realInvocation) async => Response.bytes(utf8.encode(fake.examListJsonData), 200));

      expect(find.text("菜单"), findsOneWidget);

      var rulesTab = find.text('诊断规则');
      var settingsTab = find.text('其他设置');
      var categoryTab = find.text('测评亚项');

      expect(rulesTab, findsOneWidget);
      expect(settingsTab, findsOneWidget);
      expect(categoryTab, findsOneWidget);

      await tester.tap(rulesTab, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text("无"), findsOneWidget);

      await tester.tap(rulesTab, warnIfMissed: false);
      await tester.tap(settingsTab, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text("无"), findsOneWidget);

      await tester.tap(categoryTab, warnIfMissed: false);
      await tester.pumpAndSettle();

      var categoriesTab = find.text('测试亚项');
      expect(categoriesTab, findsOneWidget);

      await tester.tap(categoriesTab, warnIfMissed: false);
      await tester.pumpAndSettle();

      var subCategoriesTab = find.text('新子项');
      expect(subCategoriesTab, findsOneWidget);

      await tester.tap(subCategoriesTab, warnIfMissed: false);
      await tester.pumpAndSettle();

      var addCategoryBtn = find.widgetWithText(TextButton, "新增亚项");
      expect(addCategoryBtn, findsOneWidget);

      var addSubCateBtn = find.widgetWithText(TextButton, "新增子项");
      expect(addSubCateBtn, findsOneWidget);

      var addQuestionBtn = find.widgetWithText(TextButton, "新增题目");
      expect(addQuestionBtn, findsOneWidget);

      var deleteBtn = find.widgetWithIcon(TextButton, Icons.delete_outline);
      expect(deleteBtn, findsNWidgets(5));

      var editBtn = find.widgetWithIcon(TextButton, Icons.edit);
      expect(editBtn, findsNWidgets(6));


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