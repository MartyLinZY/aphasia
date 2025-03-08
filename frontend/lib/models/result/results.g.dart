// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'results.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExamResult _$ExamResultFromJson(Map<String, dynamic> json) => ExamResult(
      id: json['id'] as String?,
      resultText: json['resultText'] as String?,
      finalScore: (json['finalScore'] as num?)?.toDouble(),
      startTime: json['startTime'] == null
          ? null
          : DateTime.parse(json['startTime'] as String),
      finishTime: json['finishTime'] == null
          ? null
          : DateTime.parse(json['finishTime'] as String),
      isRecovery: json['isRecovery'] as bool? ?? false,
      examName: json['examName'] as String,
    )..categoryResults = (json['categoryResults'] as List<dynamic>)
        .map((e) => CategoryResult.fromJson(e as Map<String, dynamic>))
        .toList();

Map<String, dynamic> _$ExamResultToJson(ExamResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'resultText': instance.resultText,
      'finalScore': instance.finalScore,
      'startTime': instance.startTime?.toIso8601String(),
      'finishTime': instance.finishTime?.toIso8601String(),
      'isRecovery': instance.isRecovery,
      'examName': instance.examName,
      'categoryResults':
          instance.categoryResults.map((e) => e.toJson()).toList(),
    };

CategoryResult _$CategoryResultFromJson(Map<String, dynamic> json) =>
    CategoryResult(
      name: json['name'] as String?,
      finalScore: (json['finalScore'] as num?)?.toDouble(),
    )..subResults = (json['subResults'] as List<dynamic>)
        .map((e) => SubCategoryResult.fromJson(e as Map<String, dynamic>))
        .toList();

Map<String, dynamic> _$CategoryResultToJson(CategoryResult instance) =>
    <String, dynamic>{
      'name': instance.name,
      'finalScore': instance.finalScore,
      'subResults': instance.subResults.map((e) => e.toJson()).toList(),
    };

SubCategoryResult _$SubCategoryResultFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['questionResults'],
  );
  return SubCategoryResult(
    finalScore: (json['finalScore'] as num?)?.toDouble(),
    name: json['name'] as String?,
    terminateReason: json['terminateReason'] as String?,
  )..questionResults = (json['questionResults'] as List<dynamic>)
      .map((e) => QuestionResult.fromJson(e as Map<String, dynamic>))
      .toList();
}

Map<String, dynamic> _$SubCategoryResultToJson(SubCategoryResult instance) =>
    <String, dynamic>{
      'name': instance.name,
      'finalScore': instance.finalScore,
      'terminateReason': instance.terminateReason,
      'questionResults':
          instance.questionResults.map((e) => e.toJson()).toList(),
    };

AudioQuestionResult _$AudioQuestionResultFromJson(Map<String, dynamic> json) =>
    AudioQuestionResult(
      sourceQuestion:
          Question.fromJson(json['sourceQuestion'] as Map<String, dynamic>),
      audioContent: json['audioContent'] as String? ?? "",
      answerTime: json['answerTime'] as int?,
    )
      ..finalScore = (json['finalScore'] as num?)?.toDouble()
      ..isHinted = json['isHinted'] as bool
      ..extraResults = Map<String, String>.from(json['extraResults'] as Map)
      ..typeName = json['typeName'] as String;

Map<String, dynamic> _$AudioQuestionResultToJson(
        AudioQuestionResult instance) =>
    <String, dynamic>{
      'sourceQuestion': instance.sourceQuestion.toJson(),
      'finalScore': instance.finalScore,
      'answerTime': instance.answerTime,
      'isHinted': instance.isHinted,
      'extraResults': instance.extraResults,
      'typeName': instance.typeName,
      'audioContent': instance.audioContent,
    };

