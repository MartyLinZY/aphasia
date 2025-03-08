// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AudioQuestion _$AudioQuestionFromJson(Map<String, dynamic> json) =>
    AudioQuestion(
      id: json['id'] as String?,
      alias: json['alias'] as String?,
      questionText: json['questionText'] as String?,
      audioUrl: json['audioUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      omitImageAfterSeconds: json['omitImageAfterSeconds'] as int?,
      evalRule: json['evalRule'] == null
          ? null
          : QuestionEvalRule.fromJson(json['evalRule'] as Map<String, dynamic>),
    )..typeName = json['typeName'] as String;

Map<String, dynamic> _$AudioQuestionToJson(AudioQuestion instance) =>
    <String, dynamic>{
      'alias': instance.alias,
      'questionText': instance.questionText,
      'audioUrl': instance.audioUrl,
      'imageUrl': instance.imageUrl,
      'omitImageAfterSeconds': instance.omitImageAfterSeconds,
      'typeName': instance.typeName,
      'evalRule': instance.evalRule?.toJson(),
      'id': instance.id,
    };

ChoiceQuestion _$ChoiceQuestionFromJson(Map<String, dynamic> json) =>
    ChoiceQuestion(
      id: json['id'] as String?,
      alias: json['alias'] as String?,
      questionText: json['questionText'] as String?,
      audioUrl: json['audioUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      omitImageAfterSeconds: json['omitImageAfterSeconds'] as int?,
      evalRule: json['evalRule'] == null
          ? null
          : QuestionEvalRule.fromJson(json['evalRule'] as Map<String, dynamic>),
    )..typeName = json['typeName'] as String;

Map<String, dynamic> _$ChoiceQuestionToJson(ChoiceQuestion instance) =>
    <String, dynamic>{
      'alias': instance.alias,
      'questionText': instance.questionText,
      'audioUrl': instance.audioUrl,
      'imageUrl': instance.imageUrl,
      'omitImageAfterSeconds': instance.omitImageAfterSeconds,
      'typeName': instance.typeName,
      'evalRule': instance.evalRule?.toJson(),
      'id': instance.id,
    };

CommandQuestion _$CommandQuestionFromJson(Map<String, dynamic> json) =>
    CommandQuestion(
      id: json['id'] as String?,
      alias: json['alias'] as String?,
      questionText: json['questionText'] as String? ?? "请按照给出的指令进行操作",
      audioUrl: json['audioUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      omitImageAfterSeconds: json['omitImageAfterSeconds'] as int?,
      evalRule: json['evalRule'] == null
          ? null
          : QuestionEvalRule.fromJson(json['evalRule'] as Map<String, dynamic>),
    )..typeName = json['typeName'] as String;

Map<String, dynamic> _$CommandQuestionToJson(CommandQuestion instance) =>
    <String, dynamic>{
      'alias': instance.alias,
      'questionText': instance.questionText,
      'audioUrl': instance.audioUrl,
      'imageUrl': instance.imageUrl,
      'omitImageAfterSeconds': instance.omitImageAfterSeconds,
      'typeName': instance.typeName,
      'evalRule': instance.evalRule?.toJson(),
      'id': instance.id,
    };

WritingQuestion _$WritingQuestionFromJson(Map<String, dynamic> json) =>
    WritingQuestion(
      id: json['id'] as String?,
      alias: json['alias'] as String?,
      questionText: json['questionText'] as String?,
      audioUrl: json['audioUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      omitImageAfterSeconds: json['omitImageAfterSeconds'] as int?,
      evalRule: json['evalRule'] == null
          ? null
          : QuestionEvalRule.fromJson(json['evalRule'] as Map<String, dynamic>),
    )..typeName = json['typeName'] as String;

Map<String, dynamic> _$WritingQuestionToJson(WritingQuestion instance) =>
    <String, dynamic>{
      'alias': instance.alias,
      'questionText': instance.questionText,
      'audioUrl': instance.audioUrl,
      'imageUrl': instance.imageUrl,
      'omitImageAfterSeconds': instance.omitImageAfterSeconds,
      'typeName': instance.typeName,
      'evalRule': instance.evalRule?.toJson(),
      'id': instance.id,
    };

ItemFindingQuestion _$ItemFindingQuestionFromJson(Map<String, dynamic> json) =>
    ItemFindingQuestion(
      id: json['id'] as String?,
      alias: json['alias'] as String?,
      questionText: json['questionText'] as String?,
      audioUrl: json['audioUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      omitImageAfterSeconds: json['omitImageAfterSeconds'] as int?,
      evalRule: json['evalRule'] == null
          ? null
          : QuestionEvalRule.fromJson(json['evalRule'] as Map<String, dynamic>),
    )..typeName = json['typeName'] as String;

Map<String, dynamic> _$ItemFindingQuestionToJson(
        ItemFindingQuestion instance) =>
    <String, dynamic>{
      'alias': instance.alias,
      'questionText': instance.questionText,
      'audioUrl': instance.audioUrl,
      'imageUrl': instance.imageUrl,
      'omitImageAfterSeconds': instance.omitImageAfterSeconds,
      'typeName': instance.typeName,
      'evalRule': instance.evalRule?.toJson(),
      'id': instance.id,
    };
