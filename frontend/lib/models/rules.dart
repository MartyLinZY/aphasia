import 'dart:convert';
import 'dart:math';

import 'package:aphasia_recovery/enum/command_actions.dart';
import 'package:aphasia_recovery/models/result/results.dart';
import 'package:aphasia_recovery/utils/algorithm.dart';
import 'package:aphasia_recovery/utils/thirdparty/thirdparty_api.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

import '../mixin/eval_rule_mixin.dart';
import '../widgets/ui/do_exam/command_question.dart';
import 'exam/sub_category.dart';

part 'rules.g.dart';

// #################################### 测评诊断规则 ####################################

/// 测评诊断规则
abstract class DiagnosisRule {
  late String typeName;

  List<int> categoryIndices = [];

  DiagnosisRule() {
    typeName = runtimeType.toString();
  }

  factory DiagnosisRule.fromJson(Map<String, dynamic> jsonMap) {
    String typeName = jsonMap['typeName'];
    switch(typeName) {
      case "DiagnoseByScoreRange":
        return DiagnoseByScoreRange.fromJson(jsonMap);
      default:
        throw UnimplementedError();
    }
  }

  Map<String, dynamic> toJson();

  String displayName();

  DiagnosisRule copy() {
    return DiagnosisRule.fromJson(jsonDecode(jsonEncode(this)));
  }

  void addCategory(int categoryIndex) {
    categoryIndices.add(categoryIndex);
  }

  int removeCategory(int categoryIndex) {
    int found = categoryIndices.indexOf(categoryIndex);
    if (found != -1) {
      categoryIndices.removeAt(found);
      return found;
    }
    return -1;
  }

  bool checkAndDiagnose(ExamResult result);
}


@JsonSerializable()
class ScoreRange {
  double min;
  double max;
  ScoreRange({this.min = double.negativeInfinity, this.max = double.infinity});

  factory ScoreRange.fromJson(Map<String, dynamic> jsonMap) {
    return _$ScoreRangeFromJson(jsonMap);
  }

  Map<String, dynamic> toJson() {
    return _$ScoreRangeToJson(this);
  }
}

@JsonSerializable(explicitToJson: true)
class DiagnoseByScoreRange extends DiagnosisRule {
  /// [ranges]的长度与[categoryIndices]的长度一致
  List<ScoreRange> ranges = [];

  @JsonKey(required: true)
  String aphasiaType;

  static String ruleDisplayName() {
    return "按亚项得分范围";
  }

  DiagnoseByScoreRange({required this.aphasiaType});

  factory DiagnoseByScoreRange.fromJson(Map<String, dynamic> jsonMap) {
    return _$DiagnoseByScoreRangeFromJson(jsonMap);
  }

  @override
  Map<String, dynamic> toJson() {
    return _$DiagnoseByScoreRangeToJson(this);
  }

  @override
  DiagnoseByScoreRange copy() {
    return super.copy() as DiagnoseByScoreRange;
  }

  @override
  String displayName() {
    return aphasiaType;
  }

  void addRange({required int categoryIndex, required ScoreRange range}) {

  }

  @override
  int removeCategory(int categoryIndex) {
    int removeAt = super.removeCategory(categoryIndex);
    if (removeAt != -1 ) {
      ranges.removeAt(removeAt);
    }
    return removeAt;
  }

  @override
  bool checkAndDiagnose(ExamResult result) {
    assert(categoryIndices.length == ranges.length);


    for (var i = 0;i < ranges.length;i++) {
      int categoryIndex = categoryIndices[i];
      ScoreRange range = ranges[i];

      double score = result.categoryResults[categoryIndex].finalScore!;

      if (score.clamp(range.min, range.max) != score) {
        return false;
      }
    }

    debugPrint("${runtimeType.toString()}条件命中：");
    for (var i = 0;i < ranges.length;i++) {
      int categoryIndex = categoryIndices[i];
      ScoreRange range = ranges[i];

      double score = result.categoryResults[categoryIndex].finalScore!;
      debugPrint("第$categoryIndices个亚项得分为$score，处于${range.min}与${range.max}之间，");
    }
    debugPrint("诊断为$aphasiaType。");
    result.resultText = aphasiaType;
    return true;
  }
}


// #################################### 测评结算总评分规则 ####################################

/// 测评整体评分规则
abstract class ExamEvalRule {
  List<int> categoryIndices = [];
  String resultDimensionName;
  late String typeName;

  ExamEvalRule({required this.resultDimensionName}) {
    typeName = runtimeType.toString();
  }

  ExamResult evaluate(ExamResult result);

  String displayName();

  Map<String, dynamic> toJson();

  factory ExamEvalRule.fromJson(Map<String, dynamic> jsonMap) {
    String typeName = jsonMap["typeName"];
    switch(typeName) {
      case "ExamEvalByCategoryScoreSum":
        return ExamEvalByCategoryScoreSum.fromJson(jsonMap);
      default:
        throw UnimplementedError();
    }
  }
}

@JsonSerializable(explicitToJson: true)
class ExamEvalByCategoryScoreSum extends ExamEvalRule {
  ExamEvalByCategoryScoreSum({super.resultDimensionName = "总分"});

  factory ExamEvalByCategoryScoreSum.fromJson(Map<String, dynamic> jsonMap) {
    return _$ExamEvalByCategoryScoreSumFromJson(jsonMap);
  }

  static String ruleDisplayName() {
    return "对所有亚项得分求和";
  }

  @override
  ExamResult evaluate(ExamResult result) {
    result.finalScore = result.categoryResults.fold(0.0, (previousValue, element) {
      if (previousValue == null || element.finalScore == null) {
        return null;
      } else {
        return previousValue + element.finalScore!;
      }
    });

    return result;
  }


  @override
  Map<String, dynamic> toJson() {
    return _$ExamEvalByCategoryScoreSumToJson(this);
  }

  @override
  String displayName() {
    return ruleDisplayName();
  }
}

// #################################### 测评亚项结算总评分规则 ####################################
/// 测评亚项评分规则
abstract class ExamCategoryEvalRule {
  late String typeName;
  ExamCategoryEvalRule() {
    typeName = runtimeType.toString();
  }

  factory ExamCategoryEvalRule.fromJson(Map<String, dynamic> jsonMap) {
    String typeName = jsonMap['typeName'];
    switch (typeName) {
      case "EvalBySubCategoryScoreSum":
        return EvalBySubCategoryScoreSum.fromJson(jsonMap);
      default:
        throw UnimplementedError();
    }
  }

  Map<String, dynamic> toJson();