CommandQuestionResult _$CommandQuestionResultFromJson(
        Map<String, dynamic> json) =>
    CommandQuestionResult(
      sourceQuestion:
          Question.fromJson(json['sourceQuestion'] as Map<String, dynamic>),
      actions: (json['actions'] as List<dynamic>?)
          ?.map((e) => CommandActions.fromJson(e as Map<String, dynamic>))
          .toList(),
      answerTime: json['answerTime'] as int?,
    )
      ..finalScore = (json['finalScore'] as num?)?.toDouble()
      ..isHinted = json['isHinted'] as bool
      ..extraResults = Map<String, String>.from(json['extraResults'] as Map)
      ..typeName = json['typeName'] as String;

Map<String, dynamic> _$CommandQuestionResultToJson(
        CommandQuestionResult instance) =>
    <String, dynamic>{
      'sourceQuestion': instance.sourceQuestion.toJson(),
      'finalScore': instance.finalScore,
      'answerTime': instance.answerTime,
      'isHinted': instance.isHinted,
      'extraResults': instance.extraResults,
      'typeName': instance.typeName,
      'actions': instance.actions.map((e) => e.toJson()).toList(),
    };

ChoiceQuestionResult _$ChoiceQuestionResultFromJson(
        Map<String, dynamic> json) =>
    ChoiceQuestionResult(
      sourceQuestion:
          Question.fromJson(json['sourceQuestion'] as Map<String, dynamic>),
      choiceSelected: (json['choiceSelected'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
      answerTime: json['answerTime'] as int?,
    )
      ..finalScore = (json['finalScore'] as num?)?.toDouble()
      ..isHinted = json['isHinted'] as bool
      ..extraResults = Map<String, String>.from(json['extraResults'] as Map)
      ..typeName = json['typeName'] as String;

Map<String, dynamic> _$ChoiceQuestionResultToJson(
        ChoiceQuestionResult instance) =>
    <String, dynamic>{
      'sourceQuestion': instance.sourceQuestion.toJson(),
      'finalScore': instance.finalScore,
      'answerTime': instance.answerTime,
      'isHinted': instance.isHinted,
      'extraResults': instance.extraResults,
      'typeName': instance.typeName,
      'choiceSelected': instance.choiceSelected,
    };

WritingQuestionResult _$WritingQuestionResultFromJson(
        Map<String, dynamic> json) =>
    WritingQuestionResult(
      sourceQuestion:
          Question.fromJson(json['sourceQuestion'] as Map<String, dynamic>),
      answerTime: json['answerTime'] as int?,
    )
      ..finalScore = (json['finalScore'] as num?)?.toDouble()
      ..isHinted = json['isHinted'] as bool
      ..extraResults = Map<String, String>.from(json['extraResults'] as Map)
      ..typeName = json['typeName'] as String;

Map<String, dynamic> _$WritingQuestionResultToJson(
        WritingQuestionResult instance) =>
    <String, dynamic>{
      'sourceQuestion': instance.sourceQuestion.toJson(),
      'finalScore': instance.finalScore,
      'answerTime': instance.answerTime,
      'isHinted': instance.isHinted,
      'extraResults': instance.extraResults,
      'typeName': instance.typeName,
    };

ItemFindingQuestionResult _$ItemFindingQuestionResultFromJson(
        Map<String, dynamic> json) =>
    ItemFindingQuestionResult(
      sourceQuestion:
          Question.fromJson(json['sourceQuestion'] as Map<String, dynamic>),
      answerTime: json['answerTime'] as int?,
    )
      ..finalScore = (json['finalScore'] as num?)?.toDouble()
      ..isHinted = json['isHinted'] as bool
      ..extraResults = Map<String, String>.from(json['extraResults'] as Map)
      ..typeName = json['typeName'] as String
      ..clickCoordinate = (json['clickCoordinate'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList();

Map<String, dynamic> _$ItemFindingQuestionResultToJson(
        ItemFindingQuestionResult instance) =>
    <String, dynamic>{
      'sourceQuestion': instance.sourceQuestion.toJson(),
      'finalScore': instance.finalScore,
      'answerTime': instance.answerTime,
      'isHinted': instance.isHinted,
      'extraResults': instance.extraResults,
      'typeName': instance.typeName,
      'clickCoordinate': instance.clickCoordinate,
    };
