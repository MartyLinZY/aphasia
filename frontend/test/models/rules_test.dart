import 'dart:convert';

import 'package:aphasia_recovery/enum/command_actions.dart';
import 'package:aphasia_recovery/models/result/results.dart';
import 'package:aphasia_recovery/models/rules.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../TestBase.dart';

void main () {
  test("EvalByCategoryScoreSum basic test", () {
    TestBase.commonSetUp();

    var result = ExamResult(examName: '测试');
    var cateRes = CategoryResult();
    cateRes.finalScore = 100.0;
    var cateRes1 = CategoryResult();
    cateRes1.finalScore = 150.0;
    result.categoryResults.add(cateRes);
    result.categoryResults.add(cateRes1);
    var rule = ExamEvalByCategoryScoreSum();
    rule.evaluate(result);

    expect(result.finalScore, 250.0);

    var cateResUnCompleted = CategoryResult();
    result.categoryResults.add(cateResUnCompleted);
    rule.evaluate(result);
    expect(result.finalScore, null);
  });

  test("DiagnosisRule json test", () {
    var diagnosisRule = DiagnoseByScoreRange(aphasiaType: "测试");
    diagnosisRule.categoryIndices.add(0);
    diagnosisRule.categoryIndices.add(2);
    diagnosisRule.ranges.add(ScoreRange(min: 0.0, max: 4.0));
    diagnosisRule.ranges.add(ScoreRange(min: 7.0, max: 10.0));

    var jsonStr = jsonEncode(diagnosisRule.toJson());
    debugPrint(jsonStr);
    var diagnosisRuleDecoded = DiagnosisRule.fromJson(jsonDecode(jsonStr)) as DiagnoseByScoreRange;
    expect(diagnosisRule.ranges[0].min, diagnosisRuleDecoded.ranges[0].min);
    expect(diagnosisRule.ranges[1].max, diagnosisRuleDecoded.ranges[1].max);
    expect(diagnosisRule.categoryIndices[0], diagnosisRuleDecoded.categoryIndices[0]);
    expect(diagnosisRule.categoryIndices[1], diagnosisRuleDecoded.categoryIndices[1]);

    jsonStr = jsonEncode(diagnosisRule.toJson()..update("typeName", (value) => "random"));
    expect(() => DiagnosisRule.fromJson(jsonDecode(jsonStr)), throwsA(isA<UnimplementedError>()));
  });

  test("ExamEvalRule json test", () {
    var evalRule = ExamEvalByCategoryScoreSum(resultDimensionName: "测试");
    evalRule.categoryIndices.add(0);
    evalRule.categoryIndices.add(2);

    var jsonStr = jsonEncode(evalRule.toJson());
    debugPrint(jsonStr);
    var evalRuleDecoded = ExamEvalRule.fromJson(jsonDecode(jsonStr)) as ExamEvalByCategoryScoreSum;
    expect(evalRule.categoryIndices[0], evalRuleDecoded.categoryIndices[0]);
    expect(evalRule.categoryIndices[1], evalRuleDecoded.categoryIndices[1]);
    expect(evalRule.resultDimensionName, evalRuleDecoded.resultDimensionName);

    jsonStr = jsonEncode(evalRule.toJson()..update("typeName", (value) => "random"));
    expect(() => ExamEvalRule.fromJson(jsonDecode(jsonStr)), throwsA(isA<UnimplementedError>()));
  });

  test("ExamCategoryEvalRule json test", () {
    var evalRule = EvalBySubCategoryScoreSum();

    var jsonStr = jsonEncode(evalRule.toJson());
    debugPrint(jsonStr);
    var evalRuleDecoded = ExamCategoryEvalRule.fromJson(jsonDecode(jsonStr));
    expect(evalRuleDecoded, isA<EvalBySubCategoryScoreSum>());

    jsonStr = jsonEncode(evalRule.toJson()..update("typeName", (value) => "random"));
    expect(() => ExamCategoryEvalRule.fromJson(jsonDecode(jsonStr)), throwsA(isA<UnimplementedError>()));
  });

  test("ExamSubCategoryEvalRule json test", () {
    var evalRule = EvalSubCategoryByQuestionScoreSum();

    var jsonStr = jsonEncode(evalRule.toJson());
    debugPrint(jsonStr);
    var evalRuleDecoded = ExamSubCategoryEvalRule.fromJson(jsonDecode(jsonStr));
    expect(evalRuleDecoded, isA<EvalSubCategoryByQuestionScoreSum>());

    jsonStr = jsonEncode(evalRule.toJson()..update("typeName", (value) => "random"));
    expect(() => ExamSubCategoryEvalRule.fromJson(jsonDecode(jsonStr)), throwsA(isA<UnimplementedError>()));

    try {
      ExamSubCategoryEvalRule.fromJson(jsonDecode(jsonStr));
    } on UnimplementedError catch (e) {
      expect(e.message, "无法识别的ExamSubCategoryEvalRule类型");
    }
  });

  test("TerminateRule json test", () {
    var reason = "1";
    var equivScore = 1.0;
    var threshold = 1;
    var tRule = ContinuousWrongAnswerTerminate(reason: reason, equivalentScore: equivScore, errorCountThreshold: threshold);

    var jsonStr = jsonEncode(tRule.toJson());
    debugPrint(jsonStr);
    var tRuleDecoded = TerminateRule.fromJson(jsonDecode(jsonStr)) as ContinuousWrongAnswerTerminate;
    expect(tRuleDecoded.reason, reason);
    expect(tRuleDecoded.equivalentScore, equivScore);
    expect(tRuleDecoded.errorCountThreshold, threshold);

    jsonStr = jsonEncode(tRule.toJson()..update("typeName", (value) => "random"));
    expect(() => TerminateRule.fromJson(jsonDecode(jsonStr)), throwsA(isA<UnimplementedError>()));

    try {
      TerminateRule.fromJson(jsonDecode(jsonStr));
    } on UnimplementedError catch (e) {
      expect(e.message, "无法识别的TerminateRule类型");
    }
  });

  test("HintRule json test", () {
    var hintRule = HintRule(hintText: "测试", hintAudioUrl: "fake://test", hintImageUrl: "fake://test", scoreLowBound: 0.0, scoreHighBound: 3.0, adjustValue: 1, scoreAdjustType: 1);

    var jsonStr = jsonEncode(hintRule.toJson());
    debugPrint(jsonStr);
    var hintRuleDecoded = HintRule.fromJson(jsonDecode(jsonStr));
    expect(hintRule.hintAudioUrl, hintRuleDecoded.hintAudioUrl);
    expect(hintRule.hintImageUrl, hintRuleDecoded.hintImageUrl);
    expect(hintRule.hintText, hintRuleDecoded.hintText);
    expect(hintRule.scoreAdjustType, hintRuleDecoded.scoreAdjustType);
    expect(hintRule.adjustValue, hintRuleDecoded.adjustValue);
    expect(hintRule.scoreLowBound, hintRuleDecoded.scoreLowBound);
    expect(hintRule.scoreHighBound, hintRuleDecoded.scoreHighBound);
  });

  test("EvalCondition json test", () {
    var evalCondition = EvalCondition(score: 10);
    evalCondition.score = 8.0;
    evalCondition.ranges.add({"lowBound": 0, "highBound": 10, "includeHigh": true, "includeLow": true});
    evalCondition.ranges.add({"lowBound": 0, "highBound": 3, "includeHigh": true, "includeLow": true});

    var jsonStr = jsonEncode(evalCondition.toJson());
    debugPrint(jsonStr);
    var evalCondDecoded = EvalCondition.fromJson(jsonDecode(jsonStr));
    expect(evalCondition.score, evalCondDecoded.score);
    expect(evalCondition.ranges[0]['lowBound'], evalCondDecoded.ranges[0]['lowBound']);
    expect(evalCondition.ranges[0]['includeLow'], evalCondDecoded.ranges[0]['includeLow']);
    expect(evalCondition.ranges[1]['highBound'], evalCondDecoded.ranges[1]['highBound']);
    expect(evalCondition.ranges[1]['includeHigh'], evalCondDecoded.ranges[1]['includeHigh']);
  });

  test("EvalAudioQuestionByKeywordsMatchesCount json test", () {
    var evalRule = EvalAudioQuestionByKeywordsMatchesCount(keywords: ["测试"],);
    evalRule.enableFuzzyEvaluation = true;
    evalRule.defaultScore = 9;

    var jsonStr = jsonEncode(evalRule.toJson());
    debugPrint(jsonStr);
    var evalRuleDecoded = QuestionEvalRule.fromJson(jsonDecode(jsonStr)) as EvalAudioQuestionByKeywordsMatchesCount;
    expect(evalRule.ansTimeLimit, evalRuleDecoded.ansTimeLimit);
    expect(evalRule.ansTimeLimit, 20);
    expect(evalRule.defaultScore, evalRuleDecoded.defaultScore);
    expect(evalRule.defaultScore, 9);
    expect(evalRule.enableFuzzyEvaluation, evalRuleDecoded.enableFuzzyEvaluation);
    expect(evalRule.hintRules.length, evalRuleDecoded.hintRules.length);
  });

  test("EvalCommandQuestionByCorrectActionCount json test", () {
    var evalRule = EvalCommandQuestionByCorrectActionCount(slotCount: 20);
    evalRule.defaultScore = 9;
    expect(evalRule.slots.length, 20);
    evalRule.slots[0].itemImageUrl = "fake://test0";
    evalRule.slots[0].itemName = "测试0";
    evalRule.slots[9].itemImageUrl = "fake://test9";
    evalRule.slots[9].itemName = "测试9";
    evalRule.actions.add(CommandActions(sourceSlotIndex: 0, firstAction: ClickAction.take, targetSlotIndex: 9, secondAction: PutDownAction.cover));
    evalRule.actions.add(CommandActions(sourceSlotIndex: 0, firstAction: ClickAction.take));
    evalRule.conditions.add(EvalCondition(score: 10)..addRange(0, 5 ));

    var jsonStr = jsonEncode(evalRule.toJson());
    debugPrint(jsonStr);
    var evalRuleDecoded = QuestionEvalRule.fromJson(jsonDecode(jsonStr)) as EvalCommandQuestionByCorrectActionCount;
    expect(evalRule.defaultScore, evalRuleDecoded.defaultScore);
    expect(evalRule.defaultScore, 9);
    expect(evalRule.slotCount, evalRuleDecoded.slotCount);
    expect(evalRule.slots.length, evalRuleDecoded.slots.length);
    expect(evalRule.slots[0].itemName, "测试0");
    expect(evalRule.actions.length, evalRuleDecoded.actions.length);
    expect(evalRule.conditions.length, evalRuleDecoded.conditions.length);
  });

  test("EvalChoiceQuestionByCorrectChoiceCount json test", () {
    var evalRule = EvalChoiceQuestionByCorrectChoiceCount(enforceOrder: true);
    evalRule.defaultScore = 9;
    evalRule.choices.add(Choice(imageUrl: "fake://test", text: "选项1"));
    evalRule.choices.add(Choice(imageUrl: "fake://test", text: "选项2"));
    evalRule.choices.add(Choice(imageUrl: "fake://test", text: "选项3"));
    evalRule.correctChoices.add(0);
    evalRule.conditions.add(EvalCondition(score: 10)..addRange(0, 1 ));

    var jsonStr = jsonEncode(evalRule.toJson());
    debugPrint(jsonStr);
    var evalRuleDecoded = QuestionEvalRule.fromJson(jsonDecode(jsonStr)) as EvalChoiceQuestionByCorrectChoiceCount;
    expect(evalRule.defaultScore, evalRuleDecoded.defaultScore);
    expect(evalRule.defaultScore, 9);
    expect(evalRule.enforceOrder, evalRuleDecoded.enforceOrder);
    expect(evalRule.choices.length, evalRuleDecoded.choices.length);
    expect(evalRule.choices[0].text, evalRuleDecoded.choices[0].text);
    expect(evalRule.choices[0].imageUrl, evalRuleDecoded.choices[0].imageUrl);
    expect(evalRule.choices[0].text, "选项1");
    expect(evalRule.correctChoices[0], evalRuleDecoded.correctChoices[0]);
  });

  test("EvalWritingQuestionByCorrectKeywordCount json test", () {
    var evalRule = EvalWritingQuestionByCorrectKeywordCount();
    evalRule.defaultScore = 9;
    evalRule.keywords.add("关键词1");
    evalRule.keywords.add("关键词2");
    evalRule.conditions.add(EvalCondition(score: 10)..addRange(0, 1 ));

    var jsonStr = jsonEncode(evalRule.toJson());
    debugPrint(jsonStr);
    var evalRuleDecoded = QuestionEvalRule.fromJson(jsonDecode(jsonStr)) as EvalWritingQuestionByCorrectKeywordCount;
    expect(evalRule.defaultScore, evalRuleDecoded.defaultScore);
    expect(evalRule.defaultScore, 9);
    expect(evalRule.keywords[0], "关键词1");
    expect(evalRule.keywords[1], "关键词2");
    expect(evalRule.keywords[1], evalRuleDecoded.keywords[1]);
    expect(evalRule.conditions[0].score, evalRuleDecoded.conditions[0].score);
    expect(evalRule.conditions[0].ranges[0]["lowBound"], 0);
    expect(evalRule.conditions[0].ranges[0]["includeHigh"], true);
    expect(evalRule.conditions[0].ranges[0]["lowBound"], evalRuleDecoded.conditions[0].ranges[0]["lowBound"]);
  });

  test("EvalWritingQuestionByMatchRate json test", () {
    var evalRule = EvalWritingQuestionByMatchRate();
    evalRule.defaultScore = 9;
    evalRule.keyword = "测试关键词";
    evalRule.conditions.add(EvalCondition(score: 10)..addRange(0, 1 ));

    var jsonStr = jsonEncode(evalRule.toJson());
    debugPrint(jsonStr);
    var evalRuleDecoded = QuestionEvalRule.fromJson(jsonDecode(jsonStr)) as EvalWritingQuestionByMatchRate;
    expect(evalRule.defaultScore, evalRuleDecoded.defaultScore);
    expect(evalRule.defaultScore, 9);
  });

  test("EvalItemFoundQuestion json test", () {
    var evalRule = EvalItemFoundQuestion();

    try {
      evalRule.defaultScore = 11;
    } on ArgumentError catch (e) {
      expect(e.message, "11.0 > ${evalRule.fullScore}, defaultScore 必须小于等于 fullScore");
    }

    evalRule.defaultScore = 9;
    evalRule.coordinates.add([0.5, 0.5]);
    evalRule.coordinates.add([0.75, 0.75]);
    evalRule.coordinates.add([0.85, 0.65]);
    evalRule.conditions.add(EvalCondition(score: 10)..addRange(0, 1 ));

    var jsonStr = jsonEncode(evalRule.toJson());
    debugPrint(jsonStr);
    var evalRuleDecoded = QuestionEvalRule.fromJson(jsonDecode(jsonStr)) as EvalItemFoundQuestion;
    expect(evalRule.defaultScore, evalRuleDecoded.defaultScore);
    expect(evalRule.defaultScore, 9);
    expect(evalRule.coordinates.length, evalRuleDecoded.coordinates.length);
    expect(evalRule.coordinates[0][0], evalRuleDecoded.coordinates[0][0]);
    expect(evalRule.coordinates[1][1], evalRuleDecoded.coordinates[1][1]);
    expect(evalRule.coordinates[2][0], evalRuleDecoded.coordinates[2][0]);
  });
}