  ExamCategoryEvalRule copy() {
    return ExamCategoryEvalRule.fromJson(jsonDecode(jsonEncode(toJson())));
  }

  String displayName();

  CategoryResult evaluate(CategoryResult result);
}

@JsonSerializable(explicitToJson: true)
class EvalBySubCategoryScoreSum extends ExamCategoryEvalRule {
  EvalBySubCategoryScoreSum();

  factory EvalBySubCategoryScoreSum.fromJson(Map<String, dynamic> jsonMap) {
    return _$EvalBySubCategoryScoreSumFromJson(jsonMap);
  }

  @override
  CategoryResult evaluate(CategoryResult result) {
    double sum = 0;
    for (var subCateRes in result.subResults) {
      assert(subCateRes.finalScore != null);

      sum += subCateRes.finalScore!;
    }

    result.finalScore = sum;
    debugPrint("由${runtimeType.toString()}规则进行亚项得分计算，亚项得分为 ${result.finalScore}");

    return result;
  }

  @override
  Map<String, dynamic> toJson() {
    return _$EvalBySubCategoryScoreSumToJson(this);
  }

  @override
  String displayName() {
    return "各个子项分数求和";
  }
}

// #################################### 测评子项结算总评分规则 ####################################

/// 测评子项评分规则
abstract class ExamSubCategoryEvalRule {
  late String typeName;
  ExamSubCategoryEvalRule() {
    typeName = runtimeType.toString();
  }

  factory ExamSubCategoryEvalRule.fromJson(Map<String, dynamic> jsonMap) {
    var typeName = jsonMap['typeName'];
    switch (typeName) {
      case "EvalSubCategoryByQuestionScoreSum":
        return EvalSubCategoryByQuestionScoreSum.fromJson(jsonMap);
      default:
        try {
          return TerminateRule.fromJson(jsonMap);
        } on UnimplementedError {
          throw UnimplementedError("无法识别的ExamSubCategoryEvalRule类型");
        }
    }
  }

  Map<String, dynamic> toJson();

  String displayName();

  ExamSubCategoryEvalRule copy() {
    return ExamSubCategoryEvalRule.fromJson(jsonDecode(jsonEncode(this)));
  }

  SubCategoryResult evaluate(SubCategoryResult result);
}

@JsonSerializable(explicitToJson: true)
class EvalSubCategoryByQuestionScoreSum extends ExamSubCategoryEvalRule {
  EvalSubCategoryByQuestionScoreSum();

  factory EvalSubCategoryByQuestionScoreSum.fromJson(Map<String, dynamic> jsonMap) {
    return _$EvalSubCategoryByQuestionScoreSumFromJson(jsonMap);
  }

  @override
  Map<String, dynamic> toJson() {
    return _$EvalSubCategoryByQuestionScoreSumToJson(this);
  }

  @override
  SubCategoryResult evaluate(SubCategoryResult result) {
    double sum = 0;
    for (var qres in result.questionResults) {
      assert(qres.finalScore != null);

      sum += qres.finalScore!;
    }

    result.finalScore = sum;
    debugPrint("由${runtimeType.toString()}规则进行子项得分计算，子项得分为 ${result.finalScore}");

    return result;
  }


  @override
  String displayName() {
    // TODO: implement displayName
    return "各题目得分求和";
  }
}

// #################################### 测评子项终止规则 ####################################

/// 测评子项终止规则
abstract class TerminateRule implements ExamSubCategoryEvalRule {
  String reason;
  double equivalentScore;

  @override
  late String typeName;

  TerminateRule({required this.reason, required this.equivalentScore}) {
    typeName = runtimeType.toString();
  }

  factory TerminateRule.fromJson(Map<String, dynamic> jsonMap) {
    var typeName = jsonMap['typeName'];
    switch (typeName) {
      case "ContinuousWrongAnswerTerminate":
        return ContinuousWrongAnswerTerminate.fromJson(jsonMap);
      default:
        throw UnimplementedError("无法识别的TerminateRule类型");
    }
  }
  
  @override
  TerminateRule copy() {
    return TerminateRule.fromJson(jsonDecode(jsonEncode(this)));
  }

  bool checkIfNeedTerminate(QuestionSubCategory category, SubCategoryResult result, int questionIndex);
}


@JsonSerializable(explicitToJson: true)
class ContinuousWrongAnswerTerminate extends TerminateRule {
  @JsonKey(required: true)
  int errorCountThreshold;
  // int scoreThreshold; // TODO

  static String ruleDisplayName() {
    return "连续答错N题（得分小于等于满分的一半为答错）";
  }

  ContinuousWrongAnswerTerminate({required super.reason, required super.equivalentScore, required this.errorCountThreshold});

  factory ContinuousWrongAnswerTerminate.fromJson(Map<String, dynamic> jsonMap) {
    return _$ContinuousWrongAnswerTerminateFromJson(jsonMap);
  }

  @override
  Map<String, dynamic> toJson() {
    return _$ContinuousWrongAnswerTerminateToJson(this);
  }

  @override
  SubCategoryResult evaluate(SubCategoryResult result) {
    // TODO: implement evaluate
    throw UnimplementedError();
  }

  @override
  String displayName() {
    return ruleDisplayName();
  }

  @override
  bool checkIfNeedTerminate(QuestionSubCategory category, SubCategoryResult result, int questionIndex) {
    debugPrint("检查规则${runtimeType.toString()}");
    if (result.questionResults.length >= errorCountThreshold) {
      int errCount = 0;
      for (var i = 0;i < result.questionResults.length;i++) {
        var q = category.questions[i];
        assert(q.evalRule != null);
        var qres = result.questionResults[i];
        assert(qres.finalScore != null);

        double fullScore = q.evalRule!.fullScore;
        if (qres.finalScore! < fullScore / 2) {
          errCount++;
          if (errCount >= errorCountThreshold) {
            debugPrint("第${i - errCount + 2}至第${i+1}题连续错误，由${runtimeType.toString()}终止");
            return true;
          }
        } else {
          errCount = 0;
        }
      }
    }

    return false;
  }

}

// #################################### 题目作答时提醒规则 ####################################
/// 题目提示规则
@JsonSerializable()
class HintRule {
  /// 提示文本
  String? hintText;
  /// 提示语音文件URL
  String? hintAudioUrl;
  /// 提示图片文件URL
  String? hintImageUrl;
  /// 提示图片文件asset路径
  String? hintImageAssetPath;
  /// 触发提示的分数下限
  double scoreLowBound;
  /// 触发提示的分数上限
  double scoreHighBound;
  /// 调整值，见[scoreAdjustType]的注释
  double adjustValue;
  /// 触发提示后的正确作答得分的调整方式，0表示不调整，1表示减去[adjustValue]（最终不低于0分），2表示设为[adjustValue] - 暂不支持修改，默认为1
  int scoreAdjustType;

