import 'dart:convert';

import 'package:aphasia_recovery/exceptions/http_exceptions.dart';
import 'package:aphasia_recovery/exceptions/local_exceptions.dart';
import 'package:aphasia_recovery/models/exam/sub_category.dart';
import 'package:aphasia_recovery/models/question/question.dart';
import 'package:aphasia_recovery/models/rules.dart';
import 'package:aphasia_recovery/utils/http/http_manager.dart';
import 'package:aphasia_recovery/settings.dart';
import 'package:json_annotation/json_annotation.dart';

import 'category.dart';

part 'exam_recovery.g.dart';

@JsonSerializable(explicitToJson: true)
class ExamQuestionSet {
  String? _id;
  String name;
  String description;
  bool recovery;
  bool published;
  List<QuestionCategory> categories = [];
  // Client? _httpClient;

  String? get id => _id;

  set id(String? testId) {
    if (AppSettings.testMode) {
      _id = testId;
    } else {
      throw Exception(AppSettings.notInTestModeErrMsg);
    }
  }

  List<DiagnosisRule> diagnosisRules = [];
  List<ExamEvalRule> rules = [];

  /// 构造器中必须要带id参数，json_serialization包需要调用id setter来赋值，
  ExamQuestionSet(
      {String? id,
      this.name = "新测评",
      this.description = "",
      this.recovery = false})
      : published = false,
        _id = id;

  factory ExamQuestionSet.fromJson(Map<String, dynamic> jsonData) {
    return _$ExamQuestionSetFromJson(jsonData);
  }

  Map<String, dynamic> toJson() {
    return _$ExamQuestionSetToJson(this);
  }

  ExamQuestionSet copy() {
    return ExamQuestionSet.fromJson(jsonDecode(jsonEncode(toJson())));
  }

