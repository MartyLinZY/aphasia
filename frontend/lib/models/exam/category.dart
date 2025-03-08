
import 'dart:convert';

import 'package:aphasia_recovery/models/exam/sub_category.dart';
import 'package:json_annotation/json_annotation.dart';

import '../rules.dart';
import 'exam_recovery.dart';

part 'category.g.dart';

@JsonSerializable(explicitToJson: true)
class QuestionCategory {
  String description;
  List<QuestionSubCategory> subCategories = [];
  List<ExamCategoryEvalRule> rules = [];

  QuestionCategory({this.description = ""})
      : subCategories = <QuestionSubCategory>[];

  factory QuestionCategory.copy(QuestionCategory old) {
    return QuestionCategory.fromJson(jsonDecode(jsonEncode(old.toJson())));
  }

  factory QuestionCategory.fromJson(Map<String, dynamic> jsonData) {
    return _$QuestionCategoryFromJson(jsonData);
  }

  Map<String, dynamic> toJson() {
    return _$QuestionCategoryToJson(this);
  }

  /// 仅本地添加测评子项，不与后端同步
  void addSubCategoryLocally({String description = "新子项"}) {
    subCategories.add(QuestionSubCategory(description: description));
  }
}