  HintRule({
    this.hintText,
    this.hintAudioUrl,
    this.hintImageUrl,
    this.hintImageAssetPath,
    this.scoreLowBound = 0.0,
    this.scoreHighBound = 1.0,
    this.scoreAdjustType = 1,
    this.adjustValue = 0,
  });

  factory HintRule.fromJson(Map<String, dynamic> jsonMap) => _$HintRuleFromJson(jsonMap);

  Map<String, dynamic> toJson() => _$HintRuleToJson(this);

  String? checkSetting() {
    if (hintText == null && hintAudioUrl == null && hintImageUrl == null && hintImageAssetPath == null) {
      return "请至少在提示文本，提示音频和提示图片中选择一个进行设置";
    }

    if (scoreHighBound < 0) {
      return "触发分数上界不能小于0";
    }

    if (scoreLowBound < 0) {
      return "触发分数下界不能小于0";
    }

    if (scoreLowBound > scoreHighBound) {
      return "触发分数的下界不能大于上界";
    }

    return null;
  }

  bool checkIfMatch(double score) {
    if (score <= scoreHighBound && score >= scoreLowBound) {
      return true;
    }
    return false;
  }

  // void adjustScore(QuestionResult result) {
  //   if (scoreAdjustType == 1) {
  //     result.finalScore = max(0, result.finalScore! - adjustValue);
  //   }
  // }
}

// #################################### 题目评分规则 ####################################
@JsonSerializable()
class EvalCondition {
  double score;

  /// 一般是两个条件，第一个是题目的计分单位（例如关键词正确的个数），第二个是患者开始作答的时间，
  List<Map<String, dynamic>> ranges = [];

  bool isHinted;

  int get length => ranges.length;

  EvalCondition({required this.score, this.isHinted = false});

  factory EvalCondition.fromJson(Map<String, dynamic> jsonMap) => _$EvalConditionFromJson(jsonMap);

  Map<String, dynamic> toJson() => _$EvalConditionToJson(this);

  /// 包含上下界
  void addRange(num lowBound, num highBound) {
    if (lowBound > highBound) {
      throw ArgumentError("lowBound大于highBound, $lowBound > $highBound");
    }
    ranges.add({"lowBound": lowBound, "highBound": highBound});
  }

  Map<String, dynamic> removeRange(int index) {
    assert(index >= 0 && index < ranges.length);

    return ranges.removeAt(index);
  }

  /// [values] - 要检查的值的列表，与[ranges.length]相等
  bool checkIfMatch({required List<num> values, required bool isHinted}) {
    assert(values.length == ranges.length);
    for (int i = 0;i < values.length;i++) {
      var range = ranges[i];
      var value = values[i];

      if (value > range['highBound'] || value < range['lowBound'] || isHinted != this.isHinted) {
        return false;
      }
    }

    return true;
  }
}

/// 题目评分规则
abstract class QuestionEvalRule {
  /// 本题的满分
  double fullScore;

  /// 答题限时，以秒为单位
  num timeLimit;

  /// 答题限时，以秒为单位
  @JsonKey(includeFromJson: false, includeToJson: false)
  int get ansTimeLimit => timeLimit.toInt();

  /// 作答情况不满足已设置的任意打分条件（[conditions]）时题目的得分
  double _defaultScore;
  double get defaultScore => _defaultScore;
  set defaultScore(double newScore) {
    if (newScore > fullScore) {
      throw ArgumentError("$newScore > $fullScore, defaultScore 必须小于等于 fullScore",);
    }
    _defaultScore = newScore;
  }

  /// 打分条件，打分规则由[evaluate]实现，一般是遍历打分规则直到找到第一个满足条件规则然后为作答赋分
  List<EvalCondition> conditions = [];

  /// 提示规则列表
  List<HintRule> hintRules = []; // 提示必须逐个触发，但一般就一个提示规则

  late String typeName;

  QuestionEvalRule({this.timeLimit = 20, this.fullScore = 10, double defaultScore = 0})
    : _defaultScore = defaultScore {
    typeName = runtimeType.toString();
  }

  factory QuestionEvalRule.fromJson(Map<String, dynamic> jsonMap) {
    var typeName = jsonMap['typeName'];
    switch (typeName) {
    // TODO: add types
      case "EvalAudioQuestionByKeywordsMatchesCount":
        return EvalAudioQuestionByKeywordsMatchesCount.fromJson(jsonMap);
      case "EvalAudioQuestionByKeywordMatch":
        return EvalAudioQuestionByKeywordMatch.fromJson(jsonMap);
      case "EvalAudioQuestionByPronunciation":
        return EvalAudioQuestionByPronunciation.fromJson(jsonMap);
      case "EvalAudioQuestionByFluency":
        return EvalAudioQuestionByFluency.fromJson(jsonMap);
      case "EvalAudioQuestionBySimilarity":
        return EvalAudioQuestionBySimilarity.fromJson(jsonMap);
      case "EvalAudioQuestionByWordType":
        return EvalAudioQuestionByWordType.fromJson(jsonMap);
      case "EvalCommandQuestionByCorrectActionCount":
        final tmp = EvalCommandQuestionByCorrectActionCount.fromJson(jsonMap);
        // debugPrint(jsonEncode(tmp.toJson()));
        return tmp;
      case "EvalChoiceQuestionByCorrectChoiceCount":
        return EvalChoiceQuestionByCorrectChoiceCount.fromJson(jsonMap);
      case "EvalWritingQuestionByCorrectKeywordCount":
        return EvalWritingQuestionByCorrectKeywordCount.fromJson(jsonMap);
      case "EvalWritingQuestionByMatchRate":
        return EvalWritingQuestionByMatchRate.fromJson(jsonMap);
      case "EvalItemFoundQuestion":
        return EvalItemFoundQuestion.fromJson(jsonMap);
      default:
        throw UnimplementedError("无效的QuestionEvalRule类型：$typeName");
    }
  }

  Map<String, dynamic> toJson();

  /// 部分题目需要请求后端来验证题目
  Future<QuestionResult> evaluate(QuestionResult result);

