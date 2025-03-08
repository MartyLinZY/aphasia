import 'dart:convert';

import 'package:aphasia_recovery/enum/fake_reflection.dart';
import 'package:aphasia_recovery/mixin/widgets_mixin.dart';
import 'package:aphasia_recovery/models/result/results.dart';
import 'package:aphasia_recovery/settings.dart';
import 'package:aphasia_recovery/models/rules.dart';
import 'package:aphasia_recovery/widgets/ui/do_exam/Item_finding_question.dart';
import 'package:aphasia_recovery/widgets/ui/do_exam/audio_question.dart';
import 'package:aphasia_recovery/widgets/ui/do_exam/choice_question.dart';
import 'package:aphasia_recovery/widgets/ui/do_exam/command_question.dart';
import 'package:aphasia_recovery/widgets/ui/do_exam/writing_question.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../utils/io/file.dart';

part 'question.g.dart';

abstract class Question {
  // 对于非录音题的题干图片最大展示时间
  static const int maxOmitTime = 10;

  String? _id;

  /// 题目别名
  String? alias;

  /// 题干文本
  String? questionText;

  /// 题干音频
  String? audioUrl;

  /// 题干图片
  String? imageUrl;

  /// 题干图片展示时间，以秒为单位，需要为正整数，对录音题来说可以设为-1来表示始终显示图片
  int omitImageAfterSeconds;

  late String typeName;

  QuestionEvalRule? evalRule;

  String? get id => _id;

  /// 该属性仅在测试函数中时可直接赋值，对于测试代码，请在代码开头写上TestBase.commonSetup()
  set id(String? newId) {
    if (AppSettings.testMode) {
      _id = newId;
    } else {
      throw Exception(AppSettings.notInTestModeErrMsg);
    }
  }

  static Future<Question> updateQuestion(Question updated) async {
    return await Future.delayed(const Duration(seconds: 1), () => updated);
  }

  Question(
      {String? id,
      this.alias,
      this.questionText,
      this.audioUrl,
      this.imageUrl,
      int? omitImageAfterSeconds,
      this.evalRule})
      : _id = id,
        omitImageAfterSeconds = maxOmitTime  {
    typeName = runtimeType.toString();
    if (omitImageAfterSeconds != null) {
      this.omitImageAfterSeconds = omitImageAfterSeconds;
    }
  }

  factory Question.fromJson(Map<String, dynamic> jsonMap) {
    assert(jsonMap['typeName'] != null);

    switch (jsonMap['typeName']) {
      case "AudioQuestion":
        return AudioQuestion.fromJson(jsonMap);
      case "ChoiceQuestion":
        return ChoiceQuestion.fromJson(jsonMap);
      case "CommandQuestion":
        return CommandQuestion.fromJson(jsonMap);
      case "WritingQuestion":
        return WritingQuestion.fromJson(jsonMap);
      case "ItemFindingQuestion":
        return ItemFindingQuestion.fromJson(jsonMap);
      default:
        throw UnimplementedError("Invalid question type${jsonMap['typeName']}");
    }
  }

  Map<String, dynamic> toJson();

  Question copy() {
    return Question.fromJson(jsonDecode(jsonEncode(this)));
  }

  String defaultQuestionName();

  Widget buildAnswerAreaWidget(BuildContext context, {
    required CommonStyles? commonStyles,
    required void Function(QuestionResult) goToNextQuestion,
  });
}

@JsonSerializable(explicitToJson: true)
class AudioQuestion extends Question {
  AudioQuestion({
    super.id,
    super.alias,
    super.questionText,
    super.audioUrl,
    super.imageUrl,
    super.omitImageAfterSeconds,
    super.evalRule,
  }) {
    evalRule ??= EvalAudioQuestionByKeywordMatch(keyword: "关键词");
  }

