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

import '../../TestBase.dart';
import '../../fake_data.dart' as fake;

void main() {
  TestBase.commonSetUp();

  testWidgets("DoctorAllExamsPage basic test", (WidgetTester tester) async {
    TestBase.testWithFullGlobalStates(tester, const DoctorAllExamsListPage(commonStyles: null,), () async {
      var fakeExam = ExamQuestionSet(id: "2143223252543",name: "测试测评1", description: "测试测评描述1");
      var cate1 = QuestionCategory(description: "测评1第一个大项");
      cate1.subCategories.add(QuestionSubCategory(description: "子项1"));
      cate1.subCategories[0].questions.add(AudioQuestion(id: "3", evalRule: EvalAudioQuestionByKeywordsMatchesCount()));
      cate1.subCategories[0].questions.add(ChoiceQuestion(id: "3", alias: "题目2", evalRule: EvalChoiceQuestionByCorrectChoiceCount()));
      fakeExam.categories.add(cate1);

      var fakeExam1 = ExamQuestionSet(id: "2", name: "测试测评2", description: "测试测评描述2");
      var cate2 = QuestionCategory(description: "测评1第一个大项");
      cate2.subCategories.add(QuestionSubCategory(description: "子项1"));
      cate2.subCategories[0].questions.add(CommandQuestion(id: "5", evalRule: EvalCommandQuestionByCorrectActionCount()));
      cate2.subCategories[0].questions.add(WritingQuestion(id: "6", evalRule: EvalWritingQuestionByCorrectKeywordCount()));
      fakeExam1.categories.add(cate2);

      final client = HttpClientManager().testClient!;
      when(client.get(Uri.parse("${HttpConstants.backendBaseUrl}/api/doctors/${fake.uid}/exams")))
          .thenAnswer((realInvocation) async => Response.bytes(utf8.encode(jsonEncode([fakeExam.toJson(), fakeExam1.toJson()])), 200));

      final userIdentity = UserIdentity.login(identity: fake.identity, password: fake.validateCode);
      await tester.pumpAndSettle();

      var page = find.byType(DoctorAllExamsListPage);
      expect(page, findsOneWidget);

      expect(find.text("测评列表"), findsOneWidget);
      var newExamBtn = find.text("新建");
      expect(newExamBtn, findsOneWidget);

      var listView = find.byType(ListView);
      expect(listView, findsOneWidget);

      var exam1 = find.text("测试测评1");
      expect(exam1, findsOneWidget);

      var exam2 = find.text("测试测评2");
      expect(exam2, findsOneWidget);

      expect(find.text("点击左侧测评查看详情"), findsOneWidget);

      // 点击第二个测评
      await tester.tap(exam1, warnIfMissed: false);
      await tester.pump();
      expect(find.text("测评名称：测试测评1"), findsOneWidget);
      expect(find.text("简介：测试测评描述1"), findsOneWidget);
      expect(find.text("题目目录："), findsOneWidget);

      // 点击第一个测评大项
      var category = find.widgetWithText(ExpansionTile, "1. 测评1第一个大项");
      expect(category, findsOneWidget);
      await tester.tap(category);
      await tester.pumpAndSettle();

      // 点击第一个子项
      var subCategory = find.text("1. 子项1");
      await tester.tap(subCategory, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(subCategory, findsOneWidget);

      var firstQ = find.widgetWithText(ListTile, "1. 录音作答题");
      expect(firstQ, findsOneWidget);
      var secondQ = find.widgetWithText(ListTile, "2. 题目2");
      expect(secondQ, findsOneWidget);

      var editBtnOnDetail = find.widgetWithText(ElevatedButton, "编辑");
      expect(editBtnOnDetail, findsOneWidget);
      var deleteBtnOnDetail = find.widgetWithText(ElevatedButton, "删除");
      expect(deleteBtnOnDetail, findsOneWidget);

      // 点击第二个测评
      await tester.tap(exam2, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text("测评名称：测试测评2"), findsOneWidget);
      expect(find.text("简介：测试测评描述2"), findsOneWidget);

      // 点击第二个测评的编辑按钮
      await tester.tap(editBtnOnDetail);
      await tester.pumpAndSettle();
      var editPage = find.byType(DoctorExamEditPage);
      expect(editPage, findsOneWidget);
      expect(editPage.evaluate().first.read<ExamState>().exam.id, "2");
      Navigator.pop(editPage.evaluate().first);
      await tester.pumpAndSettle();
      expect(page, findsOneWidget);

      // 点击第二个测评的删除按钮
      await tester.tap(deleteBtnOnDetail);
      await tester.pumpAndSettle();
      var dialog = find.byType(AlertDialog);
      var inputBox = find.byType(TextField);
      var confirmBtn = find.byKey(const Key("confirmBtnOnConfirmDialog"));
      var cancelBtn = find.byKey(const Key("cancelBtnOnConfirmDialog"));

      expect(dialog, findsOneWidget);
      expect(inputBox, findsOneWidget);
      expect(confirmBtn, findsOneWidget);
      expect(cancelBtn, findsOneWidget);

      // 点击取消
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();
      expect(dialog, findsNothing);

      // 再次点击删除按钮
      await tester.tap(deleteBtnOnDetail);
      await tester.pumpAndSettle();
      // 点击确认按钮
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();
      expect(dialog, findsOneWidget);

      // 输入文本
      await tester.tap(inputBox);
      await tester.enterText(inputBox, "立即删除");
      // 点击确认按钮
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();
      expect(dialog, findsNothing);
      // TODO: 等到后端逻辑实现后再测试
      // expect(exam2, findsNothing);


      // 点击新建按钮
      await tester.tap(newExamBtn);
      await tester.pumpAndSettle();

      expect(find.byType(DoctorExamEditInstructionPage), findsOneWidget);
    });
  });
}