  void setScoreByConditions (QuestionResult result, num answerResult) {
    for (var condition in conditions) {
      List<num> valueArr;
      if (condition.ranges.length == 1) {
        valueArr = [answerResult];
      } else {
        valueArr = [answerResult, result.answerTime!];
      }

      if (condition.checkIfMatch(values: valueArr, isHinted: result.isHinted)) {
        result.finalScore = condition.score;
        break;
      }
    }
  }

  HintRule? getMatchHintRule(double score) {
    for (var hintRule in hintRules) {
      if (hintRule.checkIfMatch(score)) {
        return hintRule;
      }
    }
    return null;
  }

  String getScoreConditionName();

  String? checkSetting() {
    if (conditions.isEmpty) {
      return "请至少设置一条得分条件";
    }
    return null;
  }


  void addEvalCondition(EvalCondition condition) {
    conditions.add(condition);
  }

  void updateEvalCondition({required EvalCondition updated, required int index}) {
    assert(index >= 0 && index < conditions.length);
    conditions[index] = updated;
  }

  void deleteEvalCondition(int index) {
    assert(index >= 0 && index < conditions.length);
    conditions.removeAt(index);
  }

  void moveUpEvalCondition(int index) {
    assert(index >= 0 && index < conditions.length);
    if (index == 0) {
      return;
    }
    final tmp = conditions[index];
    conditions[index] = conditions[index - 1];
    conditions[index - 1] = tmp;
  }

  void moveDownEvalCondition(int index) {
    assert(index >= 0 && index < conditions.length);
    if (index == conditions.length - 1) {
      return;
    }
    final tmp = conditions[index];
    conditions[index] = conditions[index + 1];
    conditions[index + 1] = tmp;
  }

  void addHintRule(HintRule rule) {
    hintRules.add(rule);
  }

  void deleteHintRule(int index) {
    assert(index < hintRules.length && index >= 0);
    hintRules.removeAt(index);
  }

  void updateHintRule({required HintRule updated, required int index}) {
    assert(index >= 0 && index < hintRules.length);
    hintRules[index] = updated;
  }

  void moveUpHintRule(int index) {
    assert(index >= 0 && index < hintRules.length);
    if (index == 0) {
      return;
    }

    final tmp = hintRules[index];
    hintRules[index] = hintRules[index - 1];
    hintRules[index - 1] = tmp;
  }

  void moveDownHintRule(int index) {
    assert(index >= 0 && index < hintRules.length);
    if (index == hintRules.length - 1) {
      return;
    }
    final tmp = hintRules[index];
    hintRules[index] = hintRules[index + 1];
    hintRules[index + 1] = tmp;
  }


}

// ******************************* 录音题规则
/// 录音题 - 按关键字正确个数计分
@JsonSerializable(explicitToJson: true)
class EvalAudioQuestionByKeywordsMatchesCount extends QuestionEvalRule with FuzzyEvalSetting, KeywordList, AnswerOrder {
  EvalAudioQuestionByKeywordsMatchesCount({super.defaultScore, List<String>? keywords, bool fuzzy = true, bool enforceOrder = false}) {
    enableFuzzyEvaluation = fuzzy;
    if (keywords != null) {
      this.keywords = keywords;
    }

    this.enforceOrder = enforceOrder;
  }

  static String ruleDisplayName() {
    return "按关键字正确个数计分";
  }

  factory EvalAudioQuestionByKeywordsMatchesCount.fromJson(Map<String, dynamic> jsonMap) => _$EvalAudioQuestionByKeywordsMatchesCountFromJson(jsonMap);

  @override
  Map<String, dynamic> toJson() => _$EvalAudioQuestionByKeywordsMatchesCountToJson(this);

  @override
  Future<QuestionResult> evaluate(QuestionResult result) async {
    result = result as AudioQuestionResult;

    // TODO: 有时间考虑发送请求到后端用拼音做一下判断
    // if (!enableFuzzyEvaluation) {
    int count = 0;
    for (var keyword in keywords) {
      if (result.audioContent.contains(keyword)) {
        count++;
      }
    }
    //
    // } else {
    // }

    setScoreByConditions(result, count);

    result.finalScore ??= defaultScore;

    result.extraResults['患者说话内容'] = result.audioContent;
    result.extraResults['关键词列表'] = keywords.fold("", (prev, e) => prev == ""? e :"$prev, $e");
    result.extraResults['关键词正确个数'] = count.toString();
    result.extraResults['是否要求关键词按顺序说出'] = enforceOrder ? "是": "否";

    return result;
  }

  @override
  String? checkSetting() {
    String? errMsg = super.checkSetting();
    if (errMsg != null) {
      return errMsg;
    }

    if (keywords.isEmpty) {
      return "请至少设置一个关键词";
    }
    return null;
  }

  @override
  String getScoreConditionName() {
    return "关键词正确个数";
  }
}

/// 录音题 - 单个关键字内容正确
@JsonSerializable(explicitToJson: true)
class EvalAudioQuestionByKeywordMatch extends QuestionEvalRule with FuzzyEvalSetting, RuleKeyword {
  EvalAudioQuestionByKeywordMatch({super.defaultScore, String keyword = "关键词", bool fuzzy = true}) {
    enableFuzzyEvaluation = fuzzy;
    this.keyword = keyword;
  }

  static String ruleDisplayName() {
    return "语音内容是否正确（单个关键字）";
  }

  factory EvalAudioQuestionByKeywordMatch.fromJson(Map<String, dynamic> jsonMap) => _$EvalAudioQuestionByKeywordMatchFromJson(jsonMap);

  @override
  Map<String, dynamic> toJson() => _$EvalAudioQuestionByKeywordMatchToJson(this);

  @override
  Future<QuestionResult> evaluate(QuestionResult result) async {
    result = result as AudioQuestionResult;
    // TODO：有时间做发送请求到后端用拼音判分
    int count = 0;
    if (enableFuzzyEvaluation) {
      if (result.audioContent.contains(keyword)) {
        count = 1;
      }
    } else {
      if (result.audioContent.contains(keyword)) {
        count = 1;
      }
    }

    setScoreByConditions(result, count);

    result.finalScore ??= defaultScore;

    result.extraResults['患者说话内容'] = result.audioContent;
    result.extraResults['关键词'] = keyword;
    result.extraResults['关键词正确字数'] = count.toString();

    return result;
  }

  @override
  String? checkSetting() {
    String? errMsg = super.checkSetting();
    if (errMsg != null) {
      return errMsg;
    }
    return null;
  }

  @override
  String getScoreConditionName() {
    return "关键词正确个数";
  }
}

