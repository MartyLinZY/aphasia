import 'dart:convert';
import 'dart:math';

import 'package:aphasia_recovery/models/exam/category.dart';
import 'package:aphasia_recovery/models/exam/sub_category.dart';
import 'package:aphasia_recovery/settings.dart';
import 'package:aphasia_recovery/models/exam/exam_recovery.dart';
import 'package:aphasia_recovery/models/question/question.dart';
import 'package:aphasia_recovery/models/rules.dart';
import 'package:aphasia_recovery/states/question_set_states.dart';
import 'package:aphasia_recovery/utils/http/http_manager.dart';
import 'package:aphasia_recovery/widgets/ui/doctor/doctor_exam_edit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

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

}