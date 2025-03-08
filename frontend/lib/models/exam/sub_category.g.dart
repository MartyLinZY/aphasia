// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sub_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuestionSubCategory _$QuestionSubCategoryFromJson(Map<String, dynamic> json) =>
    QuestionSubCategory(
      description: json['description'] as String? ?? "新子项",
    )
      ..questions = (json['questions'] as List<dynamic>)
          .map((e) => Question.fromJson(e as Map<String, dynamic>))
          .toList()
      ..terminateRules = (json['terminateRules'] as List<dynamic>)
          .map((e) => TerminateRule.fromJson(e as Map<String, dynamic>))
          .toList()
      ..evalRules = (json['evalRules'] as List<dynamic>)
          .map((e) =>
              ExamSubCategoryEvalRule.fromJson(e as Map<String, dynamic>))
          .toList();

Map<String, dynamic> _$QuestionSubCategoryToJson(
        QuestionSubCategory instance) =>
    <String, dynamic>{
      'description': instance.description,
      'questions': instance.questions.map((e) => e.toJson()).toList(),
      'terminateRules': instance.terminateRules.map((e) => e.toJson()).toList(),
      'evalRules': instance.evalRules.map((e) => e.toJson()).toList(),
    };