  static Future<ExamQuestionSet?> getById({required String id}) async {
    try {
      Map<String, dynamic> jsonData = await HttpClientManager()
          .get(url: "${HttpConstants.backendBaseUrl}/api/exams/$id");

      return ExamQuestionSet.fromJson(jsonData);
    } on HttpRequestException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      } else {
        rethrow;
      }
    }
  }

  static Future<List<ExamQuestionSet>> getByDoctorUserId(
      {required String userId, bool getRecovery = false}) async {
    List<dynamic> jsonData;
    if (!getRecovery) {
      jsonData = await HttpClientManager().get(
          url: "${HttpConstants.backendBaseUrl}/api/doctors/$userId/exams");
    } else {
      jsonData = await HttpClientManager().get(
          url:
              "${HttpConstants.backendBaseUrl}/api/doctors/$userId/recoveries");
    }

    return jsonData.map((e) => ExamQuestionSet.fromJson(e)).toList();
  }

  static Future<ExamQuestionSet> createExam(
      {required String name,
      String description = "",
      bool isRecovery = false}) async {
    var exam = ExamQuestionSet(
        name: name, description: description, recovery: isRecovery);

    var jsonData = await HttpClientManager().post(
        url: "${HttpConstants.backendBaseUrl}/api/exams",
        body: jsonEncode(exam.toJson()));

    return ExamQuestionSet.fromJson(jsonData);
  }

  /// 仅本地添加测评亚项，不与后端同步
  void addCategoryLocally({String description = "新亚项"}) {
    categories.add(QuestionCategory(description: description));
  }

  void _checkPublished() {
    if (published) {
      throw EditPublishedQuestionSetException();
    }
  }

  void _checkCategoryIndex(int index) {
    if (index < 0 || index >= categories.length) {
      throw RangeError.index(index, categories);
    }
  }

  Future<void> updateName({required String newName}) async {
    await HttpClientManager().patch(
        url: "${HttpConstants.backendBaseUrl}/api/exams/$_id/name/$newName",
        body: '{}');

    name = newName;
  }

  Future<void> updateDescription({required String newDescription}) async {
    await HttpClientManager().patch(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/desc/$newDescription",
        body: '{}');

    description = newDescription;
  }

  /// 新增测评亚项，发送http请求更新后台数据库，若http请求失败，本地数据不变。要求测评未发布，否则抛出[EditPublishedQuestionSetException]异常
  Future<QuestionCategory> addCategory(
      {String description = "新亚项", int? insertAt}) async {
    insertAt ??= categories.length;

    _checkPublished();
    if (insertAt != categories.length) {
      // 允许插入到亚项列表末尾
      _checkCategoryIndex(insertAt);
    }

    // 默认添加一条按子项得分求和得评分规则
    var newCategory = QuestionCategory(description: description)
      ..rules.add(EvalBySubCategoryScoreSum());
    await HttpClientManager().post(
        url: "${HttpConstants.backendBaseUrl}/api/exams/$_id/category",
        body: jsonEncode(newCategory.toJson()));

    categories.insert(insertAt, newCategory);

    return categories[insertAt];
  }

  /// 删除亚项，发送http请求更新后台数据库，若http请求失败，本地数据不变。要求测评未发布，否则抛出[EditPublishedQuestionSetException]异常
  Future<QuestionCategory> deleteCategory({required int categoryIndex}) async {
    _checkPublished();
    _checkCategoryIndex(categoryIndex);

    await HttpClientManager().delete(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/categories/$categoryIndex");

    for (int i = 0; i < diagnosisRules.length; i++) {
      var diagnosisRule = diagnosisRules[i];
      var removeAt = diagnosisRule.removeCategory(categoryIndex);
      if (removeAt != -1) {
        await updateDiagnosisRule(updatedRule: diagnosisRule, ruleIndex: i);
      }
    }

    return categories.removeAt(categoryIndex);
  }

  Future<void> updateCategory(
      {required QuestionCategory updatedCategory,
      required int categoryIndex}) async {
    _checkPublished();
    _checkCategoryIndex(categoryIndex);

    await HttpClientManager().patch(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/categories/$categoryIndex",
        body: jsonEncode(updatedCategory.toJson()));

    // debugPrint(categories.fold("", (previousValue, element) => "$previousValue\n${element.toJson()}"));
    categories[categoryIndex] = updatedCategory;
  }

  Future<void> moveCategoryUp({required int categoryIndex}) async {
    _checkPublished();
    _checkCategoryIndex(categoryIndex);

    await HttpClientManager().patch(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/categories/$categoryIndex/up",
        body: '{}');

    if (categoryIndex > 0) {
      var tmp = categories[categoryIndex - 1];
      categories[categoryIndex - 1] = categories[categoryIndex];
      categories[categoryIndex] = tmp;
    }
  }

  Future<void> moveCategoryDown({required int categoryIndex}) async {
    _checkPublished();
    _checkCategoryIndex(categoryIndex);

    await HttpClientManager().patch(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/categories/$categoryIndex/down",
        body: '{}');

    if (categoryIndex < categories.length - 1) {
      var tmp = categories[categoryIndex + 1];
      categories[categoryIndex + 1] = categories[categoryIndex];
      categories[categoryIndex] = tmp;
    }
  }

  void _checkSubCategoryIndex(int categoryIndex, int subCategoryIndex) {
    _checkCategoryIndex(categoryIndex);
    var category = categories[categoryIndex];
    if (subCategoryIndex < 0 ||
        subCategoryIndex >= category.subCategories.length) {
      throw RangeError.index(subCategoryIndex, category.subCategories);
    }
  }

  Future<QuestionSubCategory> addSubCategory(
      {String description = "新子项", required int categoryIndex}) async {
    _checkPublished();
    _checkCategoryIndex(categoryIndex);
    QuestionCategory category = categories[categoryIndex];

    // 默认添加一条评分规则：下属所有题目得分之和
    var newSubCategory = QuestionSubCategory(description: description)
      ..evalRules.add(EvalSubCategoryByQuestionScoreSum());
    await HttpClientManager().post(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/categories/$categoryIndex/subCategory",
        body: jsonEncode(newSubCategory.toJson()));

    category.subCategories.add(newSubCategory);

    return category.subCategories.last;
  }

  /// 修改测评子项，发送http请求更新后台数据库，若http请求失败，本地数据不变。要求测评未发布，否则抛出[EditPublishedQuestionSetException]异常
  Future<void> updateSubCategory(
      {required QuestionSubCategory updatedSubCategory,
      required int categoryIndex,
      required int subCategoryIndex}) async {
    _checkPublished();
    _checkSubCategoryIndex(categoryIndex, subCategoryIndex);
    QuestionCategory category = categories[categoryIndex];

    await HttpClientManager().patch(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/categories/$categoryIndex/subCategories/$subCategoryIndex",
        body: jsonEncode(updatedSubCategory.toJson()));

    category.subCategories[subCategoryIndex] = updatedSubCategory;
  }

  /// 删除指定测评子项，发送http请求更新后台数据库，若http请求失败，本地数据不变。要求测评未发布，否则抛出[EditPublishedQuestionSetException]异常
  Future<QuestionSubCategory> deleteSubCategory(
      {required int categoryIndex, required int subCategoryIndex}) async {
    _checkPublished();
    _checkSubCategoryIndex(categoryIndex, subCategoryIndex);
    QuestionCategory category = categories[categoryIndex];

    await HttpClientManager().delete(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/categories/$categoryIndex/subCategories/$subCategoryIndex");

    return category.subCategories.removeAt(subCategoryIndex);
  }

  Future<void> moveSubCategoryUp(
      {required int categoryIndex, required int subCategoryIndex}) async {
    _checkPublished();
    _checkSubCategoryIndex(categoryIndex, subCategoryIndex);

    await HttpClientManager().patch(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/categories/$categoryIndex/subCategories/$subCategoryIndex/up",
        body: '{}');

    if (subCategoryIndex > 0) {
      QuestionSubCategory tmp =
          categories[categoryIndex].subCategories[subCategoryIndex - 1];
      categories[categoryIndex].subCategories[subCategoryIndex - 1] =
          categories[categoryIndex].subCategories[subCategoryIndex];
      categories[categoryIndex].subCategories[subCategoryIndex] = tmp;
    }
  }

  Future<void> moveSubCategoryDown(
      {required int categoryIndex, required int subCategoryIndex}) async {
    _checkPublished();
    _checkSubCategoryIndex(categoryIndex, subCategoryIndex);

    await HttpClientManager().patch(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/categories/$categoryIndex/subCategories/$subCategoryIndex/down",
        body: '{}');
    if (subCategoryIndex < categories[categoryIndex].subCategories.length - 1) {
      QuestionSubCategory tmp =
          categories[categoryIndex].subCategories[subCategoryIndex + 1];
      categories[categoryIndex].subCategories[subCategoryIndex + 1] =
          categories[categoryIndex].subCategories[subCategoryIndex];
      categories[categoryIndex].subCategories[subCategoryIndex] = tmp;
    }
  }

  _checkQuestionIndex(int categoryIndex, int subCateIndex, int questionIndex) {
    _checkSubCategoryIndex(categoryIndex, subCateIndex);
    if (questionIndex < 0 ||
        questionIndex >=
            categories[categoryIndex]
                .subCategories[subCateIndex]
                .questions
                .length) {
      throw RangeError.index(questionIndex,
          categories[categoryIndex].subCategories[subCateIndex].questions);
    }
  }

  /// 新增问题，发送http请求更新后台数据库，若http请求失败，本地数据不变。要求测评未发布，否则抛出[EditPublishedQuestionSetException]异常
  Future<Question> addQuestion(Question questionToAdd,
      {required int categoryIndex, required int subCategoryIndex}) async {
    _checkPublished();
    if (categoryIndex >= categories.length ||
        subCategoryIndex >= categories[categoryIndex].subCategories.length) {
      if (categoryIndex >= categories.length) {
        throw RangeError.index(categoryIndex, categories);
      } else {
        throw RangeError.index(
            subCategoryIndex, categories[categoryIndex].subCategories);
      }
    }

    var jsonData = await HttpClientManager().post(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/categories/$categoryIndex/subCategories/$subCategoryIndex/question",
        body: jsonEncode(questionToAdd.toJson()));
    // 测试
    // var jsonData = questionToAdd.toJson();

    // debugPrint(jsonEncode(questionToAdd.toJson()));
    var newQuestion = Question.fromJson(jsonData);
    // debugPrint(jsonEncode(newQuestion.toJson()));
    categories[categoryIndex]
        .subCategories[subCategoryIndex]
        .questions
        .add(newQuestion);

    return newQuestion;
  }

  Future<void> updateQuestion(Question updated,
      {required int categoryIndex,
      required int subCategoryIndex,
      required int questionIndex}) async {
    _checkPublished();
    _checkQuestionIndex(categoryIndex, subCategoryIndex, questionIndex);

    await HttpClientManager().patch(
        url: "${HttpConstants.backendBaseUrl}/api/questions/${updated.id}",
        body: jsonEncode(updated.toJson()));

    categories[categoryIndex]
        .subCategories[subCategoryIndex]
        .questions[questionIndex] = updated;
  }

  Future<Question> deleteQuestion(
      {required int categoryIndex,
      required int subCategoryIndex,
      required int questionIndex}) async {
    _checkQuestionIndex(categoryIndex, subCategoryIndex, questionIndex);

    await HttpClientManager().delete(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/categories/$categoryIndex/subCategories/$subCategoryIndex/questions/$questionIndex");

    return categories[categoryIndex]
        .subCategories[subCategoryIndex]
        .questions
        .removeAt(questionIndex);
  }

  Future<void> moveQuestionUp(
      {required int categoryIndex,
      required int subCategoryIndex,
      required int questionIndex}) async {
    _checkQuestionIndex(categoryIndex, subCategoryIndex, questionIndex);

    await HttpClientManager().patch(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/categories/$categoryIndex/subCategories/$subCategoryIndex/questions/$questionIndex/up",
        body: '{}');

    var subCategoryToUpdate =
        categories[categoryIndex].subCategories[subCategoryIndex];
    if (questionIndex > 0) {
      var tmp = subCategoryToUpdate.questions[questionIndex - 1];
      subCategoryToUpdate.questions[questionIndex - 1] =
          subCategoryToUpdate.questions[questionIndex];
      subCategoryToUpdate.questions[questionIndex] = tmp;
    }
  }

  Future<void> moveQuestionDown(
      {required int categoryIndex,
      required int subCategoryIndex,
      required int questionIndex}) async {
    _checkQuestionIndex(categoryIndex, subCategoryIndex, questionIndex);

    await HttpClientManager().patch(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/categories/$categoryIndex/subCategories/$subCategoryIndex/questions/$questionIndex/down",
        body: '{}');

    var subCategoryToUpdate =
        categories[categoryIndex].subCategories[subCategoryIndex];
    if (questionIndex < subCategoryToUpdate.questions.length - 1) {
      var tmp = subCategoryToUpdate.questions[questionIndex + 1];
      subCategoryToUpdate.questions[questionIndex + 1] =
          subCategoryToUpdate.questions[questionIndex];
      subCategoryToUpdate.questions[questionIndex] = tmp;
    }
  }

  /// 仅设置published = ture, 目前仅用于测试
  void _setPublished() {
    published = true;
  }

  /// remote method, 发送http请求到后端保存
  Future<void> publish() async {
    checkSettingBeforePublish();

    await HttpClientManager().patch(
        url: "${HttpConstants.backendBaseUrl}/api/exams/$_id", body: '{}');

    _setPublished();
  }

  void _checkDiagnosisRuleIndex({required int ruleIndex}) {
    if (ruleIndex < 0 || ruleIndex >= diagnosisRules.length) {
      throw RangeError.index(ruleIndex, diagnosisRules);
    }
  }

  Future<void> addDiagnosisRule(
      {required DiagnosisRule newRule, int? ruleIndex}) async {
    _checkPublished();
    ruleIndex ??= diagnosisRules.length;
    if (ruleIndex != diagnosisRules.length) {
      _checkDiagnosisRuleIndex(ruleIndex: ruleIndex);
    }

    await HttpClientManager().post(
        url: "${HttpConstants.backendBaseUrl}/api/exams/$_id/diagnosisRule",
        body: jsonEncode(newRule.toJson()));

    diagnosisRules.insert(ruleIndex, newRule);
  }

  Future<DiagnosisRule> deleteDiagnosisRule({required int ruleIndex}) async {
    _checkPublished();
    _checkDiagnosisRuleIndex(ruleIndex: ruleIndex);

    await HttpClientManager().delete(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/diagnosisRules/$ruleIndex");

    return diagnosisRules.removeAt(ruleIndex);
  }

  Future<void> updateDiagnosisRule(
      {required DiagnosisRule updatedRule, required int ruleIndex}) async {
    _checkPublished();

    await HttpClientManager().patch(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/diagnosisRules/$ruleIndex",
        body: jsonEncode(updatedRule.toJson()));

    diagnosisRules[ruleIndex] = updatedRule;
  }

  _checkCategoryEvalRuleIndex(
      {required int categoryIndex, required int ruleIndex}) {
    _checkCategoryIndex(categoryIndex);
    var category = categories[categoryIndex];
    if (ruleIndex < 0 || ruleIndex >= category.rules.length) {
      throw RangeError.index(ruleIndex, category.rules);
    }
  }

  Future<void> addCategoryEvalRule(
      {required int categoryIndex,
      int? ruleIndex,
      required ExamCategoryEvalRule newRule}) async {
    _checkPublished();
    _checkCategoryIndex(categoryIndex);

    ruleIndex ??= categories[categoryIndex].rules.length;

    if (ruleIndex != categories[categoryIndex].rules.length) {
      _checkCategoryEvalRuleIndex(
          categoryIndex: categoryIndex, ruleIndex: ruleIndex);
    }

    await HttpClientManager().post(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/categories/$categoryIndex/evalRule",
        body: jsonEncode(newRule.toJson()));

    categories[categoryIndex].rules.insert(ruleIndex, newRule);
  }

  Future<void> updateCategoryEvalRule(
      {required int categoryIndex,
      required int ruleIndex,
      required ExamCategoryEvalRule updatedEvalRule}) async {
    _checkPublished();
    _checkCategoryEvalRuleIndex(
        categoryIndex: categoryIndex, ruleIndex: ruleIndex);

    await HttpClientManager().patch(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/categories/$categoryIndex/evalRules/$ruleIndex",
        body: jsonEncode(updatedEvalRule.toJson()));

    categories[categoryIndex].rules[ruleIndex] = updatedEvalRule;
  }

  Future<ExamCategoryEvalRule> deleteCategoryEvalRule(
      {required int categoryIndex, required int ruleIndex}) async {
    _checkPublished();
    _checkCategoryEvalRuleIndex(
        categoryIndex: categoryIndex, ruleIndex: ruleIndex);

    await HttpClientManager().delete(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/categories/$categoryIndex/evalRules/$ruleIndex");

    var categoryToUpdate = categories[categoryIndex];
    return categoryToUpdate.rules.removeAt(ruleIndex);
  }

  _checkSubCategoryEvalRuleIndex(
      {required int categoryIndex,
      required int subCategoryIndex,
      required int ruleIndex}) {
    _checkSubCategoryIndex(categoryIndex, subCategoryIndex);
    var subCategory = categories[categoryIndex].subCategories[subCategoryIndex];
    if (ruleIndex < 0 || ruleIndex >= subCategory.evalRules.length) {
      throw RangeError.index(ruleIndex, subCategory.evalRules);
    }
  }

  Future<void> addSubCategoryEvalRule(
      {required int categoryIndex,
      required int subCategoryIndex,
      int? ruleIndex,
      required ExamSubCategoryEvalRule newRule}) async {
    _checkPublished();
    _checkSubCategoryIndex(categoryIndex, subCategoryIndex);

    QuestionSubCategory subCategory =
        categories[categoryIndex].subCategories[subCategoryIndex];
    ruleIndex ??= subCategory.evalRules.length;

    if (ruleIndex != subCategory.evalRules.length) {
      _checkSubCategoryEvalRuleIndex(
          categoryIndex: categoryIndex,
          subCategoryIndex: subCategoryIndex,
          ruleIndex: ruleIndex);
    }

    await HttpClientManager().post(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/categories/$categoryIndex/subCategories/$subCategoryIndex/evalRule",
        body: jsonEncode(newRule.toJson()));

    subCategory.evalRules.insert(ruleIndex, newRule);
  }

  Future<void> updateSubCategoryEvalRule(
      {required int categoryIndex,
      required int subCategoryIndex,
      required int ruleIndex,
      required ExamSubCategoryEvalRule updatedEvalRule}) async {
    _checkPublished();
    _checkSubCategoryEvalRuleIndex(
        categoryIndex: categoryIndex,
        subCategoryIndex: subCategoryIndex,
        ruleIndex: ruleIndex);
    QuestionSubCategory subCategory =
        categories[categoryIndex].subCategories[subCategoryIndex];

    await HttpClientManager().patch(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/categories/$categoryIndex/subCategories/$subCategoryIndex/evalRules/$ruleIndex",
        body: jsonEncode(updatedEvalRule.toJson()));

    subCategory.evalRules[ruleIndex] = updatedEvalRule;
  }

  Future<ExamSubCategoryEvalRule> deleteSubCategoryEvalRule(
      {required int categoryIndex,
      required int subCategoryIndex,
      required int ruleIndex}) async {
    _checkPublished();
    _checkSubCategoryEvalRuleIndex(
        categoryIndex: categoryIndex,
        subCategoryIndex: subCategoryIndex,
        ruleIndex: ruleIndex);
    QuestionSubCategory subCategory =
        categories[categoryIndex].subCategories[subCategoryIndex];

    await HttpClientManager().delete(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/categories/$categoryIndex/subCategories/$subCategoryIndex/evalRules/$ruleIndex");

    return subCategory.evalRules.removeAt(ruleIndex);
  }

  _checkSubCategoryTerminateRuleIndex(
      {required int categoryIndex,
      required int subCategoryIndex,
      required int ruleIndex}) {
    _checkSubCategoryIndex(categoryIndex, subCategoryIndex);
    var subCategory = categories[categoryIndex].subCategories[subCategoryIndex];
    if (ruleIndex < 0 || ruleIndex >= subCategory.terminateRules.length) {
      throw RangeError.index(ruleIndex, subCategory.terminateRules);
    }
  }

  Future<void> addSubCategoryTerminateRule(
      {required int categoryIndex,
      required int subCategoryIndex,
      int? ruleIndex,
      required TerminateRule newRule}) async {
    _checkPublished();
    _checkSubCategoryIndex(categoryIndex, subCategoryIndex);

    QuestionSubCategory subCategory =
        categories[categoryIndex].subCategories[subCategoryIndex];
    ruleIndex ??= subCategory.terminateRules.length;

    if (ruleIndex != subCategory.terminateRules.length) {
      _checkSubCategoryTerminateRuleIndex(
          categoryIndex: categoryIndex,
          subCategoryIndex: subCategoryIndex,
          ruleIndex: ruleIndex);
    }

    await HttpClientManager().post(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/categories/$categoryIndex/subCategories/$subCategoryIndex/terminateRule",
        body: jsonEncode(newRule.toJson()));

    subCategory.terminateRules.insert(ruleIndex, newRule);
  }

  Future<void> updateSubCategoryTerminateRule(
      {required int categoryIndex,
      required int subCategoryIndex,
      required int ruleIndex,
      required TerminateRule updatedEvalRule}) async {
    _checkPublished();
    _checkSubCategoryTerminateRuleIndex(
        categoryIndex: categoryIndex,
        subCategoryIndex: subCategoryIndex,
        ruleIndex: ruleIndex);
    QuestionSubCategory subCategory =
        categories[categoryIndex].subCategories[subCategoryIndex];

    await HttpClientManager().patch(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/categories/$categoryIndex/subCategories/$subCategoryIndex/terminateRules/$ruleIndex",
        body: jsonEncode(updatedEvalRule.toJson()));

    subCategory.terminateRules[ruleIndex] = updatedEvalRule;
  }

  Future<TerminateRule> deleteSubCategoryTerminateRule(
      {required int categoryIndex,
      required int subCategoryIndex,
      required int ruleIndex}) async {
    _checkPublished();
    _checkSubCategoryTerminateRuleIndex(
        categoryIndex: categoryIndex,
        subCategoryIndex: subCategoryIndex,
        ruleIndex: ruleIndex);
    QuestionSubCategory subCategory =
        categories[categoryIndex].subCategories[subCategoryIndex];

    await HttpClientManager().delete(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/categories/$categoryIndex/subCategories/$subCategoryIndex/terminateRules/$ruleIndex");

    return subCategory.terminateRules.removeAt(ruleIndex);
  }

  void checkSettingBeforePublish() {
    bool needCategory = categories.isEmpty;
    bool needDiagnosisRule = diagnosisRules.isEmpty;
    bool needEvalRule = false;
    bool needSubCategory = false;
    bool needCateEvalRule = false;
    bool needQuestion = false;
    bool needSubCateEvalRule = false;

    // 这里没有记录所有的缺失，只记录了部分，后面可以改
    _passOrThrowIncompleteException(
        needSubCategory,
        needSubCateEvalRule,
        needQuestion,
        needCateEvalRule,
        needEvalRule,
        needDiagnosisRule,
        needCategory);
    for (int i = 0; i < categories.length; i++) {
      var category = categories[i];
      needSubCategory = category.subCategories.isEmpty;
      needCateEvalRule = category.rules.isEmpty;
      _passOrThrowIncompleteException(
          needSubCategory,
          needSubCateEvalRule,
          needQuestion,
          needCateEvalRule,
          needEvalRule,
          needDiagnosisRule,
          needCategory,
          cateIndex: i);
      for (var j = 0; j < category.subCategories.length; j++) {
        var subCategory = category.subCategories[j];
        needSubCateEvalRule = subCategory.evalRules.isEmpty;
        needQuestion = subCategory.questions.isEmpty;
        _passOrThrowIncompleteException(
            needSubCategory,
            needSubCateEvalRule,
            needQuestion,
            needCateEvalRule,
            needEvalRule,
            needDiagnosisRule,
            needCategory,
            cateIndex: i,
            subCateIndex: j);
      }
    }
  }

  void _passOrThrowIncompleteException(
    bool needSubCategory,
    bool needSubCateEvalRule,
    bool needQuestion,
    bool needCateEvalRule,
    bool needEvalRule,
    bool needDiagnosisRule,
    bool needCategory, {
    int? cateIndex,
    int? subCateIndex,
  }) {
    if (needSubCategory ||
        needSubCateEvalRule ||
        needQuestion ||
        needCateEvalRule ||
        needEvalRule ||
        needDiagnosisRule ||
        needCategory) {
      throw InCompleteExamException(
        needCategory: needCategory,
        needDiagnosisRule: needDiagnosisRule,
        needEvalRule: needEvalRule,
        needSubCategory: needSubCategory,
        needCateEvalRule: needCateEvalRule,
        needQuestion: needQuestion,
        needSubCateEvalRule: needSubCateEvalRule,
        categoryIndex: cateIndex,
        subCategoryIndex: subCateIndex,
      );
    }
  }
}
