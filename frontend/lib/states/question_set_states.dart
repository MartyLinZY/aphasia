import 'package:aphasia_recovery/models/exam/exam_recovery.dart';
import 'package:flutter/foundation.dart';

import '../models/exam/category.dart';
import '../models/exam/sub_category.dart';
import '../models/question/question.dart';
import '../models/rules.dart';

class SingleModelState<T> extends ChangeNotifier {
  T? model;

  SingleModelState(this.model);

  notifyAll() {
    notifyListeners();
  }
}

class ExamState extends ChangeNotifier {
  ExamQuestionSet exam;

  ExamState(this.exam);


  Future<void> updateName({required String newName}) async {
    await exam.updateName(newName: newName);
    notifyListeners();
  }

  Future<void> updateDescription({required String newDescription}) async {
    await exam.updateDescription(newDescription: newDescription);
    notifyListeners();
  }

  Future<void> addDiagnosisRule({required DiagnosisRule newRule, int? ruleIndex}) async {
    await exam.addDiagnosisRule(newRule: newRule, ruleIndex: ruleIndex);
    notifyListeners();
  }

  Future<void> updateDiagnosisRule({required DiagnosisRule updatedRule, required int ruleIndex}) async {
    await exam.updateDiagnosisRule(updatedRule: updatedRule, ruleIndex: ruleIndex);
    notifyListeners();
  }

  Future<DiagnosisRule> deleteDiagnosisRule({required int ruleIndex}) async {
    var rule = await exam.deleteDiagnosisRule(ruleIndex: ruleIndex);
    notifyListeners();
    return rule;
  }

  Future<void> updateCategory({required QuestionCategory updatedCategory, required int categoryIndex}) {
    return exam.updateCategory(updatedCategory: updatedCategory, categoryIndex: categoryIndex)
        .then((_) {
          notifyListeners();
        });
  }

  Future<QuestionCategory> deleteCategory({required int categoryIndex}) {
    return exam.deleteCategory(categoryIndex: categoryIndex)
        .then((category) {
          notifyListeners();
          return category;
        });
  }

  Future<void> moveCategoryUp({required int categoryIndex}) async {
    await exam.moveCategoryUp(categoryIndex: categoryIndex);
    notifyListeners();
  }

  Future<void> moveCategoryDown({required int categoryIndex}) async {
    await exam.moveCategoryDown(categoryIndex: categoryIndex);
    notifyListeners();
  }

  Future<void> addCategoryEvalRule({required int categoryIndex, int? ruleIndex, required ExamCategoryEvalRule newRule}) async {
    await exam.addCategoryEvalRule(categoryIndex: categoryIndex, newRule: newRule, ruleIndex: ruleIndex);
    notifyListeners();
  }

  Future<void> updateCategoryEvalRule({required int categoryIndex, required int ruleIndex, required ExamCategoryEvalRule updatedEvalRule}) async {
    await exam.updateCategoryEvalRule(categoryIndex: categoryIndex, ruleIndex: ruleIndex, updatedEvalRule: updatedEvalRule);
    notifyListeners();
  }

  Future<ExamCategoryEvalRule> deleteCategoryEvalRule({required int categoryIndex, required int ruleIndex}) async {
    var rule = await exam.deleteCategoryEvalRule(categoryIndex: categoryIndex, ruleIndex: ruleIndex);
    notifyListeners();
    return rule;
  }

  Future<void> moveSubCategoryUp({required int categoryIndex, required int subCategoryIndex,}) async {
    await exam.moveSubCategoryUp(categoryIndex: categoryIndex, subCategoryIndex: subCategoryIndex);
    notifyListeners();
  }

  Future<void> moveSubCategoryDown({required int categoryIndex, required int subCategoryIndex}) async {
    await exam.moveSubCategoryDown(categoryIndex: categoryIndex, subCategoryIndex: subCategoryIndex);
    notifyListeners();
  }

