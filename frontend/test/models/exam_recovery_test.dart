import 'dart:convert';
import 'dart:math';

import 'package:aphasia_recovery/models/exam/category.dart';
import 'package:aphasia_recovery/models/exam/sub_category.dart';
import 'package:aphasia_recovery/settings.dart';
import 'package:aphasia_recovery/exceptions/http_exceptions.dart';
import 'package:aphasia_recovery/exceptions/local_exceptions.dart';
import 'package:aphasia_recovery/models/exam/exam_recovery.dart';
import 'package:aphasia_recovery/models/question/question.dart';
import 'package:aphasia_recovery/models/rules.dart';
import 'package:aphasia_recovery/utils/http/http_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;

import '../TestBase.dart';
import '../http_mock.mocks.dart';
import '../fake_data.dart' as fake;


void main() {
  TestBase.commonSetUp();
  group("Exam and Recovery model test", () {
    test("ExamQuestionSet json test", () async {
      var exam = ExamQuestionSet(id: fake.examId1, description: "测试");
      exam.name = "测试测评";
      exam.description = "测试测评描述";

      var diagnosisRule = DiagnoseByScoreRange(aphasiaType: "测试");
      exam.diagnosisRules.add(diagnosisRule);

      var cate = QuestionCategory();
      cate.subCategories.add(QuestionSubCategory());

      exam.categories.add(cate);

      exam.categories.add(QuestionCategory());
      exam.categories[0].description = "测试亚项";
      exam.categories[0].rules.add(EvalBySubCategoryScoreSum());
      exam.categories[0].subCategories[0].description = "测试子项描述";
      exam.categories[0].subCategories[0].questions.add(AudioQuestion(evalRule: EvalAudioQuestionByKeywordsMatchesCount()));
      exam.categories[0].subCategories[0].terminateRules.add(ContinuousWrongAnswerTerminate(reason: "测试", equivalentScore: 0, errorCountThreshold: 3));
      exam.categories[0].subCategories[0].evalRules.add(EvalSubCategoryByQuestionScoreSum());

      var jsonStr = jsonEncode(exam.toJson());
      debugPrint(jsonStr);
      var examDecoded = ExamQuestionSet.fromJson(jsonDecode(jsonStr));
      expect(exam.id, examDecoded.id);
      expect(exam.name, examDecoded.name);
      expect(exam.description, examDecoded.description);
      expect(exam.diagnosisRules[0].typeName, examDecoded.diagnosisRules[0].typeName);
      expect(exam.categories.length, examDecoded.categories.length);
      expect(examDecoded.categories[0].description, "测试亚项");
    });

    test("QuestionCategory json test", () async {
      var cate = QuestionCategory();
      cate.subCategories.add(QuestionSubCategory(description: "测试"));
      cate.description = "测试描述";
      cate.subCategories[0].description = "测试子项描述";
      cate.subCategories[0].questions.add(AudioQuestion(evalRule: EvalAudioQuestionByKeywordsMatchesCount()));
      cate.subCategories[0].terminateRules.add(ContinuousWrongAnswerTerminate(reason: "测试", equivalentScore: 0, errorCountThreshold: 3));
      cate.subCategories[0].evalRules.add(EvalSubCategoryByQuestionScoreSum());
      cate.rules.add(EvalBySubCategoryScoreSum());

      var jsonStr = jsonEncode(cate.toJson());
      debugPrint(jsonStr);
      var cateDecoded = QuestionCategory.fromJson(jsonDecode(jsonStr));
      expect(cate.description, cateDecoded.description);
      expect(cate.rules[0].typeName, cateDecoded.rules[0].typeName);
      expect(cate.subCategories[0].description, cateDecoded.subCategories[0].description);
    });

    test("QuestionCategory copy test", () async {
      var cate = QuestionCategory(description: "描述1");
      var newCate = QuestionCategory.copy(cate);
      cate.description = newCate.description;
    });

    test("QuestionSubCategory json test", () {
      var subCate = QuestionSubCategory(description: "测试");
      subCate.questions.add(AudioQuestion(evalRule: EvalAudioQuestionByKeywordsMatchesCount()));
      subCate.terminateRules.add(ContinuousWrongAnswerTerminate(reason: "测试", equivalentScore: 0, errorCountThreshold: 3));
      subCate.evalRules.add(EvalSubCategoryByQuestionScoreSum());

      var jsonStr = jsonEncode(subCate.toJson());
      debugPrint(jsonStr);
      var subCateDecoded = QuestionSubCategory.fromJson(jsonDecode(jsonStr));
      expect(subCate.description, subCateDecoded.description);
      expect(subCate.questions[0].typeName, subCateDecoded.questions[0].typeName);
      expect(subCate.terminateRules[0].typeName, subCateDecoded.terminateRules[0].typeName);
      expect(subCate.evalRules[0].typeName, subCateDecoded.evalRules[0].typeName);
    });

    test("ExamQuestionSet base constructor test", () async {
      var exam = ExamQuestionSet(name: "name", description: "description");
      expect(exam.name, "name");
      expect(exam.description, "description");
      expect(exam.published, false);
      expect(exam.categories.length, 0);
    });

    test("ExamQuestionSet get by id test", () async {
      var httpManager = HttpClientManager();
      httpManager.enableTestMode();
      Client client = httpManager.testClient!;
      var examId = fake.examId1;
      var exam = ExamQuestionSet(description: fake.examDesc);
      exam.id = examId;

      // success
      when(client.get(Uri.parse("${HttpConstants.backendBaseUrl}/api/exams/$examId")))
        .thenAnswer((realInvocation) async => http.Response.bytes(
          utf8.encode(jsonEncode(exam.toJson())), 200));
      var result = await ExamQuestionSet.getById(id: examId);
      expect(result, isA<ExamQuestionSet>());
      expect(result?.id, examId);

      // fail
      when(client.get(Uri.parse("${HttpConstants.backendBaseUrl}/api/exams/$examId")))
          .thenAnswer((realInvocation) async => http.Response.bytes(
          utf8.encode("请求的资源不不存在"), 404));
      expect(() async => await ExamQuestionSet.getById(id: examId), throwsA(isA<HttpRequestException>()));
    });
  });

  test("ExamQuestionSet get by doctor user id test", () async {
    var httpManager = HttpClientManager();
    httpManager.enableTestMode();
    Client client = httpManager.testClient!;
    var userId = fake.uid;
    var examId1 = fake.examId1;
    var examId2 = fake.examId2;
    var exam1 = ExamQuestionSet(id:examId1, description: fake.examDesc);
    var exam2 = ExamQuestionSet(id:examId2, description: fake.examDesc);

    // success
    when(client.get(Uri.parse("${HttpConstants.backendBaseUrl}/api/doctors/$userId/exams")))
        .thenAnswer((realInvocation) async => http.Response.bytes(
        utf8.encode(jsonEncode([exam1.toJson(), exam2.toJson()])), 200));
    List<ExamQuestionSet> exams = await ExamQuestionSet.getByDoctorUserId(userId: userId);
    expect(exams[0].id, exam1.id);
    expect(exams[1].id, exam2.id);

    // fail
    when(client.get(Uri.parse("${HttpConstants.backendBaseUrl}/api/doctors/$userId/exams")))
        .thenAnswer((realInvocation) async => http.Response.bytes(
        utf8.encode("请求的资源不不存在"), 404));
    expect(() async => await ExamQuestionSet.getByDoctorUserId(userId: userId), throwsA(isA<HttpRequestException>()));
  });

  test("ExamQuestionSet create exam test", () async {
    TestBase.commonSetUp();

    Client client = HttpClientManager().testClient!;

    var examName = "新测评";
    var examDesc = "";

    int fakeId = Random(0).nextInt(1000000000);
    var createdExam = ExamQuestionSet(id: fakeId.toString(), name: examName, description: examDesc);

    when(client.post(Uri.parse("${HttpConstants.backendBaseUrl}/api/exams"), body: jsonEncode(ExamQuestionSet(name: examName, description: examDesc).toJson())))
        .thenAnswer((realInvocation) async => http.Response.bytes(
        utf8.encode(jsonEncode(createdExam.toJson())), 200));

    var newExam = await ExamQuestionSet.createExam(name: examName, description: examDesc);
    expect(newExam.id, fakeId.toString());
    expect(newExam.name, examName);
    expect(newExam.description, examDesc);
  });

  test("ExamQuestionSet add category test", () async {
    TestBase.commonSetUp();

    Client client = HttpClientManager().testClient!;

    var examId = fake.examId1;
    var exam = ExamQuestionSet(id: examId, name: fake.examName, description: fake.examDesc);
    var description = "新亚项";
    exam.categories.add(QuestionCategory(description: description));

    var categoryI = 0;
    expect(() async => await exam.addCategory(description: description, insertAt: -1), throwsA(isA<RangeError>()));
    expect(() async => await exam.addCategory(description: description, insertAt: exam.categories.length + 1), throwsA(isA<RangeError>()));

    var newCate = await exam.addCategory(description: description);
    expect(exam.categories[exam.categories.length - 1], newCate);
    expect(exam.categories[exam.categories.length - 1].description, description);

    description = "新亚项1";
    await exam.addCategory(description: description, insertAt: categoryI);
    expect(exam.categories[categoryI].description, description);

  });

  test("ExamQuestionSet add subCategory test", () async {
    TestBase.commonSetUp();

    Client client = HttpClientManager().testClient!;

    var examId = fake.examId1;
    var exam = ExamQuestionSet(id: examId, name: fake.examName, description: fake.examDesc);
    var cateDesc = "新亚项";
    exam.categories.add(QuestionCategory(description: cateDesc));
    exam.categories[0].subCategories.add(QuestionSubCategory(description: "新子项"));
  });

  test("ExamQuestionSet add question test", () async {
    TestBase.commonSetUp();

    Client client = HttpClientManager().testClient!;
    var examId = fake.examId1;
    var exam = ExamQuestionSet(id: examId, name: fake.examName, description: fake.examDesc);
    exam.categories.add(QuestionCategory(description: "测试")..subCategories.add(QuestionSubCategory(description: "测试")));

    var categoryI = 0;
    var subCategoryI = 0;
    var qAlias = "别名";
    var qText = "测试题干";
    var questionToAdd = AudioQuestion(alias: qAlias, questionText: qText, evalRule: EvalAudioQuestionByKeywordsMatchesCount(keywords: ["测试"]));

    int fakeId = Random(0).nextInt(1000000000);
    var fakeResponse = AudioQuestion(id: fakeId.toString(), alias: qAlias, questionText: qText, evalRule: EvalAudioQuestionByKeywordsMatchesCount(keywords: ["测试"]));

    when(client.post(Uri.parse("${HttpConstants.backendBaseUrl}/api/exam/$examId/category/$categoryI/subCategory/$subCategoryI/question"),
        body: jsonEncode(questionToAdd.toJson())))
        .thenAnswer((realInvocation) async => http.Response.bytes(
        utf8.encode(jsonEncode(fakeResponse.toJson())), 200));

    var question = await exam.addQuestion(questionToAdd, categoryIndex: categoryI, subCategoryIndex: subCategoryI);

    expect(exam.categories[categoryI].subCategories[subCategoryI].questions.last, question);
    expect(question.id, fakeId.toString());
    expect(question.alias, qAlias);
    expect(question.questionText, qText);
    expect(question, isA<AudioQuestion>());

    categoryI = 1;
    expect(() async => await exam.addQuestion(questionToAdd, categoryIndex: categoryI, subCategoryIndex: subCategoryI), throwsA(isA<RangeError>()));

    categoryI = 0;
    subCategoryI = 1;
    expect(() async => await exam.addQuestion(questionToAdd, categoryIndex: categoryI, subCategoryIndex: subCategoryI), throwsA(isA<RangeError>()));

    subCategoryI = 0;
    exam.published = true;
    expect(() async => await exam.addQuestion(questionToAdd, categoryIndex: categoryI, subCategoryIndex: subCategoryI), throwsA(isA<EditPublishedQuestionSetException>()));
  });
}
