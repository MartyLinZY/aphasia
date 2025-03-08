import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

import '../question/question.dart';
import '../result/results.dart';
import '../rules.dart';

part 'sub_category.g.dart';


@JsonSerializable(explicitToJson: true)
class QuestionSubCategory {
  String description;
  List<Question> questions = [];
  List<TerminateRule> terminateRules = [];
  List<ExamSubCategoryEvalRule> evalRules = [];

  QuestionSubCategory({this.description = "新子项"});

  factory QuestionSubCategory.fromJson(Map<String, dynamic> jsonData) {
    return _$QuestionSubCategoryFromJson(jsonData);
  }

  factory QuestionSubCategory.copy(QuestionSubCategory old) {
    return QuestionSubCategory.fromJson(jsonDecode(jsonEncode(old)));
  }

  QuestionSubCategory copy() {
    return QuestionSubCategory.copy(this);
  }

  Map<String, dynamic> toJson() {
    return _$QuestionSubCategoryToJson(this);
  }

  bool checkIfTerminate(SubCategoryResult result, int questionIndex) {
    assert(result.questionResults.length >= questionIndex);
    assert(questions.length >= result.questionResults.length);

    for (var term in terminateRules) {
      if (term.checkIfNeedTerminate(this, result, questionIndex)) {
        debugPrint("需要终止，由${term.runtimeType}规则终止");
        return true;
      }
    }
    return false;
  }
}