  Future<void> updateSubCategory({required QuestionSubCategory updatedSubCategory, required int categoryIndex, required int subCategoryIndex}) {
    return exam.updateSubCategory(updatedSubCategory: updatedSubCategory, categoryIndex: categoryIndex, subCategoryIndex: subCategoryIndex)
        .then((value) {
          notifyListeners();
        });
  }

  Future<QuestionSubCategory> deleteSubCategory({required int categoryIndex, required int subCategoryIndex}) async {
    var deleted =  await exam.deleteSubCategory(categoryIndex: categoryIndex, subCategoryIndex: subCategoryIndex);
    notifyListeners();
    return deleted;
  }

  Future<void> addSubCategoryEvalRule({required int categoryIndex, required int subCategoryIndex, int? ruleIndex, required ExamSubCategoryEvalRule newRule}) async {
    await exam.addSubCategoryEvalRule(categoryIndex: categoryIndex, newRule: newRule, ruleIndex: ruleIndex, subCategoryIndex: subCategoryIndex);
    notifyListeners();
  }

  Future<void> updateSubCategoryEvalRule({required int categoryIndex, required int subCategoryIndex, required int ruleIndex, required ExamSubCategoryEvalRule updatedEvalRule}) async {
    await exam.updateSubCategoryEvalRule(categoryIndex: categoryIndex, updatedEvalRule: updatedEvalRule, ruleIndex: ruleIndex, subCategoryIndex: subCategoryIndex);
    notifyListeners();
  }

  Future<ExamSubCategoryEvalRule> deleteSubCategoryEvalRule({required int categoryIndex, required int subCategoryIndex, required int ruleIndex}) async {
    var rule = await exam.deleteSubCategoryEvalRule(categoryIndex: categoryIndex, subCategoryIndex: subCategoryIndex, ruleIndex: ruleIndex);
    notifyListeners();
    return rule;
  }

  Future<void> addSubCategoryTerminateRule({required int categoryIndex, required int subCategoryIndex, int? ruleIndex, required TerminateRule newRule}) async {
    await exam.addSubCategoryTerminateRule(categoryIndex: categoryIndex, newRule: newRule, ruleIndex: ruleIndex, subCategoryIndex: subCategoryIndex);
    notifyListeners();
  }

  Future<void> updateSubCategoryTerminateRule({required int categoryIndex, required int subCategoryIndex, required int ruleIndex, required TerminateRule updatedEvalRule}) async {
    await exam.updateSubCategoryTerminateRule(categoryIndex: categoryIndex, updatedEvalRule: updatedEvalRule, ruleIndex: ruleIndex, subCategoryIndex: subCategoryIndex);
    notifyListeners();
  }

  Future<ExamSubCategoryEvalRule> deleteSubCategoryTerminateRule({required int categoryIndex, required int subCategoryIndex, required int ruleIndex}) async {
    var rule = await exam.deleteSubCategoryTerminateRule(categoryIndex: categoryIndex, subCategoryIndex: subCategoryIndex, ruleIndex: ruleIndex);
    notifyListeners();
    return rule;
  }

  Future<Question> deleteQuestion({required int categoryIndex, required int subCategoryIndex, required int questionIndex}) async {
    var deletedQuestion = await exam.deleteQuestion(categoryIndex: categoryIndex, subCategoryIndex: subCategoryIndex, questionIndex: questionIndex);
    notifyListeners();
    return deletedQuestion;
  }

  Future<void> moveQuestionUp({required int categoryIndex, required int subCategoryIndex, required int questionIndex}) async {
    await exam.moveQuestionUp(categoryIndex: categoryIndex, subCategoryIndex: subCategoryIndex, questionIndex: questionIndex);
    notifyListeners();
  }

  Future<void> moveQuestionDown({required int categoryIndex, required int subCategoryIndex, required int questionIndex}) async {
    await exam.moveQuestionDown(categoryIndex: categoryIndex, subCategoryIndex: subCategoryIndex, questionIndex: questionIndex);
    notifyListeners();
  }

  Future<void> publish() async {
    await exam.publish();
    notifyListeners();
  }
}