/// 录音题 - 按关键词发音（音素）正确个数
@JsonSerializable(explicitToJson: true)
class EvalAudioQuestionByPronunciation extends QuestionEvalRule with FuzzyEvalSetting, RuleKeyword {

  EvalAudioQuestionByPronunciation({super.defaultScore, String keyword = "关键词", bool fuzzy = true}) {
    enableFuzzyEvaluation = fuzzy;
    this.keyword = keyword;
  }

  static String ruleDisplayName() {
    return "按关键词发音中拼音音节正确个数";
  }

  factory EvalAudioQuestionByPronunciation.fromJson(Map<String, dynamic> jsonMap) => _$EvalAudioQuestionByPronunciationFromJson(jsonMap);

  @override
  Map<String, dynamic> toJson() => _$EvalAudioQuestionByPronunciationToJson(this);

  @override
  Future<QuestionResult> evaluate(QuestionResult result) async {
    // TODO: implement evaluate
    throw UnimplementedError();
  }

  @override
  String? checkSetting() {
    String? errMsg = super.checkSetting();
    if (errMsg != null) {
      return errMsg;
    }
    return null;
  }

  @override
  String getScoreConditionName() {
    return "关键词音节正确个数";
  }
}

/// 录音题 - 言语流畅度评分
@JsonSerializable(explicitToJson: true)
class EvalAudioQuestionByFluency extends QuestionEvalRule {

  EvalAudioQuestionByFluency({super.defaultScore, });

  factory EvalAudioQuestionByFluency.fromJson(Map<String, dynamic> jsonMap) {
    return _$EvalAudioQuestionByFluencyFromJson(jsonMap);
  }

  static String ruleDisplayName() {
    return "言语流畅度评分";
  }

  @override
  Future<QuestionResult> evaluate(QuestionResult result) async {
    result = result as AudioQuestionResult;
    final json = await audioFluency(result.rawPcm16Data!);
    result.audioContent = json['content'];
    double fluency = json['fluency'];
    result.finalScore = (fullScore / 10 * fluency).roundToDouble();

    result.extraResults['患者说话内容'] = result.audioContent;

    result.extraResults['流利性情况说明'] = json['detail'];

    return result;
  }

  @override
  Map<String, dynamic> toJson() {
    return _$EvalAudioQuestionByFluencyToJson(this);
  }

  @override
  String? checkSetting() {
    return null;
  }

  @override
  String getScoreConditionName() {
    return "";
  }
}

/// 录音题 - 按文本大意相似度
@JsonSerializable(explicitToJson: true)
class EvalAudioQuestionBySimilarity extends QuestionEvalRule with FuzzyEvalSetting, LongAnswer {
  double fullScoreThreshold;

  EvalAudioQuestionBySimilarity({super.defaultScore, this.fullScoreThreshold = 0.8, String? answerText, bool fuzzy = true}) {
    enableFuzzyEvaluation = fuzzy;
    if (answerText != null) {
      this.answerText = answerText;
    }
  }

  factory EvalAudioQuestionBySimilarity.fromJson(Map<String, dynamic> jsonMap) {
    return _$EvalAudioQuestionBySimilarityFromJson(jsonMap);
  }
  @override
  Map<String, dynamic> toJson() {
    return _$EvalAudioQuestionBySimilarityToJson(this);
  }

  static String ruleDisplayName() {
    return "按语音内容与答案文本相似度评分";
  }

  @override
  Future<QuestionResult> evaluate(QuestionResult result) async {
    result = result as AudioQuestionResult;
    double sim = await textSimilarity(result.audioContent, answerText);

    debugPrint("文本相似度: $sim");
    if (enableFuzzyEvaluation) {
      result.finalScore =  sim >= 0.6 ? fullScore : 0;
    }  else {
      result.finalScore = (fullScore * sim).roundToDouble();
    }

    result.finalScore ??= _defaultScore;

    result.extraResults['患者说话内容'] = result.audioContent;
    result.extraResults['答案文本'] = answerText;
    result.extraResults['相似度'] = '${(sim * 100).toStringAsFixed(1)}%';

    return result;
  }

  @override
  String? checkSetting() {
    return null;
  }

  @override
  String getScoreConditionName() {
    return "";
  }
}

/// 录音题 - 音频内容中特定词性的词语个数
@JsonSerializable(explicitToJson: true)
class EvalAudioQuestionByWordType extends QuestionEvalRule {
  /// 1表示动词，2表示名词
  int wordType;

  EvalAudioQuestionByWordType({this.wordType = 1, });

  factory EvalAudioQuestionByWordType.fromJson(Map<String, dynamic> jsonMap) {
    return _$EvalAudioQuestionByWordTypeFromJson(jsonMap);
  }

  @override
  Map<String, dynamic> toJson() {
    return _$EvalAudioQuestionByWordTypeToJson(this);
  }


  static String ruleDisplayName() {
    return "按语音内容中特定词性的词语个数评分";
  }

  @override
  Future<QuestionResult> evaluate(QuestionResult result) async {
    // TODO: implement evaluate
    throw UnimplementedError();
  }

  @override
  String? checkSetting() {
    String? errMsg = super.checkSetting();
    if (errMsg != null) {
      return errMsg;
    }
    return null;
  }

  @override
  String getScoreConditionName() {
    return "词性正确的词语个数";
  }
}

// ******************************* 选择题规则
/// 选择题选项类
@JsonSerializable()
class Choice {
  String? imageUrl;
  String? imageAssetPath;
  String text;

  @JsonKey(includeToJson: false, includeFromJson: false)
  String? get imageUrlOrPath => imageUrl ?? imageAssetPath;

  Choice({this.imageUrl, this.imageAssetPath, this.text = "新选项"});

  factory Choice.fromJson(Map<String, dynamic> jsonMap) {
    return _$ChoiceFromJson(jsonMap);
  }

  Map<String, dynamic> toJson() {
    return _$ChoiceToJson(this);
  }
}

/// 选择题 - 按正确选择个数计分
/// 注意不要直接向[choice]末尾之外的位置进行插入操作，否则会导致[correctChoice]错乱
@JsonSerializable(explicitToJson: true)
class EvalChoiceQuestionByCorrectChoiceCount extends QuestionEvalRule with AnswerOrder {
  List<Choice> choices = [];
  List<int> correctChoices = [];

  EvalChoiceQuestionByCorrectChoiceCount({super.defaultScore, bool enforceOrder = false}) {
    this.enforceOrder = enforceOrder;
  }

  static String ruleDisplayName() {
    return "按正确选择个数计分";
  }