  /// 返回的map中，key为可用的评分规则，value是一个返回一个key对应类型对象的函数
  static Map<Type, dynamic> availableEvalRuleTypes() {
    return {
      EvalAudioQuestionByKeywordsMatchesCount: {
        ClassProperties.constructor: () =>
            EvalAudioQuestionByKeywordsMatchesCount(),
        ClassProperties.displayName:
            EvalAudioQuestionByKeywordsMatchesCount.ruleDisplayName(),
      },
      EvalAudioQuestionByKeywordMatch: {
        ClassProperties.constructor: () => EvalAudioQuestionByKeywordMatch(),
        ClassProperties.displayName:
            EvalAudioQuestionByKeywordMatch.ruleDisplayName(),
      },
      // EvalAudioQuestionByPronunciation: {
      //   ClassProperties.constructor: () => EvalAudioQuestionByPronunciation(),
      //   ClassProperties.displayName:
      //       EvalAudioQuestionByPronunciation.ruleDisplayName(),
      // },
      EvalAudioQuestionByFluency: {
        ClassProperties.constructor: () => EvalAudioQuestionByFluency(),
        ClassProperties.displayName:
            EvalAudioQuestionByFluency.ruleDisplayName(),
      },
      EvalAudioQuestionBySimilarity: {
        ClassProperties.constructor: () => EvalAudioQuestionBySimilarity(),
        ClassProperties.displayName:
            EvalAudioQuestionBySimilarity.ruleDisplayName(),
      },
      // EvalAudioQuestionByWordType: {
      //   ClassProperties.constructor: () => EvalAudioQuestionByWordType(),
      //   ClassProperties.displayName:
      //       EvalAudioQuestionByWordType.ruleDisplayName()
      // }
      // 后续添加
    };
  }

  static String questionTypeName() {
    return "录音作答题";
  }

  factory AudioQuestion.fromJson(Map<String, dynamic> jsonMap) {
    return _$AudioQuestionFromJson(jsonMap);
  }

  @override
  Map<String, dynamic> toJson() {
    return _$AudioQuestionToJson(this);
  }

  @override
  String defaultQuestionName() {
    return questionTypeName();
  }

  @override
  Widget buildAnswerAreaWidget(BuildContext context, {
    required CommonStyles? commonStyles,
    required void Function(QuestionResult) goToNextQuestion,
  }) {
    return AudioQuestionAnswerArea(
        question: this,
        commonStyles: commonStyles,
        goToNextQuestion: goToNextQuestion,);
  }
}

@JsonSerializable(explicitToJson: true)
class ChoiceQuestion extends Question {
  ChoiceQuestion({
    super.id,
    super.alias,
    super.questionText,
    super.audioUrl,
    super.imageUrl,
    super.omitImageAfterSeconds,
    super.evalRule,
  }) {
    evalRule ??= EvalChoiceQuestionByCorrectChoiceCount();
  }

  /// 返回的map中，key为可用的评分规则，value是一个返回一个key对应类型对象的函数
  static Map<Type, dynamic> availableEvalRuleTypes() {
    return {
      EvalChoiceQuestionByCorrectChoiceCount: {
        ClassProperties.constructor: () =>
            EvalChoiceQuestionByCorrectChoiceCount(),
        ClassProperties.displayName:
            EvalChoiceQuestionByCorrectChoiceCount.ruleDisplayName(),
      },
    };
  }

  static String questionTypeName() {
    return "选择题";
  }

  factory ChoiceQuestion.fromJson(Map<String, dynamic> jsonMap) {
    return _$ChoiceQuestionFromJson(jsonMap);
  }

  @override
  Map<String, dynamic> toJson() {
    return _$ChoiceQuestionToJson(this);
  }

  @override
  String defaultQuestionName() {
    return questionTypeName();
  }

  @override
  Widget buildAnswerAreaWidget(BuildContext context, {
    required CommonStyles? commonStyles,
    required void Function(QuestionResult) goToNextQuestion,
  }) {
    return ChoiceQuestionAnswerArea(question: this, commonStyles: commonStyles, goToNextQuestion: goToNextQuestion);
  }
}

@JsonSerializable(explicitToJson: true)
class CommandQuestion extends Question {
  CommandQuestion({
    super.id,
    super.alias,
    super.questionText = "请按照给出的指令进行操作",
    super.audioUrl,
    super.imageUrl,
    super.omitImageAfterSeconds,
    super.evalRule,
  }) {
    evalRule ??= EvalCommandQuestionByCorrectActionCount();
  }

  /// 返回的map中，key为可用的评分规则，value是一个返回一个key对应类型对象的函数
  static Map<Type, dynamic> availableEvalRuleTypes() {
    return {
      EvalCommandQuestionByCorrectActionCount: {
        ClassProperties.constructor: () =>
            () => EvalCommandQuestionByCorrectActionCount(),
        ClassProperties.displayName:
            EvalCommandQuestionByCorrectActionCount.ruleDisplayName(),
      },
    };
  }

