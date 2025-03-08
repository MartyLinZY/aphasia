// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exam_recovery.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExamQuestionSet _$ExamQuestionSetFromJson(Map<String, dynamic> json) =>
    ExamQuestionSet(
      id: json['id'] as String?,
      name: json['name'] as String? ?? "新测评",
      description: json['description'] as String? ?? "",
      recovery: json['recovery'] as bool? ?? false,
    )
      ..published = json['published'] as bool
      ..categories = (json['categories'] as List<dynamic>)
          .map((e) => QuestionCategory.fromJson(e as Map<String, dynamic>))
          .toList()
      ..diagnosisRules = (json['diagnosisRules'] as List<dynamic>)
          .map((e) => DiagnosisRule.fromJson(e as Map<String, dynamic>))
          .toList()
      ..rules = (json['rules'] as List<dynamic>)
          .map((e) => ExamEvalRule.fromJson(e as Map<String, dynamic>))
          .toList();

Map<String, dynamic> _$ExamQuestionSetToJson(ExamQuestionSet instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'recovery': instance.recovery,
      'published': instance.published,
      'categories': instance.categories.map((e) => e.toJson()).toList(),
      'id': instance.id,
      'diagnosisRules': instance.diagnosisRules.map((e) => e.toJson()).toList(),
      'rules': instance.rules.map((e) => e.toJson()).toList(),
    };