  factory EvalChoiceQuestionByCorrectChoiceCount.fromJson(Map<String, dynamic> jsonMap) {
    return _$EvalChoiceQuestionByCorrectChoiceCountFromJson(jsonMap);
  }

  @override
  Map<String, dynamic> toJson() {
    return _$EvalChoiceQuestionByCorrectChoiceCountToJson(this);
  }

  @override
  Future<QuestionResult> evaluate(QuestionResult result) async {
    result = result as ChoiceQuestionResult;
    List<int> selected = result.choiceSelected;
    int count = 0;

    if (enforceOrder) {
      count = LCS(selected, correctChoices);
    } else {
      for (var selection in selected) {
        if (correctChoices.contains(selection)) {
          count++;
        }
      }
    }

    setScoreByConditions(result, count);

    result.finalScore ??= defaultScore;

    String selectedAsString = selected.fold("", (prev, e) => prev == ""?"$e": "$prev, $e");
    String correctChoicesAsString = correctChoices.fold("", (prev, e) => prev == ""?"$e": "$prev, $e");

    result.extraResults['题目是否要求按顺序选择选项'] = enforceOrder ? "是": "否";
    result.extraResults['正确选项'] = correctChoicesAsString;
    result.extraResults['患者选择的选项'] = selectedAsString;
    result.extraResults['患者正确选项数'] = count.toString();

    return result;
  }

  @override
  String getScoreConditionName() {
    return "正确选择选项个数";
  }

  void _checkChoiceIndex(int index) {
    if (index < 0 || index >= choices.length) {
      throw RangeError.index(index, choices);
    }
  }

  void _updateCorrectChoiceAfterMove(int index1, int index2) {
    for (int i = 0;i < correctChoices.length;i++) {
      if (correctChoices[i] == index1) {
        correctChoices[i] = index2;
      } else if (correctChoices[i] == index2) {
        correctChoices[i] = index1;
      }
    }
  }

  Choice deleteChoice(int index) {
    _checkChoiceIndex(index);

    final removed = choices.removeAt(index);
    for (int i = 0;i < correctChoices.length;i++) {
      if (correctChoices[i] == index) {
        correctChoices.removeAt(i);
      } else if (correctChoices[i] > index) {
        correctChoices[i]--;
      }
    }
    return removed;
  }

  void moveChoiceUp(int index) {
    _checkChoiceIndex(index);

    if (index > 0) {
      final tmp = choices[index - 1];
      choices[index - 1] = choices[index];
      choices[index] = tmp;

      _updateCorrectChoiceAfterMove(index, index - 1);
    }
  }

  void moveChoiceDown(int index) {
    _checkChoiceIndex(index);

    if (index < choices.length - 1) {
      final tmp = choices[index + 1];
      choices[index + 1] = choices[index];
      choices[index] = tmp;

      _updateCorrectChoiceAfterMove(index, index + 1);
    }
  }

  @override
  String? checkSetting() {
    String? errMsg = super.checkSetting();
    if (errMsg != null) {
      return errMsg;
    }

    if (choices.length < 2) {
      return "请至少设置两个选项";
    }
    if (correctChoices.isEmpty) {
      return "请至少设置一个正确选项";
    }
    return null;
  }
}

// ******************************* 指令题规则
/// 指令题物体区域类
@JsonSerializable()
class ItemSlot {
  String? itemName;
  String? itemImageUrl;
  String? itemImageAssetPath;

  ItemSlot({this.itemName, this.itemImageUrl, this.itemImageAssetPath});

  factory ItemSlot.fromJson(Map<String, dynamic> jsonMap) => _$ItemSlotFromJson(jsonMap);

  Map<String, dynamic> toJson() => _$ItemSlotToJson(this);

  ItemSlot copy () {
    return ItemSlot.fromJson(jsonDecode(jsonEncode(toJson())));
  }

  void setItem(String itemName, String itemImageUrl) {
    this.itemName = itemName;
    this.itemImageUrl = itemImageUrl;
    itemImageAssetPath = null;
  }

  void setItemWithBuiltInImage(String itemName, String itemImageAssetPath) {
    this.itemName = itemName;
    this.itemImageAssetPath = itemImageAssetPath;
    itemImageUrl = null;
  }
}

/// 指令题操作类
@JsonSerializable(explicitToJson: true)
class CommandActions {
  int sourceSlotIndex;
  ClickAction firstAction;
  int? targetSlotIndex;
  PutDownAction? secondAction;

  CommandActions({required this.sourceSlotIndex, required this.firstAction, this.targetSlotIndex, this.secondAction});

  factory CommandActions.fromJson(Map<String, dynamic> jsonMap) => _$CommandActionsFromJson(jsonMap);

  Map<String, dynamic> toJson() => _$CommandActionsToJson(this);

  void setSecondAction(int itemIndex, PutDownAction action) {
    secondAction = action;
    targetSlotIndex = itemIndex;
  }

  @override
  bool operator ==(Object other) {
    if (other is! CommandActions) return false;
    CommandActions o = other;
    return sourceSlotIndex == o.sourceSlotIndex && firstAction == o.firstAction
        && targetSlotIndex == o.targetSlotIndex && secondAction == o.secondAction;
  }

  @override
  int get hashCode => super.hashCode;
}

/// 指令题 - 正确动作个数或动作拆分后
@JsonSerializable(explicitToJson: true)
class EvalCommandQuestionByCorrectActionCount extends QuestionEvalRule {
  int _slotCount;

  @JsonKey(includeFromJson: false, includeToJson: false)
  int get slotCount => _slotCount;
  set slotCount(int newCount) {
    assert(newCount == 10 || newCount == 20);
    while(slots.length > newCount) {
      slots.removeLast();
    }

    while(slots.length < newCount) {
      slots.add(ItemSlot());
    }

    _slotCount = slots.length;
  }

  List<ItemSlot> slots = [];
  List<CommandActions> actions = [];

  /// 患者进行了额外的无效动作时的扣分值
  double invalidActionPunishment;

  /// 动作拆分模式
  bool detailMode;

  /// 系统生成的正确操作对应文本
  String? commandText;

  EvalCommandQuestionByCorrectActionCount({super.defaultScore, int slotCount = 10, this.invalidActionPunishment = 0, this.detailMode = false})
    : assert(slotCount == 10 || slotCount == 20),
      _slotCount = slotCount {

    for (int i = 0;i < _slotCount;i++) {
      slots.add(ItemSlot());
    }
  }

  static String ruleDisplayName() {
    return "按正确动作个数或动作拆分后正确单位计分";
  }