  static String questionTypeName() {
    return "指令题";
  }

  factory CommandQuestion.fromJson(Map<String, dynamic> jsonMap) {
    final tmp = _$CommandQuestionFromJson(jsonMap);
    // debugPrint(jsonEncode(tmp.toJson()));
    return tmp;
  }

  @override
  Map<String, dynamic> toJson() {
    return _$CommandQuestionToJson(this);
  }

  @override
  String defaultQuestionName() {
    return questionTypeName();
  }

  @override
  Widget buildAnswerAreaWidget(BuildContext context, {
    required CommonStyles? commonStyles,
    required void Function(QuestionResult) goToNextQuestion,
  }) {
    return CommandQuestionAnswerArea(question: this, commonStyles: commonStyles, goToNextQuestion: goToNextQuestion);
  }
}

@JsonSerializable(explicitToJson: true)
class WritingQuestion extends Question {
  WritingQuestion({
    super.id,
    super.alias,
    super.questionText,
    super.audioUrl,
    super.imageUrl,
    super.omitImageAfterSeconds,
    super.evalRule,
  }) {
    evalRule ??= EvalWritingQuestionByCorrectKeywordCount();
  }

  /// 返回的map中，key为可用的评分规则，value是一个返回一个key对应类型对象的函数
  static Map<Type, dynamic> availableEvalRuleTypes() {
    return {
      EvalWritingQuestionByCorrectKeywordCount: {
        ClassProperties.constructor: () =>
            EvalWritingQuestionByCorrectKeywordCount(),
        ClassProperties.displayName:
            EvalWritingQuestionByCorrectKeywordCount.ruleDisplayName(),
      },
      EvalWritingQuestionByMatchRate: {
        ClassProperties.constructor: () => EvalWritingQuestionByMatchRate(),
        ClassProperties.displayName:
            EvalWritingQuestionByMatchRate.ruleDisplayName(),
      },
    };
  }

  static String questionTypeName() {
    return "书写作答题";
  }

  factory WritingQuestion.fromJson(Map<String, dynamic> jsonMap) {
    return _$WritingQuestionFromJson(jsonMap);
  }

  @override
  Map<String, dynamic> toJson() {
    return _$WritingQuestionToJson(this);
  }

  @override
  String defaultQuestionName() {
    return questionTypeName();
  }

  @override
  Widget buildAnswerAreaWidget(BuildContext context, {
    required CommonStyles? commonStyles,
    required void Function(QuestionResult) goToNextQuestion,
  }) {
    return WritingQuestionAnswerArea(question: this, commonStyles: commonStyles, goToNextQuestion: goToNextQuestion);
  }
}

@JsonSerializable(explicitToJson: true)
class ItemFindingQuestion extends Question {
  ItemFindingQuestion({
    super.id,
    super.alias,
    super.questionText,
    super.audioUrl,
    super.imageUrl,
    super.omitImageAfterSeconds,
    super.evalRule,
  }) {
    evalRule ??= EvalItemFoundQuestion();
  }

  static Map<Type, dynamic> availableEvalRuleTypes() {
    return {
      EvalItemFoundQuestion: {
        ClassProperties.constructor: () => EvalItemFoundQuestion(),
        ClassProperties.displayName: EvalItemFoundQuestion.ruleDisplayName()
      },
    };
  }

  static String questionTypeName() {
    return "场景寻物题";
  }

  factory ItemFindingQuestion.fromJson(Map<String, dynamic> jsonMap) {
    return _$ItemFindingQuestionFromJson(jsonMap);
  }

  @override
  Map<String, dynamic> toJson() {
    return _$ItemFindingQuestionToJson(this);
  }

  @override
  String defaultQuestionName() {
    return questionTypeName();
  }

  @override
  Widget buildAnswerAreaWidget(BuildContext context, {
    required CommonStyles? commonStyles,
    required void Function(QuestionResult) goToNextQuestion,
  }) {
    return ItemFindingQuestionAnswerArea(question: this, commonStyles: commonStyles, goToNextQuestion: goToNextQuestion);
  }
}
