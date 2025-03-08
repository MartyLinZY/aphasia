// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuestionCategory _$QuestionCategoryFromJson(Map<String, dynamic> json) =>
    QuestionCategory(
      description: json['description'] as String? ?? "",
    )
      ..subCategories = (json['subCategories'] as List<dynamic>)
          .map((e) => QuestionSubCategory.fromJson(e as Map<String, dynamic>))
          .toList()
      ..rules = (json['rules'] as List<dynamic>)
          .map((e) => ExamCategoryEvalRule.fromJson(e as Map<String, dynamic>))
          .toList();

Map<String, dynamic> _$QuestionCategoryToJson(QuestionCategory instance) =>
    <String, dynamic>{
      'description': instance.description,
      'subCategories': instance.subCategories.map((e) => e.toJson()).toList(),
      'rules': instance.rules.map((e) => e.toJson()).toList(),
    };