  String generateCommandTextFromActions(List<CommandActions> actions) {
    List<StackableItemSlot> board = slots.map((e) => e.itemName != null ? StackableItemSlot(e) : StackableItemSlot()).toList();
    String text = actions.length > 1 ? "先" : "";

    for (var i = 0;i < actions.length;i++) {
      final action = actions[i];
      final sourceSlot = board[action.sourceSlotIndex];
      final item1 = sourceSlot.peekItem()!;

      switch (action.firstAction) {
        case ClickAction.touch:
          text += "指一下${item1.itemName}";
          break;
        case ClickAction.take:
          final targetSlot = board[action.targetSlotIndex!];
          final item2 = targetSlot.peekItem();

          text += "拿起${item1.itemName}";
          if (item2 != null) {
            if (item1 == item2) {
              text += "后放回原处";
            } else {
              text += "盖在${item2.itemName}上";
            }
          } else {
            int left = action.targetSlotIndex! % 5 - 1 >= 0 ? action.targetSlotIndex! - 1 : -1;
            int up = action.targetSlotIndex! - 5;
            int right = action.targetSlotIndex! % 5 + 1 <= 4 ? action.targetSlotIndex! + 1 : _slotCount;
            int down = action.targetSlotIndex! + 5;
            String sameItemExtraText = "";
            if (left >= 0 && board[left].peekItem() != null) {
              if (board[left].peekItem()!.itemName == item1.itemName) {
                sameItemExtraText = "现在的位置的";
              }
              text += "放在${board[left].peekItem()!.itemName}$sameItemExtraText右边";
            } else if (up >= 0 && board[up].peekItem() != null) {
              if (board[up].peekItem()!.itemName == item1.itemName) {
                sameItemExtraText = "现在的位置的";
              }
              text += "放在${board[up].peekItem()!.itemName}$sameItemExtraText下边";
            } else if (right <= _slotCount - 1 && board[right].peekItem() != null) {
              if (board[right].peekItem()!.itemName == item1.itemName) {
                sameItemExtraText = "现在的位置的";
              }
              text += "放在${board[right].peekItem()!.itemName}$sameItemExtraText左边";
            } else if (down <= _slotCount - 1 && board[down].peekItem() != null) {
              if (board[down].peekItem()!.itemName == item1.itemName) {
                sameItemExtraText = "现在的位置的";
              }
              text += "放在${board[down].peekItem()!.itemName}$sameItemExtraText上边";
            } else {
              text += "放在第${action.targetSlotIndex! % 4 + 1}行第${action.targetSlotIndex! % 5 + 1}列的格子上";
            }
          }

          targetSlot.pushItem(sourceSlot.popItem()!);
        default:
          throw UnimplementedError("该动作未实现");
      }
      if (i != actions.length - 1) {
        text += "，再";
      }
    }

    return text;
  }

  factory EvalCommandQuestionByCorrectActionCount.fromJson(Map<String, dynamic> jsonMap) {
    final tmp = _$EvalCommandQuestionByCorrectActionCountFromJson(jsonMap);
    // debugPrint(jsonEncode(jsonMap));
    return tmp;
  }

  @override
  Map<String, dynamic> toJson() => _$EvalCommandQuestionByCorrectActionCountToJson(this);

  @override
  Future<QuestionResult> evaluate(QuestionResult result) async {
    final res = result as CommandQuestionResult;

    List<CommandActions> correctActions = [];
    final answerActionListCopy = List.of(actions);
    for (int i = 0;i < res.actions.length;i++) {
      var userAction = res.actions[i];

      for (int j = 0;j < answerActionListCopy.length;j++) {
        var answerAction = answerActionListCopy[j];
        if (userAction == answerAction) {
          correctActions.add(userAction);
          answerActionListCopy.removeAt(j);
        }
      }
    }

    debugPrint("用户正确动作：${jsonEncode(correctActions.map((e) => e.toJson()).toList())}");

    int maxOrderedCount = LCS(correctActions, res.actions);

    int count;
    if (!detailMode) {
      count = correctActions.length;
      if (maxOrderedCount != correctActions.length) {
        count--;
      }
    } else {
      count = 0;
      for (var action in correctActions) {
        if (action.secondAction != null) {
          count += 4;
        } else {
          count += 2;
        }
      }

      count -= (correctActions.length - maxOrderedCount);
    }

    // debugPrint("count Unit: ${count.toString()}");
    setScoreByConditions(result, count);

    result.finalScore ??= defaultScore;

    if (invalidActionPunishment != 0 && correctActions.length != actions.length) {
      result.finalScore = max(0, result.finalScore! - invalidActionPunishment);
    }

    result.extraResults['患者操作'] = generateCommandTextFromActions(res.actions);
    result.extraResults['正确指令'] = generateCommandTextFromActions(actions);
    result.extraResults['动作（单位）正确个数'] = (detailMode ? count : correctActions.length).toString();
    result.extraResults['动作顺序错误个数'] = (correctActions.length - maxOrderedCount).toString();
    result.extraResults['动作顺序错误扣分值'] = (detailMode ? (correctActions.length - maxOrderedCount) : 1).toString();
    result.extraResults['无效动作个数'] = (res.actions.length - correctActions.length).toString();
    result.extraResults['无效动作扣分值'] = ((res.actions.length - correctActions.length) * invalidActionPunishment).toString();

    return result;
  }

  @override
  String? checkSetting() {
    String? errMsg = super.checkSetting();
    if (errMsg != null) {
      return errMsg;
    }

    if (slots.where((element) => element.itemName != null).isEmpty) {
      return "请至少在一个区域中设置一个物体";
    }

    if (actions.isEmpty) {
      return "录制动作未完成，请录制动作";
    }

    return null;
  }

  @override
  String getScoreConditionName() {
    return "正确动作（动作单位）个数";
  }

  Map<int, ItemSlot> getSlotsWithItem() {
    final slotsWithItem = <int, ItemSlot>{};
    for (var i = 0;i < slots.length;i++) {
      final slot = slots[i];
      if (slot.itemName != null) {
        slotsWithItem[i] = slot;
      }
    }
    return slotsWithItem;
  }

  int indexOfItemName(String itemName) {
    for (var i = 0;i< slots.length;i++) {
      var slot = slots[i];
      if (slot.itemName == itemName) {
        return i;
      }
    }
    return -1;
  }

  void setItemSlot(int index, ItemSlot slot) {
    assert(index < slotCount && index >= 0);
    if (slot.itemName == null) {
      actions = [];
      commandText = "";
    }
    slots[index] = slot;
  }

