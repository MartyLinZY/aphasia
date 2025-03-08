import 'dart:convert';

import 'package:aphasia_recovery/models/question/question.dart';
import 'package:aphasia_recovery/models/result/results.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("SubCategoryResult toJson test", () {
    var subCateRes = SubCategoryResult(finalScore: 1);
    subCateRes.questionResults.add(AudioQuestionResult(sourceQuestion: AudioQuestion(alias: "测试", questionText: "测试题干", imageUrl: "fake://image"), audioContent: "测试"));

    var subCateDecoded = SubCategoryResult.fromJson(jsonDecode(jsonEncode(subCateRes.toJson())));
    var qResDecoded = subCateDecoded.questionResults[0] as AudioQuestionResult;
    var qRes = subCateRes.questionResults[0] as AudioQuestionResult;
    expect(subCateDecoded.finalScore, subCateRes.finalScore);
    expect(qResDecoded.sourceQuestion.alias, qRes.sourceQuestion.alias);
    expect(qResDecoded.finalScore, qRes.finalScore);
    expect(qResDecoded.sourceQuestion.imageUrl, qRes.sourceQuestion.imageUrl);
    expect(qResDecoded.sourceQuestion.questionText, qRes.sourceQuestion.questionText);
    expect(qResDecoded.audioContent, qRes.audioContent);
  });
}