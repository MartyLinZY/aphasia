import 'dart:convert';

import 'package:aphasia_recovery/models/question/question.dart';
import 'package:aphasia_recovery/models/rules.dart';
import 'package:flutter_test/flutter_test.dart';

import '../TestBase.dart';
import '../fake_data.dart' as fake;

void main() {
  test("Question models.mermaid create instance from json Test", () {
    TestBase.commonSetUp();

    var test = "测试题干";
    var aUrl = "test.mp3";
    var iUrl = "test.png";
    Question q = AudioQuestion(questionText: test, audioUrl: aUrl, imageUrl: iUrl, evalRule: EvalAudioQuestionByKeywordsMatchesCount());
    q.id = fake.examId1;
    String rawJson = jsonEncode(q.toJson());

    AudioQuestion qDecoded = Question.fromJson(json.decode(rawJson)) as AudioQuestion;
    expect(qDecoded, isA<AudioQuestion>());
    expect(qDecoded.id, fake.examId1);
    expect(qDecoded.questionText, "测试题干");
    expect(qDecoded.audioUrl, "test.mp3");
    expect(qDecoded.imageUrl, "test.png");
    expect(qDecoded.alias, null);
    expect(qDecoded.typeName, qDecoded.runtimeType.toString());
    expect(qDecoded.evalRule!.typeName, q.evalRule!.typeName);

    q = ChoiceQuestion(evalRule: EvalChoiceQuestionByCorrectChoiceCount());
    q.id = fake.examId1;
    rawJson = jsonEncode(q.toJson());
    ChoiceQuestion choiceQ = Question.fromJson(jsonDecode(rawJson)) as ChoiceQuestion;
    expect(choiceQ, isA<ChoiceQuestion>());
    expect(choiceQ.id, fake.examId1);
    expect(choiceQ.evalRule!.typeName, q.evalRule!.typeName);

    var alias = "测试";
    q = CommandQuestion(alias: alias, evalRule: EvalCommandQuestionByCorrectActionCount()..slots[0].itemName = "阿萨的");
    q.id = fake.examId1;
    rawJson = jsonEncode(q.toJson());
    CommandQuestion commandQ = Question.fromJson(jsonDecode(rawJson)) as CommandQuestion;
    expect(commandQ, isA<CommandQuestion>());
    expect(commandQ.id, fake.examId1);
    expect(commandQ.alias, alias);
    expect(commandQ.evalRule!.typeName, q.evalRule!.typeName);
    expect((commandQ.evalRule as EvalCommandQuestionByCorrectActionCount).slots[0].itemName, "阿萨的");

    q = WritingQuestion(evalRule: EvalWritingQuestionByCorrectKeywordCount());
    q.id = fake.examId1;
    rawJson = jsonEncode(q.toJson());
    WritingQuestion drawQ = Question.fromJson(jsonDecode(rawJson)) as WritingQuestion;
    expect(drawQ, isA<WritingQuestion>());
    expect(drawQ.id, fake.examId1);
    expect(drawQ.evalRule!.typeName, q.evalRule!.typeName);

    q = ItemFindingQuestion(evalRule: EvalItemFoundQuestion());
    q.id = fake.examId1;
    rawJson = jsonEncode(q.toJson());
    ItemFindingQuestion itemFindingQ = Question.fromJson(jsonDecode(rawJson)) as ItemFindingQuestion;
    expect(itemFindingQ, isA<ItemFindingQuestion>());
    expect(itemFindingQ.id, fake.examId1);
    expect(itemFindingQ.evalRule!.typeName, q.evalRule!.typeName);
  });


  test("Question models.mermaid to json map Test", () {
    Question q = AudioQuestion(id: "1", alias: "2", questionText: "123", audioUrl: "3", imageUrl: "4", evalRule: EvalAudioQuestionByKeywordMatch(keyword: "测试"));
    var map = q.toJson();
    expect(map['typeName'], q.runtimeType.toString());
    expect(map['id'], "1");
    expect(map['alias'], "2");
    expect(map['questionText'], "123");
    expect(map['audioUrl'], "3");
    expect(map['imageUrl'], "4");

    q = ChoiceQuestion(id: "1", alias: "2", questionText: "123", audioUrl: "3", imageUrl: "4", evalRule: EvalChoiceQuestionByCorrectChoiceCount());
    map = q.toJson();
    expect(map['typeName'], q.runtimeType.toString());

    q = CommandQuestion(id: "1", alias: "2", questionText: "123", audioUrl: "3", imageUrl: "4", evalRule: EvalCommandQuestionByCorrectActionCount()..slots[0].itemName = "阿萨的");
    map = q.toJson();
    expect(map['typeName'], q.runtimeType.toString());

    q = WritingQuestion(id: "1", alias: "2", questionText: "123", audioUrl: "3", imageUrl: "4", evalRule: EvalWritingQuestionByCorrectKeywordCount());
    map = q.toJson();
    expect(map['typeName'], q.runtimeType.toString());

    q = ItemFindingQuestion(id: "1", alias: "2", questionText: "123", audioUrl: "3", imageUrl: "4", evalRule: EvalItemFoundQuestion());
    map = q.toJson();
    expect(map['typeName'], q.runtimeType.toString());
  });
}