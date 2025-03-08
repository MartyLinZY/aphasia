import 'package:flutter/foundation.dart';

class InCompleteExamException implements Exception {
  bool needCategory;
  bool needDiagnosisRule;
  bool needEvalRule;
  int? categoryIndex;
  bool needSubCategory;
  bool needCateEvalRule;
  int? subCategoryIndex;
  bool needQuestion;
  bool needSubCateEvalRule;

  InCompleteExamException({
    this.needCategory = false,
    this.needDiagnosisRule = false,
    this.needEvalRule = false,
    this.categoryIndex,
    this.needSubCategory = false,
    this.needSubCateEvalRule = false,
    this.subCategoryIndex,
    this.needQuestion = false,
    this.needCateEvalRule = false,
  });

  String get message {
    var msg = "问题：";

    if (needCategory) {
      msg += "测评方案中没有设置亚项，至少设置1个；";
    }

    if (needDiagnosisRule) {
      msg += "测评方案没有设置诊断规则；";
    }

    if (needEvalRule) {
      msg += "测评方案没有设置评分规则；";
    }

    if (needCateEvalRule) {
      msg += "第${categoryIndex!+1}个亚项没有设置评分规则；";
    }

    if (needSubCategory) {
      msg += "第${categoryIndex!+1}个亚项没有设置子项，至少设置一个；";
    }

    if (needSubCateEvalRule) {
      msg += "第${categoryIndex!+1}个亚项的第${subCategoryIndex!+1}个子项没有设置评分规则；";
    }

    if (needQuestion) {
      msg += "第${categoryIndex!+1}个亚项的第${subCategoryIndex!+1}个子项中没有题目，请至少添加一个题目；";
    }

    return msg;
  }
}

class EditPublishedQuestionSetException implements Exception {
  static const String promptMessage = "不可修改已发布的测评方案/康复方案，若要修改，请以原方案为模板新建一个方案并修改后发布";

  String getPromptMessage() {
    return promptMessage;
  }
}

class IncompleteModelException implements Exception {
  Type modelType;
  Object modelObj;

  IncompleteModelException({required this.modelType, required this.modelObj});
}

class UnexpectedError extends Error {
  String msg;

  UnexpectedError(this.msg);

  @override
  String toString() {
    return "${runtimeType.toString()}: $msg";
  }
}