  String updateActions(List<CommandActions> actions) {
    this.actions = actions;
    commandText = generateCommandTextFromActions(actions);
    return commandText!;
  }

}

// ******************************* 书写题规则
/// 书写题 - 按关键词正确个数
@JsonSerializable(explicitToJson: true)
class EvalWritingQuestionByCorrectKeywordCount extends QuestionEvalRule with FuzzyEvalSetting, KeywordList {
  EvalWritingQuestionByCorrectKeywordCount({super.defaultScore, bool fuzzy = true, List<String>? keywords}) {
    enableFuzzyEvaluation = fuzzy;
    if (keywords != null) {
      this.keywords = keywords;
    }
  }

  static String ruleDisplayName() {
    return "按关键词正确个数计分";
  }

  factory EvalWritingQuestionByCorrectKeywordCount.fromJson(Map<String, dynamic> jsonMap) {
    return _$EvalWritingQuestionByCorrectKeywordCountFromJson(jsonMap);
  }

  @override
  Map<String, dynamic> toJson() {
    return _$EvalWritingQuestionByCorrectKeywordCountToJson(this);
  }

  @override
  Future<QuestionResult> evaluate(QuestionResult result) async {
    WritingQuestionResult res = result as WritingQuestionResult;
    assert(res.handWriteImageData != null);

    String ansContent = await handWritingRecognize(res.handWriteImageData!);
    debugPrint("识别结果：$ansContent");

    int count = 0;

    for (int i = 0;i < keywords.length;i++) {
      if (ansContent.contains(keywords[i])) {
        count++;
        debugPrint("关键词${keywords[i]}在答案中，count++");
      }
    }
    debugPrint("一共有$count个关键词正确");

    setScoreByConditions(result, count);

    res.finalScore ??= defaultScore;

    result.extraResults['患者书写内容'] = ansContent;
    result.extraResults['关键词列表'] = keywords.fold("", (prev, e) => prev == ""? e :"$prev, $e");
    result.extraResults['关键词正确个数'] = count.toString();

    return res;
  }

  @override
  String? checkSetting() {
    String? errMsg = super.checkSetting();
    if (errMsg != null) {
      return errMsg;
    }
    if (keywords.isEmpty) {
      return "请至少设置一个关键词";
    }
    return null;
  }

  @override
  String getScoreConditionName() {
    return "关键词正确个数";
  }
}

/// 书写题 - 单个关键词/字正确字数（正确百分比）
@JsonSerializable(explicitToJson: true)
class EvalWritingQuestionByMatchRate extends QuestionEvalRule with FuzzyEvalSetting, RuleKeyword {
  EvalWritingQuestionByMatchRate({super.defaultScore, String keyword = "关键词", bool fuzzy = true}) {
    enableFuzzyEvaluation = fuzzy;
    this.keyword = keyword;
  }

  static String ruleDisplayName() {
    return "按单个关键词/字正确字数计分";
  }

  factory EvalWritingQuestionByMatchRate.fromJson(Map<String, dynamic> jsonMap) {
    return _$EvalWritingQuestionByMatchRateFromJson(jsonMap);
  }

  @override
  Map<String, dynamic> toJson() {
    return _$EvalWritingQuestionByMatchRateToJson(this);
  }

  @override
  Future<QuestionResult> evaluate(QuestionResult result) async {
    WritingQuestionResult res = result as WritingQuestionResult;
    assert(res.handWriteImageData != null);

    String ansContent = await handWritingRecognize(res.handWriteImageData!);
    debugPrint("识别结果：$ansContent");

    int count = 0;

    String keywordContent = keyword;

    for (int i = 0;i < ansContent.length;i++) {
      String char = ansContent.substring(i, i + 1);
      int index = keywordContent.indexOf(char);
      if (index != -1) {
        debugPrint("$char 在 $keywordContent中，count++");
        count++;
        keywordContent = keywordContent.substring(0 , index) + (index == keywordContent.length - 1 ? "": keywordContent.substring(index + 1));
      }
    }
    debugPrint("一共有$count个字正确");

    setScoreByConditions(result, count);

    res.finalScore ??= defaultScore;

    result.extraResults['患者书写内容'] = ansContent;
    result.extraResults['关键词'] = keyword;
    result.extraResults['关键词正确字数'] = count.toString();

    return res;
  }

  @override
  String? checkSetting() {
    String? errMsg = super.checkSetting();
    if (errMsg != null) {
      return errMsg;
    }
    return null;
  }

  @override
  String getScoreConditionName() {
    return "关键词中正确字数";
  }
}

// ******************************* 场景寻物题规则
/// 场景寻物题
@JsonSerializable(explicitToJson: true)
class EvalItemFoundQuestion extends QuestionEvalRule {
  String? imageUrl;
  List<List<double>> coordinates = [];

  EvalItemFoundQuestion({super.defaultScore});

  static String ruleDisplayName() {
    return "按点击区域评分";
  }

  factory EvalItemFoundQuestion.fromJson(Map<String, dynamic> jsonMap) {
    return _$EvalItemFoundQuestionFromJson(jsonMap);
  }

  @override
  Map<String, dynamic> toJson() {
    return _$EvalItemFoundQuestionToJson(this);
  }

  @override
  Future<QuestionResult> evaluate(QuestionResult result) async {
    ItemFindingQuestionResult res = result as ItemFindingQuestionResult;

    int count = 0;
    // debugPrint("用户点: ${res.clickCoordinate.toString()}");
    // debugPrint("poly: ${coordinates.toString()}");
    if (res.clickCoordinate != null && checkPointInPolygon(res.clickCoordinate!, coordinates)) {
      count = 1;
    }

    setScoreByConditions(result, count);

    res.finalScore ??= defaultScore;

    result.extraResults['患者是否正确点击目标区域'] = count == 1?"是" : "否";

    return result;
  }

  @override
  String? checkSetting() {
    String? errMsg = super.checkSetting();
    if (errMsg != null) {
      return errMsg;
    }
    if (imageUrl == null) {
      return "请设置一张题干图片然后在图片上设置点击区域";
    }

    if (coordinates.length < 3) {
      return "未完成点击区域设置，请先完成";
    }

    assert(convexHull(coordinates).length == coordinates.length);

    return null;
  }

  void addPoint(double x, double y) {
    if (x <= 1.0 && x >= 0.0 && y <= 1.0 && y >= 0) {
      throw UnimplementedError();
    } else {
      throw ArgumentError("点的坐标值必须规范化，在0 - 1之间。x = $x, y = $y");
    }
  }

  @override
  String getScoreConditionName() {
    return "正确点击区域数";
  }
}
